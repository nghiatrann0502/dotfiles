#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
NVM_VERSION="v0.40.4"

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

# Return success when a target is already provided by this dotfiles repo.
# This handles both direct file symlinks and Stow's older "folded directory"
# layout, where e.g. ~/.config/zsh itself points into the repo.
target_is_managed_by_repo() {
  local target="$1"
  local parent physical_parent raw candidate candidate_parent resolved

  parent="$(dirname "$target")"
  if [[ -d "$parent" ]]; then
    physical_parent="$(cd -P "$parent" 2>/dev/null && pwd || true)"
    if [[ -n "$physical_parent" ]] && path_is_inside_repo "$physical_parent"; then
      return 0
    fi
  fi

  if [[ -L "$target" ]]; then
    raw="$(readlink "$target")"
    if [[ "$raw" == /* ]]; then
      candidate="$raw"
    else
      candidate="$parent/$raw"
    fi

    candidate_parent="$(cd -P "$(dirname "$candidate")" 2>/dev/null && pwd || true)"
    if [[ -n "$candidate_parent" ]]; then
      resolved="$candidate_parent/$(basename "$candidate")"
      path_is_inside_repo "$resolved" && return 0
    fi
  fi

  return 1
}

# Restore tracked files that an older buggy installer may have moved out of
# the repo through a folded Stow directory symlink.
restore_missing_managed_sources() {
  local mappings source_rel target_rel source candidate
  local -a candidates

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
  )

  shopt -s nullglob

  for mapping in "${mappings[@]}"; do
    source_rel="${mapping%%|*}"
    target_rel="${mapping#*|}"
    source="$DOTFILES_DIR/$source_rel"

    [[ -e "$source" || -L "$source" ]] && continue

    if [[ -d "$DOTFILES_DIR/.git" ]] && \
       git -C "$DOTFILES_DIR" cat-file -e "HEAD:$source_rel" 2>/dev/null; then
      warn "Restoring missing managed source from Git: $source_rel"
      git -C "$DOTFILES_DIR" restore --source=HEAD -- "$source_rel"
      continue
    fi

    candidates=("$BACKUP_ROOT"/*/"$target_rel")
    if (( ${#candidates[@]} > 0 )); then
      candidate="${candidates[${#candidates[@]}-1]}"
      warn "Restoring missing managed source from backup: $source_rel"
      mkdir -p "$(dirname "$source")"
      cp -p "$candidate" "$source"
    fi
  done

  shopt -u nullglob
}

# Replace old folded directory symlinks with real directories. Stow will then
# create one symlink per managed file, leaving room for machine-local files.
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This setup is intended for macOS."
  exit 1
fi

log "Installing Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

log "Installing packages from Brewfile"
brew bundle --file="$DOTFILES_DIR/Brewfile"

log "Starting Colima and enabling automatic startup at login"
# Use the current user's LaunchAgent; do not run this with sudo.
# Homebrew starts Colima asynchronously using its existing default profile.
brew services start colima

log "Repairing legacy Stow layout if needed"
restore_missing_managed_sources

# Preserve local.zsh before replacing an old folded ~/.config/zsh symlink.
# Older versions accidentally created local.zsh inside the repo because the
# whole ~/.config/zsh directory was a symlink. Move that file back out.
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

# local.zsh must never be inside a Stow package, even when gitignored.
rm -f "$SOURCE_LOCAL_ZSH"

mkdir -p "$HOME/.config" "$HOME/.local"
unfold_managed_directory "$HOME/.config/zsh"
unfold_managed_directory "$HOME/.config/ghostty"
unfold_managed_directory "$HOME/.config/atuin"

if [[ -n "$LOCAL_ZSH_STASH" ]]; then
  mkdir -p "$HOME/.config/zsh"
  cp -p "$LOCAL_ZSH_STASH" "$LOCAL_ZSH"
  rm -f "$LOCAL_ZSH_STASH"
fi

log "Backing up conflicting dotfiles"
managed_targets=(
  "$HOME/.zprofile"
  "$HOME/.zshrc"
  "$HOME/.config/zsh/env.zsh"
  "$HOME/.config/zsh/completion.zsh"
  "$HOME/.config/zsh/tools.zsh"
  "$HOME/.config/zsh/aliases.zsh"
  "$HOME/.config/zsh/functions.zsh"
  "$HOME/.config/zsh/local.zsh.example"
  "$HOME/.config/ghostty/config.ghostty"
  "$HOME/.config/starship.toml"
  "$HOME/.config/atuin/config.toml"
  "$HOME/.tmux.conf"
  "$HOME/.gitconfig"
  "$HOME/.gitignore_global"
)

backed_up=false
for target in "${managed_targets[@]}"; do
  [[ -e "$target" || -L "$target" ]] || continue

  # Never move a file that is already supplied by this repository.
  if target_is_managed_by_repo "$target"; then
    continue
  fi

  relative="${target#$HOME/}"
  mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
  mv "$target" "$BACKUP_DIR/$relative"
  backed_up=true
done

if [[ "$backed_up" == true ]]; then
  echo "Existing config was backed up to: $BACKUP_DIR"
fi

log "Creating dotfile symlinks with GNU Stow"
mkdir -p \
  "$HOME/.config/zsh" \
  "$HOME/.config/ghostty" \
  "$HOME/.config/atuin"

stow --dir="$DOTFILES_DIR" --target="$HOME" --no-folding --restow \
  zsh ghostty starship atuin tmux git

log "Creating machine-local Zsh config"
LOCAL_ZSH_EXAMPLE="$HOME/.config/zsh/local.zsh.example"

if [[ ! -e "$LOCAL_ZSH" ]]; then
  cp "$LOCAL_ZSH_EXAMPLE" "$LOCAL_ZSH"
  echo "Created: $LOCAL_ZSH"
else
  echo "Keeping existing machine-local config: $LOCAL_ZSH"
fi

log "Installing Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

log "Installing fzf-tab"
FZF_TAB_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab"
if [[ ! -d "$FZF_TAB_DIR/.git" ]]; then
  rm -rf "$FZF_TAB_DIR"
  git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git "$FZF_TAB_DIR"
else
  git -C "$FZF_TAB_DIR" pull --ff-only
fi

log "Installing nvm and the current Node.js LTS"
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  export PROFILE=/dev/null
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
  unset PROFILE
fi

# shellcheck disable=SC1091
source "$NVM_DIR/nvm.sh"
if ! nvm version default >/dev/null 2>&1; then
  nvm install --lts
  nvm alias default 'lts/*'
fi

log "Installing Rust stable through rustup"
export PATH="$HOME/.cargo/bin:$PATH"

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --profile default --default-toolchain stable --no-modify-path
fi

rustup set profile default
rustup toolchain install stable
rustup default stable
rustup component add rustfmt clippy rust-analyzer rust-src || \
  warn "Some optional Rust components could not be installed. Retry with: rustup component add rustfmt clippy rust-analyzer rust-src"

log "Installing tmux plugins"
bash "$DOTFILES_DIR/scripts/sync-tmux-plugins.sh" install || {
  warn "Tmux plugin setup failed. Retry: bash \"$DOTFILES_DIR/scripts/sync-tmux-plugins.sh\" install"
  exit 1
}

log "Importing existing Zsh history into Atuin"
ATUIN_IMPORT_MARKER="$HOME/.local/state/dotfiles/atuin-zsh-history-imported"
ATUIN_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/atuin"

if [[ -e "$ATUIN_IMPORT_MARKER" ]]; then
  echo "Atuin history was already imported by this installer."
elif [[ -d "$ATUIN_DATA_DIR" ]] && find "$ATUIN_DATA_DIR" -type f -size +0c -print -quit 2>/dev/null | grep -q .; then
  warn "Existing Atuin data detected; skipping automatic history import to avoid duplicates."
  warn "Run 'atuin import zsh' manually only if this history has not been imported before."
elif [[ -s "$HOME/.zsh_history" ]]; then
  if atuin import zsh; then
    mkdir -p "$(dirname "$ATUIN_IMPORT_MARKER")"
    touch "$ATUIN_IMPORT_MARKER"
    echo "Imported existing Zsh history into Atuin."
  else
    warn "Atuin history import failed. You can retry later with: atuin import zsh"
  fi
else
  echo "No existing ~/.zsh_history found; nothing to import."
fi

log "Validating configuration"
zsh -n "$HOME/.zshrc"

cat <<'MESSAGE'

Setup complete.

Next steps:
  1. Restart Ghostty or run: exec zsh
  2. Edit ~/.config/zsh/local.zsh for machine-specific paths or aliases.
  3. For Ghostty Quick Terminal, allow Accessibility permission when macOS asks.
MESSAGE
