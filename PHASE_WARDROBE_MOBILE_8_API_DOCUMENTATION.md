# Phase 8: REST API Documentation
## Wardrobe Wishlist & Shopping Intelligence

### Base URLs
- `/api/v1/wardrobe/wishlist`
- `/api/v1/wardrobe/shopping-intelligence`

All endpoints require JWT Bearer Authentication and enforce row-level tenant isolation (`user_id = current_user.id`).

---

### Wishlist Endpoints (`/api/v1/wardrobe/wishlist`)

#### 1. `GET /api/v1/wardrobe/wishlist`
Lists wishlist items with optional filters and sorting.

- **Query Parameters**:
  - `status`: `"CONSIDERING"` | `"SHORTLISTED"` | `"PURCHASED"` | `"NOT_INTERESTED"`
  - `priority`: `"HIGH"` | `"MEDIUM"` | `"LOW"`
  - `category`: Category name string
  - `sort_by`: `"created_at"` (default) | `"expected_price"` | `"priority"`
  - `sort_order`: `"desc"` (default) | `"asc"`
- **Response `200 OK`**:
```json
[
  {
    "id": "e6f42841-...",
    "user_id": "...",
    "name": "Black Tailored Trousers",
    "category": "Bottoms",
    "subcategory": "Trousers",
    "reference_image_path": "/api/v1/wardrobe/wishlist/images/.../ref_1.jpg",
    "expected_price": 3500.0,
    "expected_currency": "INR",
    "purchase_priority": "HIGH",
    "occasion": "Work",
    "desired_colour": "Black",
    "desired_pattern": "Solid",
    "description": null,
    "notes": "Client presentations",
    "status": "CONSIDERING",
    "purchased_at": null,
    "actual_purchase_price": null,
    "actual_purchase_currency": null,
    "converted_garment_id": null,
    "created_at": "2026-11-24T12:00:00Z",
    "updated_at": "2026-11-24T12:00:00Z"
  }
]
```

---

#### 2. `POST /api/v1/wardrobe/wishlist`
Creates a new wishlist item.

- **Request Body**: `WishlistItemCreate`
- **Response `201 Created`**: Returns created `WishlistItemResponse`.

---

#### 3. `GET /api/v1/wardrobe/wishlist/summary`
Returns aggregated count and financial totals.

- **Response `200 OK`**:
```json
{
  "total_items": 4,
  "high_priority_count": 2,
  "shortlisted_count": 1,
  "purchased_count": 1,
  "considering_count": 2,
  "not_interested_count": 0,
  "estimated_wishlist_value": {
    "INR": 9800.0
  },
  "purchased_total_value": {
    "INR": 3499.0
  },
  "unpriced_items_count": 1
}
```

---

#### 4. `GET /api/v1/wardrobe/wishlist/{item_id}`
Retrieves a single wishlist item.

---

#### 5. `PUT /api/v1/wardrobe/wishlist/{item_id}`
Updates details of an existing wishlist item.

---

#### 6. `DELETE /api/v1/wardrobe/wishlist/{item_id}`
Deletes a wishlist item (`204 No Content`).

---

#### 7. `PATCH /api/v1/wardrobe/wishlist/{item_id}/status`
Updates status with optional actual price and purchased timestamp.

- **Request Body**:
```json
{
  "status": "PURCHASED",
  "actual_purchase_price": 3299.0,
  "actual_purchase_currency": "INR",
  "purchased_at": "2026-11-24T12:00:00Z"
}
```

---

#### 8. `POST /api/v1/wardrobe/wishlist/{item_id}/convert-to-wardrobe`
Idempotently converts a purchased wishlist item into an active wardrobe garment (`CLO-xxx`).

- **Request Body**:
```json
{
  "actual_purchase_price": 3299.0,
  "actual_purchase_currency": "INR",
  "purchase_date": "2026-11-24",
  "laundry_status": null,
  "garment_name_override": null,
  "primary_color": null
}
```
- **Response `200 OK`**:
```json
{
  "wishlist_item": { ... },
  "garment": {
    "id": "CLO-59B12384",
    "name": "Black Tailored Trousers",
    "main_category": "Bottoms",
    "purchase_price": 3299.0,
    "purchase_currency": "INR",
    "laundry_status": null,
    "wear_count": 0
  },
  "message": "Successfully converted wishlist item to wardrobe garment"
}
```

---

### Shopping Intelligence Endpoints (`/api/v1/wardrobe/shopping-intelligence`)

#### 1. `GET /gaps`
Returns empirical wardrobe gaps identified by analysing existing inventory.

- **Response `200 OK`**:
```json
[
  {
    "id": "gap_bottoms_imbalance",
    "title": "Complementary Bottoms Imbalance",
    "category": "Bottoms",
    "suggested_subcategory": "Trousers",
    "suggested_color": "Black",
    "supporting_evidence": "You own 6 upper garments but only 1 bottom.",
    "current_inventory_count": 1,
    "compatible_existing_garment_ids": ["CLO-001", "CLO-003"],
    "compatible_existing_garment_names": ["Classic White Shirt", "Embroidered Kurta"],
    "potential_outfit_combinations_gained": 6,
    "explanation": "Adding a versatile neutral bottom immediately pairs with multiple existing tops.",
    "confidence_score": 0.92,
    "severity": "HIGH"
  }
]
```

---

#### 2. `POST /match`
Finds existing owned garments that are similar in category, subcategory, or color.

- **Request Body**:
```json
{
  "category": "Tops",
  "desired_colour": "White",
  "limit": 5
}
```

---

#### 3. `GET /assessment/{item_id}`
Generates an explainable purchase decision assessment for a specific wishlist item.

- **Response `200 OK`**:
```json
{
  "wishlist_item_id": "...",
  "wishlist_item_name": "Black Tailored Trousers",
  "outcome": "STRONG_ADDITION",
  "headline": "Strong Wardrobe Addition",
  "explanation": "Fills an authentic gap and seamlessly integrates with 5 existing pieces.",
  "existing_similar_garments": [],
  "has_similar_owned": false,
  "fills_category_gap": true,
  "fills_colour_gap": true,
  "compatible_pieces_count": 5,
  "potential_new_combinations": 6,
  "assessment_score": 85.0,
  "contributing_factors": [
    "Directly resolves a detected wardrobe gap in 'Bottoms'",
    "High styling versatility: pairs with 5 existing garments",
    "User flagged as High Purchase Priority"
  ],
  "recommendation_action": "Prioritize this purchase: it enhances wardrobe versatility."
}
```
