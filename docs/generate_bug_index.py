#!/usr/bin/env python3
"""Generate docs/index.html — backend APIs not returning success (live curls)."""
import html
import json
from datetime import datetime, timezone
from pathlib import Path

DOCS = Path(__file__).parent
TOKEN = "ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7"
BASE = "https://my.axlpl.com/messenger/services_v8/api.php"
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

# Failing APIs only — factual: request + actual response. No fix suggestions.
ISSUES = [
    {
        "id": "getlinehauldetails_trip_no",
        "api": "getlinehauldetails",
        "summary": "trip_no lookup — error response",
        "curl": (
            f"curl -sS -G '{BASE}' \\\n"
            f"  --data-urlencode 'request=getlinehauldetails' \\\n"
            f"  --data-urlencode 'trip_no=LH1780998599' \\\n"
            f"  -H 'Authorization: Bearer {TOKEN}' \\\n"
            f"  -H 'X-App-Version: 22.1.0' \\\n"
            f"  -H 'X-App-Platform: ios'"
        ),
        "http": "404",
        "body": '{"status":"fail","message":"Linehaul not found","data":[],"error_code":404}',
    },
    {
        "id": "editlinehaul_lh_trip",
        "api": "editlinehaul",
        "summary": "linehaul_id=LH… trip code — error response",
        "curl": (
            f"curl -sS -X POST '{BASE}?request=editlinehaul' \\\n"
            f"  -H 'Authorization: Bearer {TOKEN}' \\\n"
            f"  -H 'X-App-Version: 22.3.0' \\\n"
            f"  -H 'Content-Type: application/x-www-form-urlencoded' \\\n"
            f"  --data-urlencode 'linehaul_id=LH1781776755' \\\n"
            f"  --data-urlencode 'vehicle_no=MH01AB1234' \\\n"
            f"  --data-urlencode 'driver_name=Test'"
        ),
        "http": "400",
        "body": '{"status":"fail","message":"linehaul_id is required","data":[],"error_code":400}',
    },
    {
        "id": "getmanifestdetails_MUM075",
        "api": "getmanifestdetails",
        "summary": "manifest_code=MUM075 — success but shipments[] empty",
        "curl": (
            f"curl -sS -G '{BASE}' \\\n"
            f"  --data-urlencode 'request=getmanifestdetails' \\\n"
            f"  --data-urlencode 'manifest_code=MUM075' \\\n"
            f"  -H 'Authorization: Bearer {TOKEN}' \\\n"
            f"  -H 'X-App-Version: 22.1.0' \\\n"
            f"  -H 'X-App-Platform: ios'"
        ),
        "http": "200",
        "body": (
            '{"status":"success","message":"Manifest details retrieved successfully","data":{'
            '"id":"171","manifest_no":"MUM075","bags":[{"bag_code":"BAG20260515154014"}],'
            '"debug_joined_shipments_count":"0","shipments":[]}}'
        ),
        "note": "HTTP 200 / status success — but shipments[] is empty while bags[] has data.",
    },
    {
        "id": "manifestreport_dates",
        "api": "manifestreport",
        "summary": "start_date + end_date only — error response",
        "curl": (
            f"curl -sS -G '{BASE}' \\\n"
            f"  --data-urlencode 'request=manifestreport' \\\n"
            f"  --data-urlencode 'start_date=2026-01-01' \\\n"
            f"  --data-urlencode 'end_date=2026-06-09' \\\n"
            f"  -H 'Authorization: Bearer {TOKEN}' \\\n"
            f"  -H 'X-App-Version: 22.1.0' \\\n"
            f"  -H 'X-App-Platform: ios'"
        ),
        "http": "400",
        "body": '{"status":"fail","message":"Manifest ID required","data":[],"error_code":400}',
    },
    {
        "id": "manifestreport_id",
        "api": "manifestreport",
        "summary": "manifest_id + dates — error response",
        "curl": (
            f"curl -sS -G '{BASE}' \\\n"
            f"  --data-urlencode 'request=manifestreport' \\\n"
            f"  --data-urlencode 'manifest_id=382' \\\n"
            f"  --data-urlencode 'start_date=2026-01-01' \\\n"
            f"  --data-urlencode 'end_date=2026-06-09' \\\n"
            f"  -H 'Authorization: Bearer {TOKEN}' \\\n"
            f"  -H 'X-App-Version: 22.1.0' \\\n"
            f"  -H 'X-App-Platform: ios'"
        ),
        "http": "400",
        "body": '{"status":"fail","message":"Manifest ID required","data":[],"error_code":400}',
    },
    {
        "id": "manifestreport_code",
        "api": "manifestreport",
        "summary": "manifest_code + dates — error response",
        "curl": (
            f"curl -sS -G '{BASE}' \\\n"
            f"  --data-urlencode 'request=manifestreport' \\\n"
            f"  --data-urlencode 'manifest_code=HYD010' \\\n"
            f"  --data-urlencode 'start_date=2026-01-01' \\\n"
            f"  --data-urlencode 'end_date=2026-06-09' \\\n"
            f"  -H 'Authorization: Bearer {TOKEN}' \\\n"
            f"  -H 'X-App-Version: 22.1.0' \\\n"
            f"  -H 'X-App-Platform: ios'"
        ),
        "http": "400",
        "body": '{"status":"fail","message":"Manifest ID required","data":[],"error_code":400}',
    },
    {
        "id": "listmanifests",
        "api": "listmanifests",
        "summary": "no branch_id — only 50 rows returned",
        "curl": (
            f"curl -sS -G '{BASE}' \\\n"
            f"  --data-urlencode 'request=listmanifests' \\\n"
            f"  -H 'Authorization: Bearer {TOKEN}' \\\n"
            f"  -H 'X-App-Version: 22.1.0' \\\n"
            f"  -H 'X-App-Platform: ios'"
        ),
        "http": "200",
        "body": '{"status":"success","message":"Manifests retrieved successfully","data":[...50 items...]}',
        "note": "HTTP 200 / status success — but response is capped at 50 rows; manifests beyond that are not returned.",
    },
    {
        "id": "createmanifest",
        "api": "createmanifest",
        "summary": "create manifest — error response",
        "curl": (
            f"curl -sS -X POST '{BASE}?request=createmanifest' \\\n"
            f"  -H 'Authorization: Bearer {TOKEN}' \\\n"
            f"  -H 'X-App-Version: 22.3.0' \\\n"
            f"  -F 'bag_codes=BAG20260529164714292' \\\n"
            f"  -F 'origin_branch_id=75' \\\n"
            f"  -F 'destination_branch_id=75' \\\n"
            f"  -F 'user_id=148'"
        ),
        "http": "500",
        "body": '{"status":"fail","message":"Failed to insert manifest record","data":[],"error_code":500}',
    },
    {
        "id": "createmanifest_mode",
        "api": "createmanifest",
        "summary": "create manifest with transport_mode=Airway — error response",
        "curl": (
            f"curl -sS -X POST '{BASE}?request=createmanifest' \\\n"
            f"  -H 'Authorization: Bearer {TOKEN}' \\\n"
            f"  -H 'X-App-Version: 22.3.0' \\\n"
            f"  -F 'bag_codes=BAG20260529164714292' \\\n"
            f"  -F 'origin_branch_id=75' \\\n"
            f"  -F 'destination_branch_id=75' \\\n"
            f"  -F 'user_id=148' \\\n"
            f"  -F 'transport_mode=Airway'"
        ),
        "http": "500",
        "body": '{"status":"fail","message":"Failed to insert manifest record","data":[],"error_code":500}',
    },
    {
        "id": "getpickuplist",
        "api": "getpickuplist",
        "summary": "pickup list — duplicate id in response",
        "curl": (
            f"curl -sS -G '{BASE}' \\\n"
            f"  --data-urlencode 'request=getpickuplist' \\\n"
            f"  -H 'Authorization: Bearer {TOKEN}' \\\n"
            f"  -H 'X-App-Version: 22.1.0' \\\n"
            f"  -H 'X-App-Platform: ios'"
        ),
        "http": "200",
        "body": (
            '... "id":"319","mawb_no":"31229565141","origin_hub":"Vijaywada" ...\n'
            '... "id":"319","mawb_no":"31229565141","origin_hub":"Hyderabad" ...'
        ),
        "note": "HTTP 200 / status success — but id=319 appears twice in data[] with different origin_hub.",
    },
]


