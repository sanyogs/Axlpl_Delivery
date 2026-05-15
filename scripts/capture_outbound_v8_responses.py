#!/usr/bin/env python3
"""
Call all Services V8 outbound endpoints and write raw JSON responses to a file.

Uses the same version headers as ApiClient. Optional env:
  OUTBOUND_BEARER_TOKEN   JWT (some list endpoints may stay empty without it)
  OUTBOUND_LOGIN_MOBILE   With OUTBOUND_LOGIN_PASSWORD, calls `login` first (never commit passwords)
  OUTBOUND_LOGIN_PASSWORD
  OUTBOUND_FCM_TOKEN      Optional placeholder for scripted login
  OUTBOUND_DEVICE_ID      Optional device_id for login body
  OUTBOUND_BRANCH_ID      Branch for outbound calls (default 27 — hub logs have rows there)
  OUTBOUND_LOGIN_BRANCH_ID  Set from login only; not used unless OUTBOUND_BRANCH_ID unset
  OUTBOUND_PROBE_BRANCHES  Comma-separated branches for id discovery (default: login branch,27,5)
  OUTBOUND_SKIP_CREATEBAG default 1 — skips HTTP for createbag (server returns bogus success)
  OUTBOUND_CAPTURE_MUTATIONS=1  real POST bodies (dangerous on production)
  OUTBOUND_HTTP_LOG=1     JSON lines to stderr per request/response (passwords redacted in capture file)
  OUTBOUND_DISCOVER_IDS=1 After login, call list/log endpoints and reuse first real ids (default when bearer set)
  OUTBOUND_VALID_POSTS=1  Use non-empty POST bodies with discovered ids (no production writes unless combined with MUTATIONS)
  OUTBOUND_MAWB_NO       Sector pickup: match `mawb_no` in getpickuplist → pickup_id (e.g. awb1234 → 121)
  OUTBOUND_DOCKET_NO     Shipment / docket for hub scan, bagging, sectorpickupscan
  OUTBOUND_BAG_ID        Numeric bag id for bag APIs (bag_code like BAG20260515151432 is not accepted as bag_id)
  OUTBOUND_MANIFEST_ID   Manifest code or numeric id (MUM074 works for assignlinehaul; detail GETs may need numeric)

Capture file `meta` includes `token_source`, `login_attempted`, `login_succeeded`, `had_bearer_token`, `discovered_ids`, `working_fine_by_path`.
"""

from __future__ import annotations

import json
import os
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

BASE = "https://my.axlpl.com/messenger/services_v8/"
HEADERS_BASE = {
    "accept": "*/*",
    "X-App-Version": os.environ.get("OUTBOUND_APP_VERSION", "99.99.99"),
    "X-App-Platform": os.environ.get("OUTBOUND_APP_PLATFORM", "android"),
    "X-Platform": os.environ.get("OUTBOUND_APP_PLATFORM", "android"),
}

# Messenger JWT from `OUTBOUND_BEARER_TOKEN` or from optional `login` using OUTBOUND_LOGIN_*.
_active_bearer: str | None = None
_login_used: bool = False


def _http_log_enabled() -> bool:
    return os.environ.get("OUTBOUND_HTTP_LOG", "").strip().lower() in ("1", "true", "yes")


def _redact_form_for_log(form: dict[str, Any] | None) -> dict[str, Any] | None:
    if form is None:
        return None
    out = dict(form)
    for k in list(out.keys()):
        lk = str(k).lower()
        if "password" in lk or lk in ("otp", "fcm_token", "token") or "secret" in lk:
            out[k] = "***"
    return out


def _emit_http_log(event: str, payload: dict[str, Any]) -> None:
    if not _http_log_enabled():
        return
    try:
        line = json.dumps({"event": event, **payload}, ensure_ascii=False, default=str)
    except TypeError:
        line = json.dumps({"event": event, "payload": str(payload)}, ensure_ascii=False)
    if len(line) > 240000:
        line = line[:240000] + "...(truncated)"
    print(line, file=sys.stderr, flush=True)


def _extract_login_context(parsed: Any) -> tuple[str | None, str | None, str | None]:
    """Returns (bearer, user_id, branch_id) from login response."""
    if not isinstance(parsed, dict):
        return None, None, None
    root = parsed.get("data") if isinstance(parsed.get("data"), dict) else parsed
    if not isinstance(root, dict):
        return None, None, None
    for key in ("Messangerdetail", "messangerdetail", "Customerdetail", "customerdetail"):
        block = root.get(key)
        if isinstance(block, dict):
            tok = block.get("token")
            bearer = str(tok).strip() if tok else None
            uid = block.get("id")
            user_id = str(uid).strip() if uid is not None else None
            bid = block.get("branch_id") or block.get("branchId")
            branch_id = str(bid).strip() if bid is not None else None
            if bearer:
                return bearer, user_id, branch_id
    return None, None, None


