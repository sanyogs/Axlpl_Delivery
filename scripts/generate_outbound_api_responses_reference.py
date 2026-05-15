#!/usr/bin/env python3
"""Build docs/outbound_services_v8_api_responses_reference.md from docs/outbound_v8_api_capture.json.

Run after refreshing the capture:
  python3 scripts/capture_outbound_v8_responses.py
  python3 scripts/generate_outbound_api_responses_reference.py
"""

from __future__ import annotations

import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
OUT = REPO / "docs" / "outbound_services_v8_api_responses_reference.md"
CAP = REPO / "docs" / "outbound_v8_api_capture.json"


def shrink(obj, max_list: int = 3, max_str: int = 1200):
    if isinstance(obj, dict):
        return {k: shrink(v, max_list, max_str) for k, v in obj.items()}
    if isinstance(obj, list):
        if len(obj) > max_list:
            head = [shrink(x, max_list, max_str) for x in obj[:max_list]]
            return head + [f"... ({len(obj) - max_list} more items omitted)"]
        return [shrink(x, max_list, max_str) for x in obj]
    if isinstance(obj, str) and len(obj) > max_str:
        return obj[:max_str] + f"... ({len(obj) - max_str} chars omitted)"
    return obj


REQUESTS: dict[str, tuple[str, str, list[tuple[str, str, str]]]] = {
    "hubscan": (
        "POST",
        "URL-encoded body",
        [
            ("docket_no", "string", "Shipment docket / tracking id"),
            ("branch_id", "string", "Numeric branch id as string"),
            ("user_id", "string", "Messenger user id"),
            ("status", "string", "e.g. `Hub In`, `Hub Out`"),
            ("platform", "string", "Appended by client: ios/android"),
        ],
    ),
    "gethubscanlogs": (
        "GET",
        "Query",
        [
            ("branch_id", "string", "Branch filter"),
            ("limit", "int", "Max rows (sent as string in query)"),
            ("platform", "string", "ios/android"),
        ],
    ),
    "getshipmentscanhistory": (
        "GET",
        "Query",
        [
            ("docket_no", "string", "Docket to load timeline for"),
            ("platform", "string", "ios/android"),
        ],
    ),
    "createbag": (
        "POST",
        "URL-encoded body",
        [
            ("origin_branch_id", "string", ""),
            ("destination_branch_id", "string", ""),
            ("bag_code", "string", ""),
            ("user_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "addshipmenttobag": (
        "POST",
        "URL-encoded body",
        [
            ("bag_id", "string", ""),
            ("docket_no", "string", ""),
            ("branch_id", "string", ""),
            ("user_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "getbagdetails": (
        "GET",
        "Query",
        [
            ("bag_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "listbags": (
        "GET",
        "Query",
        [
            ("branch_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "removeshipmentfrombag": (
        "POST",
        "URL-encoded body",
        [
            ("bag_id", "string", ""),
            ("docket_no", "string", ""),
            ("branch_id", "string", ""),
            ("user_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "lockbag": (
        "POST",
        "URL-encoded body",
        [
            ("bag_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "rebagshipment": (
        "POST",
        "URL-encoded body",
        [
            ("new_bag_id", "string", ""),
            ("docket_no", "string", ""),
            ("user_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "baggingreport": (
        "GET",
        "Query",
        [
            ("start_date", "string", "YYYY-MM-DD"),
            ("end_date", "string", "YYYY-MM-DD"),
            ("platform", "string", "ios/android"),
        ],
    ),
    "createmanifest": (
        "POST",
        "URL-encoded body",
        [
            ("bag_ids", "string", "Comma-separated bag ids"),
            ("origin_branch_id", "string", ""),
            ("destination_branch_id", "string", ""),
            ("user_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "getmanifestdetails": (
        "GET",
        "Query",
        [
            ("manifest_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "listmanifests": (
        "GET",
        "Query",
        [
            ("branch_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "manifestreport": (
        "GET",
        "Query",
        [
            ("start_date", "string", "YYYY-MM-DD"),
            ("end_date", "string", "YYYY-MM-DD"),
            ("platform", "string", "ios/android"),
        ],
    ),
    "printmanifestdata": (
        "GET",
        "Query",
        [
            ("manifest_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "assignlinehaul": (
        "POST",
        "URL-encoded body",
        [
            ("manifest_ids", "string", "Comma-separated manifest ids"),
            ("vehicle_no", "string", ""),
            ("driver_name", "string", ""),
            ("user_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "listlinehauls": (
        "GET",
        "Query",
        [
            ("status", "string", "e.g. `In Transit`"),
            ("platform", "string", "ios/android"),
        ],
    ),
    "getlinehauldetails": (
        "GET",
        "Query",
        [
            ("linehaul_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "updatelinehaulstatus": (
        "POST",
        "URL-encoded body",
        [
            ("linehaul_id", "string", ""),
            ("status", "string", "e.g. `ARRIVED`"),
            ("user_id", "string", ""),
            ("branch_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "linehaulreport": (
        "GET",
        "Query",
        [
            ("start_date", "string", "YYYY-MM-DD"),
            ("end_date", "string", "YYYY-MM-DD"),
            ("platform", "string", "ios/android"),
        ],
    ),
    "sectorpickupscan": (
        "POST",
        "URL-encoded body",
        [
            ("pickup_id", "string", ""),
            ("docket_no", "string", ""),
            ("status", "string", "e.g. `Picked`"),
            ("remarks", "string", ""),
            ("user_id", "string", ""),
            ("branch_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "getpickuplist": (
        "GET",
        "Query",
        [
            ("platform", "string", "ios/android only (no other params in Flutter client)"),
        ],
    ),
    "marknotpicked": (
        "POST",
        "URL-encoded body",
        [
            ("pickup_id", "string", ""),
            ("docket_no", "string", ""),
            ("remarks", "string", ""),
            ("user_id", "string", ""),
            ("branch_id", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "addmissedshipment": (
        "POST",
        "URL-encoded body",
        [
            ("pickup_id", "string", ""),
            ("docket_no", "string", ""),
            ("remarks", "string", ""),
            ("platform", "string", "ios/android"),
        ],
    ),
    "pickupreport": (
        "GET",
        "Query",
        [
            ("start_date", "string", "YYYY-MM-DD"),
            ("end_date", "string", "YYYY-MM-DD"),
            ("platform", "string", "ios/android"),
        ],
    ),
}

ENDPOINTS = [
    ("1", "Hub Scan", "hubscan"),
    ("2", "Get Hub Scan Logs", "gethubscanlogs"),
    ("3", "Get Shipment Scan History", "getshipmentscanhistory"),
    ("4", "Create Bag", "createbag"),
    ("5", "Add Shipment To Bag", "addshipmenttobag"),
    ("6", "Get Bag Details", "getbagdetails"),
    ("7", "List Bags", "listbags"),
    ("8", "Remove Shipment From Bag", "removeshipmentfrombag"),
    ("9", "Lock Bag", "lockbag"),
    ("10", "Rebag Shipment", "rebagshipment"),
    ("11", "Bagging Report", "baggingreport"),
    ("12", "Create Manifest", "createmanifest"),
    ("13", "Get Manifest Details", "getmanifestdetails"),
    ("14", "List Manifests", "listmanifests"),
    ("15", "Manifest Report", "manifestreport"),
    ("16", "Print Manifest Data", "printmanifestdata"),
    ("17", "Assign Linehaul", "assignlinehaul"),
    ("18", "List Linehauls", "listlinehauls"),
    ("19", "Get Linehaul Details", "getlinehauldetails"),
    ("20", "Update Linehaul Status", "updatelinehaulstatus"),
    ("21", "Linehaul Report", "linehaulreport"),
    ("22", "Sector Pickup Scan", "sectorpickupscan"),
    ("23", "Get Pickup List", "getpickuplist"),
    ("24", "Mark Not Picked", "marknotpicked"),
    ("25", "Add Missed Shipment", "addmissedshipment"),
    ("26", "Pickup Report", "pickupreport"),
]


def main() -> None:
    data = json.loads(CAP.read_text())
    meta = data.get("meta", {})
    by_path = {r["path"]: r for r in data.get("results", [])}

    lines: list[str] = []
    lines.append("# Outbound Services V8 — API responses & request reference\n\n")
    lines.append(
        "Single reference for **all 26 outbound endpoints** under "
        "`https://my.axlpl.com/messenger/services_v8/`: **Flutter request parameters** "
        "(as implemented in [`lib/app/data/networking/api_services.dart`](../lib/app/data/networking/api_services.dart)) "
        "and **observed JSON bodies** from the automated capture.\n\n"
    )
    lines.append("> **Regenerate this file:** `python3 scripts/generate_outbound_api_responses_reference.py`\n\n")

    lines.append("## Related documents\n\n")
    lines.append("| Document | Purpose |\n|----------|---------|\n")
    lines.append(
        "| [`outbound_services_v8_apis.md`](outbound_services_v8_apis.md) | Product flow map, backend checklist, capture instructions |\n"
    )
    lines.append(
        "| [`outbound_v8_api_capture.json`](outbound_v8_api_capture.json) | **Full** raw URLs, headers, `raw_body`, `parsed_body` per call |\n"
    )
    lines.append(
        "| [`outbound_v8_api_capture.summary.json`](outbound_v8_api_capture.summary.json) | One row per API: `api_status`, `data_kind`, lengths |\n\n"
    )

    lines.append("## Capture run metadata (embedded in JSON)\n\n```json\n")
    lines.append(json.dumps(meta, indent=2, ensure_ascii=False))
    lines.append("\n```\n\n")

    lines.append("## Standard response envelope\n\n")
    lines.append("Most endpoints return JSON with this top-level shape (keys may be omitted when empty):\n\n```json\n")
    lines.append(
        json.dumps(
            {
                "status": "success | fail | error",
                "message": "string",
                "data": "object | array | string | null - inner payload on success",
                "error_code": "number | omitted - common on fail",
            },
            indent=2,
        )
    )
    lines.append("\n```\n\n")
    lines.append(
        "- **HTTP 200 + `status: fail`:** treated as an error in [`ApiClient`](../lib/app/data/networking/api_client.dart) "
        "(`APIResponse.error`), not success.\n"
    )
    lines.append(
        "- **Success unwrap:** if top-level JSON is a `Map` and `data` is present, Flutter success callbacks receive **`data`**; "
        "if the decoded body is not a map (e.g. raw HTML string), it is returned **as-is**.\n"
    )
    lines.append(
        "- **Reports / print:** `data` may be `{}`, an array, a nested object, or (in some deployments) **non-JSON** text/HTML "
        "- inspect `Content-Type` and body for your environment.\n\n"
    )

    lines.append("---\n\n")

    for num, title, path in ENDPOINTS:
        lines.append(f"## {num}. {title} (`{path}`)\n\n")
        m, where, params = REQUESTS[path]
        lines.append(f"- **HTTP:** `{m}`\n")
        lines.append(f"- **Parameter transport:** {where}\n")
        lines.append("- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)\n\n")
        lines.append("### Request parameters (Flutter / server field names)\n\n")
        lines.append("| Field | Type | Notes |\n|-------|------|-------|\n")
        for name, typ, note in params:
            lines.append(f"| `{name}` | {typ} | {note} |\n")
        lines.append("\n")

        rec = by_path.get(path)
        if not rec:
            lines.append("*No matching capture row.*\n\n---\n\n")
            continue
        if rec.get("skipped"):
            lines.append("### Capture status\n\n")
            lines.append(f"**Skipped:** {rec.get('note', '')}\n\n---\n\n")
            continue

        lines.append("### Observed response — full `raw_body` (exact JSON text returned on wire)\n\n")
        raw = rec.get("raw_body") or ""
        try:
            pretty = json.dumps(json.loads(raw), indent=2, ensure_ascii=False)
        except Exception:
            pretty = raw
        lines.append("```json\n")
        lines.append(pretty)
        lines.append("\n```\n\n")

        pb = rec.get("parsed_body")
        if pb is not None:
            lines.append("### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)\n\n")
            lines.append("```json\n")
            lines.append(json.dumps(shrink(pb), indent=2, ensure_ascii=False))
            lines.append("\n```\n\n")

        if pb and isinstance(pb, dict):
            inner = pb.get("data")
            lines.append("### Inner `data` after unwrap (what `APIResponse.success` receives)\n\n")
            lines.append("```json\n")
            lines.append(json.dumps(shrink(inner), indent=2, ensure_ascii=False))
            lines.append("\n```\n\n")

        lines.append("### Inferred schema notes (from this capture only)\n\n")
        st = pb.get("status") if isinstance(pb, dict) else None
        inner = pb.get("data") if isinstance(pb, dict) else None
        if st == "success" and isinstance(inner, list) and inner and isinstance(inner[0], dict):
            keys = sorted(inner[0].keys())
            lines.append(
                f"- **`data` is a list** of objects with keys (first row): "
                f"{', '.join('`' + k + '`' for k in keys)}.\n"
            )
        elif st == "success" and isinstance(inner, dict) and inner:
            lines.append(
                f"- **`data` is an object** with keys: "
                f"{', '.join('`' + k + '`' for k in sorted(inner.keys()))}.\n"
            )
        elif st == "success" and inner == {}:
            lines.append(
                "- **`data` is an empty object `{}` in this capture.** For list endpoints, retry with a valid Bearer token "
                "and ids from your environment — empty `{}` often means “no rows” or unauthenticated list.\n"
            )
        elif st == "success" and isinstance(inner, list) and not inner:
            lines.append("- **`data` is an empty list `[]`.**\n")
        elif st != "success":
            lines.append("- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.\n")
        lines.append("\n---\n\n")

    lines.append("## Appendix — `createbag` and `bag_id: 0`\n\n")
    lines.append(
        "Section **4. Create Bag** includes the live capture when `OUTBOUND_SKIP_CREATEBAG=0`. **Known server behaviour:** "
        "the test account often receives **`status: success`** with **`bag_id: 0`** — Flutter treats `bag_id <= 0` as failure "
        "until backend fixes validation. Re-capture with `OUTBOUND_BAG_ID` when a real id is known.\n\n"
    )
    lines.append("## Appendix — success shapes not present in this capture file\n\n")
    lines.append("This document reflects **one** capture run. You still need samples from your backend for:\n\n")
    lines.append("- **`createbag` success** with a real new `bag_id`.\n")
    lines.append("- **`getbagdetails` / `getmanifestdetails` / `getlinehauldetails` success** (nested bags, lines, weights).\n")
    lines.append("- **`listbags` / `listmanifests` / `listlinehauls` success** when `data` is a non-empty **array**.\n")
    lines.append("- **`printmanifestdata` success** (JSON vs HTML vs URL string).\n")
    lines.append("- **All POST success** bodies after valid mutations (`OUTBOUND_CAPTURE_MUTATIONS=1`, use on staging only).\n\n")

    OUT.write_text("".join(lines))
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
