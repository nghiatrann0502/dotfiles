#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles-backup"

log() {
  printf '\n\033[1;34m==> %s\033[0m\n' "$1"
}

warn() {
  printf '\033[1;33mWarning: %s\033[0m\n' "$1"
}

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
    echo "Unfolded: $directory"
  fi
}

restore_missing_sources() {
  local mapping source_rel target_rel source candidate
  local -a mappings candidates

  mappings=(
    "zsh/.zprofile|.zprofile"
    "zsh/.zshrc|.zshrc"
    "zsh/.config/zsh/env.zsh|.config/zsh/env.zsh"
    "zsh/.config/zsh/completion.zsh|.config/zsh/completion.zsh"
    "zsh/.config/zsh/tools.zsh|.config/zsh/tools.zsh"
    "zsh/.config/zsh/aliases.zsh|.config/zsh/aliases.zsh"
    "zsh/.config/zsh/functions.zsh|.config/zsh/functions.zsh"
    "zsh/.config/zsh/local.zsh.example|.config/zsh/local.zsh.example"
    "ghostty/.config/ghostty/config.ghostty|.config/ghostty/config.ghostty"
    "starship/.config/starship.toml|.config/starship.toml"
    "atuin/.config/atuin/config.toml|.config/atuin/config.toml"
    "tmux/.tmux.conf|.tmux.conf"
    "git/.gitconfig|.gitconfig"
    "git/.gitignore_global|.gitignore_global"
    "bin/.local/bin/colima-setup|.local/bin/colima-setup"
  )

  shopt -s nullglob

  for mapping in "${mappings[@]}"; do
    source_rel="${mapping%%|*}"
    target_rel="${mapping#*|}"
    source="$DOTFILES_DIR/$source_rel"

    [[ -e "$source" || -L "$source" ]] && continue

    if [[ -d "$DOTFILES_DIR/.git" ]] && \
       git -C "$DOTFILES_DIR" cat-file -e "HEAD:$source_rel" 2>/dev/null; then
      warn "Restoring from Git: $source_rel"
      git -C "$DOTFILES_DIR" restore --source=HEAD -- "$source_rel"
      continue
    fi

    candidates=("$BACKUP_ROOT"/*/"$target_rel")
    if (( ${#candidates[@]} > 0 )); then
      candidate="${candidates[${#candidates[@]}-1]}"
      warn "Restoring from backup: $source_rel"
      mkdir -p "$(dirname "$source")"
      cp -p "$candidate" "$source"
    else
      warn "Could not restore missing file: $source_rel"
    fi
  done

  shopt -u nullglob
}

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow is not installed. Run: brew install stow"
  exit 1
fi

log "Restoring managed source files"
restore_missing_sources

log "Preserving machine-local Zsh config"
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

log "Converting folded Stow directories"
mkdir -p "$HOME/.config" "$HOME/.local"
unfold_managed_directory "$HOME/.config/zsh"
unfold_managed_directory "$HOME/.config/ghostty"
unfold_managed_directory "$HOME/.config/atuin"
unfold_managed_directory "$HOME/.local/bin"

mkdir -p \
  "$HOME/.config/zsh" \
  "$HOME/.config/ghostty" \
  "$HOME/.config/atuin" \
  "$HOME/.local/bin"

if [[ -n "$LOCAL_ZSH_STASH" ]]; then
  cp -p "$LOCAL_ZSH_STASH" "$LOCAL_ZSH"
  rm -f "$LOCAL_ZSH_STASH"
fi

log "Recreating individual file symlinks"
stow --dir="$DOTFILES_DIR" --target="$HOME" --no-folding --restow \
  zsh ghostty starship atuin tmux git bin

if [[ ! -e "$LOCAL_ZSH" ]]; then
  cp "$HOME/.config/zsh/local.zsh.example" "$LOCAL_ZSH"
fi

log "Validating repaired layout"
required_targets=(
  "$HOME/.config/zsh/env.zsh"
  "$HOME/.config/zsh/completion.zsh"
  "$HOME/.config/zsh/tools.zsh"
  "$HOME/.config/zsh/aliases.zsh"
  "$HOME/.config/zsh/functions.zsh"
  "$HOME/.config/zsh/local.zsh.example"
)

failed=false
for target in "${required_targets[@]}"; do
  if [[ ! -L "$target" ]]; then
    warn "Expected a file symlink but did not find one: $target"
    failed=true
  fi
done

if [[ -L "$HOME/.config/zsh" ]]; then
  warn "~/.config/zsh is still a directory symlink; repair is incomplete."
  failed=true
fi

if [[ "$failed" == true ]]; then
  exit 1
fi

echo
echo "Stow layout repaired. Run: exec zsh"