def _extract_bearer_from_login(parsed: Any) -> str | None:
    bearer, _, _ = _extract_login_context(parsed)
    return bearer


def _try_login_for_bearer() -> None:
    """Sets module _active_bearer when OUTBOUND_LOGIN_* is set and login succeeds."""
    global _active_bearer, _login_used
    if (os.environ.get("OUTBOUND_BEARER_TOKEN") or "").strip():
        return
    mob = os.environ.get("OUTBOUND_LOGIN_MOBILE", "").strip()
    pwd = os.environ.get("OUTBOUND_LOGIN_PASSWORD", "").strip()
    if not mob or not pwd:
        return
    form = {
        "mobile": mob,
        "password": pwd,
        "fcm_token": os.environ.get("OUTBOUND_FCM_TOKEN", "capture_script_no_fcm"),
        "version": os.environ.get("OUTBOUND_APP_VERSION", "99.99.99"),
        "latitude": os.environ.get("OUTBOUND_LOGIN_LAT", "0"),
        "longitude": os.environ.get("OUTBOUND_LOGIN_LON", "0"),
        "device_id": os.environ.get("OUTBOUND_DEVICE_ID", "python_capture_outbound"),
    }
    r = _request("POST", "login", None, form)
    tok, login_uid, login_branch = _extract_login_context(r.get("parsed_body"))
    if tok:
        _active_bearer = tok
        _login_used = True
        if login_uid:
            os.environ.setdefault("OUTBOUND_USER_ID", login_uid)
        if login_branch:
            os.environ.setdefault("OUTBOUND_LOGIN_BRANCH_ID", login_branch)
        print(
            f"OUTBOUND: login OK, bearer length={len(tok)}, "
            f"user_id={login_uid or 'n/a'}, login_branch={login_branch or 'n/a'}",
            file=sys.stderr,
        )
    else:
        print(
            "OUTBOUND: login failed or unexpected JSON (set OUTBOUND_HTTP_LOG=1 to debug)",
            file=sys.stderr,
        )


def _merge_headers(extra: dict[str, str] | None = None) -> dict[str, str]:
    h = dict(HEADERS_BASE)
    token = (os.environ.get("OUTBOUND_BEARER_TOKEN") or "").strip() or (_active_bearer or "").strip()
    if token:
        h["Authorization"] = f"Bearer {token}"
    if extra:
        h.update(extra)
    return h


def _request(
    method: str,
    path: str,
    query: dict[str, Any] | None = None,
    form: dict[str, Any] | None = None,
) -> dict[str, Any]:
    q = dict(query or {})
    q.setdefault("platform", os.environ.get("OUTBOUND_APP_PLATFORM", "android"))
    url = BASE + path.lstrip("/")
    if q:
        url += "?" + urllib.parse.urlencode(q, doseq=True)

    data_bytes: bytes | None = None
    headers = _merge_headers()
    if method.upper() == "POST" and form is not None:
        body = dict(form)
        body.setdefault("platform", os.environ.get("OUTBOUND_APP_PLATFORM", "android"))
        data_bytes = urllib.parse.urlencode(body).encode("utf-8")
        headers["Content-Type"] = "application/x-www-form-urlencoded"

    req = urllib.request.Request(url, data=data_bytes, headers=headers, method=method.upper())
    out: dict[str, Any] = {
        "method": method.upper(),
        "url": url,
        "path": path,
        "query": q if method.upper() == "GET" else None,
        "form": _redact_form_for_log(form) if method.upper() == "POST" else None,
    }
    _emit_http_log(
        "request",
        {
            "method": method.upper(),
            "url": url,
            "query": q if method.upper() == "GET" else None,
            "form": _redact_form_for_log(form) if method.upper() == "POST" else None,
        },
    )
    try:
        ctx = ssl.create_default_context()
        with urllib.request.urlopen(req, timeout=60, context=ctx) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            out["http_status"] = resp.getcode()
            out["response_headers"] = dict(resp.headers.items())
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        out["http_status"] = e.code
        out["response_headers"] = dict(e.headers.items())
    except urllib.error.URLError as e:
        out["http_status"] = None
        out["network_error"] = str(e)
        out["parsed_body"] = None
        out["raw_body"] = None
        _emit_http_log("response_error", {"url": url, "network_error": str(e)})
        return out

    out["raw_body"] = raw
    try:
        out["parsed_body"] = json.loads(raw)
    except json.JSONDecodeError:
        out["parsed_body"] = None
        out["json_decode_error"] = "response is not JSON"
    _emit_http_log(
        "response",
        {
            "url": url,
            "http_status": out.get("http_status"),
            "parsed_body": out.get("parsed_body"),
            "raw_body_len": len(raw),
        },
    )
    return out


