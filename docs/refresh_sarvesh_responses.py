#!/usr/bin/env python3
"""Run all Sarvesh + open-bug curls; update verified docs with latest JSON."""
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

TOKEN = "ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7"
BASE = "https://my.axlpl.com/messenger/services_v8/api.php"
DOCS = Path(__file__).parent
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")


def curl_get(params, ver="22.1.0", extra_headers=None):
    cmd = ["curl", "-sS", "-G", BASE]
    for k, v in params.items():
        cmd += ["--data-urlencode", f"{k}={v}"]
    cmd += ["-H", f"Authorization: Bearer {TOKEN}", "-H", f"X-App-Version: {ver}"]
    if ver == "22.1.0":
        cmd += ["-H", "X-App-Platform: ios"]
    for h in extra_headers or []:
        cmd += ["-H", h]
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()


def curl_post(request, fields, ver="22.3.0"):
    cmd = [
        "curl", "-sS", "-X", "POST", f"{BASE}?request={request}",
        "-H", f"Authorization: Bearer {TOKEN}",
        "-H", f"X-App-Version: {ver}",
        "-H", "Content-Type: application/x-www-form-urlencoded",
    ]
    for k, v in fields.items():
        cmd += ["--data-urlencode", f"{k}={v}"]
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()


def http_code(body):
    try:
        d = json.loads(body)
        if d.get("status") == "success":
            return "200"
        return str(d.get("error_code", "fail"))
    except Exception:
        return "?"


def curl_display_get(params, ver="22.1.0", extra=None):
    qs = "&".join(f"{k}={v}" for k, v in params.items())
    lines = [
        f"curl --location --request GET '{BASE}?{qs}' \\",
        f"  --header 'Authorization: Bearer {TOKEN}' \\",
        f"  --header 'X-App-Version: {ver}' \\",
    ]
    if ver == "22.1.0":
        lines.append("  --header 'X-App-Platform: ios'")
    for h in extra or []:
        lines[-1] += " \\"
        lines.append(f"  --header '{h}'")
    return "\n".join(lines)


def curl_display_post(request, fields, ver="22.3.0"):
    lines = [
        f"curl --location --request POST '{BASE}?request={request}' \\",
        f"  --header 'Authorization: Bearer {TOKEN}' \\",
        f"  --header 'X-App-Version: {ver}' \\",
        "  --header 'Content-Type: application/x-www-form-urlencoded' \\",
    ]
    for k, v in fields.items():
        lines.append(f"  --data-urlencode '{k}={v}' \\")
    return "\n".join(lines).rstrip(" \\")


def run_all():
    results = []

    def add(id_, title, method, url, curl, body, notes=""):
        results.append({
            "id": id_,
            "title": title,
            "method": method,
            "url": url,
            "curl": curl,
            "http": http_code(body),
            "body": body,
            "notes": notes,
            "verified_at": NOW,
        })

    # --- Sarvesh working curls ---
    p = {"request": "getlinehauldetails", "mawb_no": "58976412530"}
    b = curl_get(p)
    add("getlinehauldetails_mawb", "getlinehauldetails (mawb_no)", "GET",
        f"{BASE}?request=getlinehauldetails&mawb_no=58976412530",
        curl_display_get(p), b, "Works — use for linehaul detail lookup")

    p = {"request": "getlinehauldetails", "linehaul_id": "365"}
    b = curl_get(p)
    add("getlinehauldetails_linehaul_id", "getlinehauldetails (linehaul_id)", "GET",
        f"{BASE}?request=getlinehauldetails&linehaul_id=365",
        curl_display_get(p), b, "Works — alternative lookup param")

    p = {"request": "getpickupdetail", "pickup_id": "286"}
    b = curl_get(p, ver="22.3.0", extra_headers=["Accept: application/json"])
    add("getpickupdetail", "getpickupdetail", "GET",
        f"{BASE}?request=getpickupdetail&pickup_id=286",
        curl_display_get(p, ver="22.3.0", extra=["Accept: application/json"]), b,
        "Works — shipment_list[], hub, flight")

    fields = {"linehaul_id": "365"}
    b = curl_post("deletelinehaul", fields)
    add("deletelinehaul", "deletelinehaul", "POST",
        f"{BASE}?request=deletelinehaul",
        curl_display_post("deletelinehaul", fields), b, "POST urlencoded")

    fields = {
        "linehaul_id": "365", "vehicle_no": "MH01AB1234", "driver_name": "Ramesh Kumar",
        "driver_mobile": "9876543210", "mawb_no": "31229324256", "trip_no": "LH1780998599",
        "departure_time": "2026-06-09 10:00:00", "arrival_time": "2026-06-10 08:00:00",
        "remarks": "Updated via API", "flight_no": "AI101", "airline": "Air India",
        "eway_bill": "EWB123456789", "transport_type": "Airway",
    }
    b = curl_post("editlinehaul", fields)
    add("editlinehaul", "editlinehaul", "POST",
        f"{BASE}?request=editlinehaul",
        curl_display_post("editlinehaul", fields), b, "POST urlencoded")

    p = {"request": "getmanifestdetails", "manifest_code": "MUM208"}
    b = curl_get(p)
    add("getmanifestdetails_MUM208", "getmanifestdetails MUM208", "GET",
        f"{BASE}?request=getmanifestdetails&manifest_code=MUM208",
        curl_display_get(p), b, "Works — bags + rich shipments[]")

    p = {"request": "getbagdetails", "bag_code": "BAG20260518152744831"}
    b = curl_get(p)
    add("getbagdetails", "getbagdetails", "GET",
        f"{BASE}?request=getbagdetails&bag_code=BAG20260518152744831",
        curl_display_get(p), b, "items[] enriched")

    p = {"request": "manifestreport", "start_date": "2026-05-01",
          "end_date": "2026-05-18", "manifest_no": "MUM094"}
    b = curl_get(p)
    add("manifestreport_MUM094", "manifestreport", "GET",
        f"{BASE}?request=manifestreport&start_date=2026-05-01&end_date=2026-05-18&manifest_no=MUM094",
        curl_display_get(p), b, "Use manifest_no not manifest_code")

    # --- Open bugs ---
    p = {"request": "getmanifestdetails", "manifest_code": "MUM075"}
    b = curl_get(p)
    add("getmanifestdetails_MUM075", "getmanifestdetails MUM075 (OPEN)", "GET",
        f"{BASE}?request=getmanifestdetails&manifest_code=MUM075",
        curl_display_get(p), b, "OPEN — shipments[] empty")

    p = {"request": "getlinehauldetails", "trip_no": "LH1780998599"}
    b = curl_get(p)
    add("getlinehauldetails_trip_no", "getlinehauldetails trip_no (OPEN)", "GET",
        f"{BASE}?request=getlinehauldetails&trip_no=LH1780998599",
        curl_display_get(p), b, "OPEN — trip_no lookup fails (404); use mawb_no or linehaul_id")

    p = {"request": "listmanifests"}
    b = curl_get(p)
    try:
        cnt = len(json.loads(b).get("data", []))
    except Exception:
        cnt = "?"
    add("listmanifests", "listmanifests (OPEN)", "GET",
        f"{BASE}?request=listmanifests",
        curl_display_get(p), b, f"OPEN — {cnt} row cap, no pagination")

    p = {"request": "getpickuplist"}
    b = curl_get(p)
    try:
        rows = json.loads(b).get("data", [])
        dup = len(rows) - len(set(str(r.get("id")) for r in rows))
    except Exception:
        dup = "?"
    add("getpickuplist", "getpickuplist (OPEN dup)", "GET",
        f"{BASE}?request=getpickuplist",
        curl_display_get(p), b, f"OPEN — {dup} duplicate ids in response")

    return results


