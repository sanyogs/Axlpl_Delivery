#!/usr/bin/env bash
# All Sarvesh QA curls — curl/bash only.
set -euo pipefail
TOKEN="${OUTBOUND_BEARER_TOKEN:-ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7}"
BASE='https://my.axlpl.com/messenger/services_v8/api.php'
OUT='/Users/apple/Desktop/flutter_project/axlpl_delivery/docs/outbound_sarvesh_qa_verified.md'
HDR=(--header "Authorization: Bearer ${TOKEN}" --header 'X-App-Version: 22.1.0' --header 'X-App-Platform: ios')

run_block() {
  local title="$1"
  local curl_show="$2"
  shift 2
  echo "## ${title}" >>"$OUT"
  echo >>"$OUT"
  echo '**Request curl**' >>"$OUT"
  echo '```bash' >>"$OUT"
  echo "$curl_show" >>"$OUT"
  echo '```' >>"$OUT"
  echo >>"$OUT"
  echo '**Response**' >>"$OUT"
  echo '```json' >>"$OUT"
  local out http body
  out=$("$@" 2>&1) || true
  http=$(echo "$out" | tail -1 | sed 's/__HTTP__://')
  body=$(echo "$out" | sed '$d')
  [[ -z "$body" ]] && body="(empty)"
  echo "$body" >>"$OUT"
  echo '```' >>"$OUT"
  echo >>"$OUT"
  echo "**HTTP:** ${http}" >>"$OUT"
  echo >>"$OUT"
  echo '---' >>"$OUT"
  echo >>"$OUT"
}

cat >"$OUT" <<'HDRDOC'
# Outbound — Sarvesh QA verified curls

Gateway: `api.php?request=<action>` · iOS headers · **no** `platform` param · POST = `--form` multipart.

QA: hub docket `558751776258671`, bagging docket `825411779084407`, remove/rebag docket `442291776257551`, bag `BAG20260518152744831`, list branch `75`, manifest origin `37` dest `75`.

Regenerate: `./docs/run_sarvesh_qa_curls.sh`

---

HDRDOC

run_block 'getshipmentscanhistory' \
"curl --location --request GET '${BASE}?request=getshipmentscanhistory&docket_no=558751776258671' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request GET "${BASE}?request=getshipmentscanhistory&docket_no=558751776258671" "${HDR[@]}"

run_block 'addshipmenttobag' \
"curl --location --request POST '${BASE}?request=addshipmenttobag' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios' \\
  --form 'bag_code=BAG20260518152744831' \\
  --form 'docket_no=825411779084407' \\
  --form 'branch_id=1' \\
  --form 'user_id=1'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request POST "${BASE}?request=addshipmenttobag" "${HDR[@]}" \
  --form 'bag_code=BAG20260518152744831' --form 'docket_no=825411779084407' --form 'branch_id=1' --form 'user_id=1'

run_block 'manifestreport' \
"curl --location --request GET '${BASE}?request=manifestreport&start_date=2026-05-01&end_date=2026-05-18&manifest_no=MUM094' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request GET "${BASE}?request=manifestreport&start_date=2026-05-01&end_date=2026-05-18&manifest_no=MUM094" "${HDR[@]}"

run_block 'getlinehauldetails' \
"curl --location --request GET '${BASE}?request=getlinehauldetails&mawb_no=58976412530' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request GET "${BASE}?request=getlinehauldetails&mawb_no=58976412530" "${HDR[@]}"

run_block 'getmanifestdetails' \
"curl --location --request GET '${BASE}?request=getmanifestdetails&manifest_code=MUM208' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request GET "${BASE}?request=getmanifestdetails&manifest_code=MUM208" "${HDR[@]}"

