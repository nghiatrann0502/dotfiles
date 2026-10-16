# Nghĩa's macOS dotfiles

A practical macOS terminal setup managed with Git + GNU Stow.

## Included

- Ghostty
- JetBrainsMono Nerd Font (Ghostty uses the Mono family at size 14)
- XKey (Vietnamese input)
- Raycast
- RedisInsight (Redis GUI client)
- Zsh + Oh My Zsh
- Starship
- fzf + fzf-tab
- Atuin
- zoxide
- tmux + TPM + resurrect + continuum + Catppuccin + battery/CPU/RAM status
- eza, bat, fd, ripgrep
- delta, lazygit, GitHub CLI
- jq, yq, xh
- btop, dust, duf, procs
- tealdeer, hyperfine, just
- Colima + Docker CLI, Compose, Buildx and the macOS credential helper
- Go through Homebrew
- Rust stable through rustup, including Cargo, rustfmt, Clippy and rust-analyzer
- Node.js through nvm
- Python project tooling through uv

`mise` is intentionally not included.

## Repository structure

```text
dotfiles/
├── zsh/
│   ├── .zprofile
│   ├── .zshrc
│   └── .config/zsh/
│       ├── env.zsh
│       ├── completion.zsh
│       ├── tools.zsh
│       ├── aliases.zsh
│       ├── functions.zsh
│       └── local.zsh.example
├── ghostty/.config/ghostty/config.ghostty
├── starship/.config/starship.toml
├── atuin/.config/atuin/config.toml
├── tmux/.tmux.conf
├── git/.gitconfig
├── git/.gitignore_global
├── Brewfile
├── install.sh
├── update.sh
├── doctor.sh
├── repair-stow.sh
└── uninstall.sh
```

## Install on the current Mac

```bash
cd ~/dotfiles
./install.sh
```

The installer:

1. Installs Homebrew when missing.
2. Installs packages from `Brewfile`.
3. Repairs the legacy folded-directory Stow layout when detected.
4. Backs up genuinely conflicting files under `~/.dotfiles-backup/`.
5. Creates one symlink per managed file with GNU Stow `--no-folding`.
6. Installs Oh My Zsh and fzf-tab.
7. Installs nvm and the current Node.js LTS.
8. Installs Colima, Docker CLI, Compose, Buildx and the macOS credential helper, and enables Colima startup at login.
9. Installs the stable Rust toolchain through rustup.
10. Installs TPM and tmux plugins.
11. Imports existing Zsh history into Atuin when safe.
12. Validates `.zshrc` syntax.


## Repair an older Stow layout

An older installer version allowed Stow to replace directories such as `~/.config/zsh` with one directory symlink. On a later install, backup logic could then move the files behind that symlink out of the repository. The current setup uses `--no-folding`, so `~/.config/zsh` stays a real directory, managed files are individual symlinks, and `local.zsh` remains a real machine-local file.

Repair an affected checkout without reinstalling Homebrew, Rust, or Node:

```bash
cd ~/dotfiles
./repair-stow.sh
exec zsh
```

The repair script restores missing tracked files from Git when possible, otherwise from the newest `~/.dotfiles-backup/` copy. It preserves `~/.config/zsh/local.zsh`, unfolds old directory symlinks, and recreates individual file symlinks.

The expected result is:

```bash
test -d ~/.config/zsh && test ! -L ~/.config/zsh
test -L ~/.config/zsh/env.zsh
test -L ~/.config/zsh/aliases.zsh
test -f ~/.config/zsh/local.zsh && test ! -L ~/.config/zsh/local.zsh
```

## Install on a new Mac

```bash
git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

For an HTTPS repository:

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
```

## Publish this folder to GitHub

```bash
cd ~/dotfiles
git init
git add .
git commit -m "Initial dotfiles"
git branch -M main
git remote add origin git@github.com:YOUR_USERNAME/dotfiles.git
git push -u origin main
```

A private repository is a sensible default, but secrets must still stay out of it.

## Machine-specific settings

`install.sh` automatically creates `~/.config/zsh/local.zsh` from the example file when it does not already exist. Existing machine-local settings are never overwritten.

Edit `~/.config/zsh/local.zsh` for Android SDK paths, work-only aliases, or machine-specific environment variables. It is not managed by Stow or Git.

Git identity is also local:

```bash
cat > ~/.gitconfig.local <<'GIT'
[user]
    name = Your Name
    email = you@example.com
GIT
```

## Colima and Docker