def write_live_json(results):
    path = DOCS / "sarvesh_live_responses.json"
    payload = {"verified_at": NOW, "token_note": "Bearer in curl strings is production messenger token", "tests": results}
    path.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"Wrote {path} ({len(results)} tests)")


def merge_curl_verify_live(results):
    path = DOCS / "curl_verify_live.json"
    data = json.loads(path.read_text()) if path.exists() else {"tests": []}
    data["verified_at"] = NOW.split()[0]
    by_id = {t["id"]: t for t in data.get("tests", [])}
    for r in results:
        entry = {
            "id": r["id"],
            "desc": r["title"],
            "method": r["method"],
            "url": r["url"] if "?" in r["url"] else r["url"],
            "extra": None,
            "http": r["http"],
            "body": r["body"],
            "source": f"refresh_sarvesh_responses.py {NOW}",
        }
        by_id[r["id"]] = entry
    data["tests"] = list(by_id.values())
    path.write_text(json.dumps(data, indent=2) + "\n")
    print(f"Updated {path}")


def write_verified_md(results):
    path = DOCS / "outbound_sarvesh_qa_verified.md"
    lines = [
        "# Outbound — Sarvesh QA verified curls",
        "",
        "Gateway: `api.php?request=<action>` · iOS headers · POST urlencoded for edit/delete linehaul.",
        "",
        f"**Last live refresh:** {NOW} · Regenerate: `python3 docs/refresh_sarvesh_responses.py`",
        "",
        "## Summary",
        "",
        "| Status | Endpoint | HTTP |",
        "|--------|----------|------|",
    ]
    for r in results:
        st = "OPEN" if "(OPEN" in r["title"] else "OK"
        lines.append(f"| {st} | `{r['id']}` | {r['http']} |")
    lines += ["", "---", ""]

    for r in results:
        lines += [
            f"## {r['title']}",
            "",
        ]
        if r["notes"]:
            lines.append(f"**Notes:** {r['notes']}")
            lines.append("")
        lines += [
            "**Request curl**",
            "```bash",
            r["curl"],
            "```",
            "",
            "**Response**",
            "```json",
        ]
        try:
            pretty = json.dumps(json.loads(r["body"]), indent=2)
            lines.append(pretty)
        except Exception:
            lines.append(r["body"])
        lines += [
            "```",
            "",
            f"**HTTP:** {r['http']}",
            "",
            "---",
            "",
        ]

    path.write_text("\n".join(lines))
    print(f"Wrote {path}")


def main():
    print(f"Running {12} curls against production...")
    results = run_all()
    write_live_json(results)
    merge_curl_verify_live(results)
    write_verified_md(results)

    ok = sum(1 for r in results if r["http"] == "200" and "(OPEN" not in r["title"])
    open_ = sum(1 for r in results if "(OPEN" in r["title"])
    print(f"Done: {ok} OK, {open_} open bugs, {len(results)} total")


if __name__ == "__main__":
    main()
