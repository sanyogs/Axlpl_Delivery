#!/usr/bin/env python3
"""Build master API table with Request cURL + raw JSON columns from capture file.

  python3 scripts/capture_outbound_v8_responses.py   # refresh capture first
  python3 scripts/generate_outbound_api_table_with_curl.py

Writes:
  docs/outbound_services_v8_master_table.md
  docs/outbound_api_curl_response.json  (machine-readable rows for other tools)
"""

from __future__ import annotations

import json
import re
import sys
import urllib.parse
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[1]
CAP = REPO / "docs" / "outbound_v8_api_capture.json"
SUM = REPO / "docs" / "outbound_v8_api_capture.summary.json"
OUT_MD = REPO / "docs" / "outbound_services_v8_master_table.md"
OUT_JSON = REPO / "docs" / "outbound_api_curl_response.json"

BASE_DEFAULT = "https://my.axlpl.com/messenger/services_v8/"

ENDPOINTS: list[tuple[int, str, str, str]] = [
    (1, "Hub Scan", "hubscan", "A"),
    (2, "Get Hub Scan Logs", "gethubscanlogs", "A"),
    (3, "Get Shipment Scan History", "getshipmentscanhistory", "A"),
    (4, "Create Bag", "createbag", "B"),
    (5, "Add Shipment To Bag", "addshipmenttobag", "B"),
    (6, "Get Bag Details", "getbagdetails", "B"),
    (7, "List Bags", "listbags", "B"),
    (8, "Remove Shipment From Bag", "removeshipmentfrombag", "B"),
    (9, "Lock Bag", "lockbag", "B"),
    (10, "Rebag Shipment", "rebagshipment", "B"),
    (11, "Bagging Report", "baggingreport", "B"),
    (12, "Create Manifest", "createmanifest", "C"),
    (13, "Get Manifest Details", "getmanifestdetails", "C"),
    (14, "List Manifests", "listmanifests", "C"),
    (15, "Manifest Report", "manifestreport", "C"),
    (16, "Print Manifest Data", "printmanifestdata", "C"),
    (17, "Assign Linehaul", "assignlinehaul", "D"),
    (18, "List Linehauls", "listlinehauls", "D"),
    (19, "Get Linehaul Details", "getlinehauldetails", "D"),
    (20, "Update Linehaul Status", "updatelinehaulstatus", "D"),
    (21, "Linehaul Report", "linehaulreport", "D"),
    (22, "Sector Pickup Scan", "sectorpickupscan", "E"),
    (23, "Get Pickup List", "getpickuplist", "E"),
    (24, "Mark Not Picked", "marknotpicked", "E"),
    (25, "Add Missed Shipment", "addmissedshipment", "E"),
    (26, "Pickup Report", "pickupreport", "E"),
]

MODULE_TITLES = {
    "A": "Module A — Hub scan (3 APIs)",
    "B": "Module B — Bagging (8 APIs)",
    "C": "Module C — Manifest (5 APIs)",
    "D": "Module D — Linehaul (5 APIs)",
    "E": "Module E — Sector pickup (5 APIs)",
}

REQUEST_FIELDS: dict[str, str] = {
    "hubscan": "`docket_no`, `branch_id`, `user_id`, `status`",
    "gethubscanlogs": "Query: `branch_id`, `limit`",
    "getshipmentscanhistory": "Query: `docket_no`",
    "createbag": "`origin_branch_id`, `destination_branch_id`, `bag_code`, `user_id`",
    "addshipmenttobag": "`bag_id`, `docket_no`, `branch_id`, `user_id`",
    "getbagdetails": "Query: `bag_id`",
    "listbags": "Query: `branch_id`",
    "removeshipmentfrombag": "`bag_id`, `docket_no`, `branch_id`, `user_id`",
    "lockbag": "`bag_id`",
    "rebagshipment": "`new_bag_id`, `docket_no`, `user_id`",
    "baggingreport": "Query: `start_date`, `end_date`",
    "createmanifest": "`bag_ids`, branches, `user_id`",
    "getmanifestdetails": "Query: `manifest_id`",
    "listmanifests": "Query: `branch_id`",
    "manifestreport": "Query: dates",
    "printmanifestdata": "Query: `manifest_id`",
    "assignlinehaul": "`manifest_ids`, `vehicle_no`, `driver_name`, `user_id`",
    "listlinehauls": "Query: `status`",
    "getlinehauldetails": "Query: `linehaul_id`",
    "updatelinehaulstatus": "`linehaul_id`, `status`, `user_id`, `branch_id`",
    "linehaulreport": "Query: dates",
    "sectorpickupscan": "`pickup_id`, `docket_no`, `status`, `remarks`, ids",
    "getpickuplist": "`platform` only",
    "marknotpicked": "`pickup_id`, `docket_no`, `remarks`, ids",
    "addmissedshipment": "`pickup_id`, `docket_no`, `remarks`",
    "pickupreport": "Query: dates",
}

