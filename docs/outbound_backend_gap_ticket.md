# Outbound Services V8 — backend questions (AXLPL Messenger)

Copy this into your ticket or email. Canonical spec: `docs/outbound_services_v8_apis.md`.

## Backend clarification checklist (copy to ticket / email)

Use this as the message body to the backend team. Check off when answered.

### Cross-cutting

- [ ] Sample JSON (success + common errors) for **all 26** endpoints.
- [ ] Canonical **branch_id** type (int vs string) and messenger’s `branchId` mapping.
- [ ] Does `lockbag` require only `bag_id`, or also `user_id` / `branch_id`?

### Reference data

- [ ] Which endpoint provides **branch/depot/hub dropdown** data for hub scan, bagging, manifest?
- [ ] Which endpoint returns **shipment master** by docket for hub scan auto-fill (if not `getshipmentscanhistory`)?

### Hub scan

- [ ] Web **Save** vs **Confirm** — one or two server calls? Second endpoint or different `status`?
- [ ] `gethubscanlogs` — pagination cursor, filters (`scan_type`, date range)?

### Bagging

- [ ] **`createbag`** sometimes returns `status: success` with `bag_id: 0` for invalid input — confirm server-side validation and DB side effects.
- [ ] Mapping between **metal seal** column and `bag_code`.
- [ ] **Print bag challan** — dedicated endpoint or reuse something else?

### Manifest

- [ ] **Airway vs Surface** — stored how? Extra POST field planned?
- [ ] Scan field “M/Bag code” — lookup by `getbagdetails` using code vs numeric `bag_id` only?

### Linehaul

- [ ] Full mapping from **Linehaul Booking** web fields to API(s). Is `assignlinehaul` sufficient or is there a **hidden/legacy** booking API?
- [ ] **Delete** / full **edit** linehaul — any endpoint?

### Sector pickup

- [ ] `getpickuplist` — filters (`branch_id`, date)? Any params for large fleets?
- [ ] `addmissedshipment` — full required POST body including `user_id` / `branch_id`?

### Reports

- [ ] `baggingreport`, `manifestreport`, `linehaulreport`, `pickupreport` — JSON list vs download URL vs file blob?

---

## Latest capture (27)

- Bearer: True (`OUTBOUND_LOGIN_MOBILE`)
- Working fine: **Yes 13**, **Partial 12**
- `createbag` / lists: see capture — `valid_bag_id_available=True`

