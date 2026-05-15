# Outbound Services V8 — API responses & request reference

Single reference for **all 26 outbound endpoints** under `https://my.axlpl.com/messenger/services_v8/`: **Flutter request parameters** (as implemented in [`lib/app/data/networking/api_services.dart`](../lib/app/data/networking/api_services.dart)) and **observed JSON bodies** from the automated capture.

> **Regenerate this file:** `python3 scripts/generate_outbound_api_responses_reference.py`

## Related documents

| Document | Purpose |
|----------|---------|
| [`outbound_services_v8_apis.md`](outbound_services_v8_apis.md) | Product flow map, backend checklist, capture instructions |
| [`outbound_v8_api_capture.json`](outbound_v8_api_capture.json) | **Full** raw URLs, headers, `raw_body`, `parsed_body` per call |
| [`outbound_v8_api_capture.summary.json`](outbound_v8_api_capture.summary.json) | One row per API: `api_status`, `data_kind`, lengths |

## Capture run metadata (embedded in JSON)

```json
{
  "base": "https://my.axlpl.com/messenger/services_v8/",
  "had_bearer_token": true,
  "token_source": "OUTBOUND_LOGIN_MOBILE",
  "login_attempted": true,
  "login_succeeded": true,
  "mutation_capture_mode": false,
  "skip_createbag": true,
  "default_branch_id_used": "27",
  "login_branch_id": "2",
  "probe_branches": [
    "2",
    "27",
    "5"
  ],
  "destination_branch_id": "27",
  "valid_bag_id_available": true,
  "ids_used": {
    "bag_id": "BAG20260515154014",
    "manifest_id": "MUM075",
    "linehaul_id": "LH1778841961",
    "docket_no": "990831778839479",
    "pickup_id": "122",
    "user_id": "143"
  },
  "note": "valid_posts uses discovered ids and non-empty POST bodies when bearer is set; OUTBOUND_CAPTURE_MUTATIONS=1 is optional for extra writes. createbag may return success with bag_id 0 — see valid_bag_id_available.",
  "discovered_ids": {
    "docket_no": "149311778836750",
    "discovery_branch_id": "27",
    "pickup_id": "122",
    "mawb_no": "mum4321",
    "user_id": "143",
    "linehaul_id": "LH1778841961",
    "linehaul_id_source": "trip_no (assignlinehaul returned linehaul_id 0)"
  },
  "valid_posts": true,
  "working_fine_by_path": {
    "hubscan": "Yes",
    "gethubscanlogs": "Yes",
    "getshipmentscanhistory": "Yes",
    "createbag": "No",
    "listbags": "Yes",
    "getbagdetails": "Partial",
    "addshipmenttobag": "Partial",
    "removeshipmentfrombag": "Partial",
    "lockbag": "Partial",
    "rebagshipment": "Partial",
    "baggingreport": "Yes",
    "listmanifests": "Yes",
    "createmanifest": "Partial",
    "getmanifestdetails": "Partial",
    "manifestreport": "Yes",
    "printmanifestdata": "Partial",
    "listlinehauls": "Yes",
    "assignlinehaul": "Yes",
    "getlinehauldetails": "Partial",
    "updatelinehaulstatus": "Partial",
    "linehaulreport": "Yes",
    "getpickuplist": "Yes",
    "sectorpickupscan": "Partial",
    "marknotpicked": "Partial",
    "addmissedshipment": "Yes",
    "pickupreport": "Yes"
  }
}
```

## Standard response envelope

Most endpoints return JSON with this top-level shape (keys may be omitted when empty):

```json
{
  "status": "success | fail | error",
  "message": "string",
  "data": "object | array | string | null - inner payload on success",
  "error_code": "number | omitted - common on fail"
}
```

- **HTTP 200 + `status: fail`:** treated as an error in [`ApiClient`](../lib/app/data/networking/api_client.dart) (`APIResponse.error`), not success.
- **Success unwrap:** if top-level JSON is a `Map` and `data` is present, Flutter success callbacks receive **`data`**; if the decoded body is not a map (e.g. raw HTML string), it is returned **as-is**.
- **Reports / print:** `data` may be `{}`, an array, a nested object, or (in some deployments) **non-JSON** text/HTML - inspect `Content-Type` and body for your environment.

---

