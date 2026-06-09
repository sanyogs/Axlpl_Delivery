# Outbound — Sarvesh QA verified curls

Gateway: `api.php?request=<action>` · iOS headers · POST urlencoded for edit/delete linehaul.

**Last live refresh:** 2026-06-09 12:34 UTC · Regenerate: `python3 docs/refresh_sarvesh_responses.py`

## Summary

| Status | Endpoint | HTTP |
|--------|----------|------|
| OK | `getlinehauldetails_mawb` | 200 |
| OK | `getlinehauldetails_linehaul_id` | 200 |
| OK | `getpickupdetail` | 200 |
| OK | `deletelinehaul` | 200 |
| OK | `editlinehaul` | 200 |
| OK | `getmanifestdetails_MUM208` | 200 |
| OK | `getbagdetails` | 200 |
| OK | `manifestreport_MUM094` | 200 |
| OPEN | `getmanifestdetails_MUM075` | 200 |
| OPEN | `getlinehauldetails_trip_no` | 404 |
| OPEN | `listmanifests` | 200 |
| OPEN | `getpickuplist` | 200 |

---

## getlinehauldetails (mawb_no)

**Notes:** Works — use for linehaul detail lookup

**Request curl**
```bash
curl --location --request GET 'https://my.axlpl.com/messenger/services_v8/api.php?request=getlinehauldetails&mawb_no=58976412530' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.1.0' \
  --header 'X-App-Platform: ios'
```

**Response**
```json
{
  "status": "success",
  "message": "Linehaul details retrieved successfully",
  "data": {
    "id": "12",
    "origin": "75",
    "destination": "39",
    "transport_type": "Air",
    "airline": "2",
    "flight_no": "ai252",
    "mawb_no": "58976412530",
    "no_of_boxes": "2",
    "departure_time": "2026-04-17 16:00:00",
    "arrival_time": "2026-04-17 18:00:00",
    "total_cd_weight": "15000.00",
    "created_at": "2026-04-17 13:50:05",
    "updated_at": "2026-04-17 13:50:05",
    "total_billing_weight": "15000.00",
    "airway_bill_no": "58976412530",
    "eway_bill": "0",
    "no_of_bags": "2",
    "total_bags": "2",
    "total_weight": "15000.00",
    "billing_weight": "15000.00",
    "manifests": [
      {
        "id": "19",
        "manifest_no": "AMR002",
        "origin_branch": "75",
        "destination_branch": "39",
        "created_by": "182",
        "created_at": "2026-04-17 13:48:25",
        "updated_at": "2026-04-17 13:48:25"
      }
    ],
    "shipment_count": 5,
    "shipments": [
      {
        "id": "585951776412530",
        "shipment_invoice_no": "12",
        "shipment_status": "Hub in"
      },
      {
        "id": "301791776412626",
        "shipment_invoice_no": "25",
        "shipment_status": "Hub in"
      },
      {
        "id": "411341776412747",
        "shipment_invoice_no": "15",
        "shipment_status": "Hub in"
      },
      {
        "id": "653651776412928",
        "shipment_invoice_no": "15",
        "shipment_status": "Hub in"
      },
      {
        "id": "564921776413062",
        "shipment_invoice_no": "25",
        "shipment_status": "Hub in"
      }
    ]
  }
}
```

**HTTP:** 200

---

## getlinehauldetails (linehaul_id)

**Notes:** Works — alternative lookup param

**Request curl**
```bash
curl --location --request GET 'https://my.axlpl.com/messenger/services_v8/api.php?request=getlinehauldetails&linehaul_id=365' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.1.0' \
  --header 'X-App-Platform: ios'
```

**Response**
```json
{
  "status": "success",
  "message": "Linehaul details retrieved successfully",
  "data": {
    "id": "365",
    "origin": "27",
    "destination": "5",
    "transport_type": "Airway",
    "airline": "Air India",
    "flight_no": "AI101",
    "mawb_no": "31229324256",
    "no_of_boxes": "1",
    "departure_time": "2026-06-09 10:00:00",
    "arrival_time": "2026-06-10 08:00:00",
    "total_cd_weight": "0.00",
    "created_at": "2026-06-09 15:19:59",
    "updated_at": "2026-06-09 18:03:03",
    "total_billing_weight": "0.00",
    "airway_bill_no": "31229324256",
    "eway_bill": "EWB123456789",
    "no_of_bags": "1",
    "total_bags": "1",
    "total_weight": "0.00",
    "billing_weight": "0.00",
    "manifests": [
      {
        "id": "382",
        "manifest_no": "HYD010",
        "origin_branch": "27",
        "destination_branch": "5",
        "created_by": "148",
        "created_at": "2026-06-09 15:19:07",
        "updated_at": "2026-06-09 15:19:07"
      }
    ],
    "shipment_count": 0,
    "shipments": []
  }
}
```

**HTTP:** 200

---

## getpickupdetail

**Notes:** Works — shipment_list[], hub, flight

**Request curl**
```bash
curl --location --request GET 'https://my.axlpl.com/messenger/services_v8/api.php?request=getpickupdetail&pickup_id=286' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.3.0' \ \
  --header 'Accept: application/json'
```

