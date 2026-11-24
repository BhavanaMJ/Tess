# TESS — PHASE 3.4 API DOCUMENTATION
## Smart Capture: ChatGPT-Assisted Garment Import Workflow

### Base Route
`/api/v1/wardrobe/import`

All endpoints are mounted on the FastAPI backend and require standard Bearer token authentication via `Authorization: Bearer <JWT>` header (or bypass in local development via mock headers).

---

### Endpoint 1: Validate Metadata

#### `POST /api/v1/wardrobe/import/validate-metadata`
Validates a Schema Version 1.1 garment metadata JSON string or dictionary. Enforces structure, version, record type, required fields, and supported categories without persisting to the database.

#### Request Body
`application/json`
```json
{
  "raw_json": "{\n  \"schema_version\": \"1.1\",\n  \"record_type\": \"garment\",\n  \"identity\": {\n    \"garment_name\": \"Silk Blend Bandhgala\",\n    \"category\": \"Ethnic wear\",\n    \"subcategory\": \"Bandhgala\"\n  }\n}"
}
```
*Alternatively, the parsed dictionary can be supplied in `"metadata"` instead of `"raw_json"`.*

#### Success Response (`200 OK`)
```json
{
  "is_valid": true,
  "errors": [],
  "warnings": [
    "Fabric appearance not specified.",
    "Occasions list is empty."
  ],
  "normalized_metadata": {
    "schema_version": "1.1",
    "record_type": "garment",
    "identity": {
      "garment_name": "Silk Blend Bandhgala",
      "category": "Ethnic wear",
      "subcategory": "Bandhgala",
      "garment_type": null,
      "description": null,
      "gender_section": null,
      "custom_category": null
    },
    "appearance": { ... },
    "construction": { ... },
    "material": { ... },
    "sizing": { ... },
    "usage": { ... },
    "purchase": { ... },
    "care": { ... },
    "physical_location": { ... },
    "category_specific": { ... },
    "ai_metadata": { ... },
    "visual_assets": { ... },
    "notes": []
  }
}
```

#### Rejection Response (`200 OK` with `is_valid: false` or `422 Unprocessable Entity`)
```json
{
  "is_valid": false,
  "errors": [
    "This metadata version is not supported. Expected '1.1', found '1.0'.",
    "Please provide a garment name.",
    "Select a supported garment category. 'Spacesuit' is not recognized."
  ],
  "warnings": [],
  "normalized_metadata": null
}
```

---

### Endpoint 2: Upload Import Image

#### `POST /api/v1/wardrobe/import/upload-image`
Uploads either a mandatory studio catalogue photograph or an optional original photo. Saves the asset securely to Supabase Storage (or fallback local media directory) with content validation.

#### Request Form Data (`multipart/form-data`)
| Parameter | Type | Required | Description |
|---|---|---|---|
| `image` | Binary File | Yes | Image file (JPEG, PNG, WebP). Maximum size: 15MB. |
| `image_type` | String | Yes | Must be either `'catalogue'` or `'original'`. |

#### Success Response (`201 Created`)
```json
{
  "image_ref": "https://xyz.supabase.co/storage/v1/object/public/wardrobe-images/imports/cat_a891f7c.jpg",
  "image_type": "catalogue",
  "filename": "cat_a891f7c.jpg",
  "size_bytes": 1420850,
  "uploaded_at": "2026-11-24T18:30:00Z"
}
```

#### Error Response (`400 Bad Request`)
```json
{
  "detail": "Invalid image_type 'thumbnail'. Expected 'catalogue' or 'original'."
}
```

---

### Endpoint 3: Register Garment

#### `POST /api/v1/wardrobe/import/register`
Atomically generates the next sequential `CLO-xxx` garment ID, maps core attributes into relational columns on `wardrobe_items`, persists the full Schema 1.1 JSON tree in `metadata_payload`, and links visual assets.

#### Request Body
`application/json`
```json
{
  "catalogue_image_ref": "https://xyz.supabase.co/storage/v1/object/public/wardrobe-images/imports/cat_a891f7c.jpg",
  "original_image_ref": "https://xyz.supabase.co/storage/v1/object/public/wardrobe-images/imports/orig_b923a1d.jpg",
  "metadata": {
    "schema_version": "1.1",
    "record_type": "garment",
    "identity": {
      "garment_name": "Midnight Indigo Kurta",
      "category": "Tops",
      "subcategory": "Kurta"
    },
    "appearance": {
      "primary_colour": "Indigo",
      "secondary_colours": ["Silver", "Navy"],
      "pattern": "Solid with micro-weave"
    },
    "construction": {
      "neckline": "Mandarin Collar",
      "sleeve_length": "Full Sleeve",
      "fit": "Regular"
    },
    "material": {
      "fabric_appearance": "Handwoven Khadi Cotton"
    },
    "sizing": {
      "labelled_size": "L"
    },
    "usage": {
      "occasions": ["Festive", "Smart Casual"],
      "seasons": ["Spring", "Summer"]
    },
    "purchase": {
      "brand": "Fabindia",
      "purchase_price": 2499.0
    },
    "care": {
      "washing_method": "Hand wash cold separately"
    },
    "physical_location": {
      "storage_location": "Main Wardrobe, Hanger #12"
    },
    "category_specific": {},
    "ai_metadata": {
      "detection_source": "chatgpt_project",
      "model_name": "GPT-4o (TESS Custom Project)"
    },
    "visual_assets": {
      "catalogue_image_generated": true,
      "original_image_preserved": true
    }
  }
}
```

