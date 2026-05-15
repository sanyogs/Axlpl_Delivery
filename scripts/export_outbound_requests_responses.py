#!/usr/bin/env python3
"""Export request + JSON response per outbound API from capture.

Writes:
  docs/outbound_v8_api_all_requests_responses.json  — all calls (compact)
  docs/outbound_v8_api_failures_only.json           — status=fail or skipped notes
  docs/outbound_v8_api_failures_reference.md        — human-readable failure catalog

Run after:
  python3 scripts/capture_outbound_v8_responses.py
"""

from __future__ import annotations

import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CAP = REPO / "docs" / "outbound_v8_api_capture.json"
OUT_ALL = REPO / "docs" / "outbound_v8_api_all_requests_responses.json"
OUT_FAIL_JSON = REPO / "docs" / "outbound_v8_api_failures_only.json"
OUT_FAIL_MD = REPO / "docs" / "outbound_v8_api_failures_reference.md"

ORDER = [
    "hubscan",
    "gethubscanlogs",
    "getshipmentscanhistory",
    "createbag",
    "addshipmenttobag",
    "getbagdetails",
    "removeshipmentfrombag",
    "lockbag",
    "rebagshipment",
    "listbags",
    "baggingreport",
    "createmanifest",
    "getmanifestdetails",
    "listmanifests",
    "manifestreport",
    "printmanifestdata",
    "assignlinehaul",
    "listlinehauls",
    "getlinehauldetails",
    "updatelinehaulstatus",
    "linehaulreport",
    "getpickuplist",
    "sectorpickupscan",
    "marknotpicked",
    "addmissedshipment",
    "pickupreport",
]


def _compact_entry(r: dict) -> dict:
    parsed = r.get("parsed_body")
    api_status = None
    message = None
    error_code = None
    if isinstance(parsed, dict):
        api_status = parsed.get("status")
        message = parsed.get("message")
        error_code = parsed.get("error_code")

    return {
        "capture_name": r.get("capture_name"),
        "path": r.get("path"),
        "method": r.get("method"),
        "url": r.get("url"),
        "skipped": bool(r.get("skipped")),
        "http_status": r.get("http_status"),
        "api_status": api_status,
        "message": message,
        "error_code": error_code,
        "request": {
            "query": r.get("query"),
            "form": r.get("form"),
        },
        "response_json": parsed if parsed is not None else r.get("raw_body"),
        "raw_body": r.get("raw_body") if parsed is None else None,
        "note": r.get("note"),
    }


def _is_failure(entry: dict) -> bool:
    if entry.get("skipped"):
        return True
    if entry.get("http_status") != 200:
        return True
    st = (entry.get("api_status") or "").lower()
    return st == "fail"


def _json_line(obj) -> str:
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def main() -> None:
    cap = json.loads(CAP.read_text(encoding="utf-8"))
    meta = cap.get("meta") or {}
    by_path: dict[str, dict] = {}
    for r in cap.get("results") or []:
        p = r.get("path") or r.get("capture_name") or ""
        by_path[str(p)] = r

    entries: list[dict] = []
    for path in ORDER:
        r = by_path.get(path)
        if not r and path == "createbag":
            r = next(
                (x for x in (cap.get("results") or []) if x.get("path") == "createbag"),
                None,
            )
        if not r:
            continue
        entries.append(_compact_entry(r))

  # any extra paths not in ORDER
    seen = {e["path"] for e in entries}
    for r in cap.get("results") or []:
        p = r.get("path")
        if p and p not in seen:
            entries.append(_compact_entry(r))

    all_doc = {
        "meta": meta,
        "generated_from": str(CAP),
        "count": len(entries),
        "failures_count": sum(1 for e in entries if _is_failure(e)),
        "entries": entries,
    }
    OUT_ALL.write_text(
        json.dumps(all_doc, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    failures = [e for e in entries if _is_failure(e)]
    fail_doc = {
        "meta": meta,
        "generated_from": str(CAP),
        "count": len(failures),
        "entries": failures,
    }
    OUT_FAIL_JSON.write_text(
        json.dumps(fail_doc, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    lines = [
        "# Outbound V8 — failures & errors (request + JSON response)\n",
        "\n",
        f"Source: `{CAP.name}`  \n",
        f"**IDs used:** `{_json_line(meta.get('ids_used') or {})}`  \n",
        f"**Failures:** {len(failures)} / {len(entries)} calls  \n",
        "\n",
        "Success responses are in "
        f"[`outbound_v8_api_all_requests_responses.json`](outbound_v8_api_all_requests_responses.json).\n",
        "\n---\n",
    ]
    for i, e in enumerate(failures, 1):
        lines.append(f"\n## {i}. `{e.get('path')}` — {e.get('message') or e.get('note') or 'n/a'}\n\n")
        lines.append(f"- **HTTP:** {e.get('http_status')}  \n")
        lines.append(f"- **API status:** {e.get('api_status')}  \n")
        lines.append(f"- **error_code:** {e.get('error_code')}  \n")
        if e.get("skipped"):
            lines.append(f"- **Skipped:** {e.get('note')}\n")
        lines.append("\n**Request**\n\n")
        lines.append("```json\n")
        lines.append(json.dumps(e.get("request"), indent=2, ensure_ascii=False))
        lines.append("\n```\n\n")
        lines.append("**Response JSON**\n\n")
        lines.append("```json\n")
        resp = e.get("response_json")
        if isinstance(resp, (dict, list)):
            lines.append(json.dumps(resp, indent=2, ensure_ascii=False))
        else:
            lines.append(str(resp or ""))
        lines.append("\n```\n")

    OUT_FAIL_MD.write_text("".join(lines), encoding="utf-8")
    print(f"Wrote {OUT_ALL} ({len(entries)} entries, {len(failures)} failures)")
    print(f"Wrote {OUT_FAIL_JSON}")
    print(f"Wrote {OUT_FAIL_MD}")


if __name__ == "__main__":
    main()
