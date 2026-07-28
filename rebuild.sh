#!/usr/bin/env bash
# Fresh macOS → fully-configured machine, and every rebuild after. Idempotent.
set -euo pipefail

HOST="${HOST:-mac}"
LINK="$HOME/.dotfiles"                       # stable path home.nix resolves through
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

have() { command -v "$1" >/dev/null 2>&1; }
say()  { printf '\n==> %s\n' "$*"; }

[ "$(uname -s)" = Darwin ] || { echo "macOS only." >&2; exit 1; }
# Run as the user: symlinks, defaults, and home files are per-user. The steps
# that need root (pkg install, darwin-rebuild) sudo-prompt on their own.
[ "$(id -u)" -ne 0 ] || { echo "Don't sudo this script." >&2; exit 1; }

# Nix (Determinate). It owns the daemon; nix-darwin builds against it.
# The .pkg, not the curl|sh installer: on fresh FileVault Macs the shell
# installer's `diskutil mount` of the Nix Store volume is denied; the native
# installer path isn't.
if ! have nix && [ ! -e /nix/var/nix/profiles/default/bin/nix ]; then
  say "Installing Determinate Nix"
  tmp="$(mktemp -d)"
  curl --proto '=https' --tlsv1.2 -sSfL -o "$tmp/determinate.pkg" \
    "https://install.determinate.systems/determinate-pkg/stable/Universal"
  sudo installer -pkg "$tmp/determinate.pkg" -target /
  rm -rf "$tmp"
fi
# The daemon profile reads unset vars, which trips `set -u`; bracket the source.
if ! have nix; then
  set +u; . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; set -u
fi

# ~/.dotfiles indirection: home.nix's mkOutOfStoreSymlink paths resolve through
# it. -n replaces the link instead of following it into the target directory.
[ "$DIR" = "$LINK" ] || ln -sfn "$DIR" "$LINK"

# Flakes read the git tree, not the working dir — untracked files don't exist.
untracked="$(git -C "$DIR" ls-files --others --exclude-standard -- '*.nix')"
[ -z "$untracked" ] || {
  say "Untracked .nix files are invisible to the flake:"
  printf '    %s\n' $untracked
  printf '    fix: git -C %s add -A\n' "$DIR"
  exit 1
}

# Switch. Homebrew is installed by nix-homebrew during activation, not here.
say "Applying #$HOST"
if have darwin-rebuild; then
  sudo darwin-rebuild switch --flake "$LINK#$HOST"
else
  # First run: darwin-rebuild doesn't exist yet. Bootstrap it from the pinned
  # release branch (sudo's secure PATH drops /nix/.../bin, so pass nix's
  # absolute path). The applied config is still this repo's locked flake.
  sudo "$(command -v nix)" \
    --extra-experimental-features 'nix-command flakes' \
    run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
    switch --flake "$LINK#$HOST"
fi

# Toolchain *versions* are imperative — rustup/fnm install them, not nix. Do it
# here, AFTER the switch, so a network hiccup can't fail the system switch
# itself. Guarded, so repeat runs are instant no-ops.
prof="/etc/profiles/per-user/$USER/bin"
say "Bootstrapping toolchains"
if [ -x "$prof/rustup" ]; then
  "$prof/rustup" show active-toolchain &>/dev/null \
    || "$prof/rustup" default stable || echo "  rustup default stable failed — run it by hand"
  # rust-analyzer rides the toolchain (rustup's bin shim), not nix — see home.nix
  "$prof/rustup" component list --installed 2>/dev/null | grep -q rust-analyzer \
    || "$prof/rustup" component add rust-analyzer \
    || echo "  rustup component add rust-analyzer failed — run it by hand"
fi
if [ -x "$prof/fnm" ] && ! "$prof/fnm" list | grep -qE 'v[0-9]'; then
  "$prof/fnm" install --lts && "$prof/fnm" default lts-latest \
    || echo "  fnm install --lts failed — run it by hand"
fi

# Licensed fonts (Berkeley Mono etc.) live OUTSIDE the public repo, under
# ~/private/fonts — a plain dir, or a symlink to an SSD/Drive folder. Guarded:
# machines without it (or a fresh clone before restore) skip silently.
if [ -d "$HOME/private/fonts" ]; then
  say "Installing private fonts"
  cp -f "$HOME"/private/fonts/*.otf "$HOME"/private/fonts/*.ttf "$HOME/Library/Fonts/" 2>/dev/null || true
fi

# Disable Spotlight's cmd-space so Raycast can own it. dict-add touches only
# entry 64 — CustomUserPreferences would replace the whole hotkey dict.
# macOS 26 needs the exact shape the Settings UI writes: boolean false + full
# value dict (verified by diffing prefs around the UI toggle); a bare
# '{enabled = 0;}' is silently ignored.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
  '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u >/dev/null 2>&1 || true

# Wallpaper: first image in ~/private/wallpaper, applied to all desktops.
wp="$(find "$HOME/private/wallpaper" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.heic' \) 2>/dev/null | head -1)"
if [ -n "$wp" ]; then
  say "Setting wallpaper"
  osascript -e "tell app \"System Events\" to set picture of every desktop to POSIX file \"$wp\"" || true
fi

say "Done"
