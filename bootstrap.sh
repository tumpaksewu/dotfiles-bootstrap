#!/usr/bin/env sh
set -eu

DOTFILES_REPO="${DOTFILES_REPO:-tumpaksewu/dotfiles}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

log() {
  printf '==> %s\n' "$*"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

ensure_brew_on_path() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return 0
  fi

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return 0
  fi

  if [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    return 0
  fi
}

install_homebrew() {
  ensure_brew_on_path
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  log "installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ensure_brew_on_path
  command -v brew >/dev/null 2>&1 || fail "Homebrew installation failed"
}

install_gh_macos() {
  install_homebrew
  if command -v gh >/dev/null 2>&1; then
    return 0
  fi

  log "installing GitHub CLI"
  brew install gh
  command -v gh >/dev/null 2>&1 || fail "GitHub CLI installation failed"
}

install_gh_linux() {
  if command -v gh >/dev/null 2>&1; then
    return 0
  fi

  fail "GitHub CLI is required. Install it first: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
}

install_gh() {
  case "$(uname -s)" in
    Darwin) install_gh_macos ;;
    Linux) install_gh_linux ;;
    *) fail "unsupported OS: $(uname -s)" ;;
  esac
}

authenticate_github() {
  if gh auth status >/dev/null 2>&1; then
    return 0
  fi

  log "authenticating GitHub CLI"
  gh auth login
}

sync_dotfiles_repo() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    log "updating dotfiles repo in $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull --ff-only
    return 0
  fi

  if [ -e "$DOTFILES_DIR" ]; then
    fail "$DOTFILES_DIR exists but is not a git repository"
  fi

  log "cloning private dotfiles repo into $DOTFILES_DIR"
  gh repo clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

main() {
  install_gh
  authenticate_github
  sync_dotfiles_repo

  chmod +x "$DOTFILES_DIR/bootstrap"
  exec "$DOTFILES_DIR/bootstrap"
}

main "$@"
