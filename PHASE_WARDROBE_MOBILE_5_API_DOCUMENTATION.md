# TESS Wardrobe Intelligence — Mobile Phase 5 API Documentation
## Outfit Studio, AI Stylist & Lookbook Endpoints

**Base Path:** `/api/v1/wardrobe/outfits`  
**Authentication:** Bearer JWT (`auth.uid()`)  
**Format:** JSON (`application/json`)  

---

## 1. Endpoints Overview

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/generate` | Generate automatic outfit suggestions (Mode A) |
| `POST` | `/guided` | Generate guided pairings anchored on a seed garment (Mode B) |
| `POST` | `/validate` | Validate user-selected garments for availability & conflicts (Mode C) |
| `GET` | `` | List saved lookbook outfits with optional filters |
| `POST` | `` | Save an outfit combination to the lookbook |
| `GET` | `/{outfit_id}` | Retrieve details of a saved outfit with live garment laundry statuses |
| `PUT` | `/{outfit_id}` | Update outfit name, occasion, notes, favourite, or garments |
| `DELETE` | `/{outfit_id}` | Archive or delete a saved outfit |
| `POST` | `/{outfit_id}/wear` | Record outfit wear, updating garment statuses to WORN (Phase 4 integration) |

---

## 2. Detailed Endpoint Specifications

### 2.1 Mode A: Generate Automatic Suggestions
`POST /api/v1/wardrobe/outfits/generate`

#### Request Body:
```json
{
  "occasion": "Casual",
  "exclude_worn": true,
  "favorites_only": false,
  "limit": 5
}
```

#### Response: `200 OK`
```json
{
  "recommendations": [
    {
      "id": "rec_3fa85f64e8",
      "name": "Navy Oxford Shirt & Beige Chinos",
      "occasion": "Casual",
      "explanation": "The neutral balance of Beige Beige Chinos complements the Navy Blue Navy Oxford Shirt.",
      "is_available": true,
      "combination_fingerprint": "CLO-BOT-1:CLO-TOP-1",
      "garment_ids": ["CLO-TOP-1", "CLO-BOT-1"],
      "garments": [
        {
          "garment_id": "CLO-TOP-1",
          "name": "Navy Oxford Shirt",
          "main_category": "Tops",
          "primary_color": "Navy Blue",
          "secondary_colors": [],
          "pattern": "Solid",
          "laundry_status": "CLEAN",
          "is_eligible": true,
          "unavailability_reason": null
        },
        {
          "garment_id": "CLO-BOT-1",
          "name": "Beige Chinos",
          "main_category": "Bottoms",
          "primary_color": "Beige",
          "secondary_colors": [],
          "pattern": "Solid",
          "laundry_status": "CLEAN",
          "is_eligible": true,
          "unavailability_reason": null
        }
      ]
    }
  ],
  "total": 1
}
```

---

### 2.2 Mode B: Guided Styling Around Seed Garment
`POST /api/v1/wardrobe/outfits/guided`

#### Request Body:
```json
{
  "seed_garment_id": "CLO-ETH-1",
  "occasion": "Ethnic",
  "exclude_worn": true,
  "limit": 3
}
```

#### Response: `200 OK`
```json
{
  "recommendations": [
    {
      "id": "guided_98a76b5412",
      "name": "Styled with Pink Floral Kurta",
      "occasion": "Ethnic",
      "explanation": "The White Churidar Leggings in White anchors the ethnic silhouette of Pink Floral Kurta.",
      "is_available": true,
      "combination_fingerprint": "CLO-ETH-1:CLO-ETH-BOT-1",
      "garment_ids": ["CLO-ETH-1", "CLO-ETH-BOT-1"],
      "garments": [...]
    }
  ],
  "total": 1
}
```

---

### 2.3 Mode C: Validate Outfit Selection
`POST /api/v1/wardrobe/outfits/validate`

#### Request Body:
```json
{
  "garment_ids": ["CLO-TOP-1", "CLO-DRYING-1"]
}
```

#### Response: `200 OK`
```json
{
  "is_valid": true,
  "is_wearable": false,
  "conflicts": [
    "Drying Wool Sweater (CLO-DRYING-1): Garment is currently drying"
  ],
  "items": [...]
}
```

---

### 2.4 Wear Outfit (Phase 4 Integration)
`POST /api/v1/wardrobe/outfits/{outfit_id}/wear`

#### Request Body:
```json
{
  "idempotency_key": "wear-evt-20261122-001",
  "notes": "Worn to team offsite"
}
```

#### Response: `200 OK`
```json
{
  "outfit_id": "outfit_123456",
  "worn_at": "2026-11-22T15:30:00Z",
  "garments_updated": ["CLO-TOP-1", "CLO-BOT-1"],
  "wear_count": 1,
  "idempotency_key": "wear-evt-20261122-001"
}
```

