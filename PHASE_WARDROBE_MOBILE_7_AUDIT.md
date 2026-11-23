# TESS WARDROBE INTELLIGENCE — PHASE 7: REPOSITORY AUDIT
## WARDROBE INSIGHTS, USAGE ANALYTICS & PERSONAL STYLE INTELLIGENCE

**Audit Date**: 2026-11-22  
**Feature**: Wardrobe Insights, Usage Analytics & Personal Style Intelligence  
**Target Environment**: FastAPI + Supabase Backend, Flutter Mobile Client  
**Current Branch**: `main`  
**Latest Baseline Commit**: `c68c0a250fd8e07319e0b51a29d98b6c28bf5b57` (Phase 6 Outfit Calendar)

---

### 1. Architectural Baseline & Existing Wardrobe Modules

The repository currently provides six fully integrated wardrobe modules:
1. **Phase 1: Foundation, Architecture & Navigation** — Domain entities, repository abstractions, Dark Spatial Void theme tokens, initial 18 fixtures.
2. **Phase 2: Digital Wardrobe & Inventory** — Supabase `wardrobe_items` and `wardrobe_categories`, REST API endpoints, filtering, searching, favorite toggles.
3. **Phase 3: Smart Capture & AI Detection** — Background removal, edge detection, attribute extraction, multi-garment detection pipeline.
4. **Phase 4: Laundry Manager & Batch Lifecycle** — 5-status garment lifecycle (`CLEAN`, `WORN`, `WASHING`, `DRYING`, `STORED`), hamper batches, wear/wash event increments, laundry history.
5. **Phase 5: Outfit Studio & AI Stylist** — `outfits`, `outfit_items`, `outfit_wear_history`, automatic rule-based outfit generation, color harmony algorithms.
6. **Phase 6: Outfit Calendar & Weather Context** — Separation of planned outfits (`outfit_plans`) and actual wear records (`outfit_calendar_wear_records`), weather integration with caching, repetition warnings.

---

### 2. Analysis of Wear Event Sources of Truth

For usage analytics, several sources of wear data exist across the system:
1. **`outfit_calendar_wear_records` (Phase 6)**:
   - Contains `user_id`, `outfit_id`, `actual_worn_date DATE`, `worn_at TIMESTAMPTZ`, `plan_id`.
   - This is the primary event log for date-bounded wear queries (7d, 30d, 90d, 6m, 12m).
   - Each calendar wear record links to an outfit, which resolves through `outfit_items` to specific garment IDs.
2. **`outfit_wear_history` (Phase 5)**:
   - Contains `user_id`, `outfit_id`, `worn_at TIMESTAMPTZ`.
   - Records direct wear events initiated from the Outfit Studio.
3. **`wardrobe_items.wear_count` & `wardrobe_items.last_worn_date` (Phase 1–4)**:
   - Maintains lifetime aggregate counters updated whenever a garment's status transitions to `WORN` or is logged via Outfit Studio/Calendar.
   - Ideal for all-time usage analytics, least worn, and neglected garments when date bounds are omitted.

**Audit Finding**:
Period-specific analytics (e.g. "Last 30 Days") MUST evaluate actual wear events within the date range rather than relying solely on lifetime `wear_count`. When no event logs exist within the range, period wear count is `0`. All-time analytics reference aggregate `wear_count` and lifetime wear logs.

---

### 3. Economics & Purchase Metadata Assessment

Inspecting `backend/migrations/001_wardrobe.sql` and `flutter_app/lib/features/wardrobe/domain/entities/garment.dart`:
- `purchase_date DATE` exists in `wardrobe_items` and `Garment`.
- `purchase_price NUMERIC(10, 2)` exists in `wardrobe_items` and `Garment`.
- `purchase_currency` is currently implicit (defaults to `'INR'`).
- **Gap Identified**:
  1. `purchase_currency` should be formally persisted on `wardrobe_items` (`VARCHAR(10) DEFAULT 'INR'`) to avoid currency ambiguity.
  2. Garments imported or captured without user input have `purchase_price = NULL`.
  3. **Strict CPW Constraint**: Cost-Per-Wear formula:
     $$\text{CPW} = \frac{\text{purchase\_price}}{\text{wear\_count}}$$
     - If `purchase_price IS NULL`, CPW is `NULL` (never assume ₹0.00).
     - If `wear_count == 0` and `purchase_price > 0`, CPW is undefined/unrealized (presented as purchase price with "Never Worn" flag).
     - If `wear_count > 0` and `purchase_price > 0`, calculate exact CPW rounded to 2 decimal places.

---

### 4. Wardrobe Utilisation Metric Definition

According to the PRD:
$$\text{Utilisation \%} = \left(\frac{\text{Unique Garments Worn in Period}}{\text{Active Wardrobe Garments}}\right) \times 100$$
- **Active Wardrobe Garments**: Total garments belonging to user where `is_archived = false`.
- **Unique Garments Worn**: Distinct garment IDs that appeared in at least one confirmed wear event during the selected period.
- **Boundary Condition**: If `Active Wardrobe Garments == 0`, Utilisation is `0.0%`.

---

### 5. Color Distribution & Grouping Strategy

Garments currently record `primary_color` (e.g., "Navy Blue", "Sky Blue", "Charcoal", "Burgundy", "Beige").
- For charts and high-level style intelligence, we normalize colors into 10 canonical color families:
  `['Black', 'White', 'Blue', 'Grey', 'Brown / Beige', 'Green', 'Red / Pink', 'Yellow / Orange', 'Purple', 'Multicolor / Other']`.
- Crucially, the original color names are preserved and surfaced when expanding a color family.

---

### 6. Capsule Wardrobe & Personal Style Memory Foundations

- **Capsule Wardrobe**:
  - Leverages color compatibility rules and cross-category compatibility from Phase 5 (`OutfitService`).
  - Measures versatility as the count of valid outfit combinations a garment can anchor.
  - Highlights "Anchor Garments" (high versatility, neutral/compatible palette).
- **Style Memory**:
  - Tracks user preferences, dominant color palettes, favorite occasions, and style persona.
  - Schema requires `wardrobe_style_preferences` table with user preferences and persona metadata.

---

### 7. Action Plan & Next Steps

1. Execute Migration `006_wardrobe_insights.sql` adding `purchase_currency` and `wardrobe_style_preferences`.
2. Implement backend schemas and `InsightsService` in `backend/app/services/wardrobe/insights_service.py`.
3. Create API endpoints in `backend/app/api/wardrobe_insights.py` and register in `backend/app/main.py`.
4. Verify backend analytics with unit tests in `backend/tests/test_wardrobe_insights.py`.
5. Implement Flutter Domain, Data, Controller, Widgets, and Screens in `flutter_app/lib/features/wardrobe/`.
6. Update navigation in `WardrobeOverviewScreen` (badge `'PHASE 7'`, Wardrobe Insights active).
7. Create automated tests in `flutter_app/test/wardrobe_phase7_test.dart`.
8. Complete all Phase 7 documentation and commit locally.