def pretty_json(raw):
    try:
        return json.dumps(json.loads(raw), indent=2, ensure_ascii=False)
    except Exception:
        return raw


def http_label(code, note=""):
    c = str(code)
    if note and c.startswith("2"):
        return f'<span class="http warn">HTTP {html.escape(c)} — incomplete data</span>'
    if c.startswith("2"):
        return f'<span class="http ok">HTTP {html.escape(c)}</span>'
    return f'<span class="http err">HTTP {html.escape(c)}</span>'


def card(i, item):
    body = html.escape(pretty_json(item.get("body", "")))
    curl = html.escape(item["curl"])
    note = item.get("note", "")
    note_html = f'<p class="note">{html.escape(note)}</p>' if note else ""
    return f"""
<article class="card" id="{html.escape(item['id'])}">
  <header>
    <span class="num">{i}</span>
    <div>
      <h2><code>{html.escape(item['api'])}</code></h2>
      <p class="summary">{html.escape(item['summary'])}</p>
      {http_label(item['http'], note)}
    </div>
  </header>
  {note_html}
  <h3>Request (curl)</h3>
  <pre class="req">{curl}</pre>
  <button type="button" class="copy" data-target="curl-{i}">Copy curl</button>
  <textarea id="curl-{i}" class="hidden" readonly>{curl}</textarea>
  <h3>Response</h3>
  <pre class="res">{body}</pre>
</article>"""


