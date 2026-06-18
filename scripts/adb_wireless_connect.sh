#!/usr/bin/env bash
# Auto-discover and connect Pixel 7 over wireless ADB. Always exit 0 (never block debug).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/.adb_wireless.env"
PID_FILE="${ROOT}/.adb_wireless_watch.pid"
VSCODE_DIR="${ROOT}/.vscode"
SERIAL="${ADB_WIRELESS_SERIAL:-33091FDH2006CG}"
LEGACY_PORT="${ADB_WIRELESS_PORT:-5555}"

export ADB_MDNS_AUTO_CONNECT="${ADB_MDNS_AUTO_CONNECT:-adb-tls-connect,adb}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  SERIAL="${ADB_WIRELESS_SERIAL:-$SERIAL}"
  LEGACY_PORT="${ADB_WIRELESS_PORT:-$LEGACY_PORT}"
fi

log() { printf '[adb-wireless] %s\n' "$*"; }
warn() { printf '[adb-wireless] WARN: %s\n' "$*"; }

adb_start() {
  adb start-server >/dev/null 2>&1 || true
}

serial_for_endpoint() {
  adb -s "$1" shell getprop ro.serialno 2>/dev/null | tr -d '\r'
}

device_state() {
  adb devices | awk -v ep="$1" 'NR>1 && $1==ep {print $2; exit}'
}

list_device_endpoints() {
  adb devices | awk 'NR>1 && $2!=""{print $1}'
}

pixel_endpoint() {
  local ep
  if [[ "$(device_state "$SERIAL")" == "device" ]]; then
    echo "$SERIAL"
    return 0
  fi
  while read -r ep; do
    [[ -z "$ep" ]] && continue
    [[ "$(device_state "$ep")" != "device" ]] && continue
    if [[ "$(serial_for_endpoint "$ep")" == "$SERIAL" ]]; then
      echo "$ep"
      return 0
    fi
  done < <(list_device_endpoints)
  return 1
}

mac_lan_prefix() {
  local iface ip
  iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
  if [[ -n "${iface:-}" ]]; then
    ip="$(ifconfig "$iface" 2>/dev/null | awk '/inet /{print $2; exit}')"
  fi
  if [[ -z "${ip:-}" ]]; then
    ip="$(ifconfig 2>/dev/null | awk '/inet /{print $2; exit}')"
  fi
  [[ -n "${ip:-}" ]] && echo "${ip%.*}."
}

save_env() {
  local host="$1"
  local port="$2"
  local flutter_id="$3"
  cat >"$ENV_FILE" <<EOF
# Auto-updated by scripts/adb_wireless_connect.sh — do not edit while watch is running.
ADB_WIRELESS_SERIAL=${SERIAL}
ADB_WIRELESS_HOST=${host}
ADB_WIRELESS_PORT=${port}
ADB_MDNS_AUTO_CONNECT=${ADB_MDNS_AUTO_CONNECT}
FLUTTER_DEVICE_ID=${flutter_id}
EOF
  mkdir -p "$VSCODE_DIR"
  printf '%s\n' "$flutter_id" >"${VSCODE_DIR}/pixel7.device.id"
}

clear_saved_host() {
  save_env "" "$LEGACY_PORT" ""
  : >"${VSCODE_DIR}/pixel7.device.id" 2>/dev/null || true
}

disconnect_foreign() {
  local ep state serial
  while read -r ep state; do
    [[ -z "$ep" || "$ep" == "List" ]] && continue
    [[ "$state" != "device" && "$state" != "offline" ]] && continue
    if [[ "$ep" == "$SERIAL" ]]; then continue; fi
    if [[ "$ep" == *"$SERIAL"* ]]; then continue; fi
    serial="$(serial_for_endpoint "$ep" 2>/dev/null || true)"
    if [[ "$serial" == "$SERIAL" ]]; then continue; fi
    log "Disconnecting non-Pixel endpoint: $ep (serial=${serial:-unknown})"
    adb disconnect "$ep" >/dev/null 2>&1 || true
  done < <(adb devices | awk 'NR>1 {print $1,$2}')
}

endpoint_rank() {
  local ep="$1"
  if [[ "$ep" == *"$SERIAL"* && "$ep" == *"_adb-tls-connect"* ]]; then
    echo 0
  elif [[ "$ep" == *":"* ]]; then
    local port="${ep##*:}"
    if [[ "$port" != "5555" ]]; then
      echo 1
    else
      echo 2
    fi
  elif [[ "$ep" == "$SERIAL" ]]; then
    echo 3
  else
    echo 4
  fi
}

