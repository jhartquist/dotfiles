{ lib, user, ... }:

{
  home.homeDirectory = "/home/${user}";

  # Non-NixOS host (vanilla Ubuntu): wires nix profiles into XDG dirs and
  # session vars so desktop entries, fonts, and PATH behave.
  targets.genericLinux.enable = true;

  # Agent tooling the Mac gets from brew casks and the T3 desktop app. Official
  # installers into ~/.local/bin, not nix, so each one's updater works (`t3
  # update`, `herdr update`, codex's own). Bootstrap once if missing. System
  # PATH is appended because the installers use tar, sha256sum, etc. `t3 up`
  # (once, by hand) sets up its systemd service, lingering, and T3 Connect.
  home.activation.installAgentClis =
    lib.hm.dag.entryBetween [ "installHerdrSplits" ] [ "writeBoundary" ] ''
      export PATH="$HOME/.local/bin:$PATH:/usr/bin:/bin"
      for tool in t3=https://t3.codes/install.sh \
                  herdr=https://herdr.dev/install.sh \
                  codex=https://chatgpt.com/codex/install.sh; do
        bin="''${tool%%=*}" url="''${tool#*=}"
        [ -x "$HOME/.local/bin/$bin" ] && continue
        script="$(curl -fsSL "$url")" \
          && CODEX_NON_INTERACTIVE=1 sh -c "$script" </dev/null \
          || echo "$bin install failed; rerun: curl -fsSL $url | sh"
      done
    '';
}