The Brewfile installs Colima, Docker CLI, Compose, Buildx and the macOS credential helper. Both `install.sh` and `update.sh` run `brew services start colima`: this starts Colima in the background now and registers it to start automatically when you log in after restarting your Mac. It runs as your user, not before login; do not use `sudo`.

The service uses the default Colima profile and preserves its existing settings. On a fresh machine, Colima creates that profile using its defaults. The first startup may take a few minutes while the VM is downloaded and initialized. Service registration does not mean the Docker daemon is ready yet.

Manage automatic startup:

```bash
brew services info colima
brew services start colima    # Start now and enable startup at login
brew services stop colima     # Stop and disable startup at login
brew services restart colima  # Restart the managed service
```

Running `install.sh` or `update.sh` enables the service again. `uninstall.sh` only removes dotfile symlinks; disable the service separately if needed. Service logs are at `$(brew --prefix)/var/log/colima.log`.

Docker plugins and credentials still require separate configuration if they are not already set up.

Check your Docker setup:

```bash
docker context ls
docker info
docker compose version
docker buildx version
```

## Terminal font

`install.sh` and `update.sh` install `font-jetbrains-mono-nerd-font` through the Brewfile. Ghostty uses `JetBrainsMono Nerd Font Mono` at size 14 for code and terminal icons.

To install only the font on an existing setup:

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

Restart Ghostty after installation. Other editors and terminals need their font family selected separately.

## Daily workflow

Edit a linked config normally:

```bash
vim ~/.zshrc
vim ~/.config/ghostty/config.ghostty
```

Commit from the repository:

```bash
cd ~/dotfiles
git add .
git commit -m "Update terminal config"
git push
```

Update another Mac:

```bash
cd ~/dotfiles
./update.sh
exec zsh
```

## Aliases, functions and optimized workflow

The aliases below are defined in `~/.config/zsh/aliases.zsh`. Helper functions are defined in `~/.config/zsh/functions.zsh`.

You do not need to memorize everything. The most useful daily commands are:

```text
ll  lt  b  z  zi  cproj  gs  gd  lg  dcud  dcl  dcd  port  t  reload
```

### Navigation and file listing

| Command | Expands to / behavior | Recommended use |
|---|---|---|
| `..` | `cd ..` | Move up one directory |
| `...` | `cd ../..` | Move up two directories |
| `....` | `cd ../../..` | Move up three directories |
| `ls` | `eza --icons=auto --group-directories-first` | Quick directory listing |
| `ll` | `eza -lah --icons=auto --git --group-directories-first` | Detailed listing with hidden files and Git state |
| `la` | `eza -a --icons=auto --group-directories-first` | Compact listing including hidden files |
| `lt` | `eza --tree --level=2 --icons=auto` | Inspect a project tree two levels deep |
| `lta` | `eza --tree --level=3 --icons=auto --all` | Inspect a deeper tree including hidden files |

Examples:

```bash
ll
lt
z ipacer
zi
```

Prefer `z` or `zi` over typing long paths repeatedly. `zoxide` learns frequently visited directories and improves over time.

### Reading files

Native `cat` is intentionally preserved for scripts and predictable pipelines.

| Command | Behavior | Recommended use |
|---|---|---|
| `b <file>` | Open with `bat` | Read source files with syntax highlighting and line numbers |
| `bp <file>` | Plain `bat`, no pager | Print a short file or pipe its output |

Examples:

```bash
b internal/auth/service.go
b ~/.zshrc
bp package.json | jq
```

A simple rule:

```text
cat  -> scripts and compatibility-sensitive pipelines
b    -> reading files interactively
bp   -> clean output without paging
```

### Shell utilities

| Command | Behavior | Recommended use |
|---|---|---|
| `c` | Clear the terminal | Reset the visible terminal area |
| `reload` | `exec zsh` | Reload the complete shell after editing config |
| `path` | Print each PATH entry on its own line | Debug which runtime or CLI is being selected |
| `ports` | Show all listening TCP ports | Find running local services |

Examples:

```bash
reload
which go
which node
which cargo
path
ports
```

Use `reload` instead of repeatedly running `source ~/.zshrc`; it starts a clean Zsh process and avoids loading some hooks more than once.

### Git aliases

| Command | Expands to | Recommended use |
|---|---|---|
| `g` | `git` | Prefix for Git commands without a dedicated alias |
| `gs` | `git status` | Quick repository status |
| `gd` | `git diff` | Review unstaged changes through Delta |
| `gl` | `git log --graph --decorate --oneline --all` | Inspect branches and commit topology |
| `lg` | `lazygit` | Interactive staging, commits, branches and rebases |

