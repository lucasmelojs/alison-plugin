#!/usr/bin/env bash
# apresentacao-plugin — installs the machine-wide git ignore list (layer 1).
# Idempotent: creates ~/.config/git/ignore or appends missing lines to whatever
# core.excludesFile the person already has. Prints one status line for the skill.
# Skips (exit 0) when git is not really installed — on macOS the /usr/bin/git stub
# would pop the "install developer tools" dialog, which is not ours to trigger.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="$HERE/../templates/gitignore.global"

if [ "$(uname)" = "Darwin" ] && ! xcode-select -p >/dev/null 2>&1; then
  echo "gitignore_global=skipped reason=git-not-installed"
  exit 0
fi
command -v git >/dev/null 2>&1 || { echo "gitignore_global=skipped reason=git-not-installed"; exit 0; }

target="$(git config --global --get core.excludesFile 2>/dev/null || true)"
if [ -z "$target" ]; then
  target="$HOME/.config/git/ignore"
  mkdir -p "$(dirname "$target")"
  git config --global core.excludesFile "$target"
fi
target="${target/#\~/$HOME}"

if [ ! -f "$target" ]; then
  cp "$TPL" "$target"
  echo "gitignore_global=created path=$target"
  exit 0
fi

added=0
{
  echo; echo "# --- added by apresentacao-plugin ($(date +%F)) ---"
} > "$target.tmp.$$"
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue ;; esac
  grep -qxF -- "$line" "$target" || { echo "$line" >> "$target.tmp.$$"; added=$((added + 1)); }
done < "$TPL"
if [ "$added" -gt 0 ]; then cat "$target.tmp.$$" >> "$target"; fi
rm -f "$target.tmp.$$"
echo "gitignore_global=merged path=$target added=$added"
