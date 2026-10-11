# dotfiles

macOS setup managed with `nix-darwin`, `home-manager`, and `nix-homebrew`.

Covers:
- macOS settings
- apps/packages
- dev toolchains
- configs
  - zsh
  - git
  - herdr
  - wezterm
  - neovim

## Prerequisites

- Xcode Command Line Tools: `xcode-select --install` (needed before cloning)
- `~/private/` restored from backup — fonts, `secrets.zsh`, wallpaper.
  Optional; skipped when absent.

## Install

```sh
git clone https://github.com/jhartquist/dotfiles.git ~/git/jhartquist/dotfiles
cd ~/git/jhartquist/dotfiles
./rebuild.sh            # host picked by $USER; or ./rebuild.sh personal|work
```

Per-machine differences (user, git email, commit signing) live in the
`hosts` attrset in `flake.nix`; everything else is shared.

## Ubuntu (home environment only)

The deep-learning box keeps its system layer on apt (CUDA drivers, nvidia
stack); nix + home-manager manage only the user environment — same zsh, nvim,
tmux, and CLI tools as the mac, from the shared `home.nix`.

```sh
git clone https://github.com/jhartquist/dotfiles.git ~/git/jhartquist/dotfiles
cd ~/git/jhartquist/dotfiles
./setup-ubuntu.sh
```

Structure based on [kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles).
