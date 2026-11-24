# TESS — PHASE 3.4 DATABASE CHANGES
## Smart Capture: ChatGPT-Assisted Garment Import Workflow

### Overview
Phase 3.4 introduces Schema Version 1.1 structured metadata import into TESS without altering or breaking existing relational garment tables, laundry workflows, or baseline seed data (`CLO-001` through `CLO-018`).

To store the full 12-section Schema 1.1 tree with 100% attribute fidelity while maintaining ultra-fast SQL queries for core visual attributes, the database schema extends `wardrobe_items` with JSONB extensibility and provenance tracking.

---

### Migration File
`backend/migrations/008_garment_metadata_import.sql`

```sql
-- Migration 008: Add JSONB payload and import provenance to wardrobe_items
-- Supports Schema Version 1.1 ChatGPT-assisted manual garment imports

ALTER TABLE wardrobe_items
ADD COLUMN IF NOT EXISTS metadata_payload JSONB,
ADD COLUMN IF NOT EXISTS metadata_version VARCHAR(16) DEFAULT '1.1',
ADD COLUMN IF NOT EXISTS import_provenance VARCHAR(64) DEFAULT 'user_manual';

-- GIN index for efficient deep querying on nested JSON attributes
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_metadata_payload
ON wardrobe_items USING GIN (metadata_payload);

-- Index for querying import provenance
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_import_provenance
ON wardrobe_items (import_provenance);
```

---

### Table Alterations

| Column | Type | Default | Description |
|---|---|---|---|
| `metadata_payload` | `JSONB` | `NULL` | Complete, unadulterated Schema 1.1 JSON metadata tree containing all 12 sections (`identity`, `appearance`, `construction`, `material`, `sizing`, `usage`, `purchase`, `care`, `physical_location`, `category_specific`, `ai_metadata`, `visual_assets`, and `notes`). |
| `metadata_version` | `VARCHAR(16)` | `'1.1'` | Version identifier for future schema evolution and migrations. |
| `import_provenance` | `VARCHAR(64)` | `'user_manual'` | Provenance tag. For ChatGPT-assisted imports, this is explicitly stamped as `'User Imported (ChatGPT Project)'` (or `'chatgpt_project'`), preserving absolute provenance integrity. |

---

### Relational Column Mapping

During garment registration via `POST /api/v1/wardrobe/import/register`, core searchable attributes are automatically mapped from the Schema 1.1 structure into the standard relational columns of `wardrobe_items`, while the complete raw tree is simultaneously persisted in `metadata_payload`:

| Schema 1.1 JSON Path | Database Column | Notes |
|---|---|---|
| `identity.garment_name` | `name` | Primary display name |
| `identity.category` | `main_category` | Tops, Bottoms, Ethnic wear, Dresses, etc. |
| `identity.subcategory` | `subcategory` | e.g. Kurta, Chinos, Oxford Shirt |
| `appearance.primary_colour` | `primary_color` | Normalized primary color |
| `appearance.secondary_colours` | `secondary_colors` | PostgreSQL array `TEXT[]` |
| `appearance.pattern` | `pattern` | Micro-weave, Solid, Plaid, etc. |
| `material.fabric_appearance` | `fabric_material` | Khadi Cotton, Linen, Silk, etc. |
| `construction.neckline` | `neckline` | Mandarin, Crew, V-neck, etc. |
| `construction.sleeve_length` | `sleeve_length` | Full Sleeve, Half Sleeve, Sleeveless |
| `construction.fit` | `fit` | Slim, Regular, Relaxed |
| `sizing.labelled_size` | `size` | S, M, L, XL, 32, 40, etc. |
| `purchase.brand` | `brand` | Fabindia, Zara, etc. |
| `purchase.purchase_price` | `purchase_price` | Numeric cost |
| `usage.occasions` | `occasions` | PostgreSQL array `TEXT[]` |
| `usage.seasons` | `seasons` | PostgreSQL array `TEXT[]` |
| `care.washing_method` | `wash_care_instructions`| Machine wash cold, Dry clean, etc. |
| `physical_location.storage_location`| `storage_location` | Wardrobe section / Hanger |
| *Uploaded catalogue image* | `processed_image_ref` | **Mandatory** high-res studio shot |
| *Uploaded original photo* | `original_image_ref` | Optional original phone capture |
| *Initial laundry state* | `laundry_status` | **Strictly `NULL`** (unassigned) |

---

### Integrity & Safety Constraints
1. **Zero Impact on Baseline Records**: Existing seed garments `CLO-001` through `CLO-018` remain unmodified with `metadata_payload` as `NULL`.
2. **Sequential Atomic ID Generation**: Garment IDs are generated sequentially on the server (`CLO-019`, `CLO-020`, etc.) using row-locking atomic transactions. IDs from ChatGPT are never accepted.
3. **Initial Laundry State**: Newly imported garments always have `laundry_status = NULL`. They must not appear in dirty laundry bins or active wash batches until explicitly worn or queued.