## 1. Hub Scan (`hubscan`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `docket_no` | string | Shipment docket / tracking id |
| `branch_id` | string | Numeric branch id as string |
| `user_id` | string | Messenger user id |
| `status` | string | e.g. `Hub In`, `Hub Out` |
| `platform` | string | Appended by client: ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Shipment scanned successfully as Hub In",
  "data": {
    "shipment_id": "990831778839479",
    "docket_no": "3213213"
  }
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Shipment scanned successfully as Hub In",
  "data": {
    "shipment_id": "990831778839479",
    "docket_no": "3213213"
  }
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{
  "shipment_id": "990831778839479",
  "docket_no": "3213213"
}
```

### Inferred schema notes (from this capture only)

- **`data` is an object** with keys: `docket_no`, `shipment_id`.

---

## 2. Get Hub Scan Logs (`gethubscanlogs`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `branch_id` | string | Branch filter |
| `limit` | int | Max rows (sent as string in query) |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Hub scan logs retrieved",
  "data": [
    {
      "id": "220",
      "shipment_id": "149311778836750",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-15 15:12:11",
      "created_at": "2026-05-15 15:12:11",
      "updated_at": "2026-05-15 15:12:11",
      "box_no": "1",
      "shipment_invoice_no": "123654987"
    },
    {
      "id": "217",
      "shipment_id": "445681778769763",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "SGL033"
    },
    {
      "id": "211",
      "shipment_id": "872991778765685",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "RDLD/009/26-27"
    },
    {
      "id": "216",
      "shipment_id": "338481778769798",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "AG/26-27/035"
    },
    {
      "id": "218",
      "shipment_id": "236861778770022",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "BSH92/2627/52"
    },
    {
      "id": "212",
      "shipment_id": "547181778759592",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "DCS/26-27/002"
    },
    {
      "id": "215",
      "shipment_id": "700971778766947",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "MOPL/15/26-27"
    },
    {
      "id": "213",
      "shipment_id": "670281778764166",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "5"
    },
    {
      "id": "219",
      "shipment_id": "435171778773315",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "D NOTE/2026-27/87"
    },
    {
      "id": "214",
      "shipment_id": "381661778765466",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "IV/2026-27/027"
    },
    {
      "id": "208",
      "shipment_id": "638031778765858",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:40:05",
      "created_at": "2026-05-14 21:40:05",
      "updated_at": "2026-05-14 21:40:05",
      "box_no": "1",
      "shipment_invoice_no": "PR/003/26-27"
    },
    {
      "id": "207",
      "shipment_id": "666751778759202",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:40:05",
      "created_at": "2026-05-14 21:40:05",
      "updated_at": "2026-05-14 21:40:05",
      "box_no": "1",
      "shipment_invoice_no": "IRD/37"
    },
    {
      "id": "206",
      "shipment_id": "215781778766478",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:40:05",
      "created_at": "2026-05-14 21:40:05",
      "updated_at": "2026-05-14 21:40:05",
      "box_no": "1",
      "shipment_invoice_no": "26-27/SV/87"
    },
    {
      "id": "209",
      "shipment_id": "340191778773190",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:40:05",
      "created_at": "2026-05-14 21:40:05",
      "updated_at": "2026-05-14 21:40:05",
      "box_no": "1",
      "shipment_invoice_no": "D NOTE/2026-27/88"
    },
    {
      "id": "210",
      "shipment_id": "800191778769475",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:40:05",
      "created_at": "2026-05-14 21:40:05",
      "updated_at": "2026-05-14 21:40:05",
      "box_no": "1",
      "shipment_invoice_no": "SGL035"
    },
    {
      "id": "192",
      "shipment_id": "258181778677083",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-13 22:03:14",
      "created_at": "2026-05-13 22:03:14",
      "updated_at": "2026-05-13 22:03:14",
      "box_no": "1",
      "shipment_invoice_no": "CC/JW/26-27/4"
    },
    {
      "id": "186",
      "shipment_id": "767841778675611",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-13 21:59:45",
      "created_at": "2026-05-13 21:59:45",
      "updated_at": "2026-05-13 21:59:45",
      "box_no": "1",
      "shipment_invoice_no": "2025-26/03"
    },
    {
      "id": "191",
      "shipment_id": "416131778687588",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-13 21:59:45",
      "created_at": "2026-05-13 21:59:45",
      "updated_at": "2026-05-13 21:59:45",
      "box_no": "1",
      "shipment_invoice_no": "SG-245"
    },
    {
      "id": "187",
      "shipment_id": "386291778681343",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-13 21:59:45",
      "created_at": "2026-05-13 21:59:45",
      "updated_at": "2026-05-13 21:59:45",
      "box_no": "1",
      "shipment_invoice_no": "GST/2026-27/024"
    },
    {
      "id": "183",
      "shipment_id": "721271778674007",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-13 21:59:45",
      "created_at": "2026-05-13 21:59:45",
      "updated_at": "2026-05-13 21:59:45",
      "box_no": "1",
      "shipment_invoice_no": "HGJ-012/26-27"
    },
    {
      "id": "188",
      "shipment_id": "225011778682993",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-13 21:59:45",
      "created_at": "2026-05-13 21:59:45",
      "updated_at": "2026-05-13 21:59:45",
      "box_no": "1",
      "shipment_invoice_no": "BSH92/26-27/49"
    },
    {
      "id": "184",
      "shipment_id": "721271778674007",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-13 21:59:45",
      "created_at": "2026-05-13 21:59:45",
      "updated_at": "2026-05-13 21:59:45",
      "box_no": "2",
      "shipment_invoice_no": "HGJ-012/26-27"
    },
    {
      "id": "189",
      "shipment_id": "933581778683486",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-13 21:59:45",
      "created_at": "2026-05-13 21:59:45",
      "updated_at": "2026-05-13 21:59:45",
      "box_no": "1",
      "shipment_invoice_no": "SRKJB/26-27/126"
    },
    {
      "id": "185",
      "shipment_id": "450841778674298",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-13 21:59:45",
      "created_at": "2026-05-13 21:59:45",
      "updated_at": "2026-05-13 21:59:45",
      "box_no": "1",
      "shipment_invoice_no": "VSRJY/013/26-27/"
    },
    {
      "id": "190",
      "shipment_id": "135801778685021",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-13 21:59:45",
      "created_at": "2026-05-13 21:59:45",
      "updated_at": "2026-05-13 21:59:45",
      "box_no": "1",
      "shipment_invoice_no": "D NOTE/2026-27/85"
    },
    {
      "id": "170",
      "shipment_id": "523141778588996",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "4",
      "shipment_invoice_no": "DC -56"
    },
    {
      "id": "165",
      "shipment_id": "417651778581554",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "PR/26-27/5"
    },
    {
      "id": "174",
      "shipment_id": "723111778593508",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "GC/2026-27/023"
    },
    {
      "id": "172",
      "shipment_id": "982311778589762",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "6"
    },
    {
      "id": "163",
      "shipment_id": "299701778583072",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "VSR/005/26-27"
    },
    {
      "id": "175",
      "shipment_id": "985051778593737",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "SRKJ/26-27/130"
    },
    {
      "id": "171",
      "shipment_id": "742361778590521",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "2"
    },
    {
      "id": "167",
      "shipment_id": "523141778588996",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "DC -56"
    },
    {
      "id": "164",
      "shipment_id": "130811778583251",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "VSRJY/012/26-27"
    },
    {
      "id": "173",
      "shipment_id": "783091778594794",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "MOPL/14/26-27"
    },
    {
      "id": "166",
      "shipment_id": "662101778591725",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "IV/2026-27/024"
    },
    {
      "id": "168",
      "shipment_id": "523141778588996",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "2",
      "shipment_invoice_no": "DC -56"
    },
    {
      "id": "161",
      "shipment_id": "720931778586497",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "IV/2026-27/022"
    },
    {
      "id": "176",
      "shipment_id": "384581778598608",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "26-27/22"
    },
    {
      "id": "177",
      "shipment_id": "555131778592266",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "REF-13-12/P3"
    },
    {
      "id": "169",
      "shipment_id": "523141778588996",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "3",
      "shipment_invoice_no": "DC -56"
    },
    {
      "id": "179",
      "shipment_id": "372801778598930",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "D NOTE/2026-27/84"
    },
    {
      "id": "162",
      "shipment_id": "846541778586732",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "IV/2026-27/023"
    },
    {
      "id": "178",
      "shipment_id": "744211778592890",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:06:55",
      "created_at": "2026-05-12 22:06:55",
      "updated_at": "2026-05-12 22:06:55",
      "box_no": "1",
      "shipment_invoice_no": "21,20"
    },
    {
      "id": "159",
      "shipment_id": "488261778599075",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:02:02",
      "created_at": "2026-05-12 22:02:02",
      "updated_at": "2026-05-12 22:02:02",
      "box_no": "1",
      "shipment_invoice_no": "D NOTE/2026-27/82"
    },
    {
      "id": "157",
      "shipment_id": "864131778587269",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:02:02",
      "created_at": "2026-05-12 22:02:02",
      "updated_at": "2026-05-12 22:02:02",
      "box_no": "1",
      "shipment_invoice_no": "IRD/35"
    },
    {
      "id": "160",
      "shipment_id": "231571778599224",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:02:02",
      "created_at": "2026-05-12 22:02:02",
      "updated_at": "2026-05-12 22:02:02",
      "box_no": "1",
      "shipment_invoice_no": "D NOTE/2026-27/83"
    },
    {
      "id": "156",
      "shipment_id": "922661778587457",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:02:02",
      "created_at": "2026-05-12 22:02:02",
      "updated_at": "2026-05-12 22:02:02",
      "box_no": "1",
      "shipment_invoice_no": "IRD/34"
    },
    {
      "id": "158",
      "shipment_id": "770001778579162",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-12 22:02:02",
      "created_at": "2026-05-12 22:02:02",
      "updated_at": "2026-05-12 22:02:02",
      "box_no": "1",
      "shipment_invoice_no": "MBTIDL/000126-27"
    },
    {
      "id": "137",
      "shipment_id": "126441778333753",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-10 21:43:11",
      "created_at": "2026-05-10 21:43:11",
      "updated_at": "2026-05-10 21:43:11",
      "box_no": "1",
      "shipment_invoice_no": "425"
    }
  ]
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Hub scan logs retrieved",
  "data": [
    {
      "id": "220",
      "shipment_id": "149311778836750",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-15 15:12:11",
      "created_at": "2026-05-15 15:12:11",
      "updated_at": "2026-05-15 15:12:11",
      "box_no": "1",
      "shipment_invoice_no": "123654987"
    },
    {
      "id": "217",
      "shipment_id": "445681778769763",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "SGL033"
    },
    {
      "id": "211",
      "shipment_id": "872991778765685",
      "scan_type": "IN",
      "branch_id": "27",
      "scanned_at": "2026-05-14 21:43:44",
      "created_at": "2026-05-14 21:43:44",
      "updated_at": "2026-05-14 21:43:44",
      "box_no": "1",
      "shipment_invoice_no": "RDLD/009/26-27"
    },
    "... (47 more items omitted)"
  ]
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
[
  {
    "id": "220",
    "shipment_id": "149311778836750",
    "scan_type": "IN",
    "branch_id": "27",
    "scanned_at": "2026-05-15 15:12:11",
    "created_at": "2026-05-15 15:12:11",
    "updated_at": "2026-05-15 15:12:11",
    "box_no": "1",
    "shipment_invoice_no": "123654987"
  },
  {
    "id": "217",
    "shipment_id": "445681778769763",
    "scan_type": "IN",
    "branch_id": "27",
    "scanned_at": "2026-05-14 21:43:44",
    "created_at": "2026-05-14 21:43:44",
    "updated_at": "2026-05-14 21:43:44",
    "box_no": "1",
    "shipment_invoice_no": "SGL033"
  },
  {
    "id": "211",
    "shipment_id": "872991778765685",
    "scan_type": "IN",
    "branch_id": "27",
    "scanned_at": "2026-05-14 21:43:44",
    "created_at": "2026-05-14 21:43:44",
    "updated_at": "2026-05-14 21:43:44",
    "box_no": "1",
    "shipment_invoice_no": "RDLD/009/26-27"
  },
  "... (47 more items omitted)"
]
```

