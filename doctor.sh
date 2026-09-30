#!/usr/bin/env bash

set -uo pipefail

# rustup installs its command shims in ~/.cargo/bin.
# Load this explicitly so doctor.sh works even before Zsh is restarted.
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
else
  export PATH="$HOME/.cargo/bin:$PATH"
fi

commands=(
  brew stow ghostty fzf tmux zoxide eza bat starship atuin
  colima docker docker-credential-osxkeychain
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

if docker compose version >/dev/null 2>&1; then
  echo "✓ docker compose"
else
  echo "✗ docker compose"
  failed=1
fi

if docker buildx version >/dev/null 2>&1; then
  echo "✓ docker buildx"
else
  echo "✗ docker buildx"
  failed=1
fi

if colima status >/dev/null 2>&1; then
  echo "✓ Colima running"
  if docker --context colima info >/dev/null 2>&1; then
    echo "✓ Colima Docker daemon reachable"
  else
    echo "✗ Colima Docker daemon unreachable"
    failed=1
  fi
else
  echo "✗ Colima not ready; check: brew services info colima"
  echo "  Start with: brew services start colima (first startup may take a few minutes)"
  failed=1
fi

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
