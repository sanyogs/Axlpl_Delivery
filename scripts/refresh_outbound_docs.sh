#!/usr/bin/env bash
# Refresh all outbound API docs from live capture.
# Usage (set credentials in shell only — never commit):
#   export OUTBOUND_LOGIN_MOBILE='...'
#   export OUTBOUND_LOGIN_PASSWORD='...'
#   export OUTBOUND_BRANCH_ID=27
#   export OUTBOUND_VALID_POSTS=1
#   export OUTBOUND_DISCOVER_IDS=1
#   # Test data (QA — adjust per environment):
#   export OUTBOUND_DOCKET_NO='990831778839479'
#   export OUTBOUND_BAG_ID='BAG20260515154014'
#   export OUTBOUND_MANIFEST_ID='MUM075'
#   export OUTBOUND_MAWB_NO='mum4321'          # resolves pickup_id via getpickuplist
#   export OUTBOUND_PICKUP_ID='122'            # optional; skip MAWB lookup if set
#   export OUTBOUND_SKIP_CREATEBAG=1
#   ./scripts/refresh_outbound_docs.sh

set -euo pipefail
cd "$(dirname "$0")/.."

export OUTBOUND_BRANCH_ID="${OUTBOUND_BRANCH_ID:-27}"
export OUTBOUND_VALID_POSTS="${OUTBOUND_VALID_POSTS:-1}"
export OUTBOUND_DISCOVER_IDS="${OUTBOUND_DISCOVER_IDS:-1}"
export OUTBOUND_SKIP_CREATEBAG="${OUTBOUND_SKIP_CREATEBAG:-0}"
export OUTBOUND_REPORT_END_DATE="${OUTBOUND_REPORT_END_DATE:-2026-05-15}"

echo "==> capture_outbound_v8_responses.py"
python3 scripts/capture_outbound_v8_responses.py

echo "==> generate_outbound_api_table_with_curl.py"
python3 scripts/generate_outbound_api_table_with_curl.py

echo "==> generate_outbound_api_responses_reference.py"
python3 scripts/generate_outbound_api_responses_reference.py

echo "==> export_outbound_backend_ticket.py"
python3 scripts/export_outbound_backend_ticket.py

echo "==> export_outbound_requests_responses.py"
python3 scripts/export_outbound_requests_responses.py

echo "==> validate_outbound_capture.py"
python3 scripts/validate_outbound_capture.py

echo "Done. See docs/outbound_services_v8_apis.md and docs/outbound_services_v8_master_table.md"
