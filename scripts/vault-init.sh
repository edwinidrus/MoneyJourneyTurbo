#!/usr/bin/env bash
# Create or extend a vault at any path (WSL ext4, /mnt/c/..., or a cloud-synced folder).
# Adds missing folders and templates only; never overwrites existing notes.
set -euo pipefail

target="${1:-${VAULT_PATH:-}}"
[ -n "$target" ] || { echo "usage: $0 <vault-path>   (or set VAULT_PATH)" >&2; exit 1; }
template="$(cd "$(dirname "$0")/../vault-template" && pwd)"

mkdir -p "$target"
cp -r --update=none "$template"/. "$target"/

cd "$target"
if [ ! -d .git ] && ! git rev-parse --git-dir >/dev/null 2>&1; then
  git init -q
  [ -f .gitignore ] || printf '.obsidian/workspace*.json\n.trash/\n' > .gitignore
  git add -A && git commit -qm "vault init" && echo "git repo initialised"
fi
echo "vault ready at $(pwd)"
