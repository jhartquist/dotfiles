#!/usr/bin/env bash
# Fresh Ubuntu → home environment synced with the mac, and every rebuild after.
# Idempotent. The system layer stays apt's (CUDA drivers, nvidia stack);
# nix + home-manager own only $HOME.
set -euo pipefail

CONFIG="john@ubuntu"
LINK="$HOME/.dotfiles"                       # stable path home.nix resolves through
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

have() { command -v "$1" >/dev/null 2>&1; }
say()  { printf '\n==> %s\n' "$*"; }

[ "$(uname -s)" = Linux ] || { echo "Linux only." >&2; exit 1; }
[ "$(id -u)" -ne 0 ] || { echo "Don't sudo this script." >&2; exit 1; }

# Nix (Determinate). curl|sh is fine on Linux — the .pkg dance is mac-only.
if ! have nix && [ ! -e /nix/var/nix/profiles/default/bin/nix ]; then
  say "Installing Determinate Nix"
  curl --proto '=https' --tlsv1.2 -sSfL https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
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

# Switch. -b: anything unmanaged in the way gets renamed, not an error.
say "Applying #$CONFIG"
if have home-manager; then
  home-manager switch --flake "$LINK#$CONFIG" -b hm-backup
else
  nix run home-manager/release-26.05 -- switch --flake "$LINK#$CONFIG" -b hm-backup
fi

# Toolchain *versions* are imperative — rustup/fnm install them, not nix. Do it
# here, AFTER the switch, so a network hiccup can't fail the switch itself.
prof="$HOME/.nix-profile/bin"
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

say "Done"
