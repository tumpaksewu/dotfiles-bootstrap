#!/usr/bin/env bash
set -euo pipefail

PAYLOAD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_AGENT_DIR="$HOME/.pi/agent"
PPI_CONFIG_DIR="$HOME/.config/ppi"
LOCAL_BIN_DIR="$HOME/.local/bin"
PI_PACKAGE="${PI_PACKAGE:-@earendil-works/pi-coding-agent}"
NODE_VERSION="${NODE_VERSION:-lts}"

log() {
  printf '==> %s\n' "$*"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

ensure_path() {
  export PATH="$LOCAL_BIN_DIR:$HOME/.local/share/mise/bin:$HOME/.local/share/mise/shims:$PATH"
}

install_mise() {
  if command -v mise >/dev/null 2>&1; then
    return 0
  fi

  log "installing mise"
  curl -fsSL https://mise.run | sh
  ensure_path
  command -v mise >/dev/null 2>&1 || fail "mise installation failed"
}

ensure_npm() {
  if command -v npm >/dev/null 2>&1; then
    return 0
  fi

  install_mise
  log "installing node via mise"
  mise use --global "node@$NODE_VERSION"
  mise install --yes
  ensure_path
  command -v npm >/dev/null 2>&1 || fail "npm installation failed"
}

install_pi() {
  ensure_npm
  log "installing pi"
  npm install -g "$PI_PACKAGE"
  ensure_path
  command -v pi >/dev/null 2>&1 || fail "pi installation failed"
}

install_pi_config() {
  log "installing pi config"
  mkdir -p "$PI_AGENT_DIR"

  [[ -f "$PAYLOAD_DIR/pi/models.json" ]] || fail "missing payload file: pi/models.json"
  cp "$PAYLOAD_DIR/pi/models.json" "$PI_AGENT_DIR/models.json"

  if [[ -f "$PAYLOAD_DIR/pi/AGENTS.md" ]]; then
    cp "$PAYLOAD_DIR/pi/AGENTS.md" "$PI_AGENT_DIR/AGENTS.md"
  fi

  if [[ -d "$PAYLOAD_DIR/pi/extensions" ]]; then
    rm -rf "$PI_AGENT_DIR/extensions"
    mkdir -p "$PI_AGENT_DIR/extensions"
    cp -R "$PAYLOAD_DIR/pi/extensions/." "$PI_AGENT_DIR/extensions/"
  fi
}

install_ppi_secret() {
  log "installing encrypted key"
  mkdir -p "$PPI_CONFIG_DIR"
  chmod 700 "$PPI_CONFIG_DIR"

  [[ -f "$PAYLOAD_DIR/secrets/komp_pi_key.enc" ]] || fail "missing payload file: secrets/komp_pi_key.enc"
  cp "$PAYLOAD_DIR/secrets/komp_pi_key.enc" "$PPI_CONFIG_DIR/komp_pi_key.enc"
  chmod 600 "$PPI_CONFIG_DIR/komp_pi_key.enc"
}

install_ppi_wrapper() {
  log "installing ppi wrapper"
  mkdir -p "$LOCAL_BIN_DIR"
  cp "$PAYLOAD_DIR/bin/ppi" "$LOCAL_BIN_DIR/ppi"
  chmod 700 "$LOCAL_BIN_DIR/ppi"
}

main() {
  ensure_path
  install_pi
  install_pi_config
  install_ppi_secret
  install_ppi_wrapper

  cat <<'EOF'

Done.

Run:
  ppi

If ppi is not found, add this to PATH:
  export PATH="$HOME/.local/bin:$PATH"
EOF
}

main "$@"