Recommended workflow:

```bash
gs
gd
lg
```

Use `gs` and `gd` for quick inspection. Open `lg` when staging individual hunks, resolving conflicts, rebasing or managing branches.

Oh My Zsh's `git` plugin also provides additional aliases. Inspect the aliases actually available on the current machine with:

```bash
alias | grep -E "='git|='lazygit" | sort
alias gco
alias gst
```

### Docker aliases

| Command | Expands to | Recommended use |
|---|---|---|
| `d` | `docker` | General Docker commands |
| `dc` | `docker compose` | Compose commands without a dedicated alias |
| `dps` | Formatted `docker ps` | Compact container status table |
| `dcu` | `docker compose up` | Run the stack in the foreground |
| `dcud` | `docker compose up -d` | Start the stack in the background |
| `dcl` | `docker compose logs -f` | Follow all Compose logs |
| `dcd` | `docker compose down` | Stop and remove the Compose stack |

Recommended local-development workflow:

```bash
dcud
dps
dcl
```

When development is finished:

```bash
dcd
```

`dcd` stops the current Compose project.

Restart or inspect one service:

```bash
dc restart api
dc logs -f api
dc exec api sh
```

Stop the stack:

```bash
dcd
```

`dcd` does not remove volumes. Use `dc down -v` only when you intentionally want to delete persistent development data.

### tmux aliases and function

| Command | Behavior | Recommended use |
|---|---|---|
| `t` | Create or attach session `dev` | Default long-running session |
| `t <name>` | Create or attach a named session | One session per project or server |
| `tdev` | Create or attach session `dev` | Explicit equivalent of plain `t` |
| `tls` | List tmux sessions | See currently available sessions |
| `ta` | Attach to tmux | Useful when only one session exists |

Examples:

```bash
t ipacer
t infrastructure
t production
tls
```

Recommended split of responsibilities:

```text
Ghostty tabs/splits -> short local tasks
named tmux sessions -> long-running projects, SSH and persistent processes
```

#### tmux keys

The tmux prefix is `Ctrl-T`. Inside tmux, press `Ctrl-T` twice to send it to the shell (for example, to open fzf file search).

Both `install.sh` and `update.sh` install TPM and missing plugins automatically. `update.sh` also updates installed plugins. Plugin failures stop the script with an error instead of reporting success. Existing tmux sessions are not automatically reloaded; apply the new config with `tmux source-file ~/.tmux.conf`.

To retry only plugin setup:

```bash
bash scripts/sync-tmux-plugins.sh install
```

Copy mode and log search use OSC 52 to copy through the attached terminal, including over SSH. The terminal must allow clipboard writes.

| Key | Action |
|---|---|
| `Ctrl-T c` | Create a new window in the current directory |
| `Ctrl-T \|` | Split the current pane left/right |
| `Ctrl-T -` | Split the current pane top/bottom |
| `Ctrl-T h/j/k/l` | Move between panes |
| `Ctrl-T H/J/K/L` | Resize panes by five cells |
| `Ctrl-T d` | Detach from the current session |
| `Ctrl-T f` | Search all retained pane history with fzf and copy selected lines |
| `Ctrl-T m` | Toggle pane zoom |
| `Ctrl-T r` | Reload `~/.tmux.conf` |
| `Ctrl-T [` | Enter copy/scroll mode |
| `v` in copy mode | Begin selection |
| `y` in copy mode | Copy selection to the macOS clipboard |
| `Ctrl-T Shift-I` | Install TPM plugins manually |

### Helper functions

#### `mkcd`

Create a directory and enter it:

```bash
mkcd new-service
mkcd ~/Projects/ipacer/tools/migration
mkcd "Project With Spaces"
```

#### `port`

Show the process listening on one TCP port:

```bash
port 8080
port 5432
port 3000
```

Use `ports` for all listening ports and `port <number>` for one specific port.

#### `cproj`

Fuzzy-select a Git repository below `${PROJECTS_DIR:-$HOME/Projects}` and enter it:

```bash
cproj
```

To use another project root, add this to `~/.config/zsh/local.zsh`:

```bash
export PROJECTS_DIR="$HOME/Code"
```

Then reload the shell:

```bash
reload
cproj
```

#### `extract`