APIS_MD = REPO / "docs" / "outbound_services_v8_apis.md"
PLAN_MD = Path.home() / ".cursor" / "plans" / "outbound_api_doc_and_gaps_0821766e.plan.md"

# Fallback POST bodies when capture skipped (matches capture script defaults + meta ids).
FALLBACK_POST_FORM: dict[str, dict[str, str]] = {
    "createbag": {
        "origin_branch_id": "{branch_id}",
        "destination_branch_id": "5",
        "bag_code": "BAG_CODE_EXAMPLE",
        "user_id": "{user_id}",
        "platform": "android",
    },
}


def _escape_cell_html(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def _wrap_pre(text: str) -> str:
    return (
        '<pre style="white-space:pre-wrap;word-break:break-all;font-size:11px;margin:0">'
        f"{_escape_cell_html(text)}</pre>"
    )


def _rate_working_fine(summary_row: dict[str, Any]) -> str:
    if summary_row.get("skipped"):
        return "No"
    if summary_row.get("http_status") != 200:
        return "No"
    api = (summary_row.get("api_status") or "").lower()
    if api == "success":
        kind = summary_row.get("data_kind")
        if kind == "list":
            return "Yes" if (summary_row.get("data_length") or 0) > 0 else "Partial"
        if kind == "map":
            keys = summary_row.get("data_keys") or []
            return "Yes" if keys else "Partial"
        return "Yes"
    if api in ("fail", "error"):
        return "Partial"
    return "No"


def _build_curl(
    rec: dict[str, Any] | None,
    path: str,
    meta: dict[str, Any],
    token_var: str = "$OUTBOUND_BEARER_TOKEN",
) -> str:
    ids = meta.get("ids_used") or {}
    branch_id = str(ids.get("branch_id", "27"))
    user_id = str(ids.get("user_id", "148"))

    if rec and not rec.get("skipped") and rec.get("url"):
        method = (rec.get("method") or "GET").upper()
        url = str(rec["url"])
        lines = [
            f"curl -sS -X {method} '{url}' \\",
            f"  -H 'Authorization: Bearer {token_var}' \\",
            "  -H 'X-App-Version: 99.99.99' \\",
            "  -H 'X-App-Platform: android' \\",
            "  -H 'accept: */*'",
        ]
        form = rec.get("form")
        if method == "POST" and isinstance(form, dict) and form:
            body = dict(form)
            body.setdefault("platform", "android")
            encoded = urllib.parse.urlencode(body, doseq=True)
            lines[-1] = lines[-1] + " \\"
            lines.append("  -H 'Content-Type: application/x-www-form-urlencoded' \\")
            lines.append(f"  --data '{encoded}'")
        return "\n".join(lines)

    # Skipped or missing — synthesize from path + meta (PDF-style example request).
    base = str(meta.get("base") or BASE_DEFAULT).rstrip("/") + "/"
    platform = "android"
    if path in FALLBACK_POST_FORM:
        form = {
            k: v.replace("{branch_id}", branch_id).replace("{user_id}", user_id)
            for k, v in FALLBACK_POST_FORM[path].items()
        }
        url = f"{base}{path}?platform={platform}"
        encoded = urllib.parse.urlencode(form, doseq=True)
        return (
            f"curl -sS -X POST '{url}' \\\n"
            f"  -H 'Authorization: Bearer {token_var}' \\\n"
            "  -H 'X-App-Version: 99.99.99' \\\n"
            "  -H 'X-App-Platform: android' \\\n"
            "  -H 'accept: */*' \\\n"
            "  -H 'Content-Type: application/x-www-form-urlencoded' \\\n"
            f"  --data '{encoded}'"
        )

    # Generic GET example from meta ids
    q = {"platform": platform}
    if path == "gethubscanlogs":
        q.update({"branch_id": branch_id, "limit": "50"})
    elif path == "getshipmentscanhistory":
        q["docket_no"] = str(ids.get("docket_no", ""))
    elif path == "getbagdetails":
        q["bag_id"] = str(ids.get("bag_id", ""))
    elif path == "listbags":
        q["branch_id"] = branch_id
    elif path == "getmanifestdetails":
        q["manifest_id"] = str(ids.get("manifest_id", ""))
    elif path == "listmanifests":
        q["branch_id"] = branch_id
    elif path == "printmanifestdata":
        q["manifest_id"] = str(ids.get("manifest_id", ""))
    elif path == "listlinehauls":
        q["status"] = "In Transit"
    elif path == "getlinehauldetails":
        q["linehaul_id"] = str(ids.get("linehaul_id", ""))
    elif path in ("baggingreport", "manifestreport", "linehaulreport", "pickupreport"):
        q["start_date"] = "2026-04-01"
        q["end_date"] = "2026-05-14"
    url = f"{base}{path}?" + urllib.parse.urlencode(q)
    return (
        f"curl -sS -X GET '{url}' \\\n"
        f"  -H 'Authorization: Bearer {token_var}' \\\n"
        "  -H 'X-App-Version: 99.99.99' \\\n"
        "  -H 'X-App-Platform: android' \\\n"
        "  -H 'accept: */*'"
    )


def _raw_json(rec: dict[str, Any] | None) -> str:
    if not rec:
        return "(no capture row)"
    if rec.get("skipped"):
        return f"(skipped) {rec.get('note', '')}"
    raw = rec.get("raw_body")
    if raw is None:
        if rec.get("network_error"):
            return f"(network error) {rec.get('network_error')}"
        return "(empty body)"
    # Keep compact single-line JSON exactly as on the wire (no indent).
    if isinstance(raw, str):
        return raw.replace("\n", "").replace("\r", "")
    return json.dumps(raw, ensure_ascii=False, separators=(",", ":"))


def main() -> None:
    cap = json.loads(CAP.read_text(encoding="utf-8"))
    summary = json.loads(SUM.read_text(encoding="utf-8"))
    meta = cap.get("meta") or {}
    by_path: dict[str, dict[str, Any]] = {}
    for r in cap.get("results") or []:
        p = r.get("path")
        if p:
            by_path[str(p)] = r

    summary_by_name: dict[str, dict[str, Any]] = {}
    for srow in summary.get("rows") or []:
        summary_by_name[str(srow.get("capture_name", ""))] = srow

    rows_out: list[dict[str, Any]] = []
    for num, name, path, mod in ENDPOINTS:
        rec = by_path.get(path)
        cap_prefix = f"{num:02d}_"
        srow = None
        for sk, sv in summary_by_name.items():
            if sk.startswith(cap_prefix) and path in sk:
                srow = sv
                break
        if not srow:
            for sk, sv in summary_by_name.items():
                if path in sk:
                    srow = sv
                    break
        if not srow and rec:
            srow = {
                "http_status": rec.get("http_status"),
                "skipped": rec.get("skipped", False),
                "api_status": (rec.get("parsed_body") or {}).get("status")
                if isinstance(rec.get("parsed_body"), dict)
                else None,
            }

        working = _rate_working_fine(srow or {}) if srow else "No"
        if meta.get("working_fine_by_path") and path in meta["working_fine_by_path"]:
            working = meta["working_fine_by_path"][path]

        curl = _build_curl(rec, path, meta)
        raw = _raw_json(rec)
        method = (rec or {}).get("method") or (
            "POST" if path in FALLBACK_POST_FORM else "GET"
        )

        rows_out.append(
            {
                "num": num,
                "name": name,
                "method": method,
                "path": path,
                "module": mod,
                "implemented": "Yes",
                "working_fine": working,
                "request_curl": curl,
                "raw_json_response": raw,
                "capture_name": (rec or {}).get("capture_name"),
                "http_status": (rec or {}).get("http_status"),
            }
        )

    OUT_JSON.write_text(
        json.dumps(
            {"meta": meta, "generated_from": str(CAP), "rows": rows_out},
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    lines: list[str] = []
    lines.append("# Outbound APIs — master table (cURL + raw JSON)\n\n")
    lines.append(
        "Generated by [`scripts/generate_outbound_api_table_with_curl.py`](../scripts/generate_outbound_api_table_with_curl.py) "
        f"from [`outbound_v8_api_capture.json`](outbound_v8_api_capture.json).\n\n"
    )
    lines.append("## Column legend\n\n")
    lines.append("| Column | Meaning |\n|--------|---------|\n")
    lines.append("| **Implemented** | Flutter: endpoint constant, `ApiServices`, `OutboundRepository`, UI. |\n")
    lines.append(
        "| **Working fine** | **Yes** = capture `status: success` with expected `data`. "
        "**Partial** = valid JSON but fail/empty/404 in test run. **No** = skipped or not verified. |\n"
    )
    lines.append(
        "| **Request cURL** | Copy-paste example; replace `$OUTBOUND_BEARER_TOKEN`. "
        "Matches capture URL/body when a call was recorded. |\n"
    )
    lines.append(
        "| **Raw JSON response** | Exact `raw_body` string from capture (single line, not pretty-printed). |\n\n"
    )
    lines.append(
        f"Capture meta: bearer={meta.get('had_bearer_token')}, "
        f"token_source={meta.get('token_source', 'n/a')}, "
        f"mutation_mode={meta.get('mutation_capture_mode')}, "
        f"valid_posts={meta.get('valid_posts', 'n/a')}.\n\n"
    )

    current_mod = ""
    for i, row in enumerate(rows_out):
        if row["module"] != current_mod:
            if current_mod:
                lines.append("</tbody></table>\n\n")
            current_mod = row["module"]
            lines.append(f"## {MODULE_TITLES[current_mod]}\n\n")
            lines.append(
                '<table>\n<thead><tr>'
                "<th>#</th><th>Name</th><th>Method</th><th>Path</th>"
                "<th>Implemented</th><th>Working fine</th>"
                "<th>Request cURL</th><th>Raw JSON response</th>"
                "</tr></thead>\n<tbody>\n"
            )
        lines.append("<tr>")
        lines.append(f"<td>{row['num']}</td>")
        lines.append(f"<td>{_escape_cell_html(row['name'])}</td>")
        lines.append(f"<td>{row['method']}</td>")
        lines.append(f"<td><code>{row['path']}</code></td>")
        lines.append(f"<td>{row['implemented']}</td>")
        lines.append(f"<td>{row['working_fine']}</td>")
        lines.append(f"<td>{_wrap_pre(row['request_curl'])}</td>")
        lines.append(f"<td>{_wrap_pre(row['raw_json_response'])}</td>")
        lines.append("</tr>\n")
    if rows_out:
        lines.append("</tbody></table>\n\n")

    lines.append("## Per-endpoint blocks (same data, markdown-friendly)\n\n")
    for row in rows_out:
        anchor = f"api-{row['num']:02d}-{row['path']}"
        lines.append(f'<a id="{anchor}"></a>\n')
        lines.append(f"### {row['num']}. {row['name']} (`{row['path']}`)\n\n")
        lines.append(
            f"**Implemented:** {row['implemented']} · **Working fine:** {row['working_fine']} · "
            f"**HTTP:** {row.get('http_status', 'n/a')}\n\n"
        )
        lines.append("**Request cURL:**\n\n```bash\n")
        lines.append(row["request_curl"])
        lines.append("\n```\n\n**Raw JSON response (not formatted):**\n\n```json\n")
        lines.append(row["raw_json_response"])
        lines.append("\n```\n\n---\n\n")

    OUT_MD.write_text("".join(lines), encoding="utf-8")
    print(f"Wrote {OUT_MD} ({OUT_MD.stat().st_size} bytes)")
    print(f"Wrote {OUT_JSON}")

    _patch_apis_quick_summary(rows_out)
    _patch_module_sections_in_markdown(APIS_MD, rows_out, heading_prefix="## ")
    if PLAN_MD.is_file():
        try:
            _patch_plan_master_and_summary(rows_out, summary_by_name, meta)
            _patch_module_sections_in_markdown(PLAN_MD, rows_out, heading_prefix="### ")
            print(f"Patched module tables in {PLAN_MD}")
        except OSError as e:
            print(f"Warning: could not patch plan file {PLAN_MD}: {e}", file=sys.stderr)
    print(f"Patched module tables in {APIS_MD}")


def _summary_note(path: str, summary_by_name: dict[str, Any]) -> str:
    srow: dict[str, Any] | None = None
    for sk, sv in summary_by_name.items():
        if path in sk:
            srow = sv
            break
    if not srow:
        return ""
    st = srow.get("api_status") or "n/a"
    msg = (srow.get("message") or "").replace("|", "/")[:80]
    if srow.get("data_kind") == "list" and srow.get("data_length") is not None:
        return f"`{st}` — {msg} ({srow['data_length']} rows)"
    if srow.get("error_code"):
        return f"`{st}` {srow['error_code']} — {msg}"
    return f"`{st}` — {msg}"


def _patch_apis_quick_summary(rows_out: list[dict[str, Any]]) -> None:
    if not APIS_MD.is_file():
        return
    text = APIS_MD.read_text(encoding="utf-8")
    body = "\n".join(
        f"| {r['num']} | `{r['path']}` | Yes | "
        + (f"**{r['working_fine']}**" if r["working_fine"] == "Yes" else r["working_fine"])
        + " |"
        for r in rows_out
    )
    block = (
        "| # | Path | Implemented | Working fine |\n"
        "|---|------|:-----------:|:------------:|\n"
        f"{body}\n"
    )
    pattern = re.compile(
        r"\| # \| Path \| Implemented \| Working fine \|\n\|[-:| ]+\|\n.*?(?=\n---)",
        re.DOTALL,
    )
    if pattern.search(text):
        text = pattern.sub(block.rstrip() + "\n", text, count=1)
        APIS_MD.write_text(text, encoding="utf-8")


def _patch_plan_master_and_summary(
    rows_out: list[dict[str, Any]],
    summary_by_name: dict[str, Any],
    meta: dict[str, Any],
) -> None:
    if not PLAN_MD.is_file():
        return
    text = PLAN_MD.read_text(encoding="utf-8")
    yes = sum(1 for r in rows_out if r["working_fine"] == "Yes")
    partial = sum(1 for r in rows_out if r["working_fine"] == "Partial")
    no = sum(1 for r in rows_out if r["working_fine"] == "No")
    summary_line = (
        f"**Summary:** Implemented **26/26**. Working fine **Yes: {yes}**, "
        f"**Partial: {partial}**"
        + (f", **No: {no}**" if no else "")
        + "."
    )
    text = re.sub(
        r"\*\*Summary:\*\* Implemented \*\*26/26\*\*\. Working fine \*\*Yes: \d+\*\*.*",
        summary_line,
        text,
        count=1,
    )
    token_src = meta.get("token_source", "n/a")
    login_ok = meta.get("login_succeeded", meta.get("had_bearer_token"))
    capture_blurb = (
        f"**Capture source:** authenticated capture (`token_source={token_src}`, "
        f"login_ok={login_ok}, `OUTBOUND_VALID_POSTS=1`). "
        f"Re-run: `OUTBOUND_LOGIN_*` or `OUTBOUND_BEARER_TOKEN`, then capture + generate scripts."
    )
    text = re.sub(
        r"\*\*Capture source:\*\*.*?\n\n### Master table",
        capture_blurb + "\n\n### Master table",
        text,
        count=1,
        flags=re.DOTALL,
    )
    by_path = {r["path"]: r for r in rows_out}
    table_lines = [
        "| # | Name | Method | Path | Implemented | Working fine | Capture note |",
        "|---|------|--------|------|:-----------:|:------------:|--------------|",
    ]
    for num, name, path, _mod in ENDPOINTS:
        r = by_path.get(path, {})
        wf = r.get("working_fine", "No")
        wf_cell = f"**{wf}**" if wf == "Yes" else wf
        note = _summary_note(path, summary_by_name)
        method = r.get("method") or ("POST" if path in FALLBACK_POST_FORM else "GET")
        table_lines.append(
            f"| {num} | {name} | {method} | `{path}` | Yes | {wf_cell} | {note} |"
        )
    block = "\n".join(table_lines) + "\n"
    pattern = re.compile(
        r"### Master table \(all 26\)\n\n\| # \| Name \|.*?(?=\n\*\*Summary:\*\*)",
        re.DOTALL,
    )
    if pattern.search(text):
        text = pattern.sub("### Master table (all 26)\n\n" + block, text, count=1)
    try:
        PLAN_MD.write_text(text, encoding="utf-8")
    except OSError as e:
        print(f"Warning: could not patch plan file {PLAN_MD}: {e}", file=sys.stderr)


def _build_module_html_block(
    rows: list[dict[str, Any]],
    title: str,
    *,
    heading_prefix: str = "## ",
) -> str:
    out: list[str] = [f"{heading_prefix}{title}\n\n"]
    out.append(
        '<table>\n<thead><tr>'
        "<th>#</th><th>Name</th><th>Method</th><th>Path</th>"
        "<th>Request</th><th>Implemented</th><th>Working fine</th>"
        "<th>Request cURL</th><th>Raw JSON response</th>"
        "</tr></thead>\n<tbody>\n"
    )
    for row in rows:
        req = REQUEST_FIELDS.get(row["path"], "")
        out.append("<tr>")
        out.append(f"<td>{row['num']}</td>")
        out.append(f"<td>{_escape_cell_html(row['name'])}</td>")
        out.append(f"<td>{row['method']}</td>")
        out.append(f"<td><code>{row['path']}</code></td>")
        out.append(f"<td>{_escape_cell_html(req)}</td>")
        out.append(f"<td>{row['implemented']}</td>")
        out.append(f"<td>{row['working_fine']}</td>")
        out.append(f"<td>{_wrap_pre(row['request_curl'])}</td>")
        out.append(f"<td>{_wrap_pre(row['raw_json_response'])}</td>")
        out.append("</tr>\n")
    out.append("</tbody></table>\n\n")
    return "".join(out)


def _patch_module_sections_in_markdown(
    path: Path,
    rows_out: list[dict[str, Any]],
    *,
    heading_prefix: str = "## ",
) -> None:
    text = path.read_text(encoding="utf-8")
    by_mod: dict[str, list[dict[str, Any]]] = {}
    for row in rows_out:
        by_mod.setdefault(row["module"], []).append(row)

    for mod, title in MODULE_TITLES.items():
        block = _build_module_html_block(by_mod.get(mod, []), title, heading_prefix=heading_prefix)
        if heading_prefix == "## ":
            stop = (
                r"(?=\n\n\*\*Full URLs|\n\n---\n\n## Module |\n\n---\n\n## Response envelope|\Z)"
            )
        else:
            stop = r"(?=\n### Module |\n\*\*Cross-cutting|\Z)"
        pattern = re.compile(
            rf"{re.escape(heading_prefix)}{re.escape(title)}\n\n.*?"
            + stop,
            re.DOTALL,
        )
        if not pattern.search(text):
            continue
        text = pattern.sub(block, text, count=1)

    try:
        path.write_text(text, encoding="utf-8")
    except OSError as e:
        raise OSError(f"could not write {path}: {e}") from e


if __name__ == "__main__":
    main()