**Response**
```json
{
  "status": "success",
  "message": "Pickup detail retrieved successfully",
  "data": {
    "id": "286",
    "mawb_no": "31229324256",
    "hub_id": "1",
    "picked_by": null,
    "pickup_date": "2026-06-09",
    "pickup_time": "13:24:00",
    "created_at": "2026-06-09 13:18:32",
    "updated_at": "2026-06-09 13:24:23",
    "origin_hub": "Hyderabad",
    "destination_hub": "Mumbai",
    "origin_branch": "SURAT",
    "destination_branch": "Mumbai",
    "flight_no": "6E5213",
    "total_shipments": 13,
    "shipment_list": [
      {
        "shipment_id": "825411779084407",
        "shipment_invoice_no": "1",
        "status": "Hub In",
        "sender_name": "prajakta rajeshirke",
        "receiver_name": "receiver_version"
      },
      {
        "shipment_id": "123456789",
        "shipment_invoice_no": "2450000000000000",
        "status": "Not Picked",
        "sender_name": "prajakta rajeshirke",
        "receiver_name": "Version Next"
      },
      {
        "shipment_id": "556821780922469",
        "shipment_invoice_no": "35",
        "status": "Delivered",
        "sender_name": "SILVEA",
        "receiver_name": "SUBRATA HALDER"
      },
      {
        "shipment_id": "358111780926552",
        "shipment_invoice_no": "17",
        "status": "Delivered",
        "sender_name": "P N GOLD 36ABEFP6762B1Z9",
        "receiver_name": "P N GOLD(27ABEFP6762B1Z8)"
      },
      {
        "shipment_id": "188501780927776",
        "shipment_invoice_no": "NRLV/KI/2627/029",
        "status": "Delivered",
        "sender_name": "N R GOLD LIMITED(37AAECP6663M1ZS)",
        "receiver_name": "N R GOLD LIMITED( 27AAECP6663M1ZT)"
      },
      {
        "shipment_id": "421431780928907",
        "shipment_invoice_no": "DC-76",
        "status": "Delivered",
        "sender_name": "ARUN GOLDSMITH AND JEWELLERS(36AYOPM8508K1ZR)",
        "receiver_name": "BHERU GOLD"
      },
      {
        "shipment_id": "990101780929395",
        "shipment_invoice_no": "26-00315",
        "status": "Delivered",
        "sender_name": "MANEPALLY JEWELLERS PRIVATE LIMITED",
        "receiver_name": "RATNAM JEWELLERY 27ACVPJ9749E1ZV"
      },
      {
        "shipment_id": "233151780930967",
        "shipment_invoice_no": "AB/019/26-27",
        "status": "Out for delivery",
        "sender_name": "AAKASH BEGANI",
        "receiver_name": "KANTILAL CHHOTALAL"
      },
      {
        "shipment_id": "797511780931214",
        "shipment_invoice_no": "SAI/123",
        "status": "Delivered",
        "sender_name": "SAI RAJENDRA GOLD PALACE PVT LTD 37AAPCS5808L1ZN",
        "receiver_name": "MOON EXPORTS"
      },
      {
        "shipment_id": "892011780931789",
        "shipment_invoice_no": "SX-72",
        "status": "Delivered",
        "sender_name": "RAJESH JAIN ASHOK JAIN",
        "receiver_name": "MUKTI GOLD PVT LTD(BOM)"
      },
      {
        "shipment_id": "187111780931918",
        "shipment_invoice_no": "ird/62",
        "status": "Delivered",
        "sender_name": "M B ENTERPRISES (HYD)",
        "receiver_name": "Alux Diamond & Jewels LLP(27ABVFA6298C1ZX)"
      },
      {
        "shipment_id": "859001780933521",
        "shipment_invoice_no": "IRD/61",
        "status": "Hub in",
        "sender_name": "NYSA JEWELS(A UNIT OF MB ENTERPRISES)",
        "receiver_name": "AVD GLITTER JEWELS LIMITED"
      },
      {
        "shipment_id": "703941780934720",
        "shipment_invoice_no": "57",
        "status": "Delivered",
        "sender_name": "SREE CHANDANA BROTHERS",
        "receiver_name": "JAMNADAS JEWELLERS LLP(27AATFJ5026E1Z8)"
      }
    ]
  }
}
```

**HTTP:** 200

---

## deletelinehaul

**Notes:** POST urlencoded

**Request curl**
```bash
curl --location --request POST 'https://my.axlpl.com/messenger/services_v8/api.php?request=deletelinehaul' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.3.0' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'linehaul_id=365'
```

**Response**
```json
{
  "status": "success",
  "message": "Linehaul deleted successfully",
  "data": {
    "linehaul_id": 365
  }
}
```

**HTTP:** 200

---

## editlinehaul

**Notes:** POST urlencoded

**Request curl**
```bash
curl --location --request POST 'https://my.axlpl.com/messenger/services_v8/api.php?request=editlinehaul' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.3.0' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'linehaul_id=365' \
  --data-urlencode 'vehicle_no=MH01AB1234' \
  --data-urlencode 'driver_name=Ramesh Kumar' \
  --data-urlencode 'driver_mobile=9876543210' \
  --data-urlencode 'mawb_no=31229324256' \
  --data-urlencode 'trip_no=LH1780998599' \
  --data-urlencode 'departure_time=2026-06-09 10:00:00' \
  --data-urlencode 'arrival_time=2026-06-10 08:00:00' \
  --data-urlencode 'remarks=Updated via API' \
  --data-urlencode 'flight_no=AI101' \
  --data-urlencode 'airline=Air India' \
  --data-urlencode 'eway_bill=EWB123456789' \
  --data-urlencode 'transport_type=Airway'
```

**Response**
```json
{
  "status": "success",
  "message": "Linehaul updated successfully",
  "data": {
    "linehaul_id": 365
  }
}
```

**HTTP:** 200

---

## getmanifestdetails MUM208

**Notes:** Works — bags + rich shipments[]

**Request curl**
```bash
curl --location --request GET 'https://my.axlpl.com/messenger/services_v8/api.php?request=getmanifestdetails&manifest_code=MUM208' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.1.0' \
  --header 'X-App-Platform: ios'
```