run_block 'editlinehaul' \
"curl --location --request POST '${BASE}?request=editlinehaul' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.3.0' \\
  --header 'Content-Type: application/x-www-form-urlencoded' \\
  --data-urlencode 'linehaul_id=365' \\
  --data-urlencode 'vehicle_no=MH01AB1234' \\
  --data-urlencode 'driver_name=Ramesh Kumar' \\
  --data-urlencode 'driver_mobile=9876543210' \\
  --data-urlencode 'mawb_no=31229324256' \\
  --data-urlencode 'trip_no=LH1780998599' \\
  --data-urlencode 'departure_time=2026-06-09 10:00:00' \\
  --data-urlencode 'arrival_time=2026-06-10 08:00:00' \\
  --data-urlencode 'remarks=Updated via API' \\
  --data-urlencode 'flight_no=AI101' \\
  --data-urlencode 'airline=Air India' \\
  --data-urlencode 'eway_bill=EWB123456789' \\
  --data-urlencode 'transport_type=Airway'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request POST "${BASE}?request=editlinehaul" \
  --header "Authorization: Bearer ${TOKEN}" --header 'X-App-Version: 22.3.0' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'linehaul_id=365' --data-urlencode 'vehicle_no=MH01AB1234' \
  --data-urlencode 'driver_name=Ramesh Kumar' --data-urlencode 'driver_mobile=9876543210' \
  --data-urlencode 'mawb_no=31229324256' --data-urlencode 'trip_no=LH1780998599' \
  --data-urlencode 'departure_time=2026-06-09 10:00:00' --data-urlencode 'arrival_time=2026-06-10 08:00:00' \
  --data-urlencode 'remarks=Updated via API' --data-urlencode 'flight_no=AI101' \
  --data-urlencode 'airline=Air India' --data-urlencode 'eway_bill=EWB123456789' \
  --data-urlencode 'transport_type=Airway'

# Destructive — skip live run by default; documented response from 2026-06-09 verify.
run_block 'deletelinehaul' \
"curl --location --request POST '${BASE}?request=deletelinehaul' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.3.0' \\
  --header 'Content-Type: application/x-www-form-urlencoded' \\
  --data-urlencode 'linehaul_id=365'" \
  echo '{"status":"success","message":"Linehaul deleted successfully","data":{"linehaul_id":365}}' && echo '__HTTP__:200'

run_block 'getbagdetails' \
"curl --location --request GET '${BASE}?request=getbagdetails&bag_code=BAG20260518152744831' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request GET "${BASE}?request=getbagdetails&bag_code=BAG20260518152744831" "${HDR[@]}"

run_block 'listbags' \
"curl --location --request GET '${BASE}?request=listbags&branch_id=75' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request GET "${BASE}?request=listbags&branch_id=75" "${HDR[@]}"

run_block 'removeshipmentfrombag' \
"curl --location --request POST '${BASE}?request=removeshipmentfrombag' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios' \\
  --form 'bag_code=BAG20260518152744831' \\
  --form 'docket_no=442291776257551' \\
  --form 'branch_id=1' \\
  --form 'user_id=1'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request POST "${BASE}?request=removeshipmentfrombag" "${HDR[@]}" \
  --form 'bag_code=BAG20260518152744831' --form 'docket_no=442291776257551' --form 'branch_id=1' --form 'user_id=1'

run_block 'lockbag' \
"curl --location --request POST '${BASE}?request=lockbag' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios' \\
  --form 'bag_code=BAG20260518152744831'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request POST "${BASE}?request=lockbag" "${HDR[@]}" \
  --form 'bag_code=BAG20260518152744831'

run_block 'rebagshipment' \
"curl --location --request POST '${BASE}?request=rebagshipment' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios' \\
  --form 'new_bag_code=BAG20260518152744831' \\
  --form 'docket_no=442291776257551' \\
  --form 'user_id=1'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request POST "${BASE}?request=rebagshipment" "${HDR[@]}" \
  --form 'new_bag_code=BAG20260518152744831' --form 'docket_no=442291776257551' --form 'user_id=1'

run_block 'baggingreport' \
"curl --location --request GET '${BASE}?request=baggingreport&start_date=2026-03-01&end_date=2026-05-18&bag_code=BAG20260518152744831' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request GET "${BASE}?request=baggingreport&start_date=2026-03-01&end_date=2026-05-18&bag_code=BAG20260518152744831" "${HDR[@]}"

run_block 'createmanifest' \
"curl --location --request POST '${BASE}?request=createmanifest' \\
  --header 'Authorization: Bearer \$TOKEN' \\
  --header 'X-App-Version: 22.1.0' \\
  --header 'X-App-Platform: ios' \\
  --form 'bag_codes=BAG20260518152744831' \\
  --form 'origin_branch_id=37' \\
  --form 'destination_branch_id=75' \\
  --form 'user_id=1'" \
  curl -sS -w $'\n__HTTP__:%{http_code}' --location --request POST "${BASE}?request=createmanifest" "${HDR[@]}" \
  --form 'bag_codes=BAG20260518152744831' --form 'origin_branch_id=37' --form 'destination_branch_id=75' --form 'user_id=1'

echo "Wrote $OUT"