#### Success Response (`201 Created`)
```json
{
  "success": true,
  "message": "Garment successfully registered.",
  "garment": {
    "id": "CLO-019",
    "user_id": "test_user_id",
    "name": "Midnight Indigo Kurta",
    "main_category": "Tops",
    "subcategory": "Kurta",
    "primary_color": "Indigo",
    "secondary_colors": ["Silver", "Navy"],
    "pattern": "Solid with micro-weave",
    "fabric_material": "Handwoven Khadi Cotton",
    "neckline": "Mandarin Collar",
    "sleeve_length": "Full Sleeve",
    "fit": "Regular",
    "size": "L",
    "brand": "Fabindia",
    "purchase_price": 2499.0,
    "occasions": ["Festive", "Smart Casual"],
    "seasons": ["Spring", "Summer"],
    "storage_location": "Main Wardrobe, Hanger #12",
    "wash_care_instructions": "Hand wash cold separately",
    "processed_image_ref": "https://xyz.supabase.co/storage/v1/object/public/wardrobe-images/imports/cat_a891f7c.jpg",
    "original_image_ref": "https://xyz.supabase.co/storage/v1/object/public/wardrobe-images/imports/orig_b923a1d.jpg",
    "laundry_status": null,
    "is_favorite": false,
    "wear_count": 0,
    "created_at": "2026-11-24T18:35:00Z",
    "import_provenance": "User Imported (ChatGPT Project)",
    "metadata_version": "1.1",
    "has_metadata_payload": true
  }
}
```

#### Error Response (`400 Bad Request` or `422 Unprocessable Entity`)
- Missing catalogue image reference:
```json
{
  "detail": "A studio catalogue photograph reference is mandatory for garment registration."
}
```
- Invalid metadata payload:
```json
{
  "detail": "Garment metadata validation failed: Select a supported garment category."
}
```

---

### Category Mapping & Normalization Reference

The TESS import pipeline enforces canonical taxonomy while accepting commonly generated external AI aliases (case-insensitive, whitespace-trimmed).

#### Canonical Taxonomy & Accepted Aliases

| Accepted Input / Alias | Canonical TESS Category |
|---|---|
| `Bottoms`, `Bottomwear`, `Bottom Wear`, `Pants`, `Trousers`, `Lowerwear` | `Bottoms` |
| `Tops`, `Topwear`, `Upperwear` | `Tops` |
| `Ethnic Wear`, `Ethnicwear` | `Ethnic Wear` |
| `Dresses`, `Dress` | `Dresses` |
| `Outerwear` | `Outerwear` |
| `Activewear` | `Activewear` |
| `Innerwear` | `Innerwear` |
| `Sleepwear` | `Sleepwear` |
| `Footwear` | `Footwear` |
| `Accessories` | `Accessories` |

#### Subcategory & Garment Type Preservation
The normalization process preserves the exact descriptive `subcategory` (e.g., `Lounge Pants`, `Jeans`, `Leggings`, `Kurta`) and `garment_type` (e.g., `Printed Homewear Trousers`, `Casual Graphic Tee`) without modification.

#### Diagnostics & Provenance
When normalization occurs:
- A non-blocking warning is added to `warnings`: `"Category '[alias]' was automatically mapped to canonical category '[canonical]'."`
- The diagnostic is stored in `ai_metadata.diagnostics`:
  ```json
  {
    "category_normalization": {
      "category_normalized": true,
      "original_category": "Bottomwear",
      "canonical_category": "Bottoms"
    }
  }
  ```
- The user's raw JSON draft remains untouched.

#### Unsupported Category Handling
When an unrecognized category is provided without a valid `custom_category`, validation rejects the payload with:
`"Unsupported garment category: '<input>'. Supported categories are Tops, Bottoms, Ethnic Wear, Dresses, Outerwear, Activewear, Innerwear, Sleepwear, Footwear and Accessories."`


