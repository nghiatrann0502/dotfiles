#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow is not installed."
  exit 1
fi

stow --dir="$DOTFILES_DIR" --target="$HOME" --delete \
  zsh ghostty starship atuin tmux git

echo "Dotfile symlinks removed. Packages and application data were left untouched."