**Response**
```json
{
  "status": "success",
  "message": "Manifest details retrieved successfully",
  "data": {
    "id": "381",
    "manifest_no": "MUM208",
    "origin_branch": "47",
    "destination_branch": "75",
    "created_by": "187",
    "created_at": "2026-06-08 22:45:01",
    "updated_at": "2026-06-08 22:45:01",
    "origin_branch_name": "Vijaywada",
    "destination_branch_name": "Mumbai",
    "bags": [
      {
        "id": "379",
        "bag_code": "BAG20260608224439",
        "metal_seal_no": "VAL0074004 VGA TO MUM"
      }
    ],
    "debug_raw_bagging_items_count": "2",
    "debug_joined_shipments_count": "2",
    "shipments": [
      {
        "id": "188501780927776",
        "shipment_invoice_no": "NRLV/KI/2627/029",
        "shipment_status": "Delivered",
        "bag_id": "379",
        "bag_code": "BAG20260608224439",
        "sender_name": "N R GOLD LIMITED(37AAECP6663M1ZS)",
        "receiver_name": "N R GOLD LIMITED( 27AAECP6663M1ZT)",
        "destination_city": "Mumbai",
        "total_weight": "1398",
        "no_of_package": "1"
      },
      {
        "id": "797511780931214",
        "shipment_invoice_no": "SAI/123",
        "shipment_status": "Delivered",
        "bag_id": "379",
        "bag_code": "BAG20260608224439",
        "sender_name": "SAI RAJENDRA GOLD PALACE PVT LTD 37AAPCS5808L1ZN",
        "receiver_name": "MOON EXPORTS",
        "destination_city": "Mumbai",
        "total_weight": "100",
        "no_of_package": "1"
      }
    ]
  }
}
```

**HTTP:** 200

---

## getbagdetails

**Notes:** items[] enriched

**Request curl**
```bash
curl --location --request GET 'https://my.axlpl.com/messenger/services_v8/api.php?request=getbagdetails&bag_code=BAG20260518152744831' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.1.0' \
  --header 'X-App-Platform: ios'
```

**Response**
```json
{
  "status": "success",
  "message": "Bag details retrieved successfully",
  "data": {
    "id": "200",
    "bag_code": "BAG20260518152744831",
    "metal_seal_no": "MSeal825411779084407",
    "origin_branch_id": "37",
    "destination_sector_id": "95",
    "created_by": "1",
    "created_at": "2026-05-18 15:27:44",
    "updated_at": null,
    "shipment_count": 1,
    "manifest_status": "Not Manifested",
    "items": [
      {
        "shipment_id": "825411779084407",
        "shipment_invoice_no": "1",
        "shipment_status": "Hub In",
        "sender_name": "prajakta rajeshirke",
        "receiver_name": "receiver_version",
        "destination_city": "Mumbai",
        "total_weight": "11.00",
        "no_of_package": "1"
      }
    ]
  }
}
```

**HTTP:** 200

---

## manifestreport

**Notes:** Use manifest_no not manifest_code

**Request curl**
```bash
curl --location --request GET 'https://my.axlpl.com/messenger/services_v8/api.php?request=manifestreport&start_date=2026-05-01&end_date=2026-05-18&manifest_no=MUM094' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.1.0' \
  --header 'X-App-Platform: ios'
```

**Response**
```json
{
  "status": "success",
  "message": "Manifest report generated successfully",
  "data": {
    "id": "205",
    "manifest_no": "MUM094",
    "origin_branch": "37",
    "destination_branch": "75",
    "created_by": "1",
    "created_at": "2026-05-19 14:59:18",
    "updated_at": "2026-05-19 14:59:18",
    "origin_branch_name": "KOLKATTA",
    "origin_name": "KOLKATTA",
    "destination_branch_name": "Mumbai",
    "destination_name": "Mumbai",
    "shipments": [
      {
        "id": "825411779084407",
        "shipment_invoice_no": "1",
        "sender_name": "prajakta rajeshirke",
        "receiver_name": "receiver_version",
        "destination_city": "Mumbai",
        "number_of_parcel": "1",
        "gross_weight": "11",
        "volumetric_weight": "10"
      }
    ],
    "bags": [
      {
        "id": "200",
        "bag_code": "BAG20260518152744831",
        "metal_seal_no": "MSeal825411779084407",
        "gross_weight": "11"
      }
    ]
  }
}
```

**HTTP:** 200

---

## getmanifestdetails MUM075 (OPEN)

**Notes:** OPEN — shipments[] empty

**Request curl**
```bash
curl --location --request GET 'https://my.axlpl.com/messenger/services_v8/api.php?request=getmanifestdetails&manifest_code=MUM075' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.1.0' \
  --header 'X-App-Platform: ios'
```

**Response**
```json
{
  "status": "success",
  "message": "Manifest details retrieved successfully",
  "data": {
    "id": "171",
    "manifest_no": "MUM075",
    "origin_branch": "75",
    "destination_branch": "75",
    "created_by": "81",
    "created_at": "2026-05-15 15:47:10",
    "updated_at": "2026-05-15 15:47:10",
    "origin_branch_name": "Mumbai",
    "destination_branch_name": "Mumbai",
    "bags": [
      {
        "id": "173",
        "bag_code": "BAG20260515154014",
        "metal_seal_no": "bag990831778839479"
      }
    ],
    "debug_raw_bagging_items_count": "0",
    "debug_joined_shipments_count": "0",
    "shipments": []
  }
}
```

**HTTP:** 200

---

## getlinehauldetails trip_no (OPEN)

**Notes:** OPEN — SQL error trip_no column

**Request curl**
```bash
curl --location --request GET 'https://my.axlpl.com/messenger/services_v8/api.php?request=getlinehauldetails&trip_no=LH1780998599' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.1.0' \
  --header 'X-App-Platform: ios'
```

**Response**
```json
{
  "status": "fail",
  "message": "Linehaul not found",
  "data": [],
  "error_code": 404
}
```

**HTTP:** 404

---

## listmanifests (OPEN)

**Notes:** OPEN — 50 row cap, no pagination

**Request curl**
```bash
curl --location --request GET 'https://my.axlpl.com/messenger/services_v8/api.php?request=listmanifests' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.1.0' \
  --header 'X-App-Platform: ios'
```

