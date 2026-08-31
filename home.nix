{ config, lib, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  home.username = user;
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    ripgrep   # fast grep
    fd        # fast find
    fzf       # fuzzy finder
    eza       # modern ls
    bat       # cat with syntax highlighting
    jq        # json on the command line
    just      # task runner (ships its own zsh completions)
    bacon     # background rust code checker
    lazygit   # git TUI
    neovim

    # Dev toolchains — these carry over to the Ubuntu box later, too.
    rustup    # rust: manages toolchains/components/targets (not a pinned rustc)
    uv        # python: versions + venvs + packages in one tool
    fnm       # node version manager — owns node; run `fnm install --lts` once
    mise      # ruby (and anything else with a .tool-versions/.mise.toml)
    pnpm
    bun
    gh        # github cli
    oh-my-posh

    # nvim's LSP servers + formatters — declared here instead of mason, so
    # they're reproducible and on PATH for other tools too. sourcekit-lsp
    # (swift) comes with Xcode; rustfmt AND rust-analyzer come via rustup
    # (its bin/ ships proxy shims for both, which collide with the
    # standalone nix packages — and toolchain-matched versions are better).
    tree-sitter   # CLI nvim-treesitter (main branch) shells out to for parser builds
    pyright
    ruff
    typescript-language-server
    lua-language-server
    nixd
    stylua
    prettierd
    nixfmt
  ];

  home.sessionVariables.EDITOR = "nvim";

  # Per-project environments: auto-loads .envrc / flake devshells on cd. The
  # escape hatch that keeps the global toolchains above from becoming a mess.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Appended to PATH, so nix-owned tools always shadow same-named installs.
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"   # `cargo install`ed tools
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost-text suggestions from history
    syntaxHighlighting.enable = true;  # valid commands turn green

    history = {
      size = 100000;
      save = 100000;
      share = true;
      ignoreAllDups = true;
      ignoreSpace = true;
    };

    # fzf-powered tab completion (menus become fzf pickers)
    plugins = [
      { name = "fzf-tab"; src = "${pkgs.zsh-fzf-tab}/share/fzf-tab"; }
    ];

    initContent = ''
      setopt hist_save_no_dups hist_find_no_dups

      bindkey '^ ' end-of-line              # ctrl-space accepts the autosuggestion
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward

      # case-insensitive completion matching, fzf-tab dir previews
      zstyle ':completion:*' matcher-list ''' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -la --color=always $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -la --color=always $realpath'

      eval "$(fnm env --use-on-cd)"    # activate fnm; auto-switch node per .nvmrc on cd

      # mise owns ruby; without this, ruby/bundle fall through to system Ruby
      eval "$(mise activate zsh)"

      # API keys live outside the repo (1Password is the durable copy).
      [ -f ~/private/secrets.zsh ] && source ~/private/secrets.zsh

      # uv runner: `r` = uv run main.py, `r foo.py args…` = uv run foo.py args…
      run() { [ $# -eq 0 ] && uv run main.py || uv run "$@"; }

      eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"
    '';

    shellAliases = {
      ".." = "cd ..";
      v = "nvim"; vi = "nvim"; vim = "nvim";
      ls = "eza -la";
      gs = "git status";
      gits = "git status";
      ga = "git add -A";
      gp = "git push";
      gl = "git pull";
      rg = "rg --hidden --glob '!.git'";
      py = "uv run python";
      r = "run";
      c = "claude --permission-mode auto";
      icat = "wezterm imgcat";
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "John Hartquist";
      email = "john@foam.ai";
    };
    settings.init.defaultBranch = "main";
    settings.format.pretty = "oneline";
    settings.log.abbrevCommit = true;
    settings.alias = {
      l = "log --oneline";
    };
    ignores = [
      "**/.claude/settings.local.json"
      "**/CLAUDE.local.md"
      ".DS_Store"
    ];
  };

  # Syntax-highlighted diffs; was the old lazygit/jj pager.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  # Old config's delta pager, gruvbox-ified to match everything else.
  programs.lazygit.settings.git.pagers = [
    { colorArg = "always"; pager = ''delta --dark --paging=never --syntax-theme="gruvbox-dark"''; }
  ];

  programs.fzf.enable = true;      # ctrl-r history, ctrl-t files, alt-c cd
  programs.zoxide.enable = true;   # `z` — frecency-ranked cd

  # Ported from the pre-nix .tmux.conf; tpm replaced by nix-managed plugins.
  programs.tmux = {
    enable = true;
    prefix = "C-s";
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    escapeTime = 10;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator   # C-h/j/k/l across panes AND nvim splits (nvim half in init.lua)
      mode-indicator
      {
        plugin = gruvbox;  # theme options must be set before the plugin loads
        extraConfig = ''
          set -g @tmux-gruvbox-statusbar-alpha 'true'
          set -g @tmux-gruvbox-right-status-z '#h #{tmux_mode_indicator}'
        '';
      }
    ];
    extraConfig = ''
      set -g status-position top
      set -g allow-passthrough on   # image protocols (wezterm imgcat) through tmux
      set -g extended-keys on
      set -as terminal-features ',*:extkeys'

      bind r source-file ~/.config/tmux/tmux.conf
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind X kill-pane
      bind t if -F '#{s/off//:status}' 'set status off' 'set status on'
    '';
  };

  # Edit-in-place: the real config lives in this repo, ~/.config just points at
  # it (via ~/.dotfiles), so editing needs no rebuild — only new files do.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/ohmyposh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/ohmyposh";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";

  # force: settings.json predates home-manager managing it; replace, don't error.
  home.file.".claude/settings.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
    force = true;
  };
  home.file.".claude/statusline.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/statusline.sh";

  # Agent skills, managed by `npx skills` — content in .agents/skills, a layer
  # of relative symlinks in .claude/skills. Both vendored in the repo; the
  # relative links resolve within it, and `npx skills` writes flow back here.
  home.file.".agents".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents";
  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/skills";

  # Claude Code: native installer, not nix/brew, so its self-updater works.
  # Bootstrap once if missing; after that the binary manages itself.
  home.activation.installClaudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x "$HOME/.local/bin/claude" ]; then
      PATH="${lib.makeBinPath [ pkgs.curl pkgs.coreutils pkgs.perl ]}:$PATH" \
        ${pkgs.bash}/bin/bash -c "$(${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh)"
    fi
  '';

  # herdr-splits: herdr half of the seamless pane/split nav plugin (nvim half
  # pinned in nvim/lazy-lock.json — keep this --ref on the same commit).
  # Bootstrap once if missing; herdr manages it after that.
  home.activation.installHerdrSplits = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    herdr=/opt/homebrew/bin/herdr
    if [ -x "$herdr" ] && ! "$herdr" plugin list 2>/dev/null | grep -qw "herdr-splits"; then
      "$herdr" plugin install lmilojevicc/herdr-splits.nvim \
        --ref 94f30cf4e9ac76ddf185a3acd0977be728fa4106 --yes \
        || echo "herdr-splits install failed; rerun: herdr plugin install lmilojevicc/herdr-splits.nvim"
    fi
  '';

  # One instruction file for every agent CLI.
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
