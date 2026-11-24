# Phase 3.4 — Architecture Audit & Technical Feasibility Report
## AI Garment Catalogue & Metadata Generator: ChatGPT-Assisted Import Workflow

**Document Version:** 1.0  
**Date:** November 24, 2026  
**Status:** Architecture Audit Complete — Pending Implementation Review  
**Subphase:** 3.4.1 (Repository Audit)  

---

## 1. Executive Summary

Phase 3.4 establishes an import-first Smart Capture strategy for TESS: **TESS — AI Garment Catalogue & Metadata Generator**. 

Rather than relying on unreliable, hardware-constrained on-device vision generation (Phase 3.3), Phase 3.4 empowers users to leverage an external dedicated ChatGPT Project (*"TESS — AI GARMENT CATALOGUE & METADATA GENERATOR"*) to generate:
1. A clean, studio-quality catalogue photograph from their original garment photo.
2. Comprehensive, structured garment metadata adhering to **TESS Garment Metadata Schema Version 1.1**.

TESS provides a dedicated 4-stage mobile import and verification experience to ingest, validate, review, and register these garments safely into the user's wardrobe.

---

## 2. Current Architecture & Repository Audit

### 2.1 Backend Architecture
- **Framework:** FastAPI with Python 3.10 and Pydantic v2 schemas.
- **Database:** Supabase PostgreSQL with strict Row Level Security (RLS) on all user tables.
- **Session Memory Fallback:** `WardrobeService` maintains an in-memory session cache (`_SESSION_WARDROBE_STORE`) allowing the system to operate smoothly during unit tests and offline database simulations.
- **Image Storage & Serving:**
  - Files are stored in user-scoped folders on the filesystem: `backend/app/media/wardrobe/<user_id>/<folder>/<filename>`.
  - Served via `GET /api/v1/wardrobe/capture/images/{user_id}/{folder}/{filename}` with support for both `Authorization: Bearer <token>` and query parameter `?token=<token>`.
- **Existing Endpoints:**
  - Core Wardrobe: `GET/POST /api/v1/wardrobe/items`, `GET/PUT/DELETE /api/v1/wardrobe/items/{id}`, `GET /api/v1/wardrobe/categories`.
  - Capture Pipeline (Phases 3.1 & 3.2): `POST /api/v1/wardrobe/capture/jobs`, `GET /jobs/{id}`, `GET /jobs/{id}/candidates`, `PATCH /candidates/{id}`, `POST /jobs/{id}/confirm`, `GET /jobs/{id}/diagnostic`.
- **Garment ID Generation:**
  - Handled sequentially (`CLO-001`, `CLO-002`, ..., `CLO-018` for baseline).
  - Next ID is computed by inspecting existing IDs matching `CLO-([0-9]+)` and taking `MAX + 1`.

### 2.2 Flutter Mobile Architecture
- **Framework:** Flutter 3.x with Dart null-safety.
- **Design System:** Dark spatial UI (`WardrobeTheme.voidBg`, `spatialSurface`, `elevatedSurface`, `electricViolet`, `electricCyan`, `textPrimary`, `textSecondary`, `textMuted`, `statusSuccess`, `statusWarning`, `statusCritical`).
- **Domain Entities:** `Garment`, `Category`, `LaundryStatus`, `CaptureJob`, `GarmentCandidate`.
- **State Management:** `ChangeNotifier` controllers (`WardrobeController`, `WardrobeCaptureController`).
- **Network Client:** `ApiClient` handling authentication headers, multipart payloads, and JSON transformations.
- **Local Persistence:** `shared_preferences: ^2.5.6` installed and active.
- **Image Picker:** `image_picker: ^1.2.4` for device gallery and camera capture.

---

## 3. Database Structure & Schema Extension Strategy

### 3.1 Existing `wardrobe_items` Schema
In `backend/migrations/001_wardrobe.sql`, `wardrobe_items` contains columns:
- `id` (e.g. `'CLO-001'`), `user_id` (UUID), `name`, `main_category`, `subcategory`.
- `original_image_ref`, `processed_image_ref`, `thumbnail_ref`.
- `primary_color`, `secondary_colors` (TEXT[]), `pattern`, `fabric_material`.
- `neckline`, `sleeve_length`, `fit`, `silhouette`, `garment_length`, `size`, `brand`.
- `purchase_date`, `purchase_price`, `purchase_currency`, `occasions` (TEXT[]), `seasons` (TEXT[]).
- `laundry_status` (CHECK constraint: `CLEAN`, `WORN`, `WASHING`, `DRYING`, `STORED` or `NULL`).
- `is_favorite`, `notes`, `is_archived`, `created_at`, `updated_at`.

