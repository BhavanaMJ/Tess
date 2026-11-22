# TESS Wardrobe Intelligence — Phase 3 Known Limitations & Future Enhancements

**Date:** November 22, 2026  
**Version:** 1.0  

---

## 1. Known Technical Limitations

1. **Local Development Vision Segmentation Simplicity**:
   - The local `DevelopmentVisionProvider` performs vertical region-based segmentation and dominant color extraction using PIL. While deterministic and 100% offline, it relies on standard top-over-bottom placement for multi-garment photos. Complex overlapping piles of clothing require cloud vision (`MultimodalVisionProvider`) or semantic mask models (e.g., SAM).
2. **Camera Sensor Inconsistencies**:
   - Smartphone camera sensors vary widely in automatic white balance. Photographs taken under heavy tungsten (yellow) or fluorescent lighting may introduce color casts that affect primary color classification. The UI addresses this with on-screen lighting tips and the editable attribute modal.
3. **Internal Brand & Care Label Visibility**:
   - AI vision cannot extract brand names, exact sizing (e.g. "Medium", "32x30"), or fabric composition percentage if brand tags are concealed inside the garment lining. In these cases, confidence is scored as `UNCERTAIN` and highlighted with an amber note encouraging manual verification.
4. **Local Disk Storage vs. Object Storage**:
   - In development environments without active Supabase Storage buckets, raw and segmented images are stored locally under `backend/app/media/wardrobe/{user_id}/`. Production deployments will mirror these to Supabase S3-compatible buckets.

---

## 2. Transition Plan to Phase 4 (Laundry Manager)

Phase 3 intentionally stops at garment capture and catalogue registration. It does **not** implement:
- Laundry hampers, washing, drying, or wear logging (Phase 4).
- 2D Canvas outfit combinations (Phase 5).
- Calendar scheduling (Phase 6).
- Cost-per-wear analytics (Phase 7).

All garments created in Phase 3 enter `wardrobe_items` with initial laundry status `null` (unassigned), fully prepared for Phase 4 Laundry Manager's 5-state lifecycle engine.
