#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

path_is_inside_repo() {
  local path="$1"
  [[ "$path" == "$DOTFILES_DIR" || "$path" == "$DOTFILES_DIR/"* ]]
}

unfold_managed_directory() {
  local directory="$1"
  local resolved

  [[ -L "$directory" ]] || return 0
  resolved="$(cd -P "$directory" 2>/dev/null && pwd || true)"

  if [[ -n "$resolved" ]] && path_is_inside_repo "$resolved"; then
    rm "$directory"
    mkdir -p "$directory"
    echo "Unfolded managed directory: $directory"
  fi
}

# Repair files deleted by the older folded-directory installer before pulling.
if [[ -d "$DOTFILES_DIR/.git" ]]; then
  required_sources=(
    "zsh/.zprofile"
    "zsh/.zshrc"
    "zsh/.config/zsh/env.zsh"
    "zsh/.config/zsh/completion.zsh"
    "zsh/.config/zsh/tools.zsh"
    "zsh/.config/zsh/aliases.zsh"
    "zsh/.config/zsh/functions.zsh"
    "zsh/.config/zsh/local.zsh.example"
    "ghostty/.config/ghostty/config.ghostty"
    "starship/.config/starship.toml"
    "atuin/.config/atuin/config.toml"
    "tmux/.tmux.conf"
    "git/.gitconfig"
    "git/.gitignore_global"
  )

  for source_rel in "${required_sources[@]}"; do
    if [[ ! -e "$DOTFILES_DIR/$source_rel" ]] && \
       git -C "$DOTFILES_DIR" cat-file -e "HEAD:$source_rel" 2>/dev/null; then
      echo "Restoring missing managed source: $source_rel"
      git -C "$DOTFILES_DIR" restore --source=HEAD -- "$source_rel"
    fi
  done

  git -C "$DOTFILES_DIR" pull --rebase --autostash
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

brew bundle --file="$DOTFILES_DIR/Brewfile"

# Start now and register the user service for subsequent macOS logins.
# This is idempotent and preserves the existing default Colima profile.
brew services start colima

# Preserve machine-local config while migrating away from Stow directory
# folding. local.zsh must remain a real local file, never part of the repo.
LOCAL_ZSH="$HOME/.config/zsh/local.zsh"
SOURCE_LOCAL_ZSH="$DOTFILES_DIR/zsh/.config/zsh/local.zsh"
LOCAL_ZSH_STASH=""

if [[ -f "$LOCAL_ZSH" ]]; then
  LOCAL_ZSH_STASH="$(mktemp -t dotfiles-local-zsh.XXXXXX)"
  cp -p "$LOCAL_ZSH" "$LOCAL_ZSH_STASH"
elif [[ -f "$SOURCE_LOCAL_ZSH" ]]; then
  LOCAL_ZSH_STASH="$(mktemp -t dotfiles-local-zsh.XXXXXX)"
  cp -p "$SOURCE_LOCAL_ZSH" "$LOCAL_ZSH_STASH"
fi

rm -f "$SOURCE_LOCAL_ZSH"

mkdir -p "$HOME/.config" "$HOME/.local"
unfold_managed_directory "$HOME/.config/zsh"
unfold_managed_directory "$HOME/.config/ghostty"
unfold_managed_directory "$HOME/.config/atuin"

mkdir -p \
  "$HOME/.config/zsh" \
  "$HOME/.config/ghostty" \
  "$HOME/.config/atuin"

if [[ -n "$LOCAL_ZSH_STASH" ]]; then
  cp -p "$LOCAL_ZSH_STASH" "$LOCAL_ZSH"
  rm -f "$LOCAL_ZSH_STASH"
fi

stow --dir="$DOTFILES_DIR" --target="$HOME" --no-folding --restow \
  zsh ghostty starship atuin tmux git

if [[ ! -e "$LOCAL_ZSH" ]]; then
  cp "$HOME/.config/zsh/local.zsh.example" "$LOCAL_ZSH"
fi

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
