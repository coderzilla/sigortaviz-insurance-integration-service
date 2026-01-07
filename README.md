## SigortaVizz – Insurance Integration Service

Backend service (NestJS + TypeORM) that serves dynamic product configuration, normalizes quote inputs, and maps data to carrier APIs.

---

## 1) Run locally

- Prereqs: Node 18+, npm, MySQL 8+ (or compatible) reachable from your machine.
- Copy `.env.example` to `.env` (create one if missing) and set:
  - `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME`
  - `DB_SYNCHRONIZE=true` is OK for local/dev to auto-sync schema (avoid in prod).
- Install deps: `npm install`
- Start:
  - Dev (watch): `npm run start:dev`
  - Prod build + run: `npm run build && npm run start:prod`
- Health check: API uses the default Nest boot; reach `http://localhost:3000` (adjust if you changed the port).

Tests:
- Unit: `npm test`
- E2E: `npm run test:e2e`

---

## 2) Data model (core tables/entities)

- `products`: list of product types (`code`, `name`, `description`), e.g., `HEALTH`.
- `carriers`: insurance carriers (`code`, `name`, `isActive`), e.g., `AXA`.
- `carrier_products`: joins a `carrier` to a `product` with a carrier-specific `externalCode` and `isActive`.
- `carrier_product_field_sets`: versioned field sets per carrier-product. Columns:
  - `version`, `isActive`, `validFrom`, `validTo`
  - `pageChangeRequestJson` (optional request definition to call when changing pages)
  - `fields` (relation to `carrier_product_fields`)
- `carrier_product_fields`: individual form fields. Key columns:
  - `internalCode`, `label`, `description`, `inputType`, `required`
  - `orderIndex` (ordering within a page)
  - `page` (int, default 1) – which page of the form to render
  - `placeholder`, `validationRegex`, `minLength`, `maxLength`, `minValue`, `maxValue`
  - `optionsJson` (for selects/radios), `extraConfigJson` (misc per-field config)
  - `onBlurRequestJson` (optional request definition to trigger when the field blurs with a valid value)
- `carrier_field_mappings`: maps `internalCode` -> carrier API parameter name, plus `transformType` and `isRequiredForApi`.

Types exposed to clients (`src/common/types/field-types.ts`):
- `FieldConfig`: mirrors `carrier_product_fields` plus validation info and `onBlurRequest`.
- `ProductFormConfig`: `{ fields: FieldConfig[]; pageChangeRequest?: RequestTriggerConfig }`.

---

## 3) Config system flow

Endpoint:
- `GET /config?product=HEALTH&carrier=AXA`

Process (`ProductsService.getFieldConfig`):
1. Resolve active `carrier` and `product`; fetch active `carrier_product`.
2. Load active `carrier_product_field_sets` for that carrier-product.
3. Pick the effective set: latest `version` that is active and within `validFrom/validTo` window relative to the current date.
4. Build `ProductFormConfig`:
   - `fields`: sorted by `page`, then `orderIndex`. Each field includes validation rules, placeholders/options/extraConfig, and optional `onBlurRequest`.
   - `pageChangeRequest`: optional request descriptor from the field set, used by the UI between page transitions.

Request trigger shape (`RequestTriggerConfig`):
- `{ url: string; method?: 'GET' | 'POST'; params?: Record<string, any>; headers?: Record<string, string>; }`
- UI can template values (e.g., `{{value}}`, `{{form.*}}`, `{{currentPage}}`) before sending.

Usage:
- Call `/config` to render the multi-page form.
- On page change, if `pageChangeRequest` is present, fire it with the specified params/headers.
- On field blur with a valid value, if `onBlurRequest` exists for that field, fire it similarly.
- Collected form data maps to carrier API payload via `carrier_field_mappings`.

---

## 4) Sample seed (AXA Health)

Use the SQL snippet in the repo history/context (see prior assistant message) to insert:
- Product `HEALTH`
- Carrier `AXA`
- Carrier product `AXA_HEALTH_STD`
- Field set with two pages, blur trigger on TCKN, and a page-change trigger
- Carrier field mappings for API transforms

Adjust URLs and templated params to your real endpoints. Use `DB_SYNCHRONIZE=true` locally to let TypeORM create new columns (`page`, `onBlurRequestJson`, `pageChangeRequestJson`) if your DB is empty; otherwise run a migration that adds them.

---

## 5) Auth + lead capture (OTP-only)

New tables/entities: `users`, `identities`, `quote_sessions`, `quote_session_step_events` (audit trail), `vehicle_assets`, `property_assets`, `quote_session_asset_snapshots`, `otp_challenges`. See `src/migrations/1710000000000-init-auth-quote-session.ts`.

Key rules:
- Phone-based users; OTP-only login (`/auth/otp/request` + `/auth/otp/verify`). OTP codes are HMAC-hashed with salts; codes are **not** returned in API responses.
- Multiple identities per user (unique by `(userId, idNumberHash)`).
- Quote sessions persist step 1 (phone + idNumber) immediately, support multiple sessions per product and idempotency keys, and keep step history in `quote_session_step_events`.
- Assets: vehicle/property upsert for the authenticated user; snapshots can be attached to quote sessions.
- Lead token: unauthenticated quote creation returns a short-lived `leadToken` allowing step updates with the matching phone/session.

Example flows (curl):

```bash
# 1) Request OTP
curl -X POST http://localhost:3100/auth/otp/request \
  -H 'Content-Type: application/json' \
  -d '{"phoneNumber":"+905551234567","purpose":"LOGIN"}'

# 2) Verify OTP (replace 123456 with real code)
curl -X POST http://localhost:3100/auth/otp/verify \
  -H 'Content-Type: application/json' \
  -d '{"phoneNumber":"+905551234567","code":"123456"}'
# => { accessToken, user }

# 3) Create quote session (unauthenticated; returns leadToken)
curl -X POST http://localhost:3100/quote-sessions \
  -H 'Content-Type: application/json' \
  -d '{"productCode":"TRAFFIC","phoneNumber":"+905551234567","idNumber":"12345678901"}'

# 4) Update quote step with lead token
curl -X PATCH http://localhost:3100/quote-sessions/{sessionId}/step \
  -H 'Content-Type: application/json' \
  -H 'x-lead-token: {leadToken}' \
  -d '{"step":2,"payload":{"birthDate":"1990-01-01","email":"user@example.com"}}'

# 5) Authenticated asset + snapshot
curl -X POST http://localhost:3100/assets/vehicles \
  -H "Authorization: Bearer {accessToken}" \
  -H 'Content-Type: application/json' \
  -d '{"plate":"34ABC1","modelYear":2020,"brand":"Brand"}'

curl -X POST http://localhost:3100/quote-sessions/{sessionId}/assets/snapshot \
  -H "Authorization: Bearer {accessToken}" \
  -H 'Content-Type: application/json' \
  -d '{"assetType":"VEHICLE","assetId":"{vehicleId}"}'
```
