#!/usr/bin/env bash
# Outbound API failure report — curl only, no Python.
set -euo pipefail

TOKEN="${OUTBOUND_BEARER_TOKEN:-ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7}"
OUT="/Users/apple/Desktop/flutter_project/axlpl_delivery/docs/outbound_api_failures_filtered_report.html"
APIPHP="https://my.axlpl.com/messenger/services_v8/api.php"
PATH_BASE="https://my.axlpl.com/messenger/services_v8"
HDR=(-H "Authorization: Bearer ${TOKEN}" -H "X-App-Version: 22.3.0" -H "X-App-Platform: android" -H "accept: */*")

html_esc() {
  sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

# Returns 0 if row should be in report (not 200 OR no success in body)
is_failure() {
  local http="$1" body="$2"
  if [[ "$http" != "200" ]]; then return 0; fi
  echo "$body" | grep -qi 'success' && return 1
  return 0
}

emit_card() {
  local idx="$1" source="$2" api="$3" http="$4" reason="$5" curl_cmd="$6" body="$7"
  local esc_curl esc_body esc_reason
  esc_curl=$(printf '%s' "$curl_cmd" | html_esc)
  esc_body=$(printf '%s' "$body" | html_esc)
  esc_reason=$(printf '%s' "$reason" | html_esc)
  cat >>"$OUT" <<CARD
<div class="card">
  <h2>${idx}. <span class="tag ${source}">${source}</span> <code>${api}</code> — HTTP ${http}</h2>
  <div class="reason"><strong>Reason:</strong> ${esc_reason}</div>
  <p class="lbl">Request curl</p>
  <pre class="code">${esc_curl}</pre>
  <p class="lbl">Response</p>
  <pre class="code">${esc_body}</pre>
</div>
CARD
}

run_get() {
  local source="$1" api="$2" url="$3"
  local curl_cmd="curl -sS -w '\\n__HTTP_CODE__:%{http_code}' -X GET '${url}' \\
  -H 'Authorization: Bearer \$TOKEN' \\
  -H 'X-App-Version: 22.3.0' \\
  -H 'X-App-Platform: android' \\
  -H 'accept: */*'"
  local out http body
  out=$(curl -sS -w $'\n__HTTP_CODE__:%{http_code}' -X GET "$url" "${HDR[@]}")
  http=$(echo "$out" | tail -1 | sed 's/__HTTP_CODE__://')
  body=$(echo "$out" | sed '$d')
  [[ -z "$body" ]] && body="(empty response body)"
  if is_failure "$http" "$body"; then
    local reason
    if [[ "$http" != "200" ]]; then reason="HTTP status is ${http}, not 200"; else reason="HTTP 200 but response does not contain success"; fi
  if echo "$body" | grep -q '"message"'; then
      reason="${reason} — $(echo "$body" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    fi
    emit_card "$idx" "$source" "$api" "$http" "$reason" "$curl_cmd" "$body"
    idx=$((idx+1))
  fi
}

run_post() {
  local source="$1" api="$2" url="$3" data="$4"
  local curl_cmd="curl -sS -w '\\n__HTTP_CODE__:%{http_code}' -X POST '${url}' \\
  -H 'Authorization: Bearer \$TOKEN' \\
  -H 'Content-Type: application/x-www-form-urlencoded' \\
  -H 'X-App-Version: 22.3.0' \\
  -H 'X-App-Platform: android' \\
  --data '${data}'"
  local out http body
  out=$(curl -sS -w $'\n__HTTP_CODE__:%{http_code}' -X POST "$url" "${HDR[@]}" -H "Content-Type: application/x-www-form-urlencoded" --data "$data")
  http=$(echo "$out" | tail -1 | sed 's/__HTTP_CODE__://')
  body=$(echo "$out" | sed '$d')
  [[ -z "$body" ]] && body="(empty response body)"
  if is_failure "$http" "$body"; then
    local reason
    if [[ "$http" != "200" ]]; then reason="HTTP status is ${http}, not 200"; else reason="HTTP 200 but response does not contain success"; fi
    if echo "$body" | grep -q '"message"'; then
      reason="${reason} — $(echo "$body" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
    fi
    emit_card "$idx" "$source" "$api" "$http" "$reason" "$curl_cmd" "$body"
    idx=$((idx+1))
  fi
}

idx=1

cat >"$OUT" <<'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<title>Outbound API Failures — curl report</title>
<style>
body{font-family:system-ui,sans-serif;max-width:960px;margin:0 auto;padding:20px;background:#f4f6f9}
h1{color:#0d47a1}
.sql{background:#e3f2fd;padding:14px;border-radius:8px;font-family:ui-monospace,monospace;font-size:13px;margin:16px 0}
.card{background:#fff;border:1px solid #ddd;border-radius:8px;margin:18px 0;padding:18px}
.reason{background:#ffebee;padding:12px;border-left:4px solid #c62828;margin:10px 0}
.lbl{font-size:11px;font-weight:bold;color:#666;text-transform:uppercase;margin-top:14px}
pre.code{background:#1e293b;color:#eceff1;padding:14px;border-radius:6px;font-size:12px;white-space:pre-wrap;word-break:break-all}
.tag{padding:3px 10px;border-radius:4px;font-size:11px;font-weight:bold;color:#fff}
.postman{background:#e65100}.pdf{background:#1565c0}
h2{font-size:1rem;margin:0 0 10px}
</style>
</head>
<body>
<h1>Outbound API failures (curl only)</h1>
<div class="sql">
Filter: <code>status &lt;&gt; 200 OR response NOT LIKE '%success%'</code><br>
Sources: <strong>postman</strong> (api.php?request=) + <strong>pdf</strong> (path URL)<br>
Replace <code>$TOKEN</code> with messenger JWT.
</div>
<h2>Failed APIs</h2>
HTMLHEAD

# --- POSTMAN (27) ---
run_post postman hubscan "${APIPHP}?request=hubscan&platform=android" "docket_no=BAG20260515154014&branch_id=1&user_id=1&status=Hub+In&platform=android"
run_get postman gethubscanlogs "${APIPHP}?request=gethubscanlogs&branch_id=1&limit=50&platform=android"
run_get postman getshipmentscanhistory "${APIPHP}?request=getshipmentscanhistory&docket_no=BAG20260515154014&platform=android"
run_post postman createbag "${APIPHP}?request=createbag&platform=android" "origin_branch_id=1&destination_branch_id=2&bag_code=BAG20260518132700&user_id=1&platform=android"
run_post postman addshipmenttobag "${APIPHP}?request=addshipmenttobag&platform=android" "bag_code=BAG20260518132700&docket_no=AWB1234567&branch_id=1&user_id=1&platform=android"
run_get postman getbagdetails "${APIPHP}?request=getbagdetails&bag_code=BAG20260518132700&platform=android"
run_get postman listbags "${APIPHP}?request=listbags&branch_id=1&platform=android"
run_post postman removeshipmentfrombag "${APIPHP}?request=removeshipmentfrombag&platform=android" "bag_code=BAG20260518132700&docket_no=AWB1234567&branch_id=1&user_id=1&platform=android"
run_post postman lockbag "${APIPHP}?request=lockbag&platform=android" "bag_code=BAG20260518132700&platform=android"
run_post postman rebagshipment "${APIPHP}?request=rebagshipment&platform=android" "new_bag_code=BAG20260518999999&docket_no=AWB1234567&user_id=1&platform=android"
run_get postman baggingreport "${APIPHP}?request=baggingreport&start_date=2026-05-01&end_date=2026-05-18&platform=android"
run_post postman createmanifest "${APIPHP}?request=createmanifest&platform=android" "bag_codes=BAG20260518132700,BAG20260518999999&origin_branch_id=1&destination_branch_id=2&user_id=1&platform=android"
run_get postman getmanifestdetails "${APIPHP}?request=getmanifestdetails&manifest_code=MUM075&platform=android"
run_get postman listmanifests "${APIPHP}?request=listmanifests&branch_id=1&platform=android"
run_get postman manifestreport "${APIPHP}?request=manifestreport&start_date=2026-05-01&end_date=2026-05-18&platform=android"
run_get postman printmanifestdata "${APIPHP}?request=printmanifestdata&manifest_code=MUM075&platform=android"
run_post postman assignlinehaul "${APIPHP}?request=assignlinehaul&platform=android" "manifest_codes=MUM075,MUM076&vehicle_no=MH-02-AB-1234&driver_name=John+Doe&user_id=1&platform=android"
run_get postman listlinehauls "${APIPHP}?request=listlinehauls&status=In+Transit&platform=android"
run_get postman getlinehauldetails "${APIPHP}?request=getlinehauldetails&trip_no=LH1778841961&platform=android"
run_post postman updatelinehaulstatus "${APIPHP}?request=updatelinehaulstatus&platform=android" "trip_no=LH1778841961&status=Arrived&user_id=1&branch_id=2&platform=android"
run_get postman linehaulreport "${APIPHP}?request=linehaulreport&start_date=2026-05-01&end_date=2026-05-18&platform=android"
run_post postman sectorpickupscan "${APIPHP}?request=sectorpickupscan&platform=android" "pickup_id=123&docket_no=AWB1234567&status=Picked&remarks=Scanned&user_id=1&branch_id=1&platform=android"
run_get postman getpickuplist "${APIPHP}?request=getpickuplist&platform=android"
run_post postman marknotpicked "${APIPHP}?request=marknotpicked&platform=android" "pickup_id=123&docket_no=AWB1234567&remarks=Customer+not+available&user_id=1&branch_id=1&platform=android"
run_post postman addmissedshipment "${APIPHP}?request=addmissedshipment&platform=android" "pickup_id=123&docket_no=AWB1234567&remarks=Damaged&platform=android"
run_get postman pickupreport "${APIPHP}?request=pickupreport&start_date=2026-05-01&end_date=2026-05-18&platform=android"
run_get postman getbranches "${APIPHP}?request=getbranches&platform=android"

# --- PDF (26) ---
run_post pdf hubscan "${PATH_BASE}/hubscan?platform=android" "docket_no=AXL123456&branch_id=2&user_id=148&status=Hub+In&platform=android"
run_get pdf gethubscanlogs "${PATH_BASE}/gethubscanlogs?branch_id=2&limit=50&platform=android"
run_get pdf getshipmentscanhistory "${PATH_BASE}/getshipmentscanhistory?docket_no=AXL123456&platform=android"
run_post pdf createbag "${PATH_BASE}/createbag?platform=android" "origin_branch_id=2&destination_branch_id=5&bag_code=BAG1746700000&user_id=148&platform=android"
run_post pdf addshipmenttobag "${PATH_BASE}/addshipmenttobag?platform=android" "bag_id=10&docket_no=AXL123456&branch_id=2&user_id=148&platform=android"
run_get pdf getbagdetails "${PATH_BASE}/getbagdetails?bag_id=10&platform=android"
run_get pdf listbags "${PATH_BASE}/listbags?branch_id=2&platform=android"
run_post pdf removeshipmentfrombag "${PATH_BASE}/removeshipmentfrombag?platform=android" "bag_id=10&docket_no=AXL123456&branch_id=2&user_id=148&platform=android"
run_post pdf lockbag "${PATH_BASE}/lockbag?platform=android" "bag_id=10&platform=android"
run_post pdf rebagshipment "${PATH_BASE}/rebagshipment?platform=android" "new_bag_id=12&docket_no=AXL123456&user_id=148&platform=android"
run_get pdf baggingreport "${PATH_BASE}/baggingreport?start_date=2026-04-01&end_date=2026-05-08&platform=android"
run_post pdf createmanifest "${PATH_BASE}/createmanifest?platform=android" "bag_ids=10,11,12&origin_branch_id=2&destination_branch_id=5&user_id=148&platform=android"
run_get pdf getmanifestdetails "${PATH_BASE}/getmanifestdetails?manifest_id=5&platform=android"
run_get pdf listmanifests "${PATH_BASE}/listmanifests?branch_id=2&platform=android"
run_get pdf manifestreport "${PATH_BASE}/manifestreport?start_date=2026-04-01&end_date=2026-05-08&platform=android"
run_get pdf printmanifestdata "${PATH_BASE}/printmanifestdata?manifest_id=5&platform=android"
run_post pdf assignlinehaul "${PATH_BASE}/assignlinehaul?platform=android" "manifest_ids=5,6&vehicle_no=UP78AB1234&driver_name=Ramesh+Kumar&user_id=148&platform=android"
run_get pdf listlinehauls "${PATH_BASE}/listlinehauls?status=In+Transit&platform=android"
run_get pdf getlinehauldetails "${PATH_BASE}/getlinehauldetails?linehaul_id=3&platform=android"
run_post pdf updatelinehaulstatus "${PATH_BASE}/updatelinehaulstatus?platform=android" "linehaul_id=3&status=ARRIVED&user_id=148&branch_id=2&platform=android"
run_get pdf linehaulreport "${PATH_BASE}/linehaulreport?start_date=2026-04-01&end_date=2026-05-08&platform=android"
run_post pdf sectorpickupscan "${PATH_BASE}/sectorpickupscan?platform=android" "pickup_id=15&docket_no=AXL123456&status=Picked&remarks=&user_id=148&branch_id=2&platform=android"
run_get pdf getpickuplist "${PATH_BASE}/getpickuplist?platform=android"
run_post pdf marknotpicked "${PATH_BASE}/marknotpicked?platform=android" "pickup_id=15&docket_no=AXL123456&remarks=Customer+unavailable&user_id=148&branch_id=2&platform=android"
run_post pdf addmissedshipment "${PATH_BASE}/addmissedshipment?platform=android" "pickup_id=15&docket_no=AXL123456&remarks=Shipment+not+scanned&platform=android"
run_get pdf pickupreport "${PATH_BASE}/pickupreport?start_date=2026-04-01&end_date=2026-05-08&platform=android"

total=$((idx - 1))
echo "<p><strong>Total failures:</strong> ${total} (tested with curl only)</p>" >>"$OUT"
echo "</body></html>" >>"$OUT"
echo "Wrote $OUT — $total failures"
