# TESS Wardrobe Intelligence — Phase 3 API Documentation
## Smart Capture, AI Garment Detection & Batch Confirmation Endpoints

**Base Path:** `/api/v1/wardrobe/capture`  
**Authentication:** Required (`Authorization: Bearer <supabase_jwt_or_dev_token>`)  
**Security:** Supabase Row Level Security (RLS) active on all tables.

---

## 1. Endpoints Overview

| Method | Endpoint | Description | Status Codes |
|---|---|---|---|
| `POST` | `/api/v1/wardrobe/capture/upload` | Upload photograph and initialize async capture job | `200`, `400`, `401`, `422` |
| `GET` | `/api/v1/wardrobe/capture/jobs/{job_id}` | Retrieve capture job status, progress, and stage | `200`, `401`, `404` |
| `GET` | `/api/v1/wardrobe/capture/jobs/{job_id}/candidates` | Retrieve detected garment candidates for review | `200`, `401`, `404` |
| `PATCH` | `/api/v1/wardrobe/capture/candidates/{candidate_id}` | Update candidate attributes, name, or inclusion | `200`, `401`, `404` |
| `POST` | `/api/v1/wardrobe/capture/jobs/{job_id}/retry` | Re-run vision processing on preserved original photo | `200`, `401`, `404` |
| `POST` | `/api/v1/wardrobe/capture/jobs/{job_id}/confirm` | Register approved candidates into My Wardrobe | `200`, `400`, `401`, `404` |

---

## 2. Endpoint Details

### 2.1 POST `/api/v1/wardrobe/capture/upload`
Uploads a photograph via `multipart/form-data`. Validates image bytes, saves raw image into `app/media/wardrobe/{user_id}/raw/`, and kicks off vision analysis.

**Form Data:**
- `file`: `UploadFile` (image/jpeg, image/png, image/webp)

**Response `200 OK`:**
```json
{
  "id": "e964147c-2b28-48b4-9da2-3bbdb0db54bc",
  "user_id": "00000000-0000-0000-0000-000000000001",
  "original_image_ref": "media/wardrobe/00000000-0000-0000-0000-000000000001/raw/raw_1774360000_photo.jpg",
  "status": "AWAITING_APPROVAL",
  "current_stage": "Analysis complete. Awaiting user review.",
  "progress_percent": 100,
  "total_detected": 2,
  "provider_type": "DEVELOPMENT_LOCAL",
  "candidates": [
    {
      "id": "76c5b967-3729-4d69-b5a8-4e1837bc905d",
      "job_id": "e964147c-2b28-48b4-9da2-3bbdb0db54bc",
      "suggested_name": "Navy Top Garment",
      "main_category": "Tops",
      "subcategory": "Shirt",
      "primary_color": "Navy",
      "secondary_colors": [],
      "pattern": "Solid",
      "fabric_material": "Cotton",
      "confidence_scores": {
        "category": "HIGH",
        "primary_color": "HIGH",
        "pattern": "MEDIUM"
      },
      "processed_image_ref": "media/wardrobe/.../studio_cand_1.png",
      "is_included": true,
      "is_approved": false
    }
  ]
}
```

---

### 2.2 PATCH `/api/v1/wardrobe/capture/candidates/{candidate_id}`
Updates individual candidate fields before approval.

**Request Body:**
```json
{
  "suggested_name": "Premium Oxford Shirt",
  "main_category": "Tops",
  "subcategory": "Button-Down",
  "primary_color": "Navy",
  "brand": "Brooks Brothers",
  "is_included": true
}
```

**Response `200 OK`:** Returns updated candidate object.

---

### 2.3 POST `/api/v1/wardrobe/capture/jobs/{job_id}/confirm`
Finalizes the capture job. Registers all included candidates as permanent garments in `wardrobe_items` with sequential `CLO-xxx` IDs and `laundry_status = null`.

**Request Body:**
```json
{
  "candidate_ids": [
    "76c5b967-3729-4d69-b5a8-4e1837bc905d"
  ]
}
```

**Response `200 OK`:**
```json
{
  "success": true,
  "job_id": "e964147c-2b28-48b4-9da2-3bbdb0db54bc",
  "registered_count": 1,
  "registered_garment_ids": ["CLO-019"],
  "registered_garments": [
    {
      "id": "CLO-019",
      "name": "Premium Oxford Shirt",
      "category": "Tops",
      "primary_color": "Navy",
      "laundry_status": null
    }
  ]
}
```

