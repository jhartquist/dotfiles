{ user, ... }:

{
  home.homeDirectory = "/home/${user}";

  # Non-NixOS host (vanilla Ubuntu): wires nix profiles into XDG dirs and
  # session vars so desktop entries, fonts, and PATH behave.
  targets.genericLinux.enable = true;
}
