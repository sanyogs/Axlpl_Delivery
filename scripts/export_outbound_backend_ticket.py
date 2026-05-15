#!/usr/bin/env python3
"""Export backend gap checklist from docs/outbound_services_v8_apis.md for email/Jira."""

from __future__ import annotations

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
APIS = REPO / "docs" / "outbound_services_v8_apis.md"
OUT = REPO / "docs" / "outbound_backend_gap_ticket.md"
CAP_SUM = REPO / "docs" / "outbound_v8_api_capture.summary.json"


def main() -> int:
    text = APIS.read_text(encoding="utf-8")
    m = re.search(
        r"(## Backend clarification checklist.*?\n)(---\n\n## Flutter)",
        text,
        re.DOTALL,
    )
    if not m:
        raise SystemExit("Could not find backend checklist section in apis.md")
    body = m.group(1).strip()
    summary = ""
    if CAP_SUM.is_file():
        import json

        meta = json.loads(CAP_SUM.read_text(encoding="utf-8")).get("meta") or {}
        wf = meta.get("working_fine_by_path") or {}
        yes = sum(1 for v in wf.values() if v == "Yes")
        partial = sum(1 for v in wf.values() if v == "Partial")
        summary = (
            f"\n\n---\n\n## Latest capture ({meta.get('default_branch_id_used', 'n/a')})\n\n"
            f"- Bearer: {meta.get('had_bearer_token')} (`{meta.get('token_source')}`)\n"
            f"- Working fine: **Yes {yes}**, **Partial {partial}**\n"
            f"- `createbag` / lists: see capture — `valid_bag_id_available="
            f"{meta.get('valid_bag_id_available')}`\n"
        )
    out = (
        "# Outbound Services V8 — backend questions (AXLPL Messenger)\n\n"
        "Copy this into your ticket or email. Canonical spec: "
        "`docs/outbound_services_v8_apis.md`.\n\n"
        + body
        + summary
        + "\n"
    )
    OUT.write_text(out, encoding="utf-8")
    print(f"Wrote {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