**Response**
```json
{
  "status": "success",
  "message": "Manifests retrieved successfully",
  "data": [
    {
      "id": "382",
      "manifest_no": "HYD010",
      "origin_branch": "27",
      "destination_branch": "5",
      "created_by": "148",
      "created_at": "2026-06-09 15:19:07",
      "updated_at": "2026-06-09 15:19:07"
    },
    {
      "id": "381",
      "manifest_no": "MUM208",
      "origin_branch": "47",
      "destination_branch": "75",
      "created_by": "187",
      "created_at": "2026-06-08 22:45:01",
      "updated_at": "2026-06-08 22:45:01"
    },
    {
      "id": "380",
      "manifest_no": "MUM207",
      "origin_branch": "49",
      "destination_branch": "75",
      "created_by": "187",
      "created_at": "2026-06-08 22:39:24",
      "updated_at": "2026-06-08 22:39:24"
    },
    {
      "id": "379",
      "manifest_no": "MUM206",
      "origin_branch": "59",
      "destination_branch": "75",
      "created_by": "143",
      "created_at": "2026-06-08 21:09:15",
      "updated_at": "2026-06-08 21:09:15"
    },
    {
      "id": "378",
      "manifest_no": "DEL049",
      "origin_branch": "59",
      "destination_branch": "27",
      "created_by": "143",
      "created_at": "2026-06-08 21:06:43",
      "updated_at": "2026-06-08 21:06:43"
    },
    {
      "id": "377",
      "manifest_no": "MUM205",
      "origin_branch": "41",
      "destination_branch": "75",
      "created_by": "147",
      "created_at": "2026-06-08 21:04:07",
      "updated_at": "2026-06-08 21:04:07"
    },
    {
      "id": "376",
      "manifest_no": "MUM204",
      "origin_branch": "83",
      "destination_branch": "75",
      "created_by": "84",
      "created_at": "2026-06-08 20:51:36",
      "updated_at": "2026-06-08 20:51:36"
    },
    {
      "id": "375",
      "manifest_no": "MUM203",
      "origin_branch": "31",
      "destination_branch": "75",
      "created_by": "15",
      "created_at": "2026-06-08 20:44:51",
      "updated_at": "2026-06-08 20:44:51"
    },
    {
      "id": "374",
      "manifest_no": "MUM202",
      "origin_branch": "57",
      "destination_branch": "75",
      "created_by": "84",
      "created_at": "2026-06-08 20:36:27",
      "updated_at": "2026-06-08 20:36:27"
    },
    {
      "id": "373",
      "manifest_no": "MUM201",
      "origin_branch": "37",
      "destination_branch": "75",
      "created_by": "28",
      "created_at": "2026-06-08 20:32:01",
      "updated_at": "2026-06-08 20:32:01"
    },
    {
      "id": "372",
      "manifest_no": "MUM200",
      "origin_branch": "51",
      "destination_branch": "75",
      "created_by": "181",
      "created_at": "2026-06-08 19:19:04",
      "updated_at": "2026-06-08 19:19:04"
    },
    {
      "id": "371",
      "manifest_no": "JAI003",
      "origin_branch": "41",
      "destination_branch": "41",
      "created_by": "147",
      "created_at": "2026-06-08 18:25:41",
      "updated_at": "2026-06-08 18:25:41"
    },
    {
      "id": "370",
      "manifest_no": "MUM199",
      "origin_branch": "79",
      "destination_branch": "75",
      "created_by": "144",
      "created_at": "2026-06-08 16:21:13",
      "updated_at": "2026-06-08 16:21:13"
    },
    {
      "id": "369",
      "manifest_no": "MUM198",
      "origin_branch": "49",
      "destination_branch": "75",
      "created_by": "187",
      "created_at": "2026-06-07 07:01:39",
      "updated_at": "2026-06-07 07:01:39"
    },
    {
      "id": "368",
      "manifest_no": "MUM197",
      "origin_branch": "31",
      "destination_branch": "75",
      "created_by": "15",
      "created_at": "2026-06-06 21:20:53",
      "updated_at": "2026-06-06 21:20:53"
    },
    {
      "id": "367",
      "manifest_no": "MUM196",
      "origin_branch": "59",
      "destination_branch": "75",
      "created_by": "143",
      "created_at": "2026-06-06 20:49:31",
      "updated_at": "2026-06-06 20:49:31"
    },
    {
      "id": "366",
      "manifest_no": "DEL048",
      "origin_branch": "59",
      "destination_branch": "27",
      "created_by": "143",
      "created_at": "2026-06-06 20:46:57",
      "updated_at": "2026-06-06 20:46:57"
    },
    {
      "id": "365",
      "manifest_no": "IND002",
      "origin_branch": "59",
      "destination_branch": "79",
      "created_by": "143",
      "created_at": "2026-06-06 20:43:11",
      "updated_at": "2026-06-06 20:43:11"
    },
    {
      "id": "364",
      "manifest_no": "MUM195",
      "origin_branch": "51",
      "destination_branch": "75",
      "created_by": "181",
      "created_at": "2026-06-06 20:38:55",
      "updated_at": "2026-06-06 20:38:55"
    },
    {
      "id": "363",
      "manifest_no": "DEL047",
      "origin_branch": "41",
      "destination_branch": "27",
      "created_by": "147",
      "created_at": "2026-06-06 20:25:35",
      "updated_at": "2026-06-06 20:25:35"
    },
    {
      "id": "362",
      "manifest_no": "MUM194",
      "origin_branch": "41",
      "destination_branch": "75",
      "created_by": "147",
      "created_at": "2026-06-06 20:04:56",
      "updated_at": "2026-06-06 20:04:56"
    },
    {
      "id": "361",
      "manifest_no": "MUM193",
      "origin_branch": "37",
      "destination_branch": "75",
      "created_by": "28",
      "created_at": "2026-06-06 19:40:50",
      "updated_at": "2026-06-06 19:40:50"
    },
    {
      "id": "360",
      "manifest_no": "MUM192",
      "origin_branch": "47",
      "destination_branch": "75",
      "created_by": "187",
      "created_at": "2026-06-05 23:01:06",
      "updated_at": "2026-06-05 23:01:06"
    },
    {
      "id": "359",
      "manifest_no": "MUM191",
      "origin_branch": "45",
      "destination_branch": "75",
      "created_by": "40",
      "created_at": "2026-06-05 22:58:44",
      "updated_at": "2026-06-05 22:58:44"
    },
    {
      "id": "358",
      "manifest_no": "MUM190",
      "origin_branch": "49",
      "destination_branch": "75",
      "created_by": "187",
      "created_at": "2026-06-05 22:48:10",
      "updated_at": "2026-06-05 22:48:10"
    },
    {
      "id": "357",
      "manifest_no": "MUM189",
      "origin_branch": "41",
      "destination_branch": "75",
      "created_by": "147",
      "created_at": "2026-06-05 21:03:02",
      "updated_at": "2026-06-05 21:03:02"
    },
    {
      "id": "356",
      "manifest_no": "DEL046",
      "origin_branch": "41",
      "destination_branch": "27",
      "created_by": "147",
      "created_at": "2026-06-05 20:53:10",
      "updated_at": "2026-06-05 20:53:10"
    },
    {
      "id": "355",
      "manifest_no": "MUM188",
      "origin_branch": "31",
      "destination_branch": "75",
      "created_by": "15",
      "created_at": "2026-06-05 20:48:29",
      "updated_at": "2026-06-05 20:48:29"
    },
    {
      "id": "354",
      "manifest_no": "DEL045",
      "origin_branch": "59",
      "destination_branch": "27",
      "created_by": "143",
      "created_at": "2026-06-05 20:46:32",
      "updated_at": "2026-06-05 20:46:32"
    },
    {
      "id": "353",
      "manifest_no": "MUM187",
      "origin_branch": "59",
      "destination_branch": "75",
      "created_by": "143",
      "created_at": "2026-06-05 20:41:55",
      "updated_at": "2026-06-05 20:41:55"
    },
    {
      "id": "352",
      "manifest_no": "MUM186",
      "origin_branch": "37",
      "destination_branch": "75",
      "created_by": "28",
      "created_at": "2026-06-05 20:12:50",
      "updated_at": "2026-06-05 20:12:50"
    },
    {
      "id": "351",
      "manifest_no": "MUM185",
      "origin_branch": "51",
      "destination_branch": "75",
      "created_by": "181",
      "created_at": "2026-06-05 20:01:16",
      "updated_at": "2026-06-05 20:01:16"
    },
    {
      "id": "350",
      "manifest_no": "MUM184",
      "origin_branch": "79",
      "destination_branch": "75",
      "created_by": "144",
      "created_at": "2026-06-05 18:31:10",
      "updated_at": "2026-06-05 18:31:10"
    },
    {
      "id": "349",
      "manifest_no": "MUM183",
      "origin_branch": "49",
      "destination_branch": "75",
      "created_by": "187",
      "created_at": "2026-06-05 06:29:42",
      "updated_at": "2026-06-05 06:29:42"
    },
    {
      "id": "348",
      "manifest_no": "MUM182",
      "origin_branch": "31",
      "destination_branch": "75",
      "created_by": "15",
      "created_at": "2026-06-04 21:31:40",
      "updated_at": "2026-06-04 21:31:40"
    },
    {
      "id": "347",
      "manifest_no": "MUM181",
      "origin_branch": "59",
      "destination_branch": "75",
      "created_by": "143",
      "created_at": "2026-06-04 20:23:11",
      "updated_at": "2026-06-04 20:23:11"
    },
    {
      "id": "346",
      "manifest_no": "MUM180",
      "origin_branch": "37",
      "destination_branch": "75",
      "created_by": "28",
      "created_at": "2026-06-04 20:21:07",
      "updated_at": "2026-06-04 20:21:07"
    },
    {
      "id": "345",
      "manifest_no": "DEL044",
      "origin_branch": "59",
      "destination_branch": "27",
      "created_by": "143",
      "created_at": "2026-06-04 20:20:06",
      "updated_at": "2026-06-04 20:20:06"
    },
    {
      "id": "344",
      "manifest_no": "MUM179",
      "origin_branch": "51",
      "destination_branch": "75",
      "created_by": "181",
      "created_at": "2026-06-04 19:21:29",
      "updated_at": "2026-06-04 19:21:29"
    },
    {
      "id": "343",
      "manifest_no": "MUM178",
      "origin_branch": "51",
      "destination_branch": "75",
      "created_by": "181",
      "created_at": "2026-06-04 15:44:45",
      "updated_at": "2026-06-04 15:44:45"
    },
    {
      "id": "342",
      "manifest_no": "MUM177",
      "origin_branch": "49",
      "destination_branch": "75",
      "created_by": "187",
      "created_at": "2026-06-03 22:02:27",
      "updated_at": "2026-06-03 22:02:27"
    },
    {
      "id": "341",
      "manifest_no": "MUM176",
      "origin_branch": "59",
      "destination_branch": "75",
      "created_by": "143",
      "created_at": "2026-06-03 20:33:41",
      "updated_at": "2026-06-03 20:33:41"
    },
    {
      "id": "340",
      "manifest_no": "MUM175",
      "origin_branch": "31",
      "destination_branch": "75",
      "created_by": "15",
      "created_at": "2026-06-03 20:33:04",
      "updated_at": "2026-06-03 20:33:04"
    },
    {
      "id": "339",
      "manifest_no": "MUM174",
      "origin_branch": "41",
      "destination_branch": "75",
      "created_by": "147",
      "created_at": "2026-06-03 20:31:52",
      "updated_at": "2026-06-03 20:31:52"
    },
    {
      "id": "338",
      "manifest_no": "DEL043",
      "origin_branch": "59",
      "destination_branch": "27",
      "created_by": "143",
      "created_at": "2026-06-03 20:31:33",
      "updated_at": "2026-06-03 20:31:33"
    },
    {
      "id": "337",
      "manifest_no": "HYD009",
      "origin_branch": "41",
      "destination_branch": "49",
      "created_by": "147",
      "created_at": "2026-06-03 20:26:43",
      "updated_at": "2026-06-03 20:26:43"
    },
    {
      "id": "336",
      "manifest_no": "CHE012",
      "origin_branch": "51",
      "destination_branch": "29",
      "created_by": "181",
      "created_at": "2026-06-03 20:26:01",
      "updated_at": "2026-06-03 20:26:01"
    },
    {
      "id": "335",
      "manifest_no": "MUM173",
      "origin_branch": "51",
      "destination_branch": "75",
      "created_by": "181",
      "created_at": "2026-06-03 20:12:00",
      "updated_at": "2026-06-03 20:12:00"
    },
    {
      "id": "334",
      "manifest_no": "MUM172",
      "origin_branch": "37",
      "destination_branch": "75",
      "created_by": "28",
      "created_at": "2026-06-03 19:57:41",
      "updated_at": "2026-06-03 19:57:41"
    },
    {
      "id": "333",
      "manifest_no": "MUM171",
      "origin_branch": "79",
      "destination_branch": "75",
      "created_by": "182",
      "created_at": "2026-06-03 18:06:44",
      "updated_at": "2026-06-03 18:06:44"
    }
  ]
}
```

