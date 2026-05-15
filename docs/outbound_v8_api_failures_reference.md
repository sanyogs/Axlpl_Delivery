# Outbound V8 — failures & errors (request + JSON response)

Source: `outbound_v8_api_capture.json`  
**IDs used:** `{"bag_id":"BAG20260515154014","manifest_id":"MUM075","linehaul_id":"LH1778842087","docket_no":"990831778839479","pickup_id":"122","user_id":"143"}`  
**Failures:** 13 / 26 calls  

Success responses are in [`outbound_v8_api_all_requests_responses.json`](outbound_v8_api_all_requests_responses.json).

---

## 1. `createbag` — Skipped by default (OUTBOUND_SKIP_CREATEBAG=1). The live createbag endpoint often returns status success with bag_id 0 even for invalid or incomplete payloads, so HTTP capture is misleading. Set OUTBOUND_SKIP_CREATEBAG=0 to record the real response body.

- **HTTP:** None  
- **API status:** None  
- **error_code:** None  
- **Skipped:** Skipped by default (OUTBOUND_SKIP_CREATEBAG=1). The live createbag endpoint often returns status success with bag_id 0 even for invalid or incomplete payloads, so HTTP capture is misleading. Set OUTBOUND_SKIP_CREATEBAG=0 to record the real response body.

**Request**

```json
{
  "query": null,
  "form": null
}
```

**Response JSON**

```json

```

## 2. `addshipmenttobag` — Bag ID and Docket Number required

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 400  

**Request**

```json
{
  "query": null,
  "form": {
    "bag_id": "BAG20260515154014",
    "docket_no": "990831778839479",
    "branch_id": "27",
    "user_id": "143"
  }
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Bag ID and Docket Number required",
  "data": {},
  "error_code": 400
}
```

## 3. `getbagdetails` — Bag ID required

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 400  

**Request**

```json
{
  "query": {
    "bag_id": "BAG20260515154014",
    "platform": "android"
  },
  "form": null
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Bag ID required",
  "data": {},
  "error_code": 400
}
```

## 4. `removeshipmentfrombag` — Bag ID and Docket Number required

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 400  

**Request**

```json
{
  "query": null,
  "form": {
    "bag_id": "BAG20260515154014",
    "docket_no": "990831778839479",
    "branch_id": "27",
    "user_id": "143"
  }
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Bag ID and Docket Number required",
  "data": {},
  "error_code": 400
}
```

## 5. `lockbag` — Bag ID required

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 400  

**Request**

```json
{
  "query": null,
  "form": {
    "bag_id": "BAG20260515154014"
  }
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Bag ID required",
  "data": {},
  "error_code": 400
}
```

## 6. `rebagshipment` — New Bag ID and Docket Number required

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 400  

**Request**

```json
{
  "query": null,
  "form": {
    "new_bag_id": "BAG20260515154014",
    "docket_no": "990831778839479",
    "user_id": "143"
  }
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "New Bag ID and Docket Number required",
  "data": {},
  "error_code": 400
}
```

## 7. `createmanifest` — Invalid Bag IDs format

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 400  

**Request**

```json
{
  "query": null,
  "form": {
    "bag_ids": "BAG20260515154014",
    "origin_branch_id": "27",
    "destination_branch_id": "27",
    "user_id": "143"
  }
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Invalid Bag IDs format",
  "data": {},
  "error_code": 400
}
```

## 8. `getmanifestdetails` — Manifest ID required

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 400  

**Request**

```json
{
  "query": {
    "manifest_id": "MUM075",
    "platform": "android"
  },
  "form": null
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Manifest ID required",
  "data": {},
  "error_code": 400
}
```

## 9. `printmanifestdata` — Manifest ID required

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 400  

**Request**

```json
{
  "query": {
    "manifest_id": "MUM075",
    "platform": "android"
  },
  "form": null
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Manifest ID required",
  "data": {},
  "error_code": 400
}
```

## 10. `getlinehauldetails` — Linehaul ID required

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 400  

**Request**

```json
{
  "query": {
    "linehaul_id": "LH1778842087",
    "platform": "android"
  },
  "form": null
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Linehaul ID required",
  "data": {},
  "error_code": 400
}
```

## 11. `updatelinehaulstatus` — Linehaul ID and Status required

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 400  

**Request**

```json
{
  "query": null,
  "form": {
    "linehaul_id": "LH1778842087",
    "status": "ARRIVED",
    "user_id": "143",
    "branch_id": "27"
  }
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Linehaul ID and Status required",
  "data": {},
  "error_code": 400
}
```

## 12. `sectorpickupscan` — Shipment already scanned for this pickup

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 422  

**Request**

```json
{
  "query": null,
  "form": {
    "pickup_id": "122",
    "docket_no": "990831778839479",
    "status": "Picked",
    "remarks": "",
    "user_id": "143",
    "branch_id": "27"
  }
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Shipment already scanned for this pickup",
  "data": {},
  "error_code": 422
}
```

## 13. `marknotpicked` — Shipment already scanned for this pickup

- **HTTP:** 200  
- **API status:** fail  
- **error_code:** 422  

**Request**

```json
{
  "query": null,
  "form": {
    "pickup_id": "122",
    "docket_no": "990831778839479",
    "remarks": "api_capture_script_test",
    "user_id": "143",
    "branch_id": "27"
  }
}
```

**Response JSON**

```json
{
  "status": "fail",
  "message": "Shipment already scanned for this pickup",
  "data": {},
  "error_code": 422
}
```