def _has_bearer() -> bool:
    return bool(
        (os.environ.get("OUTBOUND_BEARER_TOKEN") or "").strip()
        or (_active_bearer or "").strip()
    )


def _as_row_list(data: Any) -> list[dict[str, Any]]:
    if data is None:
        return []
    if isinstance(data, list):
        return [x for x in data if isinstance(x, dict)]
    if isinstance(data, dict):
        for key in (
            "data",
            "list",
            "items",
            "rows",
            "bags",
            "manifests",
            "linehauls",
            "logs",
            "pickups",
        ):
            v = data.get(key)
            if isinstance(v, list):
                return [x for x in v if isinstance(x, dict)]
        if data:
            return [data]
    return []


def _first_field(row: dict[str, Any], keys: list[str]) -> str | None:
    for k in keys:
        v = row.get(k)
        if v is None:
            continue
        s = str(v).strip()
        if s and s != "0":
            return s
    return None


def _id_from_success(pb: Any, keys: list[str]) -> str | None:
    if not isinstance(pb, dict) or (pb.get("status") or "").lower() != "success":
        return None
    data = pb.get("data")
    if isinstance(data, dict):
        return _first_field(data, keys)
    return None


def _sync_call_ids(
    query: dict[str, Any] | None,
    form: dict[str, Any] | None,
    *,
    bag_id: str,
    manifest_id: str,
    linehaul_id: str,
    docket_no: str,
    pickup_id: str,
) -> None:
    if query:
        if "bag_id" in query:
            query["bag_id"] = bag_id
        if "manifest_id" in query:
            query["manifest_id"] = manifest_id
        if "linehaul_id" in query:
            query["linehaul_id"] = linehaul_id
        if "docket_no" in query:
            query["docket_no"] = docket_no
    if form:
        for key in ("bag_id", "new_bag_id", "bag_ids", "manifest_ids", "linehaul_id"):
            if key in form:
                if key == "bag_ids":
                    form[key] = bag_id
                elif key == "manifest_ids":
                    form[key] = manifest_id
                elif key == "new_bag_id":
                    form[key] = bag_id
                elif key == "linehaul_id":
                    form[key] = linehaul_id
                else:
                    form[key] = bag_id
        if "docket_no" in form:
            form["docket_no"] = docket_no
        if "pickup_id" in form:
            form["pickup_id"] = pickup_id


def _probe_branch_ids(branch_id: str, found: dict[str, str]) -> None:
    r = _request("GET", "gethubscanlogs", query={"branch_id": branch_id, "limit": "10"})
    pb = r.get("parsed_body")
    if isinstance(pb, dict) and (pb.get("status") or "").lower() == "success":
        rows = _as_row_list(pb.get("data"))
        if rows:
            docket = _first_field(rows[0], ["shipment_id", "docket_no", "docket"])
            if docket and "docket_no" not in found:
                found["docket_no"] = docket

    r = _request("GET", "listbags", query={"branch_id": branch_id})
    pb = r.get("parsed_body")
    if isinstance(pb, dict) and (pb.get("status") or "").lower() == "success":
        rows = _as_row_list(pb.get("data"))
        if rows:
            bid = _first_field(rows[0], ["bag_id", "id", "bagId"])
            if bid and "bag_id" not in found:
                found["bag_id"] = bid

    r = _request("GET", "listmanifests", query={"branch_id": branch_id})
    pb = r.get("parsed_body")
    if isinstance(pb, dict) and (pb.get("status") or "").lower() == "success":
        rows = _as_row_list(pb.get("data"))
        if rows:
            mid = _first_field(rows[0], ["manifest_id", "id", "manifestId"])
            if mid and "manifest_id" not in found:
                found["manifest_id"] = mid


def _pickup_id_for_mawb(mawb_no: str) -> str | None:
    """Resolve sector pickup row id from test/free-text mawb_no (e.g. awb1234)."""
    needle = mawb_no.strip().lower()
    if not needle:
        return None
    r = _request("GET", "getpickuplist", query={})
    pb = r.get("parsed_body")
    if not isinstance(pb, dict) or (pb.get("status") or "").lower() != "success":
        return None
    for row in _as_row_list(pb.get("data")):
        mawb = (_first_field(row, ["mawb_no", "mawbNo"]) or "").strip().lower()
        if mawb == needle:
            return _first_field(row, ["id", "pickup_id"])
    return None


