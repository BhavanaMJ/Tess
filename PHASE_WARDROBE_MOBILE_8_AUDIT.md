# Phase 8: Repository & Architecture Audit
## Wardrobe Wishlist, Shopping Intelligence & Wardrobe Gap Analysis

### 1. Executive Summary
Phase 8 connects future purchasing decisions with empirical wardrobe telemetry. Prior to implementation, an audit of the database schema, backend services, Flutter domain/data/presentation layers, and security infrastructure was conducted to ensure zero regressions across Phases 1–7.

---

### 2. Existing Functionality to Reuse

1. **Garment & Wardrobe Service (`WardrobeService`)**:
   - `wardrobe_items` schema and CRUD APIs (`/api/v1/wardrobe/items`).
   - Garment creation logic with unique `CLO-xxx` ID generation.
   - Category hierarchy: 10 standard categories (`Tops`, `Bottoms`, `Ethnic wear`, `Dresses`, `Outerwear`, `Activewear`, `Innerwear`, `Sleepwear`, `Footwear`, `Accessories`) with standardized subcategories.
2. **Purchase Metadata**:
   - `purchase_date`, `purchase_price`, and `purchase_currency` (added in Migration 006) already exist on `wardrobe_items`.
   - No duplicate purchase price or currency columns will be added to `wardrobe_items`.
3. **Outfit Studio & Compatibility Intelligence (`OutfitService`)**:
   - Color harmony engine (`_colors_complement`) and styling compatibility rules.
   - Saved outfit combinations and active wear logs.
4. **Wardrobe Insights & Capsule Intelligence (`WardrobeInsightsService`)**:
   - Color normalization (`_normalize_color`) into 11 canonical color families.
   - Category composition and volume distribution.
   - Capsule versatility scoring, anchor garment identification, and combination calculations.
   - Style preferences (`wardrobe_style_preferences`).
5. **Laundry Manager (`LaundryService`)**:
   - 5-status garment lifecycle (`CLEAN`, `WORN`, `WASHING`, `DRYING`, `STORED`) and unassigned status handling.
   - When converting a purchased wishlist item to a wardrobe garment, the initial laundry status remains unassigned (`null`) unless explicitly declared by the user.
6. **Authentication & Multi-Tenant Isolation**:
   - Supabase JWT authentication (`get_current_user_id`).
   - Row-Level Security (RLS) enforcing `auth.uid() = user_id`.

---

### 3. Existing Fields to Extend / Link

1. **`wardrobe_items`**:
   - Contains: `id`, `user_id`, `name`, `main_category`, `subcategory`, `primary_color`, `purchase_price`, `purchase_date`, `purchase_currency`.
   - Linkage: Wishlist items will reference their converted garment via `converted_garment_id REFERENCES wardrobe_items(id) ON DELETE SET NULL`.
2. **Distinction between Financial Values**:
   - Wishlist Item: `expected_price` (budgetary estimate) and `expected_currency`.
   - Converted Wardrobe Item: `purchase_price` (actual transaction amount) and `purchase_currency`.
   - Wishlist Item will additionally record `actual_purchase_price`, `actual_purchase_currency`, and `purchased_at` for financial history without overwriting the original `expected_price`.

---

### 4. Required New Database Tables

#### Table: `wishlist_items`
Migration `007_wardrobe_wishlist.sql`:
- `id` UUID PRIMARY KEY DEFAULT gen_random_uuid()
- `user_id` UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
- `name` VARCHAR(150) NOT NULL
- `category` VARCHAR(50) NOT NULL
- `subcategory` VARCHAR(50)
- `reference_image_path` TEXT
- `expected_price` NUMERIC(10, 2)
- `expected_currency` VARCHAR(10) DEFAULT 'INR'
- `purchase_priority` VARCHAR(20) DEFAULT 'MEDIUM' -- 'HIGH', 'MEDIUM', 'LOW'
- `occasion` VARCHAR(50)
- `desired_colour` VARCHAR(50)
- `desired_pattern` VARCHAR(50)
- `description` TEXT
- `notes` TEXT
- `status` VARCHAR(30) DEFAULT 'CONSIDERING' -- 'CONSIDERING', 'SHORTLISTED', 'PURCHASED', 'NOT_INTERESTED'
- `purchased_at` TIMESTAMPTZ
- `actual_purchase_price` NUMERIC(10, 2)
- `actual_purchase_currency` VARCHAR(10) DEFAULT 'INR'
- `converted_garment_id` VARCHAR(50) REFERENCES wardrobe_items(id) ON DELETE SET NULL
- `created_at` TIMESTAMPTZ DEFAULT NOW()
- `updated_at` TIMESTAMPTZ DEFAULT NOW()

