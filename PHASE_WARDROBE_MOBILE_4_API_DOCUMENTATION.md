# TESS Wardrobe Intelligence — Mobile Phase 4 API Documentation
## Laundry Manager & Garment Lifecycle Endpoints

**Base Path:** `/api/v1/wardrobe`  
**Authentication:** Bearer JWT (Supabase Auth `auth.uid()`)  
**Format:** JSON (`application/json`)  

---

## 1. Endpoints Overview

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/laundry/stats` | Aggregated counts of garments by status, active batches, and unassigned garments |
| `GET` | `/laundry/items` | Filter garments by status (including `UNASSIGNED`), search query, and pagination |
| `PATCH` | `/items/{garment_id}/laundry-status` | Update individual garment laundry status with wear/wash counters and logging |
| `GET` | `/items/{garment_id}/laundry-history` | Retrieve full chronological lifecycle history of a garment |
| `POST` | `/laundry/batches` | Create a new laundry batch containing selected garment IDs |
| `GET` | `/laundry/batches` | List laundry batches for the user (active or historical) |
| `GET` | `/laundry/batches/{batch_id}` | Retrieve details of a specific batch including member garment states |
| `PATCH` | `/laundry/batches/{batch_id}/status` | Advance batch status along lifecycle with override safety |
| `POST` | `/laundry/batches/{batch_id}/items` | Add one or more garments to an existing batch |
| `DELETE` | `/laundry/batches/{batch_id}/items/{garment_id}` | Remove a garment from an active batch |

---

## 2. Detailed Endpoint Specifications

### 2.1 Get Laundry Dashboard Stats
`GET /api/v1/wardrobe/laundry/stats`

#### Response: `200 OK`
```json
{
  "clean_count": 8,
  "worn_count": 4,
  "washing_count": 2,
  "drying_count": 1,
  "stored_count": 3,
  "unassigned_count": 0,
  "total_tracked": 18,
  "active_batches_count": 2
}
```

---

### 2.2 Filter Garments by Laundry Status
`GET /api/v1/wardrobe/laundry/items?laundry_status=WORN&query=shirt&page=1&limit=50`

#### Query Parameters:
- `laundry_status` (optional): `CLEAN`, `WORN`, `WASHING`, `DRYING`, `STORED`, or `UNASSIGNED`.
- `query` (optional): Case-insensitive search on name, category, or notes.
- `page` (optional, default `1`): Page number.
- `limit` (optional, default `50`): Results per page.

#### Response: `200 OK`
```json
{
  "items": [
    {
      "id": "CLO-001",
      "user_id": "usr-123456",
      "name": "Navy Oxford Button-Down",
      "category": "TOPS",
      "laundry_status": "WORN",
      "wear_count": 3,
      "wash_count": 2,
      "last_worn_date": "2026-11-22T14:30:00Z",
      "last_washed_date": "2026-11-18T10:15:00Z",
      "active_batch_id": null
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 50,
  "pages": 1
}
```

---

### 2.3 Update Garment Laundry Status
`PATCH /api/v1/wardrobe/items/{garment_id}/laundry-status`

#### Request Body:
```json
{
  "status": "WORN",
  "notes": "Worn to client presentation",
  "idempotency_key": "clo001-worn-20261122",
  "remove_from_batch": false
}
```

#### Transition Behavior:
- Setting `status: "WORN"` increments `wear_count` by 1 and sets `last_worn_date = NOW()`.
- Setting `status: "CLEAN"` from `WASHING` or `DRYING` increments `wash_count` by 1 and sets `last_washed_date = NOW()`.
- Setting `status: null` resets status to unassigned without decrementing historical counts.
- Duplicate identical requests with the same status return current state idempotently.

#### Response: `200 OK`
```json
{
  "id": "CLO-001",
  "laundry_status": "WORN",
  "wear_count": 3,
  "wash_count": 2,
  "last_worn_date": "2026-11-22T14:30:00Z",
  "last_washed_date": "2026-11-18T10:15:00Z",
  "active_batch_id": null
}
```

---

### 2.4 Get Garment Laundry History
`GET /api/v1/wardrobe/items/{garment_id}/laundry-history`

#### Response: `200 OK`
```json
[
  {
    "id": "hist-9901",
    "garment_id": "CLO-001",
    "previous_status": "CLEAN",
    "new_status": "WORN",
    "batch_id": null,
    "source": "USER_MANUAL",
    "notes": "Worn to client presentation",
    "created_at": "2026-11-22T14:30:00Z"
  },
  {
    "id": "hist-9801",
    "garment_id": "CLO-001",
    "previous_status": "DRYING",
    "new_status": "CLEAN",
    "batch_id": "batch-102",
    "source": "BATCH_PROGRESSION",
    "notes": "Batch completed",
    "created_at": "2026-11-18T10:15:00Z"
  }
]
```

---

### 2.5 Create Laundry Batch
`POST /api/v1/wardrobe/laundry/batches`

#### Request Body:
```json
{
  "name": "Midweek Dark Wash",
  "batch_type": "STANDARD",
  "garment_ids": ["CLO-001", "CLO-004", "CLO-008"],
  "notes": "Cold cycle 30C"
}
```

#### Response: `201 Created`
```json
{
  "id": "batch-102",
  "user_id": "usr-123456",
  "name": "Midweek Dark Wash",
  "batch_type": "STANDARD",
  "status": "CREATED",
  "notes": "Cold cycle 30C",
  "item_count": 3,
  "created_at": "2026-11-22T15:00:00Z",
  "updated_at": "2026-11-22T15:00:00Z",
  "completed_at": null,
  "items": [
    {
      "garment_id": "CLO-001",
      "initial_laundry_status": "WORN",
      "current_laundry_status": "WORN"
    }
  ]
}
```

---

### 2.6 Advance Batch Lifecycle
`PATCH /api/v1/wardrobe/laundry/batches/{batch_id}/status`

#### Request Body:
```json
{
  "next_status": "WASHING",
  "notes": "Started washer with lavender detergent"
}
```

#### Lifecycle State Progression:
- `CREATED` → `WASHING` (all batch garments transition to `WASHING`)
- `WASHING` → `DRYING` (all garments not overridden transition to `DRYING`)
- `DRYING` → `COMPLETED` (all garments transition to `CLEAN`, wash count +1, disassociated from batch)

#### Response: `200 OK`
```json
{
  "id": "batch-102",
  "status": "WASHING",
  "item_count": 3,
  "overridden_item_count": 0,
  "updated_at": "2026-11-22T15:05:00Z"
}
```