def _discover_linehaul_id() -> str | None:
    for status in ("In Transit", "Pending", "Dispatched", "ARRIVED", "Open", ""):
        q = {"status": status} if status else {}
        r = _request("GET", "listlinehauls", query=q)
        pb = r.get("parsed_body")
        if isinstance(pb, dict) and (pb.get("status") or "").lower() == "success":
            rows = _as_row_list(pb.get("data"))
            if rows:
                return _first_field(rows[0], ["linehaul_id", "id", "linehaulId"])
    return None


def _discover_ids(branch_ids: list[str], user_id: str) -> dict[str, str]:
    """Pre-flight list/log calls to pick real ids for detail GETs and valid POST bodies."""
    found: dict[str, str] = {}
    print(
        f"OUTBOUND: discovering ids (branches={branch_ids})…",
        file=sys.stderr,
    )

    for branch_id in branch_ids:
        before = len(found)
        _probe_branch_ids(branch_id, found)
        if len(found) > before:
            found.setdefault("discovery_branch_id", branch_id)

    mawb_env = (os.environ.get("OUTBOUND_MAWB_NO") or "").strip()
    if mawb_env:
        pid = _pickup_id_for_mawb(mawb_env)
        if pid:
            found["pickup_id"] = pid
            found["mawb_no"] = mawb_env
    if "pickup_id" not in found:
        r = _request("GET", "getpickuplist", query={})
        pb = r.get("parsed_body")
        if isinstance(pb, dict) and (pb.get("status") or "").lower() == "success":
            rows = _as_row_list(pb.get("data"))
            if rows:
                pid = _first_field(rows[0], ["id", "pickup_id"])
                if pid:
                    found["pickup_id"] = pid

    lid = _discover_linehaul_id()
    if lid:
        found["linehaul_id"] = lid

    if user_id:
        found.setdefault("user_id", user_id)
    print(f"OUTBOUND: discovered ids = {json.dumps(found)}", file=sys.stderr)
    return found


def _env_locked_ids() -> dict[str, bool]:
    """True when caller set an id explicitly — discovery must not overwrite it."""
    return {
        "docket_no": bool(os.environ.get("OUTBOUND_DOCKET_NO", "").strip()),
        "bag_id": bool(os.environ.get("OUTBOUND_BAG_ID", "").strip()),
        "manifest_id": bool(os.environ.get("OUTBOUND_MANIFEST_ID", "").strip()),
        "linehaul_id": bool(os.environ.get("OUTBOUND_LINEHAUL_ID", "").strip()),
        "pickup_id": bool(os.environ.get("OUTBOUND_PICKUP_ID", "").strip()),
    }


def _resolve_branch_ids() -> tuple[str, list[str]]:
    """Returns (primary branch for calls, branches to probe for discovery)."""
    login_branch = (os.environ.get("OUTBOUND_LOGIN_BRANCH_ID") or "").strip()
    primary = (os.environ.get("OUTBOUND_BRANCH_ID") or "").strip()
    if not primary:
        primary = login_branch or "27"
    probe_env = (os.environ.get("OUTBOUND_PROBE_BRANCHES") or "").strip()
    if probe_env:
        probe = [b.strip() for b in probe_env.split(",") if b.strip()]
    else:
        probe = []
        for b in (login_branch, primary, "27", "5"):
            if b and b not in probe:
                probe.append(b)
    if primary not in probe:
        probe.insert(0, primary)
    return primary, probe


