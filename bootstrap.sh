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

install_macos_tools() {
  install_homebrew

  if ! command -v gh >/dev/null 2>&1; then
    log "installing GitHub CLI"
    brew install gh
  fi
  command -v gh >/dev/null 2>&1 || fail "GitHub CLI installation failed"

  if ! command -v dotstate >/dev/null 2>&1; then
    log "installing DotState"
    brew tap serkanyersen/dotstate
    brew install dotstate
  fi
  command -v dotstate >/dev/null 2>&1 || fail "DotState installation failed"
}

install_linux_tools() {
  if ! command -v gh >/dev/null 2>&1; then
    fail "GitHub CLI is required. Install it first: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
  fi

  if ! command -v dotstate >/dev/null 2>&1; then
    log "installing DotState"
    curl -fsSL https://dotstate.serkan.dev/install.sh | bash
    export PATH="$HOME/.local/bin:$PATH"
  fi
  command -v dotstate >/dev/null 2>&1 || fail "DotState installation failed"
}

install_tools() {
  case "$(uname -s)" in
    Darwin) install_macos_tools ;;
    Linux) install_linux_tools ;;
    *) fail "unsupported OS: $(uname -s)" ;;
  esac
}

print_next_steps() {
  cat <<EOF

Ready.

Next steps:
  gh auth login
  gh repo clone $DOTFILES_REPO $DOTFILES_DIR
  cd $DOTFILES_DIR
  dotstate activate

If the repo already exists:
  cd $DOTFILES_DIR
  git pull --ff-only
  dotstate activate

EOF
}

main() {
  install_tools
  print_next_steps
}

main "$@"
