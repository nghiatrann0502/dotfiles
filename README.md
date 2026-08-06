# Nghĩa's macOS dotfiles

A practical macOS terminal setup managed with Git + GNU Stow.

## Included

- Ghostty
- Zsh + Oh My Zsh
- Starship
- fzf + fzf-tab
- Atuin
- zoxide
- tmux + TPM + resurrect + continuum
- eza, bat, fd, ripgrep
- delta, lazygit, GitHub CLI
- jq, yq, xh
- btop, dust, duf, procs
- tealdeer, hyperfine, just
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
3. Backs up conflicting files under `~/.dotfiles-backup/`.
4. Creates symlinks with GNU Stow.
5. Installs Oh My Zsh and fzf-tab.
6. Installs nvm and the current Node.js LTS.
7. Installs the stable Rust toolchain through rustup.
8. Installs TPM and tmux plugins.
9. Imports existing Zsh history into Atuin when safe.
10. Validates `.zshrc` syntax.

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

## Useful keys and commands

### Shell

- `Ctrl-R`: Atuin history search
- `Ctrl-T`: fzf file picker
- `Option-C`: fzf directory picker
- `Tab`: fzf-tab completion
- `Option-F`: accept the next autosuggested word
- `z <name>`: jump to a frequently used directory
- `zi`: interactively choose a zoxide directory

### Ghostty

- `Cmd + backtick`: global Quick Terminal
- Ghostty may request macOS Accessibility permission for the global shortcut.

### tmux

- `t` or `tdev`: create/attach a session
- Prefix: `Ctrl-A`
- `Ctrl-A c`: new window
- `Ctrl-A |`: horizontal split
- `Ctrl-A -`: vertical split
- `Ctrl-A h/j/k/l`: navigate panes
- `Ctrl-A H/J/K/L`: resize panes
- `Ctrl-A d`: detach
- `Ctrl-A r`: reload config
- `Ctrl-A Shift-I`: install TPM plugins manually

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
