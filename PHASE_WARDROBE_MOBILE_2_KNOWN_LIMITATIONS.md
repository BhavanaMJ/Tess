# TESS WARDROBE INTELLIGENCE — PHASE 2
## KNOWN LIMITATIONS & FUTURE PHASE ROADMAP

### Current Scope & Operational Boundaries
Phase 2 strictly implements the digital wardrobe foundation, manual garment cataloguing, persistent database schemas, REST APIs, and lifecycle status management.

The following capabilities are deliberately scoped to future phases per the product requirements:

---

### 1. Camera & Image Capture (Phase 3)
- **Current State**: Garment creation allows manual attribute entry and displays clean studio placeholders or linked URLs.
- **Phase 3 Objective**: Native camera capture flow with multi-angle capture guidance, live cropping, and direct upload to Supabase Storage bucket `wardrobe-images`.

### 2. AI Background Removal & Rembg (Phase 3)
- **Current State**: UI provides studio-white cards (`#FAFAFA`) to frame garments cleanly without dark-on-dark contrast failure.
- **Phase 3 Objective**: Automated background extraction using `rembg` (or server-side ONNX U^2-Net model) to isolate the clothing item on pure transparent / studio neutral background.

### 3. Automated AI Attribute Extraction (Phase 3)
- **Current State**: Visual attributes (neckline, sleeve length, fabric, pattern, fit) are selected manually by the user with category-aware form fields.
- **Phase 3 Objective**: Multimodal vision analysis (Gemini / localized vision model) to automatically infer dominant color, pattern, material, and category from raw photos.

### 4. Laundry Manager & Wash Cycle Tracking (Phase 4)
- **Current State**: 5 confirmed operational laundry statuses (CLEAN, WORN, WASHING, DRYING, STORED) can be updated manually on individual items via detail and inventory sheets.
- **Phase 4 Objective**: Dedicated Laundry Manager module with drag-and-drop hamper bins, batch cycle logging, and notification alerts when laundry drying completes.

### 5. Outfit Studio & Mix-and-Match Canvas (Phase 5)
- **Current State**: Overview dashboard contains module placeholder with informative Phase 5 status pill.
- **Phase 5 Objective**: Multi-layer outfit composition canvas, lookbook creation, and AI outfit recommendations based on weather and occasion.

### 6. Outfit Calendar & Wear Logging (Phase 6)
- **Current State**: Garment schema stores `purchase_date` and timestamp tracking.
- **Phase 6 Objective**: Calendar view for scheduling upcoming daily looks and logging wear history for accurate cost-per-wear computation.

### 7. Cost-Per-Wear & Wardrobe Insights (Phase 7)
- **Current State**: Overview displays high-level operational counts (Total, Clean, Laundry, Unassigned).
- **Phase 7 Objective**: In-depth analytics screen detailing cost-per-wear breakdown, wardrobe category balance, underutilized items, and eco-efficiency metrics.

### 8. Desktop Clothes Organizer (Phase 8)
- **Current State**: Desktop application remains stable and untouched, continuing to pass all 113 D6 tests.
- **Phase 8 Objective**: Bring the digital wardrobe, outfit studio, and laundry manager to the TESS Desktop UI using the shared FastAPI backend endpoints established in Phase 2.