- **Constraints & Indexes**:
  - `idx_wishlist_items_user_status` ON `(user_id, status)`
  - `idx_wishlist_items_user_priority` ON `(user_id, purchase_priority)`
  - `idx_wishlist_items_converted_garment` ON `(converted_garment_id)`
  - Unique idempotency constraint on conversion: Ensure a wishlist item cannot link to conflicting multiple garments.

---

### 5. Required API Endpoints

Base: `/api/v1/wardrobe/wishlist` & `/api/v1/wardrobe/shopping-intelligence`

1. **Wishlist Operations**:
   - `GET /api/v1/wardrobe/wishlist`: List wishlist items with status, priority, and category filters.
   - `POST /api/v1/wardrobe/wishlist`: Create a new wishlist item.
   - `GET /api/v1/wardrobe/wishlist/{item_id}`: Get wishlist item detail.
   - `PUT /api/v1/wardrobe/wishlist/{item_id}`: Update wishlist item.
   - `DELETE /api/v1/wardrobe/wishlist/{item_id}`: Delete wishlist item.
   - `PATCH /api/v1/wardrobe/wishlist/{item_id}/status`: Transition status (`CONSIDERING`, `SHORTLISTED`, `PURCHASED`, `NOT_INTERESTED`).
   - `POST /api/v1/wardrobe/wishlist/{item_id}/convert`: Convert purchased wishlist item into a `wardrobe_items` record.
   - `GET /api/v1/wardrobe/wishlist/summary`: Aggregate statistics (counts by status/priority, expected investment, purchased totals).
   - `POST /api/v1/wardrobe/wishlist/upload-image`: Upload reference image.
2. **Shopping Intelligence & Wardrobe Gap Analysis**:
   - `GET /api/v1/wardrobe/shopping-intelligence/gaps`: Empirical wardrobe gap analysis (unmatched pieces, category imbalances, missing versatile neutrals/bottoms).
   - `POST /api/v1/wardrobe/shopping-intelligence/match`: Existing wardrobe similarity search (find existing similar clothes matching a target category/color).
   - `GET /api/v1/wardrobe/shopping-intelligence/assessment/{item_id}`: Explainable purchase assessment score and decision support for a wishlist item.

---

### 6. Existing Image-Storage Capabilities

- `MEDIA_ROOT` (`backend/media`) with user isolation: `os.path.join(MEDIA_ROOT, user_id, "wishlist")`.
- Supported formats: JPEG, PNG, WebP. File size limit: 15MB.
- Served via authenticated endpoint: `/api/v1/wardrobe/wishlist/images/{user_id}/{filename}`.

---

### 7. Required Flutter Screens & Widgets

#### Screens
1. `WishlistScreen`: Main dashboard with summary metrics, filter chips, sorting, and item cards.
2. `WishlistAddEditScreen`: Form for creating or modifying wishlist items with priority, expected price, category, desired color, notes, and image picker.
3. `WishlistDetailScreen`: Detail view showing reference photo, purchase status, priority, shopping intelligence section, and actions.
4. `WardrobeGapAnalysisScreen`: Visual cards explaining wardrobe gaps with supporting evidence, current inventory, and "Add to Wishlist" action.
5. `PurchaseAssessmentScreen`: Detailed breakdown of purchase decision score, similar owned garments, and versatile outfit combinations.
6. `WishlistConversionScreen`: Flow to confirm purchase, review prepopulated garment attributes, capture/upload actual garment photo, and register to My Wardrobe.

#### Widgets
- `WishlistItemCard`
- `WishlistPriorityBadge`
- `WishlistSummaryCard`
- `WardrobeGapCard`
- `PurchaseAssessmentCard`
- `ExistingGarmentMatchCard`
- `WishlistEmptyState`

---

### 8. Known Limitations & Constraints

1. **No External E-Commerce Checkout**: TESS is a personal wardrobe intelligence system, not a retail marketplace or price-comparison aggregator.
2. **Multi-Currency Aggregations**: Financial summaries will display currency subtotals rather than attempting speculative forex conversions without external market rates.
3. **Conversion Idempotency**: Once converted, re-converting the same wishlist item will return the already-linked garment rather than generating duplicate items.

