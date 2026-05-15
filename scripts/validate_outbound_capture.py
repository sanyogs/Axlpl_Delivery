#!/usr/bin/env python3
"""Validate outbound capture + doc artifacts (26 APIs, no skipped HTTP unless documented)."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CAP = REPO / "docs" / "outbound_v8_api_capture.json"
SUM = REPO / "docs" / "outbound_v8_api_capture.summary.json"
APIS = REPO / "docs" / "outbound_services_v8_apis.md"
MASTER = REPO / "docs" / "outbound_services_v8_master_table.md"
REF = REPO / "docs" / "outbound_services_v8_api_responses_reference.md"
CURL_JSON = REPO / "docs" / "outbound_api_curl_response.json"

EXPECTED_PATHS = {
    "hubscan",
    "gethubscanlogs",
    "getshipmentscanhistory",
    "createbag",
    "addshipmenttobag",
    "getbagdetails",
    "listbags",
    "removeshipmentfrombag",
    "lockbag",
    "rebagshipment",
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
    "sectorpickupscan",
    "getpickuplist",
    "marknotpicked",
    "addmissedshipment",
    "pickupreport",
}


def main() -> int:
    errors: list[str] = []
    for p in (CAP, SUM, APIS, MASTER, REF, CURL_JSON):
        if not p.is_file():
            errors.append(f"Missing file: {p.relative_to(REPO)}")

    if CAP.is_file():
        data = json.loads(CAP.read_text(encoding="utf-8"))
        results = data.get("results") or []
        paths = {r.get("path") for r in results if r.get("path")}
        missing = EXPECTED_PATHS - paths
        extra = paths - EXPECTED_PATHS
        if missing:
            errors.append(f"Capture missing paths: {sorted(missing)}")
        if extra:
            errors.append(f"Capture unexpected paths: {sorted(extra)}")
        if len(results) != 26:
            errors.append(f"Expected 26 capture rows, got {len(results)}")
        skipped = [r for r in results if r.get("skipped")]
        if skipped:
            names = [r.get("capture_name") for r in skipped]
            errors.append(f"Skipped capture entries: {names}")
        meta = data.get("meta") or {}
        wf = meta.get("working_fine_by_path") or {}
        yes = sum(1 for v in wf.values() if v == "Yes")
        partial = sum(1 for v in wf.values() if v == "Partial")
        no = sum(1 for v in wf.values() if v == "No")
        print(
            f"Capture OK: {len(results)} calls, "
            f"Working fine Yes={yes} Partial={partial} No={no}, "
            f"bearer={meta.get('had_bearer_token')}, branch={meta.get('default_branch_id_used')}"
        )

    if APIS.is_file():
        apis_text = APIS.read_text(encoding="utf-8")
        if apis_text.count("<table>") < 5:
            errors.append(
                f"apis.md expected >=5 module HTML tables, found {apis_text.count('<table>')}"
            )
        if "Project completion checklist" not in apis_text:
            errors.append("apis.md missing Project completion checklist section")

    if REF.is_file():
        ref_text = REF.read_text(encoding="utf-8")
        api_sections = len(re.findall(r"^## \d+\. ", ref_text, re.MULTILINE))
        if api_sections != 26:
            errors.append(f"reference.md expected 26 API sections, found {api_sections}")

    if CURL_JSON.is_file():
        rows = json.loads(CURL_JSON.read_text(encoding="utf-8")).get("rows") or []
        if len(rows) != 26:
            errors.append(f"outbound_api_curl_response.json expected 26 rows, got {len(rows)}")
        for row in rows:
            if not row.get("request_curl") or not row.get("raw_json_response"):
                errors.append(
                    f"curl JSON row {row.get('num')} missing request_curl or raw_json_response"
                )
                break

    if SUM.is_file() and CAP.is_file():
        cap_meta = json.loads(CAP.read_text(encoding="utf-8")).get("meta") or {}
        sum_meta = json.loads(SUM.read_text(encoding="utf-8")).get("meta") or {}
        if cap_meta.get("working_fine_by_path") != sum_meta.get("working_fine_by_path"):
            errors.append("capture.json and summary.json working_fine_by_path mismatch")

    if errors:
        for e in errors:
            print(f"ERROR: {e}", file=sys.stderr)
        return 1
    print("validate_outbound_capture: all checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