def generate():
    verified = "2026-06-18 09:59 UTC"
    live = DOCS / "sarvesh_live_responses.json"
    if live.exists():
        verified = json.loads(live.read_text()).get("verified_at", verified)

    cards = "\n".join(card(i + 1, x) for i, x in enumerate(ISSUES))
    apis = sorted({x["api"] for x in ISSUES})

    page = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Outbound API — Not Working (Live Curls)</title>
<style>
:root {{
  --bg:#0f1419; --card:#1a2332; --head:#243044; --text:#e7ecf3; --muted:#8b9cb3;
  --accent:#3d9eff; --err:#ff6b6b; --warn:#ffb347; --border:#2d3a4f;
  --mono:ui-monospace,Menlo,Consolas,monospace; --sans:system-ui,sans-serif;
}}
*{{box-sizing:border-box}}
body{{margin:0;font-family:var(--sans);background:var(--bg);color:var(--text);line-height:1.5}}
.wrap{{max-width:920px;margin:0 auto;padding:28px 20px 60px}}
h1{{margin:0 0 6px;font-size:22px}}
.sub{{color:var(--muted);font-size:13px;margin:0 0 8px}}
.apis{{color:var(--muted);font-size:12px;margin-bottom:28px}}
.apis code{{color:var(--accent)}}
.card{{background:var(--card);border:1px solid var(--border);border-radius:10px;margin-bottom:20px;overflow:hidden}}
.card header{{display:flex;gap:14px;padding:16px 18px;background:var(--head);border-bottom:1px solid var(--border);align-items:flex-start}}
.num{{font:700 15px var(--mono);color:var(--err);min-width:24px}}
.card h2{{margin:0 0 4px;font-size:16px}}
.card h2 code{{color:var(--accent);font-family:var(--mono)}}
.summary{{margin:0 0 8px;font-size:13px;color:var(--muted)}}
.http{{font:600 12px var(--mono)}}
.http.err{{color:var(--err)}}
.http.warn{{color:var(--warn)}}
.http.ok{{color:#3dd68c}}
.note{{margin:0;padding:12px 18px;font-size:13px;color:var(--warn);background:#ffb34711;border-bottom:1px solid var(--border)}}
.card h3{{margin:14px 18px 6px;font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted)}}
pre{{margin:0 18px 12px;padding:12px;background:#0a0e14;border:1px solid var(--border);border-radius:8px;
  font:11px/1.45 var(--mono);overflow:auto;max-height:220px;white-space:pre-wrap;word-break:break-all}}
pre.req{{color:#8ec8ff}}
pre.res{{color:#c5d4e8}}
.copy{{margin:0 18px 16px;font-size:11px;padding:5px 12px;border-radius:6px;border:1px solid var(--border);
  background:var(--head);color:var(--text);cursor:pointer}}
.copy:hover{{background:var(--accent);color:#000;border-color:var(--accent)}}
.hidden{{position:absolute;left:-9999px}}
footer{{margin-top:32px;padding-top:14px;border-top:1px solid var(--border);font-size:12px;color:var(--muted)}}
</style>
</head>
<body>
<div class="wrap">
  <h1>Outbound APIs — not working</h1>
  <p class="sub">Live curls against production · verified {html.escape(verified)}</p>
  <p class="apis">APIs with issues: {", ".join(f"<code>{html.escape(a)}</code>" for a in apis)}</p>
  <p class="sub">Below: exact request sent and actual response received. No success or incomplete/error data.</p>
  {cards}
  <footer>Generated {html.escape(NOW)} · Regenerate: <code>python3 docs/generate_bug_index.py</code></footer>
</div>
<script>
document.querySelectorAll('.copy').forEach(btn => {{
  btn.addEventListener('click', () => {{
    const ta = document.getElementById(btn.dataset.target);
    ta.select();
    navigator.clipboard.writeText(ta.value).then(() => {{
      btn.textContent = 'Copied';
      setTimeout(() => btn.textContent = 'Copy curl', 1200);
    }});
  }});
}});
</script>
</body>
</html>"""

    out = DOCS / "index.html"
    out.write_text(page)
    print(f"Wrote {out} ({len(ISSUES)} issues)")


if __name__ == "__main__":
    generate()
