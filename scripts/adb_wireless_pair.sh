#!/usr/bin/env bash
# One-time wireless-debugging pair (Android 11+).
# On Pixel 7: Settings → Developer options → Wireless debugging → Pair device with pairing code
# Usage: ./scripts/adb_wireless_pair.sh 123456 [host:pair_port]
set -euo pipefail

CODE="${1:-}"
PAIR_TARGET="${2:-}"

if [[ -z "$CODE" ]]; then
  echo "Usage: $0 <6-digit-pairing-code> [host:pair_port]"
  echo "Get the code from Pixel 7 → Developer options → Wireless debugging → Pair device"
  exit 1
fi

export ADB_MDNS_AUTO_CONNECT="${ADB_MDNS_AUTO_CONNECT:-adb-tls-connect,adb}"
adb start-server >/dev/null

if [[ -z "$PAIR_TARGET" ]]; then
  echo "Discovered pairing endpoints:"
  adb mdns services 2>/dev/null | awk '/_adb-tls-pairing\._tcp/ {print $3}'
  PAIR_TARGET="$(adb mdns services 2>/dev/null | awk '/_adb-tls-pairing\._tcp/ {print $3; exit}')"
fi

if [[ -z "$PAIR_TARGET" ]]; then
  echo "No pairing endpoint found. Enable Wireless debugging on the phone (same Wi‑Fi as Mac)."
  exit 1
fi

echo "Pairing with $PAIR_TARGET …"
adb pair "$PAIR_TARGET" "$CODE"
echo "Pairing done. Running wireless connect …"
"$(cd "$(dirname "$0")" && pwd)/adb_wireless_connect.sh"
