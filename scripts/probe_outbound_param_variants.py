#!/usr/bin/env python3
"""Probe alternate query/body keys for Partial outbound endpoints."""

from __future__ import annotations

import json
import os
import sys
import urllib.parse
import urllib.request

BASE = "https://my.axlpl.com/messenger/services_v8/"
HEADERS = {
    "X-App-Version": "99.99.99",
    "X-App-Platform": "android",
    "accept": "*/*",
}

DOCKET = os.environ.get("OUTBOUND_DOCKET_NO", "990831778839479")
BAG = os.environ.get("OUTBOUND_BAG_ID", "BAG20260515154014")
MANIFEST = os.environ.get("OUTBOUND_MANIFEST_ID", "MUM075")
TRIP = os.environ.get("OUTBOUND_LINEHAUL_ID", "LH1778842087")


def login() -> str:
    mobile = os.environ.get("OUTBOUND_LOGIN_MOBILE", "")
    password = os.environ.get("OUTBOUND_LOGIN_PASSWORD", "")
    if not mobile or not password:
        return os.environ.get("OUTBOUND_BEARER_TOKEN", "")
    form = urllib.parse.urlencode(
        {
            "mobile": mobile,
            "password": password,
            "fcm_token": "probe",
            "version": "99.99.99",
            "latitude": "0",
            "longitude": "0",
            "device_id": "probe",
            "platform": "android",
        }
    ).encode()
    req = urllib.request.Request(
        BASE + "login?platform=android",
        data=form,
        headers={**HEADERS, "Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        pb = json.loads(r.read().decode())
    data = pb.get("data") or {}
    return data.get("token") or data.get("Messangerdetail", {}).get("token") or ""


def call(
    method: str,
    path: str,
    *,
    query: dict | None = None,
    form: dict | None = None,
    token: str,
) -> dict:
    q = dict(query or {})
    q.setdefault("platform", "android")
    url = BASE + path + "?" + urllib.parse.urlencode(q)
    headers = {**HEADERS, "Authorization": f"Bearer {token}"}
    data = None
    if form is not None:
        f = dict(form)
        f.setdefault("platform", "android")
        data = urllib.parse.urlencode(f).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read().decode()
            pb = json.loads(raw)
            return {"ok": (pb.get("status") or "").lower() == "success", "status": pb.get("status"), "message": pb.get("message"), "keys": list((pb.get("data") or {}).keys()) if isinstance(pb.get("data"), dict) else type(pb.get("data")).__name__}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def main() -> int:
    token = login()
    if not token:
        print("No token — set OUTBOUND_LOGIN_* or OUTBOUND_BEARER_TOKEN", file=sys.stderr)
        return 1
    probes: list[tuple[str, str, str, dict | None, dict | None]] = [
        ("GET", "getbagdetails", "bag_id", {"bag_id": BAG}, None),
        ("GET", "getbagdetails", "bag_code", {"bag_code": BAG}, None),
        ("GET", "getbagdetails", "code", {"code": BAG}, None),
        ("POST", "addshipmenttobag", "bag_id", None, {"bag_id": BAG, "docket_no": DOCKET, "branch_id": "27", "user_id": "143"}),
        ("POST", "addshipmenttobag", "bag_code", None, {"bag_code": BAG, "docket_no": DOCKET, "branch_id": "27", "user_id": "143"}),
        ("POST", "lockbag", "bag_id", None, {"bag_id": BAG}),
        ("POST", "lockbag", "bag_code", None, {"bag_code": BAG}),
        ("POST", "createmanifest", "bag_ids", None, {"bag_ids": BAG, "origin_branch_id": "27", "destination_branch_id": "27", "user_id": "143"}),
        ("POST", "createmanifest", "bag_codes", None, {"bag_codes": BAG, "origin_branch_id": "27", "destination_branch_id": "27", "user_id": "143"}),
        ("GET", "getmanifestdetails", "manifest_id", {"manifest_id": MANIFEST}, None),
        ("GET", "getmanifestdetails", "manifest_code", {"manifest_code": MANIFEST}, None),
        ("GET", "getmanifestdetails", "code", {"code": MANIFEST}, None),
        ("GET", "printmanifestdata", "manifest_id", {"manifest_id": MANIFEST}, None),
        ("GET", "printmanifestdata", "manifest_code", {"manifest_code": MANIFEST}, None),
        ("GET", "getlinehauldetails", "linehaul_id", {"linehaul_id": TRIP}, None),
        ("GET", "getlinehauldetails", "trip_no", {"trip_no": TRIP}, None),
        ("POST", "createbag", "existing code", None, {"origin_branch_id": "27", "destination_branch_id": "27", "bag_code": BAG, "user_id": "143"}),
    ]
    results = []
    for method, path, label, query, form in probes:
        r = call(method, path, query=query, form=form, token=token)
        row = {"path": path, "variant": label, **r}
        results.append(row)
        mark = "OK" if r.get("ok") else "FAIL"
        print(f"{mark} {path} [{label}] -> {r.get('message') or r.get('error')}")
    out = os.path.join(os.path.dirname(__file__), "..", "docs", "outbound_param_probe_results.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    print(f"\nWrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
