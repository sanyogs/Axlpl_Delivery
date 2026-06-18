#!/usr/bin/env bash
# Connect Pixel 7 + install + launch with API/curl logging.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER="${ROOT}/.fvm/versions/3.27.2/bin/flutter"
[[ -x "$FLUTTER" ]] || FLUTTER=flutter

export ADB_FULL_SCAN="${ADB_FULL_SCAN:-0}"
"${ROOT}/scripts/adb_wireless_connect.sh"

DEVICE=""
if [[ -f "${ROOT}/.vscode/pixel7.device.id" ]]; then
  DEVICE="$(tr -d '[:space:]' <"${ROOT}/.vscode/pixel7.device.id")"
fi
if [[ -z "$DEVICE" ]] || ! adb devices | awk -v d="$DEVICE" '$1==d && $2=="device"{found=1} END{exit !found}'; then
  DEVICE="$(adb devices | awk 'NR>1 && $2=="device" && $1 !~ /^emulator/{print $1; exit}')"
fi

if [[ -z "$DEVICE" ]]; then
  echo ""
  echo "Pixel 7 not on ADB. On the phone:"
  echo "  1. Same Wi‑Fi as Mac (192.168.1.x)"
  echo "  2. Settings → Developer options → Wireless debugging ON"
  echo "  3. Pair: ./scripts/adb_wireless_pair.sh <6-digit-code>"
  echo "  Or plug USB once, then re-run this script."
  exit 1
fi

echo "Launching on $DEVICE with API_HTTP_LOG …"
cd "$ROOT"
exec "$FLUTTER" run -d "$DEVICE" --dart-define=API_HTTP_LOG=true
