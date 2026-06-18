#!/usr/bin/env bash
# Re-attach Flutter debugger when the app is reopened (debug builds only).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/.adb_wireless.env"
FLUTTER="${ROOT}/.fvm/versions/3.27.2/bin/flutter"
[[ -x "$FLUTTER" ]] || FLUTTER=flutter
INTERVAL="${FLUTTER_ATTACH_INTERVAL_SEC:-8}"

source_env() {
  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
  fi
}

log() { printf '[flutter-attach-watch] %s\n' "$*"; }

while true; do
  source_env
  "${ROOT}/scripts/adb_wireless_connect.sh" >/dev/null 2>&1 || true

  DEVICE="${FLUTTER_DEVICE_ID:-}"
  if [[ -z "$DEVICE" && -f "${ROOT}/.vscode/pixel7.device.id" ]]; then
    DEVICE="$(tr -d '[:space:]' <"${ROOT}/.vscode/pixel7.device.id")"
  fi

  if [[ -z "$DEVICE" ]]; then
    DEVICE="$("$FLUTTER" devices 2>/dev/null | awk '/Pixel 7/{print $2; exit}')"
  fi

  if [[ -n "$DEVICE" ]]; then
    if ! pgrep -f "flutter attach.*${DEVICE}" >/dev/null 2>&1; then
      if "$FLUTTER" devices 2>/dev/null | grep -q "$DEVICE"; then
        log "Attaching to $DEVICE …"
        "$FLUTTER" attach -d "$DEVICE" --dart-define=API_HTTP_LOG=true 2>&1 | sed 's/^/[flutter-attach] /' &
        sleep 2
      fi
    fi
  fi
  sleep "$INTERVAL"
done
