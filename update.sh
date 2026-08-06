#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  git -C "$DOTFILES_DIR" pull --ff-only
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

brew bundle --file="$DOTFILES_DIR/Brewfile"
stow --dir="$DOTFILES_DIR" --target="$HOME" --restow \
  zsh ghostty starship atuin tmux git

[[ -d "$HOME/.oh-my-zsh/.git" ]] && git -C "$HOME/.oh-my-zsh" pull --ff-only
[[ -d "$HOME/.oh-my-zsh/custom/plugins/fzf-tab/.git" ]] && \
  git -C "$HOME/.oh-my-zsh/custom/plugins/fzf-tab" pull --ff-only
[[ -d "$HOME/.tmux/plugins/tpm/.git" ]] && \
  git -C "$HOME/.tmux/plugins/tpm" pull --ff-only

if [[ -x "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]]; then
  "$HOME/.tmux/plugins/tpm/bin/update_plugins" all || true
fi

if [[ -x "$HOME/.cargo/bin/rustup" ]]; then
  "$HOME/.cargo/bin/rustup" update stable
  "$HOME/.cargo/bin/rustup" component add rustfmt clippy rust-analyzer rust-src || true
fi

zsh -n "$HOME/.zshrc"
echo "Dotfiles updated. Run: exec zsh"
