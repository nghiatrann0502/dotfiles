#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
NVM_VERSION="v0.40.4"

log() {
  printf '\n\033[1;34m==> %s\033[0m\n' "$1"
}

warn() {
  printf '\033[1;33mWarning: %s\033[0m\n' "$1"
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

  # Keep links that already point into this dotfiles repository.
  if [[ -L "$target" ]]; then
    link_target="$(readlink "$target")"
    if [[ "$link_target" == *"$DOTFILES_DIR"* || "$link_target" == *"dotfiles/"* ]]; then
      continue
    fi
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
mkdir -p "$HOME/.config"
stow --dir="$DOTFILES_DIR" --target="$HOME" --restow \
  zsh ghostty starship atuin tmux git

log "Creating machine-local Zsh config"
LOCAL_ZSH="$HOME/.config/zsh/local.zsh"
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

# Keep the default stable toolchain current and install the standard dev components.
rustup set profile default
rustup toolchain install stable
rustup default stable
rustup component add rustfmt clippy rust-analyzer rust-src || \
  warn "Some optional Rust components could not be installed. Retry with: rustup component add rustfmt clippy rust-analyzer rust-src"

log "Installing tmux plugins"
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR/.git" ]]; then
  rm -rf "$TPM_DIR"
  git clone --depth 1 https://github.com/tmux-plugins/tpm.git "$TPM_DIR"
else
  git -C "$TPM_DIR" pull --ff-only
fi

if [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
  "$TPM_DIR/bin/install_plugins" || warn "Open tmux and press Ctrl-A then Shift-I to install plugins."
fi

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
