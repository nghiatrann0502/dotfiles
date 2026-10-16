#!/usr/bin/env bash
# Install missing plugins and optionally update existing ones, without reloading
# the user's running tmux sessions or triggering session restoration.
set -euo pipefail

mode="${1:-install}"
case "$mode" in
  install|update) ;;
  *) echo "Usage: $0 [install|update]" >&2; exit 2 ;;
esac

TPM_DIR="$HOME/.tmux/plugins/tpm"
mkdir -p "$HOME/.tmux/plugins"
if [[ -d "$TPM_DIR/.git" ]]; then
  git -C "$TPM_DIR" pull --ff-only
elif [[ -e "$TPM_DIR" || -L "$TPM_DIR" ]]; then
  echo "TPM path exists but is not a Git checkout: $TPM_DIR" >&2
  echo "Move it aside before retrying; no files were removed." >&2
  exit 1
else
  git clone --depth 1 https://github.com/tmux-plugins/tpm.git "$TPM_DIR"
fi

# TPM's command-line tools read plugin declarations from the user's config,
# but still need a live tmux server to query the plugin installation directory.
# Use a private server so this also works on a fresh machine or an old session.
TMUX_SYNC_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tpm.XXXXXX")"
TMUX_SYNC_SOCKET="$TMUX_SYNC_DIR/socket"
cleanup() {
  tmux -S "$TMUX_SYNC_SOCKET" kill-server >/dev/null 2>&1 || true
  rm -rf "$TMUX_SYNC_DIR"
}
trap cleanup EXIT

tmux -S "$TMUX_SYNC_SOCKET" -f /dev/null start-server \; \
  set-option -g exit-empty off \; \
  set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
export TMUX="$TMUX_SYNC_SOCKET,0,0"

"$TPM_DIR/bin/install_plugins"
if [[ "$mode" == update ]]; then
  "$TPM_DIR/bin/update_plugins" all
fi

echo "Tmux plugins ready. In an existing session, run: tmux source-file ~/.tmux.conf"
