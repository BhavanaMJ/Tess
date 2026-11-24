# TESS Wardrobe Intelligence — Phase 8: Known Limitations & Future Considerations

**Product:** TESS Wardrobe Intelligence / Clothes Organizer  
**Version:** 1.0  
**Phase:** 8 (Wardrobe Wishlist, Shopping Intelligence & Wardrobe Gap Analysis)  
**Date:** November 24, 2026  

---

## 1. Intentional Architectural Boundaries

### 1.1 No E-Commerce Checkout or External Affiliate Marketplaces
- **Design Philosophy**: TESS is a **mindful wardrobe management system**, not a sponsored shopping storefront.
- **Boundary**: There is no direct integration with retailer checkouts, payment processing APIs (Stripe, Apple Pay), or sponsored product feeds.
- **Rationale**: The core philosophy of TESS is to prevent overconsumption and impulse buying by prioritizing existing clothes.

### 1.2 Unassigned Laundry Status on Converted Items
- **Boundary**: Newly converted garments from the wishlist are registered with `laundry_status: null` (UNASSIGNED).
- **Rationale**: This is a strict safety guarantee. Physical clothes arriving from stores or deliveries may be unwashed or packaged; TESS deliberately requires user intervention to confirm when an item has been washed or deemed ready to wear.

### 1.3 Local vs Remote Image Storage for Wishlist Items
- **Boundary**: Wishlist items support arbitrary image URLs or local photo paths. If an external URL becomes invalid or expires, the item defaults to a category icon representation.
- **Future Consideration**: In a subsequent release, external wishlist image URLs could be ingested into Supabase Storage buckets upon creation to ensure permanent asset availability.

---

## 2. Technical Limitations & Edge Cases

### 2.1 Rule-Based vs Deep Neural Gap Analysis
- **Current Implementation**: The Wardrobe Gap Analysis service utilizes deterministic category completeness, seasonal balance checks, and color-wheel complement heuristics.
- **Observation**: While fast, explainable, and fully functional offline, it does not currently execute deep neural silhouette or visual style embedding comparisons.
- **Future Enhancement**: Integrate OpenRouter multimodal embeddings to compare clothing silhouettes against seasonal runway trends and personal style preferences.

### 2.2 Offline Purchase Assessment Heuristics
- **Current Implementation**: When the mobile client cannot reach the FastAPI backend, the `WishlistRepositoryImpl` performs client-side synthetic similarity matching and recommendation scoring.
- **Observation**: The client-side heuristic compares category, color distance, and occasion matching accurately, but does not calculate multi-factor combinatorial versatility across all saved lookbooks.
- **Mitigation**: Once network connectivity is restored, the full backend assessment endpoint `/api/v1/wardrobe/shopping-intelligence/assess-purchase` can be re-queried for rich styling explanations.

### 2.3 Single-Currency Budgeting
- **Current Implementation**: Wishlist budget limits and garment prices are calculated assuming a consistent user currency (defaulting to `USD` or symbol `$`).
- **Observation**: Cross-currency conversion rates are not fetched in real-time.
- **Mitigation**: Users who enter items in mixed currencies will see raw numeric summations; currency standardization is planned for multi-currency user settings.

---

## 3. Desktop Rollout (Roadmap Horizon)

- **Mobile Implementation Complete**: Mobile Phase 8 completes the full 8-phase mobile wardrobe architecture.
- **Desktop Rollout**: The TESS Tauri desktop application remains clean and untouched in this mobile implementation. Future desktop work will mirror these mobile interfaces using React/Tailwind, consuming the same unified FastAPI + Supabase backend endpoints.
