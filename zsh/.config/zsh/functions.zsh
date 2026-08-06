# Create a directory and enter it.
mkcd() {
  if (( $# != 1 )); then
    echo "Usage: mkcd <directory>"
    return 1
  fi

  mkdir -p -- "$1" && cd -- "$1"
}

# Display the process listening on a TCP port.
port() {
  if (( $# != 1 )); then
    echo "Usage: port <number>"
    return 1
  fi

  lsof -nP -iTCP:"$1" -sTCP:LISTEN
}

# Fuzzy-select a project directory below ~/Projects.
cproj() {
  local projects_dir="${PROJECTS_DIR:-$HOME/Projects}"
  local project

  if [[ ! -d "$projects_dir" ]]; then
    echo "Projects directory does not exist: $projects_dir"
    return 1
  fi

  project="$({
    find "$projects_dir" -mindepth 1 -maxdepth 3 -type d -name .git -prune -print 2>/dev/null |
      sed 's#/.git$##'
  } | fzf --preview 'eza --tree --level=2 --icons=auto --color=always {} | head -200')"

  [[ -n "$project" ]] && cd "$project"
}

# Create or attach to a named tmux session.
t() {
  local session="${1:-dev}"
  tmux new-session -A -s "$session"
}

# Extract common archive formats.
extract() {
  if [[ ! -f "$1" ]]; then
    echo "File not found: $1"
    return 1
  fi

  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.bz2)     bunzip2 "$1" ;;
    *.gz)      gunzip "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.tbz2)    tar xjf "$1" ;;
    *.tgz)     tar xzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *)         echo "Unsupported archive: $1"; return 1 ;;
  esac
}