### 3.2 Schema Gap Analysis: Schema 1.1 vs Database
The **TESS Garment Metadata Schema Version 1.1** introduces structured sections:
1. `identity` (garment_type, description, gender_section, custom_category)
2. `appearance` (accent_colours, colour_family, colour_temperature, colour_distribution, pattern_scale, pattern_density, pattern_placement, print_technique, visual_texture, surface_finish)
3. `construction` (collar_type, sleeve_style, sleeve_finish, shoulder_style, hemline, waist_design, closure_type, pocket_details, lining, embroidery, embellishments, slit_details, border_details, back_design)
4. `material` (primary_material, secondary_material, fabric_composition, weave_type, fabric_weight, stretch, transparency, thickness, drape, texture)
5. `sizing` (labelled_size, size_system, fit_type, measurements: chest, waist, hip, etc., alteration_details)
6. `usage` (weather_suitability, dress_code, style_aesthetic, formality_level, comfort_rating, activity_suitability, compatible_accessories)
7. `purchase` (product_name, purchase_source, store_name, product_url, invoice_reference, ownership_status)
8. `care` (washing_method, washing_temperature, bleach_allowed, ironing_temperature, drying_method, dry_cleaning, care_label_instructions, care_precautions)
9. `physical_location` (storage_location, storage_section, shelf, drawer, hanger_section, storage_container, location_notes)
10. `category_specific` (dynamic dict)
11. `ai_metadata` (detection_source, vision_provider, image_generation_provider, model_name, processing_timestamp, schema_version, attribute_confidence, verification_status, user_verified_fields, user_corrected_fields)
12. `visual_assets` (original_image_description, catalogue_image_description, catalogue_image_generated, original_image_preserved)

### 3.3 Proposed Non-Destructive Database Extension
To prevent cluttering SQL with 60+ new columns and maintain complete backward compatibility with Phases 1–8:
1. **Core Relational Mapping:** Map primary visual and operational attributes to existing top-level columns (`name`, `main_category`, `subcategory`, `primary_color`, `secondary_colors`, `pattern`, `fabric_material`, `neckline`, `sleeve_length`, `fit`, `silhouette`, `garment_length`, `size`, `brand`, `purchase_date`, `purchase_price`, `purchase_currency`, `occasions`, `seasons`, `notes`, `original_image_ref`, `processed_image_ref`, `laundry_status`).
2. **JSONB Extension Columns (Migration `008_garment_metadata_import.sql`):**
   ```sql
   ALTER TABLE public.wardrobe_items
       ADD COLUMN IF NOT EXISTS metadata_payload JSONB DEFAULT '{}'::jsonb,
       ADD COLUMN IF NOT EXISTS metadata_version VARCHAR(16) DEFAULT '1.1',
       ADD COLUMN IF NOT EXISTS import_provenance VARCHAR(64) DEFAULT 'CHATGPT_IMPORT';
   ```
3. **Integrity Rule:** Unknown scalar fields remain `null`; unknown lists remain `[]`. No default values are fabricated.

---

## 4. Existing Reusable Components

| Component / Subsystem | Location | Reusability in Phase 3.4 |
| :--- | :--- | :--- |
| `GarmentImagePlaceholder` | `flutter_app/.../garment_image_placeholder.dart` | Reused for rendering imported catalogue and original image previews with relative URL support. |
| `GarmentAttributeEditor` | `flutter_app/.../garment_attribute_editor.dart` | Pattern and category chips reused for the review and editing screen. |
| `WardrobeTheme` | `flutter_app/.../wardrobe_theme.dart` | Complete reuse of dark spatial palette, card styles, and buttons. |
| `ApiClient` | `flutter_app/.../api_client.dart` | Reused for multipart image uploading and JSON payload submission. |
| Image Serving API | `backend/app/api/wardrobe_capture.py` | `serve_capture_image` handles user-scoped secure streaming with `?token=` query param support. |
| Sequential ID Generator | `backend/app/services/wardrobe/capture_service.py` | Adapted with thread/database locks to enforce concurrent-safe `CLO-xxx` ID allocation. |
| `SharedPreferences` | `flutter_app` | Reused for local draft auto-saving and recovery. |

---

## 5. Required New Endpoints & Services

### 5.1 Backend (`backend/app/api/wardrobe_import.py`)
1. `POST /api/v1/wardrobe/import/validate-metadata`
   - Validates incoming raw JSON against Pydantic schema `GarmentMetadataInterchangeV1_1`.
   - Returns validation errors, normalized metadata, and attribute status.
