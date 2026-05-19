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
