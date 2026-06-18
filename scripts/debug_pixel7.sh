#!/usr/bin/env bash
# One command: wireless ADB + Flutter run with API logging (for terminal debugging).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"${ROOT}/scripts/adb_wireless_connect.sh"
DEVICE=""
if [[ -f "${ROOT}/.vscode/pixel7.device.id" ]]; then
  DEVICE="$(tr -d '[:space:]' <"${ROOT}/.vscode/pixel7.device.id")"
fi
if [[ -z "$DEVICE" && -f "${ROOT}/.adb_wireless.env" ]]; then
  # shellcheck disable=SC1090
  source "${ROOT}/.adb_wireless.env"
  DEVICE="${FLUTTER_DEVICE_ID:-}"
fi
ARGS=(run --dart-define=API_HTTP_LOG=true)
[[ -n "$DEVICE" ]] && ARGS+=(-d "$DEVICE")
cd "$ROOT"
.fvm/versions/3.27.2/bin/flutter "${ARGS[@]}" 2>/dev/null || flutter "${ARGS[@]}"
