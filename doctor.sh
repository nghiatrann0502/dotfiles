#!/usr/bin/env bash

set -uo pipefail

commands=(
  brew stow ghostty fzf tmux zoxide eza bat starship atuin
  fd rg jq yq xh delta lazygit gh btop dust duf procs
  tldr hyperfine just go uv rustup rustc cargo rustfmt rust-analyzer
)

failed=0
for command_name in "${commands[@]}"; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '✓ %s\n' "$command_name"
  else
    printf '✗ %s\n' "$command_name"
    failed=1
  fi
done

if command -v cargo >/dev/null 2>&1 && cargo clippy --version >/dev/null 2>&1; then
  echo "✓ clippy"
else
  echo "✗ clippy"
  failed=1
fi

if zsh -n "$HOME/.zshrc"; then
  echo "✓ ~/.zshrc syntax"
else
  echo "✗ ~/.zshrc syntax"
  failed=1
fi

exit "$failed"
