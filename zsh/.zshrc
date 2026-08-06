# ============================================================
# Base paths and environment
# ============================================================

if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
  elif [[ -x /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX="/usr/local"
  fi
fi

ZSH_CONFIG_DIR="$HOME/.config/zsh"

[[ -r "$ZSH_CONFIG_DIR/env.zsh" ]] && source "$ZSH_CONFIG_DIR/env.zsh"
[[ -r "$ZSH_CONFIG_DIR/completion.zsh" ]] && source "$ZSH_CONFIG_DIR/completion.zsh"

# ============================================================
# Oh My Zsh
# ============================================================

export ZSH="$HOME/.oh-my-zsh"
export ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR"

# Starship renders the prompt, so no Oh My Zsh theme is needed.
ZSH_THEME=""

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 14
zstyle ':omz:update' verbose minimal

# Keep useful Git aliases, disable aliases from other OMZ plugins.
zstyle ':omz:plugins:*' aliases no
zstyle ':omz:plugins:git' aliases yes

# Load nvm only when node/npm/nvm is first used.
export NVM_DIR="$HOME/.nvm"
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' lazy-cmd eslint prettier vite pnpm yarn corepack

plugins=(
  git
  fzf-tab
  nvm
  sudo
  macos
  ssh
  docker
  docker-compose
  golang
  colored-man-pages
)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  print -P "%F{yellow}Oh My Zsh is not installed. Run ~/dotfiles/install.sh%f"
fi

# ============================================================
# User configuration
# ============================================================

[[ -r "$ZSH_CONFIG_DIR/tools.zsh" ]] && source "$ZSH_CONFIG_DIR/tools.zsh"
[[ -r "$ZSH_CONFIG_DIR/aliases.zsh" ]] && source "$ZSH_CONFIG_DIR/aliases.zsh"
[[ -r "$ZSH_CONFIG_DIR/functions.zsh" ]] && source "$ZSH_CONFIG_DIR/functions.zsh"

# Machine-specific settings. This file is intentionally not tracked.
[[ -r "$ZSH_CONFIG_DIR/local.zsh" ]] && source "$ZSH_CONFIG_DIR/local.zsh"

# Autosuggestions should load after tools that create ZLE widgets.
if [[ -n "${HOMEBREW_PREFIX:-}" ]] && \
   [[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=80
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Syntax highlighting must remain last.
if [[ -n "${HOMEBREW_PREFIX:-}" ]] && \
   [[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