Extract common archive formats without remembering individual `tar` flags:

```bash
extract archive.zip
extract source.tar.gz
extract backup.tar.xz
```

Supported formats include `.zip`, `.tar`, `.tar.gz`, `.tgz`, `.tar.bz2`, `.tbz2`, `.tar.xz`, `.gz` and `.bz2`.

### fzf, Atuin and autosuggestion keys

| Key | Action |
|---|---|
| `Ctrl-R` | Search command history with Atuin |
| `Ctrl-T` | Fuzzy-select a file and insert its path into the command line |
| `Option-C` | Fuzzy-select a directory and enter it |
| `Tab` | Fuzzy Zsh completion through fzf-tab |
| `Option-F` | Accept the next word from the autosuggestion |

Examples:

```text
b <Ctrl-T>                 -> select a file to open with bat
vim <Ctrl-T>               -> select a file to edit
cd ~/Pro<Tab>              -> fuzzy-complete the directory
ssh <Tab>                  -> fuzzy-complete a known SSH host
docker compose logs <Tab>  -> complete a service name
```

Ghostty is configured to treat Option as Alt, which is required for `Option-C` and `Option-F`.

### Suggested daily workflows

#### Open a project

```bash
cproj
# or after zoxide has learned the directory:
z ipacer

ll
lt
t ipacer
```

#### Start backend development

```bash
gs
dcud
dps
port 8080
go run ./cmd/api
```

Open another tmux window with `Ctrl-T c`, then follow the stack logs:

```bash
dcl
```

#### Review and commit code

```bash
gs
gd
lg
```

#### Debug a local service

```bash
ports
port 8080
dps
dc logs -f api
xh GET localhost:8080/health
```

Search the codebase and inspect a result:

```bash
rg "CreateUser"
fd "handler"
b internal/user/handler.go
```

### Inspect aliases and functions

Show all aliases:

```bash
alias | sort
```

Check whether a command is an alias, function or executable:

```bash
type gs
type cproj
type git
type node
```

Print a function definition:

```bash
functions cproj
functions port
```

The goal is not to replace every Unix command with a private language. Keep aliases for commands used many times per day; use full command names for rare or safety-sensitive operations.

## Atuin

On first installation, `install.sh` automatically imports `~/.zsh_history` when it finds old Zsh history and no existing Atuin data. A local marker prevents the installer from importing the same history again.

If existing Atuin data is detected, automatic import is skipped to avoid duplicate entries. Run the command below manually only when you are certain the old history has not already been imported:

```bash
atuin import zsh
```

Cloud sync remains disabled until you explicitly configure it.

## Node.js

nvm is lazy-loaded by the Oh My Zsh nvm plugin.

```bash
nvm install --lts
nvm alias default 'lts/*'
node --version
```

Per project:

```bash
echo "lts/*" > .nvmrc
nvm use
```

## Go

Go is installed through Homebrew:

```bash
go version
brew upgrade go
```

Go tools installed with `go install` are available through `~/go/bin`.

## Rust

Rust is installed with the official `rustup` installer rather than Homebrew. The installer configures the stable toolchain and these development components:

- Cargo
- rustfmt
- Clippy
- rust-analyzer
- Rust standard-library source

Check the installation:

```bash
rustup show
rustc --version
cargo --version
cargo clippy --version
rust-analyzer --version
```

Update Rust:

```bash
rustup update stable
```

Use a project-specific toolchain when needed:

```bash
rustup override set stable
# or, for a project that explicitly requires nightly:
rustup override set nightly
```

Install a Cargo CLI:

```bash
cargo install cargo-watch
```

Cargo-installed binaries are available through `~/.cargo/bin`.

## Python

Use Homebrew's `uv` for project environments and packages:

```bash
uv init
uv add requests
uv run python main.py
```

## Validate

```bash
./doctor.sh
hyperfine --warmup 5 'zsh -i -c exit'
```

`doctor.sh` verifies the Docker CLI, Compose, Buildx, credential helper, and Colima daemon using the `colima` Docker context. Run `docker info` separately to check the currently selected Docker context.

## Remove symlinks

```bash
./uninstall.sh
```

This only removes Stow symlinks. It does not uninstall applications, delete Oh My Zsh, remove nvm/rustup, or delete shell history.

## Never commit

- SSH private keys
- API tokens
- `.env` files
- `~/.npmrc` containing credentials
- cloud credentials
- Docker auth config
- Atuin database
- tmux-resurrect session data
- shell history
