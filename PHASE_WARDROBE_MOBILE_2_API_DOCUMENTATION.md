# TESS WARDROBE INTELLIGENCE — PHASE 2
## API DOCUMENTATION & SCHEMA SPECIFICATION

### Base Path
All wardrobe intelligence routes are mounted under:
`/api/v1/wardrobe`

All requests require authentication via Bearer token:
`Authorization: Bearer <supabase_jwt_token>`

---

### Endpoints

#### 1. List Wardrobe Categories
- **Route**: `GET /api/v1/wardrobe/categories`
- **Response**: `200 OK`
```json
[
  {
    "id": "c1",
    "name": "Tops",
    "icon_name": "checkroom",
    "display_order": 1
  },
  {
    "id": "c2",
    "name": "Bottoms",
    "icon_name": "straighten",
    "display_order": 2
  }
]
```

---

#### 2. List & Query Wardrobe Items
- **Route**: `GET /api/v1/wardrobe/items`
- **Query Parameters**:
  - `category` (string, optional): Filter by main category name (case-insensitive).
  - `laundry_status` (string, optional): Filter by operational laundry status (`CLEAN`, `WORN`, `WASHING`, `DRYING`, `STORED`).
  - `is_favorite` (bool, optional): Filter favorites only (`true` or `false`).
  - `search` (string, optional): Substring match across name, primary color, brand, pattern, fabric material.
  - `sort_by` (string, default: `"created_at"`): Sort column (`created_at`, `name`, `updated_at`).
  - `sort_order` (string, default: `"desc"`): Sort direction (`asc` or `desc`).
  - `page` (int, default: 1): Page number (1-indexed).
  - `limit` (int, default: 50): Number of items per page.
- **Response**: `200 OK`
```json
{
  "items": [
    {
      "id": "CLO-001",
      "user_id": "d6dd3895-95c9-414b-8f08-863ba3985492",
      "name": "Navy Blue Oxford Shirt",
      "main_category": "Tops",
      "subcategory": "Button-down",
      "original_image_ref": null,
      "processed_image_ref": null,
      "thumbnail_ref": null,
      "primary_color": "Navy Blue",
      "secondary_colors": ["White"],
      "pattern": "Solid",
      "fabric_material": "100% Cotton",
      "neckline": "Button-down Collar",
      "sleeve_length": "Full Sleeves",
      "fit": "Regular Fit",
      "silhouette": null,
      "garment_length": null,
      "size": "M",
      "brand": "Uniqlo",
      "purchase_date": "2024-01-15",
      "purchase_price": 39.90,
      "occasions": ["Work", "Casual"],
      "seasons": ["All-Season"],
      "laundry_status": "CLEAN",
      "is_favorite": true,
      "notes": "Machine wash cold",
      "is_archived": false,
      "created_at": "2026-11-22T14:00:00Z",
      "updated_at": "2026-11-22T14:00:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 50,
  "has_more": false
}
```

---

#### 3. Create Garment
- **Route**: `POST /api/v1/wardrobe/items`
- **Request Body**:
```json
{
  "id": "CLO-019",
  "name": "Olive Green Bomber Jacket",
  "main_category": "Outerwear",
  "subcategory": "Bomber Jacket",
  "primary_color": "Olive Green",
  "secondary_colors": ["Black"],
  "pattern": "Solid",
  "fabric_material": "Nylon",
  "sleeve_length": "Full Sleeves",
  "fit": "Regular Fit",
  "size": "L",
  "brand": "Alpha Industries",
  "purchase_price": 180.00,
  "laundry_status": "STORED",
  "is_favorite": false,
  "notes": "Spot clean only"
}
```
- **Response**: `201 Created` with created garment schema.

---

#### 4. Get Single Garment
- **Route**: `GET /api/v1/wardrobe/items/{id}`
- **Response**: `200 OK` with full garment schema.
- **Errors**: `404 Not Found` if item does not exist or belongs to another user.

---

#### 5. Full Update Garment
- **Route**: `PUT /api/v1/wardrobe/items/{id}`
- **Request Body**: Complete or partial `GarmentUpdate` payload.
- **Response**: `200 OK` with updated garment schema.

---

#### 6. Partial Patch Garment
- **Route**: `PATCH /api/v1/wardrobe/items/{id}`
- **Request Body**: Delta payload (e.g. `{"laundry_status": "WASHING"}` or `{"is_favorite": true}`).
- **Response**: `200 OK` with updated garment schema.

---

#### 7. Delete / Archive Garment
- **Route**: `DELETE /api/v1/wardrobe/items/{id}`
- **Query Parameters**:
  - `hard_delete` (bool, default: `false`): If `true`, permanently deletes the row from Supabase. If `false`, soft-archives by setting `is_archived = true`.
- **Response**: `200 OK`
```json
{
  "success": true,
  "id": "CLO-019",
  "hard_delete": false
}
```

---

#### 8. Wardrobe Telemetry Statistics
- **Route**: `GET /api/v1/wardrobe/stats`
- **Response**: `200 OK`
```json
{
  "total_garments": 18,
  "clean_count": 8,
  "worn_count": 3,
  "in_laundry_count": 2,
  "stored_count": 5,
  "unassigned_count": 0,
  "category_counts": {
    "Tops": 8,
    "Bottoms": 4,
    "Ethnic Wear": 3,
    "Dresses": 1,
    "Outerwear": 2
  },
  "laundry_counts": {
    "CLEAN": 8,
    "WORN": 3,
    "WASHING": 1,
    "DRYING": 1,
    "STORED": 5
  }
}
```

---

#### 9. Idempotent Initial Inventory Import
- **Route**: `POST /api/v1/wardrobe/import-initial`
- **Request Body**:
```json
{
  "items": [ ...array of GarmentCreate... ]
}
```
- **Response**: `200 OK`
```json
{
  "success": true,
  "imported_count": 18,
  "skipped_count": 0
}
```
If an item ID already exists for the user, it updates the record rather than duplicating it.
