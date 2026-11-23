# Phase 7: REST API Documentation
## Wardrobe Insights, Usage Analytics & Personal Style Intelligence

### Base URL
`/api/v1/wardrobe/insights`

All endpoints require JWT Bearer Authentication and execute with row-level ownership isolation (`user_id = current_user.id`).

---

### Endpoints Specification

#### 1. `GET /overview`
Returns high-level wardrobe utilisation and lifecycle totals for a given temporal window.

- **Query Parameters**:
  - `period` (optional, default: `"30d"`): `"7d"` | `"30d"` | `"90d"` | `"all"`
  - `start_date` (optional, ISO 8601 string)
  - `end_date` (optional, ISO 8601 string)
- **Response `200 OK`**:
```json
{
  "period": "30d",
  "start_date": "2026-10-24T00:00:00Z",
  "end_date": "2026-11-23T20:30:00Z",
  "total_active_garments": 18,
  "total_archived_garments": 2,
  "total_worn_garments_in_period": 14,
  "unique_garments_worn_in_period": 8,
  "utilisation_percentage": 44.44,
  "clean_garments_count": 12,
  "in_laundry_count": 6,
  "never_worn_count": 3,
  "total_outfits_worn_in_period": 6,
  "total_investment": 38400.0,
  "average_cost_per_wear": 320.0,
  "currency": "INR"
}
```

---

#### 2. `GET /categories`
Returns category breakdown, item counts, and percentage distribution of active wardrobe.

- **Response `200 OK`**:
```json
[
  {
    "category": "Tops",
    "count": 7,
    "percentage_of_wardrobe": 38.89,
    "active_count": 7
  },
  {
    "category": "Bottoms",
    "count": 5,
    "percentage_of_wardrobe": 27.78,
    "active_count": 5
  }
]
```

---

#### 3. `GET /most-worn`
Returns garments with the highest wear count within the specified window.

- **Query Parameters**:
  - `period` (default: `"all"`): `"7d"` | `"30d"` | `"90d"` | `"all"`
  - `limit` (default: 5)
- **Response `200 OK`**:
```json
[
  {
    "garment_id": "CLO-001",
    "garment_name": "Classic White Shirt",
    "main_category": "Tops",
    "primary_color": "White",
    "image_url": "https://example.com/images/CLO-001.jpg",
    "wear_count": 14,
    "purchase_price": 2400.0,
    "purchase_currency": "INR",
    "cost_per_wear": 171.43,
    "last_worn_date": "2026-11-20T10:00:00Z",
    "laundry_status": "CLEAN"
  }
]
```

---

#### 4. `GET /least-worn` & `GET /neglected`
Returns garments with zero wears or dormant for more than the threshold (default: 60 days).

- **Query Parameters**:
  - `threshold_days` (default: 60)
  - `limit` (default: 10)
- **Response `200 OK`**:
```json
[
  {
    "garment_id": "CLO-009",
    "garment_name": "Yellow Party Top",
    "main_category": "Tops",
    "primary_color": "Yellow",
    "wear_count": 0,
    "purchase_price": 1800.0,
    "purchase_currency": "INR",
    "cost_per_wear": null,
    "neglect_reason": "never_recorded",
    "laundry_status": "CLEAN"
  }
]
```

---

#### 5. `GET /colours`
Returns normalisation of garment primary colors into canonical families.

- **Response `200 OK`**:
```json
[
  {
    "color_group": "Blue",
    "original_colors": ["Navy", "Sky Blue", "Denim"],
    "count": 6,
    "percentage": 33.33
  }
]
```

---

#### 6. `GET /cost-per-wear`
Returns full wardrobe financial performance, best value items, and unpriced items.

- **Response `200 OK`**:
```json
{
  "total_garments_count": 18,
  "garments_with_price_count": 14,
  "garments_without_price_count": 4,
  "total_investment": 38400.0,
  "currency": "INR",
  "average_cost_per_wear": 320.0,
  "items": [...],
  "best_value_garments": [...],
  "highest_cost_per_wear_garments": [...]
}
```

---

#### 7. `GET /outfit-repetition`
Returns frequency and average interval of repeated outfit combinations.

- **Response `200 OK`**:
```json
[
  {
    "outfit_id": "outfit_123",
    "outfit_name": "Office Smart Look",
    "wear_count": 4,
    "garment_names": ["Classic White Shirt", "Indigo Jeans"],
    "garment_ids": ["CLO-001", "CLO-002"],
    "last_worn_date": "2026-11-19T09:00:00Z",
    "average_interval_days": 7.0,
    "occasion": "Work"
  }
]
```

---

#### 8. `GET /capsule`
Returns capsule wardrobe score, anchor garments, and combination potential.

- **Response `200 OK`**:
```json
{
  "total_active_garments": 18,
  "capsule_ready_garments_count": 10,
  "average_versatility_score": 74.5,
  "anchor_garments": [...],
  "potential_outfit_combinations": 48
}
```

---

#### 9. `GET /recommendations`
Returns actionable AI advice (e.g. revive neglected piece, MVP garment celebrate, laundry recovery).

---

#### 10. `GET /style-memory` & `PUT /style-memory`
Retrieves or updates user style persona, preferred colors, categories, occasions, and personal style notes.
