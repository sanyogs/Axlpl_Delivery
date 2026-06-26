#!/usr/bin/env bash
# Connect Pixel 7 (wireless/USB), run debug build, open DevTools Network tab in browser.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER="${ROOT}/.fvm/versions/3.27.2/bin/flutter"
[[ -x "$FLUTTER" ]] || FLUTTER=flutter
PKG=com.vnt.axlpl.messenger
VM_URI_FILE="${ROOT}/.vscode/flutter_vm_service.uri"
DEVTOOLS_PORT="${DEVTOOLS_PORT:-9105}"
RETRIES="${ADB_CONNECT_RETRIES:-12}"

log() { printf '[debug-pixel7] %s\n' "$*" >&2; }

pick_device() {
  local d
  if [[ -f "${ROOT}/.adb_wireless.env" ]]; then
    # shellcheck disable=SC1090
    source "${ROOT}/.adb_wireless.env"
    d="${FLUTTER_DEVICE_ID:-}"
    if [[ -n "$d" ]] && adb devices | awk -v ep="$d" '$1==ep && $2=="device"{found=1} END{exit !found}'; then
      echo "$d"
      return 0
    fi
  fi
  d="$(adb devices | awk 'NR>1 && $2=="device" && $1 !~ /^emulator/ {print $1; exit}')"
  [[ -n "$d" ]] && echo "$d"
}

wait_for_device() {
  local attempt=1
  while (( attempt <= RETRIES )); do
    log "Connect attempt $attempt/$RETRIES …"
    ADB_FULL_SCAN="${ADB_FULL_SCAN:-$(( attempt > 3 ? 1 : 0 ))}" \
      "${ROOT}/scripts/adb_wireless_connect.sh" >/dev/null 2>&1 || true
    if d="$(pick_device)"; then
      echo "$d"
      return 0
    fi
    sleep 5
    attempt=$((attempt + 1))
  done
  return 1
}

ensure_debug_installable() {
  local device="$1"
  local apk="${ROOT}/build/app/outputs/flutter-apk/app-debug.apk"
  if [[ ! -f "$apk" ]]; then
    return 0
  fi
  if adb -s "$device" install -r "$apk" >/dev/null 2>&1; then
    return 0
  fi
  log "Debug install blocked (release signature?) — uninstalling $PKG …"
  adb -s "$device" uninstall "$PKG" >/dev/null 2>&1 || true
}

open_network_devtools() {
  local vm_uri="$1"
  mkdir -p "${ROOT}/.vscode"
  printf '%s\n' "$vm_uri" >"$VM_URI_FILE"
  local encoded
  encoded="$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$vm_uri")"
  local url="http://127.0.0.1:${DEVTOOLS_PORT}/network?uri=${encoded}"
  log "Opening DevTools Network tab: $url"
  if ! curl -sf "http://127.0.0.1:${DEVTOOLS_PORT}/" >/dev/null 2>&1; then
    log "Starting DevTools server on port ${DEVTOOLS_PORT} …"
    nohup "${ROOT}/.fvm/versions/3.27.2/bin/dart" devtools --port="$DEVTOOLS_PORT" >/dev/null 2>&1 &
    sleep 2
  fi
  open "$url" 2>/dev/null || xdg-open "$url" 2>/dev/null || true
}

main() {
  local device
  if ! device="$(wait_for_device)"; then
    local subnet
    subnet="$(route -n get default 2>/dev/null | awk '/interface:/{iface=$2} END{if(iface) print iface}' | xargs -I{} ifconfig {} 2>/dev/null | awk '/inet /{print $2}' | head -1)"
    log "Pixel 7 not found on ADB."
    log "Mac LAN: ${subnet:-unknown} — phone must be on the same Wi‑Fi with Wireless debugging ON."
    log "Or plug USB once, then re-run: ./scripts/debug_pixel7_network.sh"
    exit 1
  fi

  log "Using device: $device"
  mkdir -p "${ROOT}/.vscode"
  echo "$device" >"${ROOT}/.vscode/pixel7.device.id"
  cat >"${ROOT}/.adb_wireless.env" <<EOF
ADB_WIRELESS_SERIAL=33091FDH2006CG
ADB_WIRELESS_HOST=${device%%:*}
ADB_WIRELESS_PORT=${device##*:}
ADB_MDNS_AUTO_CONNECT=adb-tls-connect,adb
FLUTTER_DEVICE_ID=${device}
EOF

  ensure_debug_installable "$device"

  cd "$ROOT"
  log "Starting Flutter debug (API_HTTP_LOG=true) …"
  local log_file
  log_file="$(mktemp)"
  trap 'rm -f "$log_file"' EXIT

  (
    "$FLUTTER" run -d "$device" \
      --dart-define=API_HTTP_LOG=true 2>&1 | tee "$log_file"
  ) &
  local run_pid=$!

  local vm_uri=""
  local waited=0
  while (( waited < 300 )); do
    if grep -q "Dart VM Service" "$log_file" 2>/dev/null; then
      vm_uri="$(grep -oE 'http://127\.0\.0\.1:[0-9]+/[A-Za-z0-9_=/]+' "$log_file" | head -1 || true)"
      [[ -n "$vm_uri" ]] && break
    fi
    if ! kill -0 "$run_pid" 2>/dev/null; then
      break
    fi
    sleep 2
    waited=$((waited + 2))
  done

  if [[ -z "$vm_uri" ]]; then
    log "Waiting for VM service URI …"
    sleep 5
    vm_uri="$(grep -oE 'http://127\.0\.0\.1:[0-9]+/[A-Za-z0-9_=/]+' "$log_file" | head -1 || true)"
  fi

  if [[ -n "$vm_uri" ]]; then
    open_network_devtools "$vm_uri"
    log "Debug session running (pid $run_pid). DevTools Network tab should be open in your browser."
    wait "$run_pid"
  else
    log "Flutter run failed before VM service was available. Log:"
    tail -30 "$log_file" || true
    wait "$run_pid" || true
    exit 1
  fi
}

main "$@"
