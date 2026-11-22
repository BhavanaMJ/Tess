# TESS Wardrobe Intelligence — Backend & Database Gap Analysis

**Feature:** TESS Wardrobe Intelligence / Personal Clothes Organizer  
**Backend:** FastAPI (`backend/app/`)  
**Database & Storage:** Supabase PostgreSQL & Supabase Storage  
**Date:** November 22, 2026  

---

## 1. Executive Summary

A comprehensive inspection of the existing FastAPI backend (`backend/app/`) and Supabase database integrations revealed that **no wardrobe-specific endpoints, database tables, or storage buckets currently exist**.

In Phase 1, the Flutter mobile application establishes the frontend domain, data models, and repository interfaces. The mobile application gracefully catches 404/503 responses and maintains an in-memory/local repository fallback so the UI remains fully functional and testable.

To transition from Phase 1 foundation to Phase 2 (Digital Wardrobe) and Phase 3 (Smart Capture), backend APIs, database tables, Row Level Security (RLS) policies, and Supabase Storage buckets must be provisioned.

---

## 2. API Endpoint Gap Analysis

The following REST API family must be implemented in FastAPI under `backend/app/api/wardrobe.py` and registered in `backend/app/main.py`:

| Endpoint | Method | Status | Required Request Payload | Expected Response | Description |
| :--- | :---: | :---: | :--- | :--- | :--- |
| `/api/v1/wardrobe/items` | `GET` | **MISSING** | Query params: `category`, `laundry_status`, `is_favorite` | `List[GarmentResponse]` | Fetch user garments with optional filtering |
| `/api/v1/wardrobe/items/{id}` | `GET` | **MISSING** | Path param: `id` | `GarmentResponse` | Fetch single garment metadata |
| `/api/v1/wardrobe/items` | `POST` | **MISSING** | `GarmentCreateRequest` (JSON) | `GarmentResponse` | Create new garment record |
| `/api/v1/wardrobe/items/{id}` | `PUT` | **MISSING** | `GarmentUpdateRequest` (JSON) | `GarmentResponse` | Update existing garment attributes |
| `/api/v1/wardrobe/items/{id}` | `DELETE` | **MISSING** | Path param: `id` | `{"success": true}` | Archive or delete garment |
| `/api/v1/wardrobe/categories` | `GET` | **MISSING** | None | `List[CategoryResponse]` | Fetch standard and custom user categories |
| `/api/v1/wardrobe/images/upload-url` | `POST` | **MISSING** | `{"file_name": str, "content_type": str}` | `{"upload_url": str, "image_ref": str}` | Pre-signed upload URL for Supabase Storage |
| `/api/v1/wardrobe/process-image` | `POST` | **MISSING** | `{"original_image_ref": str}` | `{"processed_image_ref": str, "attributes": dict}` | AI background removal & attribute extraction |
| `/api/v1/wardrobe/laundry/status` | `PUT` | **MISSING** | `{"garment_id": str, "status": str}` | `GarmentResponse` | Update laundry operational status |
| `/api/v1/wardrobe/outfits` | `GET/POST`| **MISSING** | Outfit definition payload | `List[OutfitResponse]` | Outfit Studio combinations (Phase 5) |

---

## 3. Database Schema Requirements (Supabase PostgreSQL)

The following tables must be created via Supabase SQL migration:

### 1. `wardrobe_categories`
```sql
CREATE TABLE public.wardrobe_categories (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon_name TEXT,
    parent_category_id TEXT REFERENCES public.wardrobe_categories(id),
    subcategories TEXT[] DEFAULT '{}',
    order_index INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. `wardrobe_items`
```sql
CREATE TABLE public.wardrobe_items (
    id TEXT PRIMARY KEY, -- e.g. 'CLO-001'
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    main_category TEXT NOT NULL,
    subcategory TEXT,
    original_image_ref TEXT,
    processed_image_ref TEXT,
    thumbnail_ref TEXT,
    primary_color TEXT NOT NULL,
    secondary_colors TEXT[] DEFAULT '{}',
    pattern TEXT,
    fabric_material TEXT,
    neckline TEXT,
    sleeve_length TEXT,
    fit TEXT,
    silhouette TEXT,
    garment_length TEXT,
    size TEXT,
    brand TEXT,
    purchase_date DATE,
    purchase_price NUMERIC(10, 2),
    occasions TEXT[] DEFAULT '{}',
    seasons TEXT[] DEFAULT '{}',
    laundry_status TEXT CHECK (laundry_status IN ('CLEAN', 'WORN', 'WASHING', 'DRYING', 'STORED') OR laundry_status IS NULL),
    is_favorite BOOLEAN DEFAULT FALSE,
    notes TEXT,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3. Future Support Tables (Phases 4–7)
- `outfits` (id, user_id, name, occasion, season, is_favorite, created_at)
- `outfit_items` (outfit_id, garment_id, layer_index, position)
- `wear_history` (id, user_id, garment_id, outfit_id, worn_date, notes)
- `laundry_records` (id, user_id, garment_id, previous_status, new_status, recorded_at)
- `wishlist_items` (id, user_id, name, target_category, target_color, price, url, notes)

---

## 4. Row Level Security (RLS) Policies

All tables must enforce strict user-scoped Row Level Security:

```sql
ALTER TABLE public.wardrobe_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wardrobe_categories ENABLE ROW LEVEL SECURITY;

-- Allow users to manage only their own garments
CREATE POLICY "Users can view own wardrobe items"
    ON public.wardrobe_items FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wardrobe items"
    ON public.wardrobe_items FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wardrobe items"
    ON public.wardrobe_items FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own wardrobe items"
    ON public.wardrobe_items FOR DELETE
    USING (auth.uid() = user_id);
```

---

## 5. Storage Architecture (Supabase Storage)

Create a dedicated Supabase Storage bucket named `wardrobe`:

```text
wardrobe/
    {user_id}/
        {garment_id}/
            original/     <-- Raw photograph uploaded from mobile camera/gallery
            processed/    <-- Clean transparent PNG on pure studio white canvas
            thumbnails/   <-- High-performance compressed WebP (256x256)
```

**Storage Security**:
- Bucket `wardrobe` is private.
- Authenticated users can only read/write files where path begins with `auth.uid() + '/*'`.

---

## 6. AI Processing Pipeline Dependencies (Phase 3)

Smart Capture image processing requires backend AI workers:
1. **Background Removal & Studio Normalization**: Rembg / BiRefNet / SAM (Segment Anything Model) running on GPU worker or Ollama/OpenRouter vision microservice.
2. **Attribute Extraction**: Vision-Language Model (e.g. Gemini 2.5 Flash / Qwen-VL) to extract primary color, neckline, sleeve length, pattern, and fabric from the photograph.