consolidate_pixel_endpoints() {
  local ep serial rank best_ep="" best_rank=99
  local -a pixel_eps=()
  while read -r ep; do
    [[ -z "$ep" ]] && continue
    [[ "$(device_state "$ep")" != "device" ]] && continue
    serial="$(serial_for_endpoint "$ep" 2>/dev/null || true)"
    [[ "$serial" != "$SERIAL" ]] && continue
    pixel_eps+=("$ep")
  done < <(list_device_endpoints)

  ((${#pixel_eps[@]} == 0)) && return 1

  for ep in "${pixel_eps[@]}"; do
    rank="$(endpoint_rank "$ep")"
    if [[ -z "$best_ep" || "$rank" -lt "$best_rank" ]]; then
      best_ep="$ep"
      best_rank="$rank"
    fi
  done

  for ep in "${pixel_eps[@]}"; do
    [[ "$ep" == "$best_ep" ]] && continue
    log "Dropping duplicate Pixel endpoint: $ep"
    adb disconnect "$ep" >/dev/null 2>&1 || true
  done
  sleep 0.3

  echo "$best_ep"
}

adb_connect_timeout() {
  local endpoint="$1"
  local max="${2:-6}"
  adb connect "$endpoint" >/tmp/adb_connect_out.$$ 2>&1 &
  local cpid=$!
  local waited=0
  while kill -0 "$cpid" 2>/dev/null && (( waited < max )); do
    sleep 1
    waited=$((waited + 1))
  done
  if kill -0 "$cpid" 2>/dev/null; then
    kill "$cpid" 2>/dev/null || true
    wait "$cpid" 2>/dev/null || true
    return 1
  fi
  wait "$cpid"
}

try_connect_endpoint() {
  local endpoint="$1"
  local host="${endpoint%:*}"
  local port="${endpoint##*:}"
  local state serial

  state="$(device_state "$endpoint" 2>/dev/null || true)"
  if [[ "$state" == "device" ]]; then
    serial="$(serial_for_endpoint "$endpoint")"
    if [[ "$serial" == "$SERIAL" ]]; then
      log "Already connected: $endpoint ($SERIAL)"
      save_env "$host" "$port" "$endpoint"
      return 0
    fi
    adb disconnect "$endpoint" >/dev/null 2>&1 || true
  elif [[ "$state" == "offline" && "$endpoint" == *"$SERIAL"* ]]; then
    log "Reconnecting offline TLS endpoint: $endpoint"
    adb disconnect "$endpoint" >/dev/null 2>&1 || true
  fi

  log "Connecting $endpoint …"
  if adb_connect_timeout "$endpoint" 6; then
    if grep -qiE 'connected|already' /tmp/adb_connect_out.$$ 2>/dev/null; then
      sleep 1
    fi
  fi
  rm -f /tmp/adb_connect_out.$$

  if [[ "$(device_state "$endpoint")" == "device" ]]; then
    serial="$(serial_for_endpoint "$endpoint")"
    if [[ "$serial" == "$SERIAL" ]]; then
      save_env "$host" "$port" "$endpoint"
      log "Connected: $endpoint ($SERIAL)"
      return 0
    fi
    adb disconnect "$endpoint" >/dev/null 2>&1 || true
  fi
  return 1
}

scan_lan_for_pixel() {
  local prefix="$1"
  local ip last_octet hits
  [[ -z "$prefix" ]] && return 1
  log "Scanning ${prefix}0/24 for Pixel 7 (port $LEGACY_PORT)…"
  hits="$(mktemp)"
  for last_octet in $(seq 1 254); do
    ip="${prefix}${last_octet}"
    (nc -z -G 1 -w 1 "$ip" "$LEGACY_PORT" 2>/dev/null && echo "$ip" >>"$hits") &
  done
  wait
  while read -r ip; do
    [[ -z "$ip" ]] && continue
    if try_connect_endpoint "${ip}:${LEGACY_PORT}"; then
      rm -f "$hits"
      return 0
    fi
  done <"$hits"
  rm -f "$hits"
  return 1
}

start_watch_if_needed() {
  if [[ -n "${ADB_WATCH_CHILD:-}" ]]; then
    return 0
  fi
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
    rm -f "$PID_FILE"
  fi
  nohup "${ROOT}/scripts/adb_wireless_watch.sh" >>"${ROOT}/.adb_wireless_watch.log" 2>&1 &
  echo $! >"$PID_FILE"
  log "Background reconnect watch started (pid $(cat "$PID_FILE"))."
}

prefer_tls_pixel_endpoint() {
  local ep endpoint service proto
  while read -r ep; do
    [[ -z "$ep" ]] && continue
    if [[ "$ep" == *"$SERIAL"* && "$ep" == *"_adb-tls-connect"* ]]; then
      consolidate_pixel_endpoints >/dev/null
      echo "$ep"
      return 0
    fi
  done < <(list_device_endpoints)

  while read -r service proto endpoint; do
    [[ -z "${endpoint:-}" ]] && continue
    [[ "$proto" != "_adb-tls-connect._tcp" ]] && continue
    [[ "$service" != *"$SERIAL"* ]] && continue
    if try_connect_endpoint "$endpoint"; then
      consolidate_pixel_endpoints >/dev/null
      pixel_endpoint
      return 0
    fi
  done < <(adb mdns services 2>/dev/null | awk 'NR>1 {print $1,$2,$3}')
  return 1
}

adb_start
disconnect_foreign
sleep 0.3

if ep="$(consolidate_pixel_endpoints)"; then
  if tls_ep="$(prefer_tls_pixel_endpoint)"; then
    ep="$tls_ep"
  fi
  host="${ep%:*}"
  port="${ep##*:}"
  if [[ "$ep" != *":"* ]]; then
    host=""
    port="$LEGACY_PORT"
  fi
  save_env "$host" "$port" "$ep"
  log "Pixel 7 ready: $ep"
  start_watch_if_needed
  exit 0
fi

if ep="$(pixel_endpoint)"; then
  host="${ep%:*}"
  port="${ep##*:}"
  [[ "$ep" == *":"* ]] || { host=""; port="$LEGACY_PORT"; }
  save_env "$host" "$port" "$ep"
  log "Pixel 7 ready: $ep"
  start_watch_if_needed
  exit 0
fi

# USB bootstrap (legacy tcpip) when cable attached.
if [[ "$(device_state "$SERIAL")" == "device" ]]; then
  phone_ip="$(adb -s "$SERIAL" shell ip -f inet addr show wlan0 2>/dev/null \
    | awk '/inet /{print $2}' | cut -d/ -f1 | tr -d '\r')"
  prefix="$(mac_lan_prefix)"
  if [[ -n "${phone_ip:-}" && -n "${prefix:-}" && "$phone_ip" == ${prefix}* ]]; then
    log "USB bootstrap: adb tcpip $LEGACY_PORT on $phone_ip"
    adb -s "$SERIAL" tcpip "$LEGACY_PORT" >/dev/null
    sleep 2
    try_connect_endpoint "${phone_ip}:${LEGACY_PORT}" && start_watch_if_needed && exit 0
  fi
fi

# Saved endpoint.
if [[ -n "${ADB_WIRELESS_HOST:-}" && -n "${ADB_WIRELESS_PORT:-}" ]]; then
  if try_connect_endpoint "${ADB_WIRELESS_HOST}:${ADB_WIRELESS_PORT}"; then
    start_watch_if_needed
    exit 0
  fi
  warn "Stale saved host ${ADB_WIRELESS_HOST}:${ADB_WIRELESS_PORT}"
  clear_saved_host
fi

# mDNS — prefer Pixel serial in service name, then TLS, then legacy.
adb_start
sleep 2
while read -r service proto endpoint; do
  [[ -z "${endpoint:-}" ]] && continue
  case "$proto" in
    _adb-tls-connect._tcp)
      if [[ "$service" == *"$SERIAL"* ]]; then
        try_connect_endpoint "$endpoint" && start_watch_if_needed && exit 0
      fi
      ;;
    _adb._tcp)
      if [[ "$service" != *"$SERIAL"* ]]; then continue; fi
      try_connect_endpoint "$endpoint" && start_watch_if_needed && exit 0
      ;;
  esac
done < <(adb mdns services 2>/dev/null | awk 'NR>1 {print $1,$2,$3}')

# mDNS TLS any (after serial-specific pass failed).
while read -r service proto endpoint; do
  [[ "$proto" == "_adb-tls-connect._tcp" ]] || continue
  try_connect_endpoint "$endpoint" && start_watch_if_needed && exit 0
done < <(adb mdns services 2>/dev/null | awk 'NR>1 {print $1,$2,$3}')

# LAN scan fallback (slow — off by default for F5 preLaunch).
prefix="$(mac_lan_prefix)"
if [[ "${ADB_FULL_SCAN:-0}" == "1" ]] && scan_lan_for_pixel "$prefix"; then
  start_watch_if_needed
  exit 0
elif [[ "${ADB_FULL_SCAN:-0}" != "1" ]]; then
  log "Skipping full LAN scan (set ADB_FULL_SCAN=1 to enable)."
fi

if ep="$(pixel_endpoint)"; then
  log "Pixel 7 connected: $ep"
  start_watch_if_needed
  exit 0
fi

warn "Pixel 7 ($SERIAL) not found."
warn "Keep Wireless debugging ON. Pair once: ./scripts/adb_wireless_pair.sh <code>"
start_watch_if_needed
exit 0