2. `POST /api/v1/wardrobe/import/upload-image`
   - Accepts multipart image (`image_type`: `"catalogue"` or `"original"`).
   - Validates file type (`image/jpeg`, `image/png`, `image/webp`) and size ($\le 15\text{MB}$).
   - Saves to `media/wardrobe/<user_id>/catalogue/` or `media/wardrobe/<user_id>/originals/`.
   - Returns user-scoped image reference.
3. `POST /api/v1/wardrobe/import/register`
   - Accepts validated metadata, catalogue image reference, and optional original image reference.
   - Atomically allocates sequential `CLO-xxx` ID.
   - Saves record to `wardrobe_items` with `metadata_payload` and `laundry_status: null`.
   - Cleans up temporary artifacts.

### 5.2 Flutter Architecture (`flutter_app/lib/features/wardrobe/`)
1. **Domain Entities & Models:**
   - `domain/entities/garment_metadata_v1_1.dart` (Strongly-typed entity representing the 1.1 tree).
   - `data/models/garment_metadata_model_v1_1.dart` (Serialization, parsing, and JSON validation).
2. **Services & Repositories:**
   - `data/services/wardrobe_import_api_service.dart`.
   - `data/repositories/wardrobe_import_repository_impl.dart`.
3. **Controller & State:**
   - `presentation/controllers/garment_import_controller.dart` (Manages 4-stage wizard, image picking, JSON parsing, draft auto-save/restore, validation errors, and registration).
4. **Screens & Views:**
   - `presentation/screens/garment_import_wizard_screen.dart` (Coordinator with step indicator).
   - `presentation/widgets/import_stage1_prepare.dart` (Original photo & ChatGPT instructions).
   - `presentation/widgets/import_stage2_catalogue.dart` (Mandatory catalogue photo upload & preview).
   - `presentation/widgets/import_stage3_json.dart` (JSON paste, file import, syntax & schema validator).
   - `presentation/widgets/import_stage4_review.dart` (Collapsible attribute categories, provenance tags, edit controls, final Add to My Wardrobe confirmation).

---

## 6. Compatibility & Guardrails Analysis

1. **Non-Destructive Wardrobe Guarantee:** Existing items `CLO-001` through `CLO-018` remain unmodified. All previous Phase 1–8 unit tests must pass without modification.
2. **Laundry Lifecycle Isolation:** Newly registered garments must strictly possess `laundry_status: null`. They do not enter laundry batches until explicitly worn or washed by the user.
3. **No False Automation Claims:** Provenance is explicitly tracked and displayed as `"User Imported (ChatGPT Project)"`, avoiding fake claims of automated vision generation.
4. **Backward Compatibility:** All existing wardrobe screens (`WardrobeOverviewScreen`, `WardrobeInventoryScreen`, `OutfitStudioScreen`, `CalendarScreen`, `InsightsScreen`, `WishlistScreen`) continue to function without schema regressions.
5. **Entry Point Integration:**
   - `My Wardrobe → Add Garment` bottom sheet will offer a 3rd distinct option: **"AI Garment Catalogue Import (ChatGPT-Assisted)"** alongside "Smart Capture (Camera & AI)" and "Add Garment Manually".

---

## 7. Implementation Plan (Subphases 3.4.2 — 3.4.6)

1. **Subphase 3.4.2 — Metadata Schema & Validation:**
   - Define Pydantic V2 schema in backend: `backend/app/schemas/wardrobe_import.py`.
   - Define Dart entity & model in Flutter: `garment_metadata_v1_1.dart`.
   - Implement `POST /api/v1/wardrobe/import/validate-metadata`.
   - Unit test validation rules (valid schemas, malformed JSON, unsupported versions, empty arrays, null values).
2. **Subphase 3.4.3 — Image Import Pipeline:**
   - Implement `POST /api/v1/wardrobe/import/upload-image`.
   - Implement Stage 1 (Original Photo) & Stage 2 (Catalogue Image) UI in Flutter.
   - Implement file format & size validation, replacement, removal, and draft caching.
3. **Subphase 3.4.4 — JSON Import & Review Workspace:**
   - Implement Stage 3 (Paste / File import with real-time error highlight).
   - Implement Stage 4 (Collapsible review groups, provenance badges, inline attribute editing).
4. **Subphase 3.4.5 — Backend Registration & Atomic ID Allocation:**
   - Implement `POST /api/v1/wardrobe/import/register`.
   - Implement safe `CLO-xxx` allocation and rollback on failure.
   - Apply database migration `008_garment_metadata_import.sql`.
5. **Subphase 3.4.6 — Integration QA & Regression Verification:**
   - Run end-to-end import using real test image and metadata.
   - Run 100% backend test suite (`pytest`) and Flutter test suite (`flutter test`).
   - Run `flutter analyze` ensuring 0 issues.
   - Produce documentation suite (`PHASE_3_4_*.md`).

