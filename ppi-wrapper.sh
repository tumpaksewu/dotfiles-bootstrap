#!/usr/bin/env bash
set -euo pipefail

SECRET_FILE="${PPI_SECRET_FILE:-$HOME/.config/ppi/komp_pi_key.enc}"
CACHE_DIR="${PPI_CACHE_DIR:-${TMPDIR:-/tmp}/ppi-$UID}"
CACHE_FILE="$CACHE_DIR/komp_pi_key"
REAL_PI="${PPI_REAL_PI:-pi}"

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

fail() {
  printf 'ppi: %s\n' "$*" >&2
  exit 1
}

ensure_cache_dir() {
  mkdir -p "$CACHE_DIR"
  chmod 700 "$CACHE_DIR"
}

is_valid_key_file() {
  local file="$1"
  [[ -s "$file" ]] || return 1
  LC_ALL=C grep -Eq '^[[:print:]]+$' "$file" || return 1
}

read_pin() {
  local pin
  [[ -t 0 ]] || fail "PIN prompt requires an interactive TTY"
  printf 'KOMP_PI_KEY PIN: ' >&2
  stty -echo
  read -r pin
  stty echo
  printf '\n' >&2
  [[ "$pin" =~ ^[0-9]{8}$ ]] || fail "PIN must be exactly 8 digits"
  printf '%s' "$pin"
}

decrypt_key_to_file() {
  local pin="$1"
  local output="$2"
  [[ -f "$SECRET_FILE" ]] || fail "encrypted key not found: $SECRET_FILE"

  openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -salt \
    -in "$SECRET_FILE" \
    -out "$output" \
    -pass "pass:$pin" 2>/dev/null || return 1

  is_valid_key_file "$output"
}

load_key() {
  if [[ -n "${KOMP_PI_KEY:-}" ]]; then
    printf '%s' "$KOMP_PI_KEY"
    return 0
  fi

  ensure_cache_dir
  if is_valid_key_file "$CACHE_FILE"; then
    cat "$CACHE_FILE"
    return 0
  fi
  rm -f "$CACHE_FILE"

  local pin tmp_file
  pin="$(read_pin)"
  tmp_file="$(mktemp "$CACHE_DIR/komp_pi_key.XXXXXX")"
  chmod 600 "$tmp_file"

  if ! decrypt_key_to_file "$pin" "$tmp_file"; then
    rm -f "$tmp_file"
    fail "failed to decrypt key"
  fi

  mv "$tmp_file" "$CACHE_FILE"
  chmod 600 "$CACHE_FILE"
  cat "$CACHE_FILE"
}

main() {
  command -v "$REAL_PI" >/dev/null 2>&1 || fail "pi not found in PATH"
  export KOMP_PI_KEY="$(load_key)"
  exec "$REAL_PI" "$@"
}

main "$@"