**HTTP:** 200

---

## getpickuplist (OPEN dup)

**Notes:** OPEN — 9 duplicate ids in response

**Request curl**
```bash
curl --location --request GET 'https://my.axlpl.com/messenger/services_v8/api.php?request=getpickuplist' \
  --header 'Authorization: Bearer ecf2c67fd1b93af39f00ddf0ced734ac1cccc7ea4f51725e0b4a4dfff20ca9e7' \
  --header 'X-App-Version: 22.1.0' \
  --header 'X-App-Platform: ios'
```

**Response**
```json
{
  "status": "success",
  "message": "Pickup list retrieved successfully",
  "data": [
    {
      "id": "287",
      "mawb_no": "312-29239943",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "16:02:00",
      "created_at": "2026-06-09 16:02:51",
      "updated_at": "2026-06-09 16:02:51",
      "destination_hub": "Mumbai",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5262"
    },
    {
      "id": "286",
      "mawb_no": "31229324256",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "13:24:00",
      "created_at": "2026-06-09 13:18:32",
      "updated_at": "2026-06-09 13:24:23",
      "destination_hub": "Mumbai",
      "origin_hub": "Hyderabad",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5213"
    },
    {
      "id": "286",
      "mawb_no": "31229324256",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "13:24:00",
      "created_at": "2026-06-09 13:18:32",
      "updated_at": "2026-06-09 13:24:23",
      "destination_hub": "Mumbai",
      "origin_hub": "Hyderabad",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5213"
    },
    {
      "id": "286",
      "mawb_no": "31229324256",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "13:24:00",
      "created_at": "2026-06-09 13:18:32",
      "updated_at": "2026-06-09 13:24:23",
      "destination_hub": "SURAT",
      "origin_hub": "Delhi",
      "origin_branch_name": "SURAT",
      "destination_branch_name": null,
      "flight_no": "AI101"
    },
    {
      "id": "285",
      "mawb_no": "312-29319983",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "11:47:00",
      "created_at": "2026-06-09 11:48:04",
      "updated_at": "2026-06-09 11:48:04",
      "destination_hub": "Mumbai",
      "origin_hub": "Lucknow",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E2058"
    },
    {
      "id": "284",
      "mawb_no": "312-29316803",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "11:46:00",
      "created_at": "2026-06-09 11:46:53",
      "updated_at": "2026-06-09 11:46:53",
      "destination_hub": "Mumbai",
      "origin_hub": "Bangalore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5205"
    },
    {
      "id": "283",
      "mawb_no": "312-29311273",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "11:44:00",
      "created_at": "2026-06-09 11:44:19",
      "updated_at": "2026-06-09 11:44:19",
      "destination_hub": "Mumbai",
      "origin_hub": "Coimbatore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E2409 / 6E353"
    },
    {
      "id": "282",
      "mawb_no": "MH02FG43141780933201",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "11:43:00",
      "created_at": "2026-06-09 11:43:47",
      "updated_at": "2026-06-09 11:43:47",
      "destination_hub": "Mumbai",
      "origin_hub": "Surat",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "BAY ROAD"
    },
    {
      "id": "281",
      "mawb_no": "312-29307132",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "11:38:00",
      "created_at": "2026-06-09 11:39:04",
      "updated_at": "2026-06-09 11:39:04",
      "destination_hub": "Mumbai",
      "origin_hub": "Kolkatta",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E6366"
    },
    {
      "id": "280",
      "mawb_no": "BY BUS1780757824",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-08",
      "pickup_time": "12:16:00",
      "created_at": "2026-06-08 12:16:07",
      "updated_at": "2026-06-08 12:16:07",
      "destination_hub": "Delhi",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Delhi",
      "flight_no": "BY BUS"
    },
    {
      "id": "279",
      "mawb_no": ":312-29239943",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-08",
      "pickup_time": "11:40:00",
      "created_at": "2026-06-08 11:40:12",
      "updated_at": "2026-06-08 11:40:12",
      "destination_hub": "Mumbai",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5262"
    },
    {
      "id": "278",
      "mawb_no": "312-29177481",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-08",
      "pickup_time": "11:36:00",
      "created_at": "2026-06-08 11:36:38",
      "updated_at": "2026-06-08 11:36:38",
      "destination_hub": "Mumbai",
      "origin_hub": "Coimbatore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E2409"
    },
    {
      "id": "277",
      "mawb_no": "31229241984",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-08",
      "pickup_time": "11:32:00",
      "created_at": "2026-06-08 11:32:52",
      "updated_at": "2026-06-08 11:32:52",
      "destination_hub": "Mumbai",
      "origin_hub": "Hyderabad",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5213"
    },
    {
      "id": "276",
      "mawb_no": "098-05483553",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-08",
      "pickup_time": "11:35:00",
      "created_at": "2026-06-07 11:49:28",
      "updated_at": "2026-06-08 11:35:58",
      "destination_hub": "Mumbai",
      "origin_hub": "Kolkatta",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "AI 2410"
    },
    {
      "id": "275",
      "mawb_no": "MH02FG43141780759224",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-08",
      "pickup_time": "11:33:00",
      "created_at": "2026-06-07 11:46:59",
      "updated_at": "2026-06-08 11:33:55",
      "destination_hub": "Mumbai",
      "origin_hub": "Surat",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "BAY ROAD"
    },
    {
      "id": "274",
      "mawb_no": "312-29241855",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-08",
      "pickup_time": "11:35:00",
      "created_at": "2026-06-07 11:43:49",
      "updated_at": "2026-06-08 11:35:26",
      "destination_hub": "Mumbai",
      "origin_hub": "Bangalore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5205"
    },
    {
      "id": "273",
      "mawb_no": "312-29108321",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "15:30:00",
      "created_at": "2026-06-06 12:39:11",
      "updated_at": "2026-06-06 15:30:38",
      "destination_hub": "Mumbai",
      "origin_hub": "Vishakapatnam",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6e883"
    },
    {
      "id": "272",
      "mawb_no": "BY BUS",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "12:26:00",
      "created_at": "2026-06-06 12:27:01",
      "updated_at": "2026-06-06 12:27:01",
      "destination_hub": "Delhi",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Delhi",
      "flight_no": "BY BUS"
    },
    {
      "id": "272",
      "mawb_no": "BY BUS",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "12:26:00",
      "created_at": "2026-06-06 12:27:01",
      "updated_at": "2026-06-06 12:27:01",
      "destination_hub": "Delhi",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Delhi",
      "flight_no": "BY BUS"
    },
    {
      "id": "272",
      "mawb_no": "BY BUS",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "12:26:00",
      "created_at": "2026-06-06 12:27:01",
      "updated_at": "2026-06-06 12:27:01",
      "destination_hub": "Delhi",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Delhi",
      "flight_no": "BY BUS"
    },
    {
      "id": "272",
      "mawb_no": "BY BUS",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "12:26:00",
      "created_at": "2026-06-06 12:27:01",
      "updated_at": "2026-06-06 12:27:01",
      "destination_hub": "Delhi",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Delhi",
      "flight_no": "BY BUS"
    },
    {
      "id": "272",
      "mawb_no": "BY BUS",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "12:26:00",
      "created_at": "2026-06-06 12:27:01",
      "updated_at": "2026-06-06 12:27:01",
      "destination_hub": "Delhi",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Delhi",
      "flight_no": "BY BUS"
    },
    {
      "id": "272",
      "mawb_no": "BY BUS",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "12:26:00",
      "created_at": "2026-06-06 12:27:01",
      "updated_at": "2026-06-06 12:27:01",
      "destination_hub": "Delhi",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Delhi",
      "flight_no": "BY BUS"
    },
    {
      "id": "271",
      "mawb_no": "31229182591",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "11:54:00",
      "created_at": "2026-06-06 11:55:02",
      "updated_at": "2026-06-06 11:55:02",
      "destination_hub": "Mumbai",
      "origin_hub": "Bangalore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5205"
    },
    {
      "id": "270",
      "mawb_no": "31229187211",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-08",
      "pickup_time": "12:28:00",
      "created_at": "2026-06-06 11:54:07",
      "updated_at": "2026-06-08 12:28:35",
      "destination_hub": "Mumbai",
      "origin_hub": "Hyderabad",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5143"
    },
    {
      "id": "270",
      "mawb_no": "31229187211",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-08",
      "pickup_time": "12:28:00",
      "created_at": "2026-06-06 11:54:07",
      "updated_at": "2026-06-08 12:28:35",
      "destination_hub": "Mumbai",
      "origin_hub": "Vijaywada",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5143"
    },
    {
      "id": "269",
      "mawb_no": ":312-29186356",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "11:52:00",
      "created_at": "2026-06-06 11:52:20",
      "updated_at": "2026-06-06 11:52:20",
      "destination_hub": "Mumbai",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5262"
    },
    {
      "id": "268",
      "mawb_no": "29180152",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "11:52:00",
      "created_at": "2026-06-06 11:51:05",
      "updated_at": "2026-06-09 11:52:43",
      "destination_hub": "Mumbai",
      "origin_hub": "Indore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E-6598/AIR"
    },
    {
      "id": "268",
      "mawb_no": "29180152",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-09",
      "pickup_time": "11:52:00",
      "created_at": "2026-06-06 11:51:05",
      "updated_at": "2026-06-09 11:52:43",
      "destination_hub": "Indore",
      "origin_hub": "Surat",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Indore",
      "flight_no": "6E-6598/AIR"
    },
    {
      "id": "267",
      "mawb_no": "MH02FG43141780672363",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "11:49:00",
      "created_at": "2026-06-06 11:50:13",
      "updated_at": "2026-06-06 11:50:13",
      "destination_hub": "Mumbai",
      "origin_hub": "Surat",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "BAY ROAD"
    },
    {
      "id": "266",
      "mawb_no": "312-29180970",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "11:45:00",
      "created_at": "2026-06-06 11:45:47",
      "updated_at": "2026-06-06 11:45:47",
      "destination_hub": "Mumbai",
      "origin_hub": "Coimbatore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E2409 / 6E353"
    },
    {
      "id": "265",
      "mawb_no": "312-29177256",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-06",
      "pickup_time": "11:44:00",
      "created_at": "2026-06-06 11:44:43",
      "updated_at": "2026-06-06 11:45:06",
      "destination_hub": "Mumbai",
      "origin_hub": "Kolkatta",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E6366"
    },
    {
      "id": "264",
      "mawb_no": "312-29111445",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-05",
      "pickup_time": "12:32:00",
      "created_at": "2026-06-05 12:29:50",
      "updated_at": "2026-06-05 12:34:16",
      "destination_hub": "Mumbai",
      "origin_hub": "Kolkatta",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E6366"
    },
    {
      "id": "263",
      "mawb_no": "312-259121525",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-05",
      "pickup_time": "12:32:00",
      "created_at": "2026-06-05 12:23:38",
      "updated_at": "2026-06-05 12:33:36",
      "destination_hub": "Mumbai",
      "origin_hub": "Bangalore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5205"
    },
    {
      "id": "262",
      "mawb_no": "MH02FG43141780584851",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-05",
      "pickup_time": "12:32:00",
      "created_at": "2026-06-05 12:23:30",
      "updated_at": "2026-06-05 12:34:38",
      "destination_hub": "Mumbai",
      "origin_hub": "Surat",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "BAY ROAD"
    },
    {
      "id": "261",
      "mawb_no": "312-29117104",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-05",
      "pickup_time": "12:32:00",
      "created_at": "2026-06-05 12:22:26",
      "updated_at": "2026-06-05 12:33:58",
      "destination_hub": "Mumbai",
      "origin_hub": "Coimbatore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E2409 / 6E675"
    },
    {
      "id": "260",
      "mawb_no": "312-29105554",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-05",
      "pickup_time": "12:32:00",
      "created_at": "2026-06-05 12:22:06",
      "updated_at": "2026-06-05 12:32:31",
      "destination_hub": "Mumbai",
      "origin_hub": "Coimbatore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E697"
    },
    {
      "id": "259",
      "mawb_no": "31229129586",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-05",
      "pickup_time": "12:14:00",
      "created_at": "2026-06-05 12:14:37",
      "updated_at": "2026-06-05 12:21:35",
      "destination_hub": "Mumbai",
      "origin_hub": "Hyderabad",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5213"
    },
    {
      "id": "258",
      "mawb_no": "TN04BC22191780498884",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-04",
      "pickup_time": "13:43:00",
      "created_at": "2026-06-04 13:43:58",
      "updated_at": "2026-06-04 13:45:32",
      "destination_hub": "Chennai",
      "origin_hub": "Coimbatore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Chennai",
      "flight_no": "TN04BC2219"
    },
    {
      "id": "257",
      "mawb_no": "312-29060286",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-04",
      "pickup_time": "12:37:00",
      "created_at": "2026-06-04 12:33:54",
      "updated_at": "2026-06-04 12:37:28",
      "destination_hub": "Hyderabad",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Hyderabad",
      "flight_no": "6E 816"
    },
    {
      "id": "256",
      "mawb_no": "312-29060216",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-04",
      "pickup_time": "13:06:00",
      "created_at": "2026-06-04 12:26:38",
      "updated_at": "2026-06-04 13:06:56",
      "destination_hub": "Mumbai",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5262"
    },
    {
      "id": "255",
      "mawb_no": "31229062924",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-04",
      "pickup_time": "16:40:00",
      "created_at": "2026-06-04 12:26:11",
      "updated_at": "2026-06-04 16:40:32",
      "destination_hub": "Mumbai",
      "origin_hub": "Hyderabad",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E 5213"
    },
    {
      "id": "254",
      "mawb_no": "MH02FG43141780499063",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-04",
      "pickup_time": "11:36:00",
      "created_at": "2026-06-04 11:36:23",
      "updated_at": "2026-06-04 11:36:23",
      "destination_hub": "Mumbai",
      "origin_hub": "Surat",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "BAY ROAD"
    },
    {
      "id": "253",
      "mawb_no": "31229058142",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-04",
      "pickup_time": "11:34:00",
      "created_at": "2026-06-04 11:34:51",
      "updated_at": "2026-06-04 11:34:51",
      "destination_hub": "Mumbai",
      "origin_hub": "Bangalore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5205"
    },
    {
      "id": "252",
      "mawb_no": "312-29056064",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-04",
      "pickup_time": "11:32:00",
      "created_at": "2026-06-04 11:32:52",
      "updated_at": "2026-06-04 11:34:03",
      "destination_hub": "Mumbai",
      "origin_hub": "Coimbatore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E2409 / 6E675"
    },
    {
      "id": "251",
      "mawb_no": "312-28931895",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-04",
      "pickup_time": "11:30:00",
      "created_at": "2026-06-04 11:30:14",
      "updated_at": "2026-06-04 11:30:14",
      "destination_hub": "Mumbai",
      "origin_hub": "Kolkatta",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E6366"
    },
    {
      "id": "250",
      "mawb_no": "29059446",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-04",
      "pickup_time": "11:27:00",
      "created_at": "2026-06-04 11:28:24",
      "updated_at": "2026-06-04 11:28:24",
      "destination_hub": "Mumbai",
      "origin_hub": "Indore",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6e-6598"
    },
    {
      "id": "249",
      "mawb_no": "312-29001055",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-03",
      "pickup_time": "13:36:00",
      "created_at": "2026-06-03 13:10:10",
      "updated_at": "2026-06-03 13:41:21",
      "destination_hub": "Delhi",
      "origin_hub": "Jaipur",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Delhi",
      "flight_no": "6E2165"
    },
    {
      "id": "248",
      "mawb_no": "98-05325924",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-04",
      "pickup_time": "11:43:00",
      "created_at": "2026-06-03 12:18:09",
      "updated_at": "2026-06-04 11:43:11",
      "destination_hub": "Mumbai",
      "origin_hub": "Kolkatta",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "AI 2410"
    },
    {
      "id": "247",
      "mawb_no": "31229001243",
      "hub_id": "1",
      "picked_by": null,
      "pickup_date": "2026-06-03",
      "pickup_time": "13:09:00",
      "created_at": "2026-06-03 11:50:47",
      "updated_at": "2026-06-03 13:09:22",
      "destination_hub": "Mumbai",
      "origin_hub": "Hyderabad",
      "origin_branch_name": "SURAT",
      "destination_branch_name": "Mumbai",
      "flight_no": "6E5213"
    }
  ]
}
```

**HTTP:** 200

---