### Inferred schema notes (from this capture only)

- **`data` is a list** of objects with keys (first row): `box_no`, `branch_id`, `created_at`, `id`, `scan_type`, `scanned_at`, `shipment_id`, `shipment_invoice_no`, `updated_at`.

---

## 3. Get Shipment Scan History (`getshipmentscanhistory`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `docket_no` | string | Docket to load timeline for |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Shipment scan history retrieved",
  "data": [
    {
      "id": "1946273",
      "s_id": "990831778839479",
      "status": "Hub In",
      "is_exception": "0",
      "branch_id": "27",
      "created_by": "143",
      "u_type": null,
      "remark": "",
      "created_date": "2026-05-15 16:15:57",
      "modified_date": "2026-05-15 16:15:57",
      "sequence_no": "0",
      "is_negative": "0",
      "negative_remark": null,
      "receiver_name": null
    },
    {
      "id": "1946197",
      "s_id": "990831778839479",
      "status": "Pending",
      "is_exception": "0",
      "branch_id": null,
      "created_by": "81",
      "u_type": null,
      "remark": "",
      "created_date": "2026-05-15 15:34:39",
      "modified_date": "2026-05-15 15:34:39",
      "sequence_no": "1",
      "is_negative": "0",
      "negative_remark": null,
      "receiver_name": null
    },
    {
      "id": "1946212",
      "s_id": "990831778839479",
      "status": "Hub In",
      "is_exception": "0",
      "branch_id": "75",
      "created_by": null,
      "u_type": null,
      "remark": "",
      "created_date": "2026-05-15 00:00:00",
      "modified_date": "2026-05-15 00:00:00",
      "sequence_no": "0",
      "is_negative": "0",
      "negative_remark": null,
      "receiver_name": null
    },
    {
      "id": "1946218",
      "s_id": "990831778839479",
      "status": "Bagged",
      "is_exception": "0",
      "branch_id": "75",
      "created_by": null,
      "u_type": null,
      "remark": "",
      "created_date": "2026-05-15 00:00:00",
      "modified_date": "2026-05-15 00:00:00",
      "sequence_no": "0",
      "is_negative": "0",
      "negative_remark": null,
      "receiver_name": null
    },
    {
      "id": "1946231",
      "s_id": "990831778839479",
      "status": "Manifest Created",
      "is_exception": "0",
      "branch_id": "75",
      "created_by": null,
      "u_type": null,
      "remark": "",
      "created_date": "2026-05-15 00:00:00",
      "modified_date": "2026-05-15 00:00:00",
      "sequence_no": "0",
      "is_negative": "0",
      "negative_remark": null,
      "receiver_name": null
    },
    {
      "id": "1946235",
      "s_id": "990831778839479",
      "status": "Linehaul Dispatched",
      "is_exception": "0",
      "branch_id": "75",
      "created_by": null,
      "u_type": null,
      "remark": "",
      "created_date": "2026-05-15 00:00:00",
      "modified_date": "2026-05-15 00:00:00",
      "sequence_no": "0",
      "is_negative": "0",
      "negative_remark": null,
      "receiver_name": null
    },
    {
      "id": "1946237",
      "s_id": "990831778839479",
      "status": "Hub in",
      "is_exception": "0",
      "branch_id": "2",
      "created_by": null,
      "u_type": null,
      "remark": "",
      "created_date": "2026-05-15 00:00:00",
      "modified_date": "2026-05-15 00:00:00",
      "sequence_no": "0",
      "is_negative": "0",
      "negative_remark": null,
      "receiver_name": null
    }
  ]
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Shipment scan history retrieved",
  "data": [
    {
      "id": "1946273",
      "s_id": "990831778839479",
      "status": "Hub In",
      "is_exception": "0",
      "branch_id": "27",
      "created_by": "143",
      "u_type": null,
      "remark": "",
      "created_date": "2026-05-15 16:15:57",
      "modified_date": "2026-05-15 16:15:57",
      "sequence_no": "0",
      "is_negative": "0",
      "negative_remark": null,
      "receiver_name": null
    },
    {
      "id": "1946197",
      "s_id": "990831778839479",
      "status": "Pending",
      "is_exception": "0",
      "branch_id": null,
      "created_by": "81",
      "u_type": null,
      "remark": "",
      "created_date": "2026-05-15 15:34:39",
      "modified_date": "2026-05-15 15:34:39",
      "sequence_no": "1",
      "is_negative": "0",
      "negative_remark": null,
      "receiver_name": null
    },
    {
      "id": "1946212",
      "s_id": "990831778839479",
      "status": "Hub In",
      "is_exception": "0",
      "branch_id": "75",
      "created_by": null,
      "u_type": null,
      "remark": "",
      "created_date": "2026-05-15 00:00:00",
      "modified_date": "2026-05-15 00:00:00",
      "sequence_no": "0",
      "is_negative": "0",
      "negative_remark": null,
      "receiver_name": null
    },
    "... (4 more items omitted)"
  ]
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
[
  {
    "id": "1946273",
    "s_id": "990831778839479",
    "status": "Hub In",
    "is_exception": "0",
    "branch_id": "27",
    "created_by": "143",
    "u_type": null,
    "remark": "",
    "created_date": "2026-05-15 16:15:57",
    "modified_date": "2026-05-15 16:15:57",
    "sequence_no": "0",
    "is_negative": "0",
    "negative_remark": null,
    "receiver_name": null
  },
  {
    "id": "1946197",
    "s_id": "990831778839479",
    "status": "Pending",
    "is_exception": "0",
    "branch_id": null,
    "created_by": "81",
    "u_type": null,
    "remark": "",
    "created_date": "2026-05-15 15:34:39",
    "modified_date": "2026-05-15 15:34:39",
    "sequence_no": "1",
    "is_negative": "0",
    "negative_remark": null,
    "receiver_name": null
  },
  {
    "id": "1946212",
    "s_id": "990831778839479",
    "status": "Hub In",
    "is_exception": "0",
    "branch_id": "75",
    "created_by": null,
    "u_type": null,
    "remark": "",
    "created_date": "2026-05-15 00:00:00",
    "modified_date": "2026-05-15 00:00:00",
    "sequence_no": "0",
    "is_negative": "0",
    "negative_remark": null,
    "receiver_name": null
  },
  "... (4 more items omitted)"
]
```

### Inferred schema notes (from this capture only)

- **`data` is a list** of objects with keys (first row): `branch_id`, `created_by`, `created_date`, `id`, `is_exception`, `is_negative`, `modified_date`, `negative_remark`, `receiver_name`, `remark`, `s_id`, `sequence_no`, `status`, `u_type`.

---

## 4. Create Bag (`createbag`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `origin_branch_id` | string |  |
| `destination_branch_id` | string |  |
| `bag_code` | string |  |
| `user_id` | string |  |
| `platform` | string | ios/android |

### Capture status

**Skipped:** Skipped by default (OUTBOUND_SKIP_CREATEBAG=1). The live createbag endpoint often returns status success with bag_id 0 even for invalid or incomplete payloads, so HTTP capture is misleading. Set OUTBOUND_SKIP_CREATEBAG=0 to record the real response body.

---

## 5. Add Shipment To Bag (`addshipmenttobag`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `bag_id` | string |  |
| `docket_no` | string |  |
| `branch_id` | string |  |
| `user_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Bag ID and Docket Number required",
  "data": {},
  "error_code": 400
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Bag ID and Docket Number required",
  "data": {},
  "error_code": 400
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 6. Get Bag Details (`getbagdetails`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `bag_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Bag ID required",
  "data": {},
  "error_code": 400
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Bag ID required",
  "data": {},
  "error_code": 400
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 7. List Bags (`listbags`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `branch_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Bags retrieved",
  "data": {}
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Bags retrieved",
  "data": {}
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **`data` is an empty object `{}` in this capture.** For list endpoints, retry with a valid Bearer token and ids from your environment — empty `{}` often means “no rows” or unauthenticated list.

---

## 8. Remove Shipment From Bag (`removeshipmentfrombag`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `bag_id` | string |  |
| `docket_no` | string |  |
| `branch_id` | string |  |
| `user_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Bag ID and Docket Number required",
  "data": {},
  "error_code": 400
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Bag ID and Docket Number required",
  "data": {},
  "error_code": 400
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 9. Lock Bag (`lockbag`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `bag_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Bag ID required",
  "data": {},
  "error_code": 400
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Bag ID required",
  "data": {},
  "error_code": 400
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 10. Rebag Shipment (`rebagshipment`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `new_bag_id` | string |  |
| `docket_no` | string |  |
| `user_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "New Bag ID and Docket Number required",
  "data": {},
  "error_code": 400
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "New Bag ID and Docket Number required",
  "data": {},
  "error_code": 400
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 11. Bagging Report (`baggingreport`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `start_date` | string | YYYY-MM-DD |
| `end_date` | string | YYYY-MM-DD |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Bagging report generated",
  "data": {}
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Bagging report generated",
  "data": {}
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **`data` is an empty object `{}` in this capture.** For list endpoints, retry with a valid Bearer token and ids from your environment — empty `{}` often means “no rows” or unauthenticated list.

---

## 12. Create Manifest (`createmanifest`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `bag_ids` | string | Comma-separated bag ids |
| `origin_branch_id` | string |  |
| `destination_branch_id` | string |  |
| `user_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Invalid Bag IDs format",
  "data": {},
  "error_code": 400
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Invalid Bag IDs format",
  "data": {},
  "error_code": 400
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 13. Get Manifest Details (`getmanifestdetails`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `manifest_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Manifest ID required",
  "data": {},
  "error_code": 400
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Manifest ID required",
  "data": {},
  "error_code": 400
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 14. List Manifests (`listmanifests`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `branch_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Manifests retrieved",
  "data": {}
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Manifests retrieved",
  "data": {}
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **`data` is an empty object `{}` in this capture.** For list endpoints, retry with a valid Bearer token and ids from your environment — empty `{}` often means “no rows” or unauthenticated list.

---

## 15. Manifest Report (`manifestreport`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `start_date` | string | YYYY-MM-DD |
| `end_date` | string | YYYY-MM-DD |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Manifest report generated",
  "data": {}
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Manifest report generated",
  "data": {}
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **`data` is an empty object `{}` in this capture.** For list endpoints, retry with a valid Bearer token and ids from your environment — empty `{}` often means “no rows” or unauthenticated list.

---

## 16. Print Manifest Data (`printmanifestdata`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `manifest_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Manifest ID required",
  "data": {},
  "error_code": 400
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Manifest ID required",
  "data": {},
  "error_code": 400
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 17. Assign Linehaul (`assignlinehaul`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `manifest_ids` | string | Comma-separated manifest ids |
| `vehicle_no` | string |  |
| `driver_name` | string |  |
| `user_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Linehaul assigned",
  "data": {
    "linehaul_id": 0,
    "trip_no": "LH1778841961"
  }
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Linehaul assigned",
  "data": {
    "linehaul_id": 0,
    "trip_no": "LH1778841961"
  }
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{
  "linehaul_id": 0,
  "trip_no": "LH1778841961"
}
```

### Inferred schema notes (from this capture only)

- **`data` is an object** with keys: `linehaul_id`, `trip_no`.

---

## 18. List Linehauls (`listlinehauls`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `status` | string | e.g. `In Transit` |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Linehauls retrieved",
  "data": {}
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Linehauls retrieved",
  "data": {}
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **`data` is an empty object `{}` in this capture.** For list endpoints, retry with a valid Bearer token and ids from your environment — empty `{}` often means “no rows” or unauthenticated list.

---

## 19. Get Linehaul Details (`getlinehauldetails`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `linehaul_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Linehaul ID required",
  "data": {},
  "error_code": 400
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Linehaul ID required",
  "data": {},
  "error_code": 400
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 20. Update Linehaul Status (`updatelinehaulstatus`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `linehaul_id` | string |  |
| `status` | string | e.g. `ARRIVED` |
| `user_id` | string |  |
| `branch_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Linehaul ID and Status required",
  "data": {},
  "error_code": 400
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Linehaul ID and Status required",
  "data": {},
  "error_code": 400
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 21. Linehaul Report (`linehaulreport`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `start_date` | string | YYYY-MM-DD |
| `end_date` | string | YYYY-MM-DD |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Linehaul report generated",
  "data": {}
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Linehaul report generated",
  "data": {}
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **`data` is an empty object `{}` in this capture.** For list endpoints, retry with a valid Bearer token and ids from your environment — empty `{}` often means “no rows” or unauthenticated list.

---

## 22. Sector Pickup Scan (`sectorpickupscan`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `pickup_id` | string |  |
| `docket_no` | string |  |
| `status` | string | e.g. `Picked` |
| `remarks` | string |  |
| `user_id` | string |  |
| `branch_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Shipment already scanned for this pickup",
  "data": {},
  "error_code": 422
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Shipment already scanned for this pickup",
  "data": {},
  "error_code": 422
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 23. Get Pickup List (`getpickuplist`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `platform` | string | ios/android only (no other params in Flutter client) |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Pickup list retrieved",
  "data": [
    {
      "id": "122",
      "mawb_no": "mum4321",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "15:49:00",
      "created_at": "2026-05-15 15:50:04",
      "updated_at": "2026-05-15 15:50:04"
    },
    {
      "id": "121",
      "mawb_no": "awb1234",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "15:20:00",
      "created_at": "2026-05-15 15:20:32",
      "updated_at": "2026-05-15 15:20:34"
    },
    {
      "id": "120",
      "mawb_no": "0001",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "14:41:00",
      "created_at": "2026-05-15 14:43:04",
      "updated_at": "2026-05-15 14:43:04"
    },
    {
      "id": "119",
      "mawb_no": "MH02FG43141778772483",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "15:34:00",
      "created_at": "2026-05-15 12:42:22",
      "updated_at": "2026-05-15 15:34:05"
    },
    {
      "id": "118",
      "mawb_no": "31227879541",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "14:45:00",
      "created_at": "2026-05-15 12:39:51",
      "updated_at": "2026-05-15 14:45:12"
    },
    {
      "id": "117",
      "mawb_no": "09805370654",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "13:53:00",
      "created_at": "2026-05-15 12:37:53",
      "updated_at": "2026-05-15 13:56:23"
    },
    {
      "id": "116",
      "mawb_no": "31227937291",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "15:47:00",
      "created_at": "2026-05-15 12:10:29",
      "updated_at": "2026-05-15 15:48:07"
    },
    {
      "id": "115",
      "mawb_no": "31227935456",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "12:37:00",
      "created_at": "2026-05-15 11:55:56",
      "updated_at": "2026-05-15 12:41:33"
    },
    {
      "id": "114",
      "mawb_no": "312-27932376",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "12:42:00",
      "created_at": "2026-05-15 11:54:26",
      "updated_at": "2026-05-15 12:43:43"
    },
    {
      "id": "113",
      "mawb_no": "27935504",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "12:45:00",
      "created_at": "2026-05-15 11:53:52",
      "updated_at": "2026-05-15 12:45:45"
    },
    {
      "id": "112",
      "mawb_no": "31227881921",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "13:31:00",
      "created_at": "2026-05-15 11:50:24",
      "updated_at": "2026-05-15 13:32:15"
    },
    {
      "id": "111",
      "mawb_no": "09803808420",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "12:37:00",
      "created_at": "2026-05-15 11:44:45",
      "updated_at": "2026-05-15 12:40:55"
    },
    {
      "id": "110",
      "mawb_no": ":312-27943285",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "12:37:00",
      "created_at": "2026-05-15 11:43:43",
      "updated_at": "2026-05-15 12:40:15"
    },
    {
      "id": "109",
      "mawb_no": "09805749321",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "10:10:00",
      "created_at": "2026-05-15 10:10:48",
      "updated_at": "2026-05-15 10:10:48"
    },
    {
      "id": "108",
      "mawb_no": "up0461111778757102",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-14",
      "pickup_time": "16:41:00",
      "created_at": "2026-05-14 16:42:02",
      "updated_at": "2026-05-14 16:42:02"
    },
    {
      "id": "107",
      "mawb_no": "09804579886",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-14",
      "pickup_time": "16:01:00",
      "created_at": "2026-05-14 16:01:23",
      "updated_at": "2026-05-14 16:01:23"
    },
    {
      "id": "106",
      "mawb_no": "098-05173324",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-14",
      "pickup_time": "12:25:00",
      "created_at": "2026-05-14 12:25:18",
      "updated_at": "2026-05-14 12:25:18"
    },
    {
      "id": "105",
      "mawb_no": "312-27875621",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-14",
      "pickup_time": "12:15:00",
      "created_at": "2026-05-14 12:15:13",
      "updated_at": "2026-05-14 12:15:13"
    },
    {
      "id": "104",
      "mawb_no": "MH02FG43141778686644",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-14",
      "pickup_time": "13:38:00",
      "created_at": "2026-05-14 12:08:47",
      "updated_at": "2026-05-14 13:38:55"
    },
    {
      "id": "103",
      "mawb_no": "31227874663",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-14",
      "pickup_time": "17:06:00",
      "created_at": "2026-05-14 12:05:22",
      "updated_at": "2026-05-14 17:06:27"
    },
    {
      "id": "102",
      "mawb_no": "31227877776",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-14",
      "pickup_time": "13:38:00",
      "created_at": "2026-05-14 12:04:35",
      "updated_at": "2026-05-14 13:38:09"
    },
    {
      "id": "101",
      "mawb_no": "AWB23389",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-13",
      "pickup_time": "17:25:00",
      "created_at": "2026-05-13 17:25:40",
      "updated_at": "2026-05-13 17:25:40"
    },
    {
      "id": "98",
      "mawb_no": "27807150",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-13",
      "pickup_time": "12:31:00",
      "created_at": "2026-05-13 12:26:27",
      "updated_at": "2026-05-13 12:31:57"
    },
    {
      "id": "97",
      "mawb_no": "31227811781",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-13",
      "pickup_time": "12:32:00",
      "created_at": "2026-05-13 12:25:05",
      "updated_at": "2026-05-13 12:32:49"
    },
    {
      "id": "96",
      "mawb_no": "312-27816106",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-13",
      "pickup_time": "13:47:00",
      "created_at": "2026-05-13 12:24:43",
      "updated_at": "2026-05-13 13:47:39"
    },
    {
      "id": "95",
      "mawb_no": "31227817705",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-13",
      "pickup_time": "13:57:00",
      "created_at": "2026-05-13 12:17:17",
      "updated_at": "2026-05-13 13:57:55"
    },
    {
      "id": "94",
      "mawb_no": "MH02FG43141778598912",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-13",
      "pickup_time": "12:31:00",
      "created_at": "2026-05-13 11:00:08",
      "updated_at": "2026-05-13 12:32:17"
    },
    {
      "id": "93",
      "mawb_no": "000",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-13",
      "pickup_time": "10:05:00",
      "created_at": "2026-05-13 10:06:07",
      "updated_at": "2026-05-13 10:06:44"
    },
    {
      "id": "92",
      "mawb_no": "11052026",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-12",
      "pickup_time": "12:52:00",
      "created_at": "2026-05-12 12:52:38",
      "updated_at": "2026-05-12 12:52:38"
    },
    {
      "id": "91",
      "mawb_no": "31227752734",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-13",
      "pickup_time": "12:17:00",
      "created_at": "2026-05-12 12:09:04",
      "updated_at": "2026-05-13 12:28:36"
    },
    {
      "id": "90",
      "mawb_no": "31227748276",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-12",
      "pickup_time": "12:52:00",
      "created_at": "2026-05-12 12:07:58",
      "updated_at": "2026-05-12 12:56:03"
    },
    {
      "id": "89",
      "mawb_no": "312-27755442",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-12",
      "pickup_time": "12:52:00",
      "created_at": "2026-05-12 11:56:15",
      "updated_at": "2026-05-12 12:55:40"
    },
    {
      "id": "88",
      "mawb_no": "27756142",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-13",
      "pickup_time": "12:33:00",
      "created_at": "2026-05-12 11:41:48",
      "updated_at": "2026-05-13 12:33:30"
    },
    {
      "id": "87",
      "mawb_no": "MH02FG43141778511581",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-12",
      "pickup_time": "12:52:00",
      "created_at": "2026-05-12 10:56:54",
      "updated_at": "2026-05-12 12:56:50"
    },
    {
      "id": "86",
      "mawb_no": "09052026",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-13",
      "pickup_time": "15:53:00",
      "created_at": "2026-05-11 15:58:10",
      "updated_at": "2026-05-13 15:53:19"
    },
    {
      "id": "85",
      "mawb_no": "10052026",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-11",
      "pickup_time": "16:47:00",
      "created_at": "2026-05-11 12:53:39",
      "updated_at": "2026-05-11 16:48:06"
    },
    {
      "id": "84",
      "mawb_no": "312-27672131",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-11",
      "pickup_time": "12:36:00",
      "created_at": "2026-05-11 12:33:29",
      "updated_at": "2026-05-11 12:36:38"
    },
    {
      "id": "83",
      "mawb_no": "312-27671733",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-11",
      "pickup_time": "12:19:00",
      "created_at": "2026-05-11 12:09:53",
      "updated_at": "2026-05-11 12:20:25"
    },
    {
      "id": "82",
      "mawb_no": "31227671582",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-11",
      "pickup_time": "12:19:00",
      "created_at": "2026-05-11 12:08:58",
      "updated_at": "2026-05-11 12:22:35"
    },
    {
      "id": "81",
      "mawb_no": "09804802033",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-11",
      "pickup_time": "12:19:00",
      "created_at": "2026-05-11 11:33:45",
      "updated_at": "2026-05-11 12:19:49"
    },
    {
      "id": "80",
      "mawb_no": "MH02FG43141778338146",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-11",
      "pickup_time": "12:19:00",
      "created_at": "2026-05-11 11:06:23",
      "updated_at": "2026-05-11 12:23:01"
    },
    {
      "id": "79",
      "mawb_no": "0001778429718",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-11",
      "pickup_time": "12:51:00",
      "created_at": "2026-05-11 11:03:21",
      "updated_at": "2026-05-11 12:51:45"
    },
    {
      "id": "78",
      "mawb_no": "312-27620294",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-09",
      "pickup_time": "14:04:00",
      "created_at": "2026-05-09 12:28:39",
      "updated_at": "2026-05-09 14:04:37"
    },
    {
      "id": "77",
      "mawb_no": "31227622420",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-11",
      "pickup_time": "12:19:00",
      "created_at": "2026-05-09 12:27:29",
      "updated_at": "2026-05-11 12:23:56"
    },
    {
      "id": "76",
      "mawb_no": "31227619292",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-09",
      "pickup_time": "14:01:00",
      "created_at": "2026-05-09 12:00:04",
      "updated_at": "2026-05-09 14:01:09"
    },
    {
      "id": "75",
      "mawb_no": "312-27610682",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-09",
      "pickup_time": "18:54:00",
      "created_at": "2026-05-09 11:50:10",
      "updated_at": "2026-05-09 18:54:58"
    },
    {
      "id": "74",
      "mawb_no": "31227610295",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-09",
      "pickup_time": "14:03:00",
      "created_at": "2026-05-09 11:49:30",
      "updated_at": "2026-05-09 14:03:57"
    },
    {
      "id": "73",
      "mawb_no": "27616131",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-09",
      "pickup_time": "12:30:00",
      "created_at": "2026-05-09 11:48:38",
      "updated_at": "2026-05-09 12:31:12"
    },
    {
      "id": "72",
      "mawb_no": "312-00000000",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-09",
      "pickup_time": "11:03:00",
      "created_at": "2026-05-09 11:03:56",
      "updated_at": "2026-05-09 11:03:56"
    },
    {
      "id": "71",
      "mawb_no": "DEL TO LKO",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-09",
      "pickup_time": "14:01:00",
      "created_at": "2026-05-09 11:02:00",
      "updated_at": "2026-05-09 14:01:34"
    }
  ]
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Pickup list retrieved",
  "data": [
    {
      "id": "122",
      "mawb_no": "mum4321",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "15:49:00",
      "created_at": "2026-05-15 15:50:04",
      "updated_at": "2026-05-15 15:50:04"
    },
    {
      "id": "121",
      "mawb_no": "awb1234",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "15:20:00",
      "created_at": "2026-05-15 15:20:32",
      "updated_at": "2026-05-15 15:20:34"
    },
    {
      "id": "120",
      "mawb_no": "0001",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-05-15",
      "pickup_time": "14:41:00",
      "created_at": "2026-05-15 14:43:04",
      "updated_at": "2026-05-15 14:43:04"
    },
    "... (47 more items omitted)"
  ]
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
[
  {
    "id": "122",
    "mawb_no": "mum4321",
    "hub_id": "1",
    "picked_by": null,
    "pickup_date": "2026-05-15",
    "pickup_time": "15:49:00",
    "created_at": "2026-05-15 15:50:04",
    "updated_at": "2026-05-15 15:50:04"
  },
  {
    "id": "121",
    "mawb_no": "awb1234",
    "hub_id": "1",
    "picked_by": null,
    "pickup_date": "2026-05-15",
    "pickup_time": "15:20:00",
    "created_at": "2026-05-15 15:20:32",
    "updated_at": "2026-05-15 15:20:34"
  },
  {
    "id": "120",
    "mawb_no": "0001",
    "hub_id": "1",
    "picked_by": null,
    "pickup_date": "2026-05-15",
    "pickup_time": "14:41:00",
    "created_at": "2026-05-15 14:43:04",
    "updated_at": "2026-05-15 14:43:04"
  },
  "... (47 more items omitted)"
]
```

### Inferred schema notes (from this capture only)

- **`data` is a list** of objects with keys (first row): `created_at`, `hub_id`, `id`, `mawb_no`, `picked_by`, `pickup_date`, `pickup_time`, `updated_at`.

---

## 24. Mark Not Picked (`marknotpicked`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `pickup_id` | string |  |
| `docket_no` | string |  |
| `remarks` | string |  |
| `user_id` | string |  |
| `branch_id` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "fail",
  "message": "Shipment already scanned for this pickup",
  "data": {},
  "error_code": 422
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "fail",
  "message": "Shipment already scanned for this pickup",
  "data": {},
  "error_code": 422
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **Failure response:** use `message` and `error_code` for UX; `data` is usually `{}`.

---

## 25. Add Missed Shipment (`addmissedshipment`)

- **HTTP:** `POST`
- **Parameter transport:** URL-encoded body
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `pickup_id` | string |  |
| `docket_no` | string |  |
| `remarks` | string |  |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Missed shipment added",
  "data": {}
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Missed shipment added",
  "data": {}
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
{}
```

### Inferred schema notes (from this capture only)

- **`data` is an empty object `{}` in this capture.** For list endpoints, retry with a valid Bearer token and ids from your environment — empty `{}` often means “no rows” or unauthenticated list.

---

## 26. Pickup Report (`pickupreport`)

- **HTTP:** `GET`
- **Parameter transport:** Query
- **Auth header:** `Authorization: Bearer <token>` (same as rest of app)

### Request parameters (Flutter / server field names)

| Field | Type | Notes |
|-------|------|-------|
| `start_date` | string | YYYY-MM-DD |
| `end_date` | string | YYYY-MM-DD |
| `platform` | string | ios/android |

### Observed response — full `raw_body` (exact JSON text returned on wire)

```json
{
  "status": "success",
  "message": "Pickup report generated",
  "data": [
    {
      "status": "Picked",
      "count": "885"
    },
    {
      "status": "Missed",
      "count": "2"
    }
  ]
}
```

### Abbreviated `parsed_body` (long `data` arrays truncated for this doc)

```json
{
  "status": "success",
  "message": "Pickup report generated",
  "data": [
    {
      "status": "Picked",
      "count": "885"
    },
    {
      "status": "Missed",
      "count": "2"
    }
  ]
}
```

### Inner `data` after unwrap (what `APIResponse.success` receives)

```json
[
  {
    "status": "Picked",
    "count": "885"
  },
  {
    "status": "Missed",
    "count": "2"
  }
]
```

### Inferred schema notes (from this capture only)

- **`data` is a list** of objects with keys (first row): `count`, `status`.

---

## Appendix — `createbag` and `bag_id: 0`

Section **4. Create Bag** includes the live capture when `OUTBOUND_SKIP_CREATEBAG=0`. **Known server behaviour:** the test account often receives **`status: success`** with **`bag_id: 0`** — Flutter treats `bag_id <= 0` as failure until backend fixes validation. Re-capture with `OUTBOUND_BAG_ID` when a real id is known.

## Appendix — success shapes not present in this capture file

This document reflects **one** capture run. You still need samples from your backend for:

- **`createbag` success** with a real new `bag_id`.
- **`getbagdetails` / `getmanifestdetails` / `getlinehauldetails` success** (nested bags, lines, weights).
- **`listbags` / `listmanifests` / `listlinehauls` success** when `data` is a non-empty **array**.
- **`printmanifestdata` success** (JSON vs HTML vs URL string).
- **All POST success** bodies after valid mutations (`OUTBOUND_CAPTURE_MUTATIONS=1`, use on staging only).

