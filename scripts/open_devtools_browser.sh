#!/usr/bin/env bash
# Open Flutter DevTools in the default browser (Logging → filter ApiUrl / ApiHttp).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER="${ROOT}/.fvm/versions/3.27.2/bin/flutter"
[[ -x "$FLUTTER" ]] || FLUTTER=flutter

VM_URI=""
if [[ -f "${ROOT}/.vscode/flutter_vm_service.uri" ]]; then
  VM_URI="$(tr -d '[:space:]' <"${ROOT}/.vscode/flutter_vm_service.uri")"
fi

if [[ -z "$VM_URI" ]]; then
  VM_URI="$("$FLUTTER" pub global run devtools --machine 2>/dev/null | awk '/http/ {print; exit}' || true)"
fi

if [[ -z "$VM_URI" ]]; then
  echo "No VM service URI found. Start debug first: ./scripts/run_pixel7.sh"
  echo "Or F5 → Flutter (Pixel 7 — network)"
  exit 1
fi

ENCODED="$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$VM_URI")"
TAB="${DEVTOOLS_TAB:-network}"
URL="http://127.0.0.1:9105/${TAB}?uri=${ENCODED}"

echo "Opening DevTools: $URL"
open "$URL"