def _rate_working_fine(r: dict[str, Any], summary_row: dict[str, Any]) -> str:
    if r.get("skipped"):
        return "No"
    path = str(r.get("path") or "")
    http = r.get("http_status")
    pb = r.get("parsed_body")
    msg = (summary_row.get("message") or "").lower()
    if path in ("sectorpickupscan", "marknotpicked") and http == 422:
        if "already scanned" in msg:
            return "Yes"
    if http != 200 or not isinstance(pb, dict):
        return "No"
    if path == "createbag" and isinstance(pb, dict):
        data = pb.get("data")
        if isinstance(data, dict):
            bid = data.get("bag_id")
            code = data.get("bag_code")
            if (bid is None or str(bid).strip() in ("", "0")) and not (
                code and str(code).strip()
            ):
                return "Partial"
            if code and str(code).strip() and (
                bid is None or str(bid).strip() in ("", "0")
            ):
                return "Yes"
    api = (summary_row.get("api_status") or "").lower()
    if api == "success":
        kind = summary_row.get("data_kind")
        if kind == "list":
            n = summary_row.get("data_length") or 0
            return "Yes" if n > 0 else "Partial"
        if kind == "map":
            keys = summary_row.get("data_keys") or []
            if path in ("listbags", "listmanifests", "listlinehauls"):
                return "Yes"
            if path in ("baggingreport", "manifestreport", "linehaulreport", "pickupreport"):
                msg = (summary_row.get("message") or "").lower()
                if "generated" in msg or "retrieved" in msg:
                    return "Yes"
                return "Partial"
            if path in (
                "addmissedshipment",
                "marknotpicked",
                "sectorpickupscan",
                "hubscan",
                "lockbag",
                "addshipmenttobag",
                "removeshipmentfrombag",
            ):
                msg = (summary_row.get("message") or "").lower()
                if msg and any(
                    w in msg for w in ("success", "recorded", "added", "scanned", "removed", "locked")
                ):
                    return "Yes"
            if path in ("baggingreport", "manifestreport", "linehaulreport", "pickupreport"):
                return "Partial"
            return "Yes" if keys else "Partial"
        return "Yes"
    if api in ("fail", "error"):
        # Valid JSON envelope with business error — endpoint reachable; not happy-path.
        return "Partial"
    return "No"


def _summarize_entry(r: dict[str, Any]) -> dict[str, Any]:
    pb = r.get("parsed_body")
    row: dict[str, Any] = {
        "capture_name": r.get("capture_name"),
        "http_status": r.get("http_status"),
        "skipped": r.get("skipped", False),
    }
    if r.get("skipped"):
        row["message"] = (r.get("note") or "")[:500]
        return row
    if isinstance(pb, dict):
        row["api_status"] = pb.get("status")
        row["message"] = pb.get("message")
        row["error_code"] = pb.get("error_code")
        d = pb.get("data")
        if isinstance(d, list):
            row["data_kind"] = "list"
            row["data_length"] = len(d)
        elif isinstance(d, dict):
            row["data_kind"] = "map"
            row["data_keys"] = sorted(str(k) for k in d.keys())
        else:
            row["data_kind"] = type(d).__name__
    else:
        row["api_status"] = None
        row["message"] = r.get("json_decode_error") or (r.get("raw_body") or "")[:120]
    return row


