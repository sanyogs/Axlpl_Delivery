#!/usr/bin/env bash
# Persistent wireless ADB reconnect (every 12s). Started automatically by adb_wireless_connect.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="${ROOT}/.adb_wireless_watch.pid"
INTERVAL="${ADB_WATCH_INTERVAL_SEC:-12}"

echo $$ >"$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT

export ADB_MDNS_AUTO_CONNECT="${ADB_MDNS_AUTO_CONNECT:-adb-tls-connect,adb}"

while true; do
  ADB_WATCH_CHILD=1 "${ROOT}/scripts/adb_wireless_connect.sh" 2>&1 | sed 's/^\[adb-wireless\]/[adb-watch]/' || true
  sleep "$INTERVAL"
done
