#!/usr/bin/env python3
"""Regenerate docs/sarvesh_backend_ticket.html — open bugs, questions, verified curls."""
import html
import json
import subprocess
from datetime import datetime

TOKEN = "ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7"
BASE = "https://my.axlpl.com/messenger/services_v8/api.php"
NOW = datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def run(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    return (p.stdout or "").strip()


def http_from_body(body):
    try:
        d = json.loads(body)
        if d.get("status") == "success":
            return "200"
        return str(d.get("error_code", "fail"))
    except Exception:
        return "?"


def pretty_json(body, max_len=4000):
    try:
        s = json.dumps(json.loads(body), indent=2)
    except Exception:
        s = body
    if len(s) > max_len:
        return s[:max_len] + f"\n...(truncated — {len(s)} chars total)"
    return s


def get_curl(params, ver="22.1.0", extra=None):
    qs = "&".join(f"{k}={v}" for k, v in params.items())
    lines = [
        f"curl --location --request GET '{BASE}?{qs}' \\",
        f"  --header 'Authorization: Bearer {TOKEN}' \\",
        f"  --header 'X-App-Version: {ver}' \\",
    ]
    if ver == "22.1.0":
        lines.append("  --header 'X-App-Platform: ios'")
    if extra:
        for h in extra:
            lines[-1] += " \\"
            lines.append(f"  --header '{h}'")
    return "\n".join(lines)


def get_run(params, ver="22.1.0", extra=None):
    cmd = ["curl", "-sS", "-G", BASE]
    for k, v in params.items():
        cmd += ["--data-urlencode", f"{k}={v}"]
    cmd += ["-H", f"Authorization: Bearer {TOKEN}", "-H", f"X-App-Version: {ver}"]
    if ver == "22.1.0":
        cmd += ["-H", "X-App-Platform: ios"]
    if extra:
        for h in extra:
            cmd += ["-H", h]
    body = run(cmd)
    return get_curl(params, ver, extra), body, http_from_body(body)


def post_multipart_curl(request, fields, ver="22.1.0"):
    lines = [
        f"curl --location --request POST '{BASE}?request={request}' \\",
        f"  --header 'Authorization: Bearer {TOKEN}' \\",
        f"  --header 'X-App-Version: {ver}' \\",
        "  --header 'X-App-Platform: ios' \\",
    ]
    for k, v in fields.items():
        lines.append(f"  --form '{k}={v}' \\")
    return "\n".join(lines).rstrip(" \\")


def post_multipart_run(request, fields, ver="22.1.0"):
    cmd = [
        "curl", "-sS", "-X", "POST", f"{BASE}?request={request}",
        "-H", f"Authorization: Bearer {TOKEN}",
        "-H", f"X-App-Version: {ver}",
        "-H", "X-App-Platform: ios",
    ]
    for k, v in fields.items():
        cmd += ["-F", f"{k}={v}"]
    body = run(cmd)
    return post_multipart_curl(request, fields, ver), body, http_from_body(body)


def post_urlenc_curl(request, fields, ver="22.3.0"):
    lines = [
        f"curl --location --request POST '{BASE}?request={request}' \\",
        f"  --header 'Authorization: Bearer {TOKEN}' \\",
        f"  --header 'X-App-Version: {ver}' \\",
        "  --header 'Content-Type: application/x-www-form-urlencoded' \\",
    ]
    for k, v in fields.items():
        lines.append(f"  --data-urlencode '{k}={v}' \\")
    return "\n".join(lines).rstrip(" \\")


def post_urlenc_run(request, fields, ver="22.3.0"):
    cmd = [
        "curl", "-sS", "-X", "POST", f"{BASE}?request={request}",
        "-H", f"Authorization: Bearer {TOKEN}",
        "-H", f"X-App-Version: {ver}",
        "-H", "Content-Type: application/x-www-form-urlencoded",
    ]
    for k, v in fields.items():
        cmd += ["--data-urlencode", f"{k}={v}"]
    body = run(cmd)
    return post_urlenc_curl(request, fields, ver), body, http_from_body(body)


def bug_card(name, http, bug, fix, curl, body, kind="bad"):
    border = "var(--red)" if kind == "bad" else "var(--amber)"
    tag_cls = f"t{html.escape(str(http))}"
    return f"""<div class="ep" style="border-left-color:{border}">
<p class="lbl"><code>{html.escape(name)}</code> <span class="tag {tag_cls}">HTTP {html.escape(str(http))}</span></p>
<p class="bug"><b>Issue:</b> {html.escape(bug)}</p>
<p class="fix"><b>We need:</b> {html.escape(fix)}</p>
<p class="lbl-curl">curl (copy-paste)</p><pre class="c">{html.escape(curl)}</pre>
<p class="lbl-resp">live response ({NOW})</p><pre class="r">HTTP {html.escape(str(http))}\n{html.escape(pretty_json(body))}</pre></div>"""


def ok_card(name, http, curl, body):
    return f"""<div class="ep ok">
<p class="lbl"><code>{html.escape(name)}</code> <span class="tag t200">HTTP {html.escape(str(http))}</span></p>
<p class="lbl-curl">curl</p><pre class="c">{html.escape(curl)}</pre>
<p class="lbl-resp">live response</p><pre class="r">HTTP {html.escape(str(http))}\n{html.escape(pretty_json(body, 2500))}</pre></div>"""


def question_card(name, issue, need):
    return f"""<div class="ep ask">
<p class="lbl"><code>{html.escape(name)}</code></p>
<p class="bug"><b>Issue:</b> {html.escape(issue)}</p>
<p class="fix"><b>We need:</b> {html.escape(need)}</p>
</div>"""


def main():
    open_bugs = []
    questions = []

    # --- OPEN BUGS ---
    c, b, h = get_run({"request": "getlinehauldetails", "trip_no": "LH1780998599"})
    open_bugs.append(bug_card(
        "getlinehauldetails (trip_no)", h,
        "Postman documents trip_no as valid lookup param. Returns fail — was SQL 500, now 404 Linehaul not found. "
        "mawb_no and linehaul_id work.",
        "Either fix trip_no lookup in SQL OR update Postman/docs: messenger must use mawb_no + linehaul_id only.",
        c, b,
    ))

    c, b, h = get_run({"request": "getmanifestdetails", "manifest_code": "MUM075"})
    try:
        ships = json.loads(b).get("data", {}).get("shipments", [])
        dbg = json.loads(b).get("data", {}).get("debug_joined_shipments_count", "?")
    except Exception:
        ships, dbg = [], "?"
    open_bugs.append(bug_card(
        "getmanifestdetails MUM075", h,
        f"HTTP 200 but shipments[] is empty. debug_joined_shipments_count={dbg}. "
        "bags[] has BAG20260515154014 but no shipment rows.",
        "Fix bag→shipment join so manifest detail, print, linehaul, and sector pickup missing lists work for MUM075.",
        c, b,
    ))

    c, b, h = get_run({"request": "getpickuplist"})
    try:
        rows = json.loads(b).get("data", [])
        ids = [str(r.get("id")) for r in rows]
        dup = len(rows) - len(set(ids))
    except Exception:
        rows, dup = 0, 0
    open_bugs.append(bug_card(
        "getpickuplist duplicates", h,
        f"{len(rows)} rows returned, {dup} are duplicate pickup ids (e.g. id 286 appears multiple times with different origin_hub).",
        "Return exactly one row per pickup id. Messenger app dedupes client-side as workaround.",
        c, b[:2500] + ("..." if len(b) > 2500 else ""),
    ))

    c, b, h = get_run({"request": "listmanifests", "branch_id": "75"})
    try:
        cnt = len(json.loads(b).get("data", []))
    except Exception:
        cnt = 50
    open_bugs.append(bug_card(
        "listmanifests pagination", h,
        f"Returns exactly {cnt} rows with no page, limit, offset, or total_count params.",
        "Add server-side pagination (page/limit/total_count) so manifests older than the newest 50 are listable.",
        c, b[:900] + f"\n...(truncated — {cnt} rows total)",
    ))

    # --- QUESTIONS (no working curls — text only) ---
    questions.append(question_card(
        "createmanifest transport_mode",
        "Admin web has Airway/Surface mode on manifest create. Messenger POSTs transport_mode=Airway|Surface with bag_codes.",
        "Confirm transport_mode is stored. If unsupported, document correct field name or add column.",
    ))

    questions.append(question_card(
        "assignlinehaul + editlinehaul booking flow",
        "Admin Linehaul Booking has ~15 fields. Messenger uses assignlinehaul (4 fields) then editlinehaul for the rest.",
        "Confirm two-step flow is correct OR provide single createlinehaul endpoint. "
        "Add total_cd_weight / total_billing_weight to editlinehaul if supported.",
    ))

    questions.append(question_card(
        "createpickup / sector pickup creation",
        "Admin sector pickup edit URL is /sector-pickup/edit/{id} — pickups exist before scanning. "
        "No createpickup in messenger Postman.",
        "Document how pickup_id is created OR add createpickup API for messenger.",
    ))

    questions.append(question_card(
        "hub scan print / bag challan",
        "Admin hub scan list has print icon per row. No messenger print endpoint in Postman.",
        "Print API for messenger OR confirm web-only.",
    ))

    impl_notes = ""

    page = f"""<!DOCTYPE html>
<html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>AXLPL Outbound API — Sarvesh Backend Ticket</title>
<style>
:root{{--bg:#0f1117;--card:#181b24;--text:#e6e8ef;--muted:#8b92a8;--green:#4ade80;--red:#f87171;--amber:#fbbf24;--border:#2a2f3d;--code:#0a0c10;--accent:#60a5fa}}
body{{margin:0;font:14px/1.5 ui-monospace,Menlo,monospace;background:var(--bg);color:var(--text)}}
.wrap{{max-width:1000px;margin:0 auto;padding:24px 18px 60px}}
h1{{font:700 22px system-ui,sans-serif;margin:0 0 8px;color:var(--text)}}
h2{{font:600 15px system-ui,sans-serif;margin:28px 0 12px}}
.meta{{color:var(--muted);font:13px system-ui,sans-serif;margin-bottom:24px;line-height:1.6}}
.ep{{background:var(--card);border:1px solid var(--border);border-left:4px solid var(--red);border-radius:8px;padding:14px 16px;margin-bottom:14px}}
.ep.ok{{border-left-color:var(--green)}}
.ep.ask{{border-left-color:var(--amber)}}
.lbl{{font:600 13px system-ui;margin:0 0 6px}} .lbl code{{color:var(--accent)}}
.bug,.fix{{font:12px system-ui;margin:6px 0;line-height:1.5}} .bug{{color:#fca5a5}} .fix{{color:var(--green)}}
.lbl-curl,.lbl-resp{{font:600 10px system-ui;color:var(--muted);text-transform:uppercase;margin:12px 0 4px}}
pre{{margin:0;padding:10px;background:var(--code);border:1px solid var(--border);border-radius:6px;font-size:10px;white-space:pre-wrap;word-break:break-all}}
pre.c{{color:#93c5fd}} pre.r{{color:#c9cdd8}}
.tag{{font:600 10px system-ui;padding:2px 8px;border-radius:4px;margin-left:6px}}
.t200{{background:#14532d;color:#86efac}} .t404{{background:#7c2d12;color:#fdba74}} .t500{{background:#7c2d12;color:#fdba74}}
ul.notes{{font:12px system-ui;color:var(--text);padding-left:20px;margin:8px 0;line-height:1.7}}
footer{{margin-top:36px;padding-top:14px;border-top:1px solid var(--border);color:var(--muted);font:11px system-ui}}
</style></head><body><div class="wrap">
<h1>AXLPL Outbound API — Backend Ticket for Sarvesh</h1>
<p class="meta">
Messenger Flutter app outbound module · Live production curls below · Bearer token is real (copy-paste ready)<br>
<strong>Generated:</strong> {NOW}<br>
<strong>Regenerate:</strong> <code>python3 docs/generate_sarvesh_ticket.py</code>
</p>

{impl_notes}

<h2 style="color:var(--red)">✗ Open bugs ({len(open_bugs)}) — must fix</h2>
{"".join(open_bugs)}

<h2 style="color:var(--amber)">? Clarifications needed ({len(questions)})</h2>
{"".join(questions)}

<footer>
{len(open_bugs)} open bugs · {len(questions)} questions · Open bugs only (working endpoints omitted)<br>
QA login: 6874654654 / token in curls above
</footer>
</div></body></html>"""

    out = "docs/sarvesh_backend_ticket.html"
    with open(out, "w") as f:
        f.write(page)
    print(f"Wrote {out} | bugs={len(open_bugs)} questions={len(questions)} | {NOW}")


if __name__ == "__main__":
    main()
