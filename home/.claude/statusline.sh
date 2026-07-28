#!/usr/bin/env bash
# Claude Code statusline: cwd · git branch · model. Input is JSON on stdin.
# Runs outside a login shell, so nix's jq isn't on PATH by default.
export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

input=$(cat)
model=$(jq -r '.model.display_name' <<<"$input")
dir=$(jq -r '.workspace.current_dir' <<<"$input")
# Official figure — accounts for cache tokens and the model's real window size,
# unlike transcript-summing statuslines that assume 200k.
pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
size=$(jq -r '.context_window.context_window_size // empty' <<<"$input")
used=$(jq -r '.context_window.current_usage | if . then (add | round) else empty end' <<<"$input")
branch=$(git -C "$dir" branch --show-current 2>/dev/null)

# gruvbox-ish: yellow dir, aqua branch, purple model, context green→yellow→red
printf '\033[33m%s\033[0m' "${dir/#"$HOME"/\~}"
[ -n "$branch" ] && printf ' \033[36m %s\033[0m' "$branch"
printf ' \033[35m%s\033[0m' "$model"
fmt() {  # 157321 -> 157k, 1000000 -> 1m
  if [ "$1" -ge 1000000 ]; then echo "$(($1 / 1000000))m"; else echo "$(($1 / 1000))k"; fi
}

if [ -n "$pct" ]; then
  color=32; [ "$pct" -ge 50 ] && color=33; [ "$pct" -ge 80 ] && color=31
  toks=""
  [ -n "$used" ] && [ -n "$size" ] && toks="$(fmt "$used")/$(fmt "$size") "
  printf ' \033[2m%s\033[0m\033[%sm%s%%\033[0m' "$toks" "$color" "$pct"
fi