def main() -> int:
    global _active_bearer, _login_used
    _active_bearer = None
    _login_used = False

    _try_login_for_bearer()

    branch_id, probe_branches = _resolve_branch_ids()
    bag_id = os.environ.get("OUTBOUND_BAG_ID", "156")
    manifest_id = os.environ.get("OUTBOUND_MANIFEST_ID", "153")
    linehaul_id = os.environ.get("OUTBOUND_LINEHAUL_ID", "129")
    docket_no = os.environ.get("OUTBOUND_DOCKET_NO", "258181778677083")
    user_id = os.environ.get("OUTBOUND_USER_ID", "148")
    pickup_id = os.environ.get("OUTBOUND_PICKUP_ID", "108")

    locked = _env_locked_ids()
    discover = os.environ.get("OUTBOUND_DISCOVER_IDS", "1").strip().lower() in (
        "1",
        "true",
        "yes",
    )
    discovered: dict[str, str] = {}
    if discover and _has_bearer():
        discovered = _discover_ids(probe_branches, user_id)
        if discovered.get("discovery_branch_id"):
            branch_id = discovered["discovery_branch_id"]
        if not locked["docket_no"]:
            docket_no = discovered.get("docket_no", docket_no)
        if not locked["bag_id"]:
            bag_id = discovered.get("bag_id", bag_id)
        if not locked["manifest_id"]:
            manifest_id = discovered.get("manifest_id", manifest_id)
        if not locked["linehaul_id"]:
            linehaul_id = discovered.get("linehaul_id", linehaul_id)
        if not locked["pickup_id"]:
            pickup_id = discovered.get("pickup_id", pickup_id)
        user_id = discovered.get("user_id", user_id)

    # Default: validation-only POST bodies (no hub scan / lock / manifest create on prod data).
    # Set OUTBOUND_CAPTURE_MUTATIONS=1 to send "happy path" POST bodies (DANGEROUS on production).
    mutations = os.environ.get("OUTBOUND_CAPTURE_MUTATIONS", "").strip() in ("1", "true", "yes")
    valid_posts = os.environ.get("OUTBOUND_VALID_POSTS", "").strip().lower() in (
        "1",
        "true",
        "yes",
    ) or mutations
    # createbag returns {"status":"success","data":{"bag_id":0,...}} even for invalid/missing fields.
    skip_createbag = os.environ.get("OUTBOUND_SKIP_CREATEBAG", "1").strip() in ("1", "true", "yes")
    if valid_posts and _has_bearer():
        skip_createbag = os.environ.get("OUTBOUND_SKIP_CREATEBAG", "0").strip() in (
            "1",
            "true",
            "yes",
        )

    dest_branch = (os.environ.get("OUTBOUND_DEST_BRANCH_ID") or branch_id).strip()
    report_end = os.environ.get("OUTBOUND_REPORT_END_DATE", "2026-05-15")
    report_start = os.environ.get("OUTBOUND_REPORT_START_DATE", "2026-01-01")

    if mutations or valid_posts:
        post_hubscan = {
            "docket_no": docket_no,
            "branch_id": branch_id,
            "user_id": user_id,
            "status": "Hub In",
        }
        post_createbag = {
            "origin_branch_id": branch_id,
            "destination_branch_id": dest_branch,
            "bag_code": f"API_CAPTURE_{os.getpid()}",
            "user_id": user_id,
        }
        post_add = {
            "bag_id": bag_id,
            "docket_no": docket_no,
            "branch_id": branch_id,
            "user_id": user_id,
        }
        post_remove = dict(post_add)
        post_lock = {"bag_id": bag_id}
        post_rebag = {"new_bag_id": bag_id, "docket_no": docket_no, "user_id": user_id}
        post_manifest = {
            "bag_ids": bag_id,
            "origin_branch_id": branch_id,
            "destination_branch_id": dest_branch,
            "user_id": user_id,
        }
        post_linehaul = {
            "manifest_ids": manifest_id,
            "vehicle_no": "UP78AB1234",
            "driver_name": "API Capture Script",
            "user_id": user_id,
        }
        post_lh_status = {
            "linehaul_id": linehaul_id,
            "status": "ARRIVED",
            "user_id": user_id,
            "branch_id": branch_id,
        }
        post_pickup_scan = {
            "pickup_id": pickup_id,
            "docket_no": docket_no,
            "status": "Picked",
            "remarks": "",
            "user_id": user_id,
            "branch_id": branch_id,
        }
        post_notpicked = {
            "pickup_id": pickup_id,
            "docket_no": docket_no,
            "remarks": "api_capture_script_test",
            "user_id": user_id,
            "branch_id": branch_id,
        }
        post_missed = {
            "pickup_id": pickup_id,
            "docket_no": docket_no,
            "remarks": "api_capture_script_test",
        }
    else:
        post_hubscan = {
            "docket_no": "",
            "branch_id": branch_id,
            "user_id": user_id,
            "status": "Hub In",
        }
        post_createbag = {
            "origin_branch_id": "not_a_number",
            "destination_branch_id": "5",
            "bag_code": "DO_NOT_CREATE_VALIDATION_TEST",
            "user_id": user_id,
        }
        post_add = {
            "bag_id": "0",
            "docket_no": "",
            "branch_id": branch_id,
            "user_id": user_id,
        }
        post_remove = dict(post_add)
        post_lock = {"bag_id": "0"}
        post_rebag = {"new_bag_id": "0", "docket_no": "", "user_id": user_id}
        post_manifest = {
            "bag_ids": "",
            "origin_branch_id": branch_id,
            "destination_branch_id": "5",
            "user_id": user_id,
        }
        post_linehaul = {
            "manifest_ids": "",
            "vehicle_no": "",
            "driver_name": "",
            "user_id": user_id,
        }
        post_lh_status = {
            "linehaul_id": "0",
            "status": "",
            "user_id": user_id,
            "branch_id": branch_id,
        }
        post_pickup_scan = {
            "pickup_id": "0",
            "docket_no": "",
            "status": "Picked",
            "remarks": "",
            "user_id": user_id,
            "branch_id": branch_id,
        }
        post_notpicked = {
            "pickup_id": "0",
            "docket_no": "",
            "remarks": "",
            "user_id": user_id,
            "branch_id": branch_id,
        }
        post_missed = {"pickup_id": "0", "docket_no": "", "remarks": ""}

    calls: list[tuple[str, str | None, dict[str, Any] | None, dict[str, Any] | None]] = [
        ("01_hubscan", "hubscan", None, post_hubscan),
        ("02_gethubscanlogs", "gethubscanlogs", {"branch_id": branch_id, "limit": "50"}, None),
        ("03_getshipmentscanhistory", "getshipmentscanhistory", {"docket_no": docket_no}, None),
    ]
    if skip_createbag:
        calls.append(("04_createbag", None, None, None))
    else:
        calls.append(("04_createbag", "createbag", None, post_createbag))
    calls.extend(
        [
            ("07_listbags", "listbags", {"branch_id": branch_id}, None),
            ("06_getbagdetails", "getbagdetails", {"bag_id": bag_id}, None),
            ("05_addshipmenttobag", "addshipmenttobag", None, post_add),
            ("08_removeshipmentfrombag", "removeshipmentfrombag", None, post_remove),
            ("09_lockbag", "lockbag", None, post_lock),
            ("10_rebagshipment", "rebagshipment", None, post_rebag),
            (
                "11_baggingreport",
                "baggingreport",
                {"start_date": report_start, "end_date": report_end},
                None,
            ),
            ("14_listmanifests", "listmanifests", {"branch_id": branch_id}, None),
            ("12_createmanifest", "createmanifest", None, post_manifest),
            ("13_getmanifestdetails", "getmanifestdetails", {"manifest_id": manifest_id}, None),
            (
                "15_manifestreport",
                "manifestreport",
                {"start_date": report_start, "end_date": report_end},
                None,
            ),
            ("16_printmanifestdata", "printmanifestdata", {"manifest_id": manifest_id}, None),
            ("18_listlinehauls", "listlinehauls", {"status": "In Transit"}, None),
            ("17_assignlinehaul", "assignlinehaul", None, post_linehaul),
            ("19_getlinehauldetails", "getlinehauldetails", {"linehaul_id": linehaul_id}, None),
            ("20_updatelinehaulstatus", "updatelinehaulstatus", None, post_lh_status),
            (
                "21_linehaulreport",
                "linehaulreport",
                {"start_date": report_start, "end_date": report_end},
                None,
            ),
            ("23_getpickuplist", "getpickuplist", {}, None),
            ("22_sectorpickupscan", "sectorpickupscan", None, post_pickup_scan),
            ("24_marknotpicked", "marknotpicked", None, post_notpicked),
            ("25_addmissedshipment", "addmissedshipment", None, post_missed),
            (
                "26_pickupreport",
                "pickupreport",
                {"start_date": report_start, "end_date": report_end},
                None,
            ),
        ]
    )

    def _refresh_post_ids() -> None:
        post_add["bag_id"] = bag_id
        post_remove["bag_id"] = bag_id
        post_lock["bag_id"] = bag_id
        post_rebag["new_bag_id"] = bag_id
        post_manifest["bag_ids"] = bag_id
        post_linehaul["manifest_ids"] = manifest_id
        post_lh_status["linehaul_id"] = linehaul_id

    valid_bag_id = bool(bag_id.strip() and bag_id.strip() not in ("0",))

    results: list[dict[str, Any]] = []
    for name, path, query, form in calls:
        if path is None:
            results.append(
                {
                    "capture_name": name,
                    "skipped": True,
                    "method": "POST",
                    "path": "createbag",
                    "note": (
                        "Skipped by default (OUTBOUND_SKIP_CREATEBAG=1). The live createbag endpoint "
                        "often returns status success with bag_id 0 even for invalid or incomplete "
                        "payloads, so HTTP capture is misleading. Set OUTBOUND_SKIP_CREATEBAG=0 to "
                        "record the real response body."
                    ),
                    "http_status": None,
                    "parsed_body": None,
                    "raw_body": None,
                }
            )
            continue
        _sync_call_ids(
            query,
            form,
            bag_id=bag_id,
            manifest_id=manifest_id,
            linehaul_id=linehaul_id,
            docket_no=docket_no,
            pickup_id=pickup_id,
        )
        if form is not None:
            r = _request("POST", path, form=form)
        else:
            r = _request("GET", path, query=query or {})
        r["capture_name"] = name
        results.append(r)
        pb = r.get("parsed_body")
        if path == "createbag":
            bid = _id_from_success(pb, ["bag_id", "id"])
            if bid:
                bag_id = bid
                valid_bag_id = True
                _refresh_post_ids()
                discovered["bag_id"] = bag_id
            else:
                valid_bag_id = False
                bag_id = "0"
                _refresh_post_ids()
        elif path == "listbags":
            if not locked["bag_id"]:
                rows = _as_row_list(pb.get("data") if isinstance(pb, dict) else None)
                bid = _first_field(rows[0], ["bag_id", "id", "bagId"]) if rows else None
                if bid:
                    bag_id = bid
                    valid_bag_id = True
                    _refresh_post_ids()
                    discovered["bag_id"] = bag_id
        elif path == "createmanifest":
            if not locked["manifest_id"]:
                mid = _id_from_success(pb, ["manifest_id", "id", "manifestId"])
                if mid:
                    manifest_id = mid
                    post_linehaul["manifest_ids"] = manifest_id
                    discovered["manifest_id"] = manifest_id
        elif path == "listmanifests":
            if not locked["manifest_id"]:
                rows = _as_row_list(pb.get("data") if isinstance(pb, dict) else None)
                mid = _first_field(rows[0], ["manifest_id", "id", "manifestId"]) if rows else None
                if mid:
                    manifest_id = mid
                    post_linehaul["manifest_ids"] = manifest_id
                    discovered["manifest_id"] = manifest_id
        elif path == "assignlinehaul":
            if not locked["linehaul_id"]:
                lid = _id_from_success(pb, ["linehaul_id", "id", "linehaulId"])
                trip = _id_from_success(pb, ["trip_no", "tripNo"])
                if lid and str(lid).strip() not in ("", "0"):
                    linehaul_id = lid
                    post_lh_status["linehaul_id"] = linehaul_id
                    discovered["linehaul_id"] = linehaul_id
                elif trip:
                    linehaul_id = trip
                    post_lh_status["linehaul_id"] = linehaul_id
                    discovered["linehaul_id"] = trip
                    discovered["linehaul_id_source"] = "trip_no (assignlinehaul returned linehaul_id 0)"
        elif path == "listlinehauls":
            if not locked["linehaul_id"]:
                rows = _as_row_list(pb.get("data") if isinstance(pb, dict) else None)
                lid = _first_field(rows[0], ["linehaul_id", "id", "linehaulId"]) if rows else None
                if lid:
                    linehaul_id = lid
                    post_lh_status["linehaul_id"] = linehaul_id
                    discovered["linehaul_id"] = linehaul_id

    out_path = os.environ.get(
        "OUTBOUND_CAPTURE_OUT",
        os.path.join(
            os.path.dirname(__file__),
            "..",
            "docs",
            "outbound_v8_api_capture.json",
        ),
    )
    out_path = os.path.abspath(out_path)
    env_tok = bool((os.environ.get("OUTBOUND_BEARER_TOKEN") or "").strip())
    mob_login = (os.environ.get("OUTBOUND_LOGIN_MOBILE") or "").strip()
    pwd_login = (os.environ.get("OUTBOUND_LOGIN_PASSWORD") or "").strip()
    bearer_present = env_tok or bool((_active_bearer or "").strip())
    token_source = (
        "OUTBOUND_BEARER_TOKEN"
        if env_tok
        else ("OUTBOUND_LOGIN_MOBILE" if _login_used and _active_bearer else "none")
    )
    login_attempted = (not env_tok) and bool(mob_login and pwd_login)
    payload = {
        "meta": {
            "base": BASE,
            "had_bearer_token": bearer_present,
            "token_source": token_source,
            "login_attempted": login_attempted,
            "login_succeeded": _login_used,
            "mutation_capture_mode": mutations,
            "skip_createbag": skip_createbag,
            "default_branch_id_used": branch_id,
            "login_branch_id": (os.environ.get("OUTBOUND_LOGIN_BRANCH_ID") or "").strip() or None,
            "probe_branches": probe_branches,
            "destination_branch_id": dest_branch,
            "valid_bag_id_available": valid_bag_id,
            "ids_used": {
                "bag_id": bag_id,
                "manifest_id": manifest_id,
                "linehaul_id": linehaul_id,
                "docket_no": docket_no,
                "pickup_id": pickup_id,
                "user_id": user_id,
            },
            "note": (
                "valid_posts uses discovered ids and non-empty POST bodies when bearer is set; "
                "OUTBOUND_CAPTURE_MUTATIONS=1 is optional for extra writes. "
                "createbag may return success with bag_id 0 — see valid_bag_id_available."
            ),
        },
        "results": results,
    }

    summary_rows = [_summarize_entry(x) for x in results]
    working_fine_by_path: dict[str, str] = {}
    for r, srow in zip(results, summary_rows):
        path = r.get("path")
        if path:
            working_fine_by_path[str(path)] = _rate_working_fine(r, srow)
            srow["working_fine"] = working_fine_by_path[str(path)]

    payload["meta"]["discovered_ids"] = discovered
    payload["meta"]["valid_posts"] = valid_posts
    payload["meta"]["working_fine_by_path"] = working_fine_by_path

    summary_path = (
        out_path[:-5] + ".summary.json" if out_path.endswith(".json") else out_path + ".summary.json"
    )
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)

    summary_payload = {
        "meta": {**payload["meta"], "summary_for": out_path},
        "rows": summary_rows,
    }
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(summary_payload, f, indent=2, ensure_ascii=False)

    print(out_path, file=sys.stderr)
    print(summary_path, file=sys.stderr)
    print(
        json.dumps({"written": out_path, "summary": summary_path, "count": len(results)}, indent=2)
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
