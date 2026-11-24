# Phase 3.1 — Known Limitations, Edge Cases & Operational Guidance

**Document Version:** 1.0  
**Date:** November 24, 2026  
**Status:** Documented  

---

## 1. Overview

While Phase 3.1 dramatically elevates garment detection, neural background removal, CIELAB color accuracy, and attribute extraction to production multimodal standards, real-world smartphone clothing photography involves inherent physical constraints. This document details known edge cases, operational boundaries, and recommended user guidance.

---

## 2. Known Limitations & Technical Boundaries

### 2.1 Severely Overlapping or Tangled Multi-Garment Photos
- **Limitation:** When multiple garments are piled directly on top of each other in a laundry basket or tangled in a heap with no visible background separating them, U2-Net segments the entire pile as a single unified silhouette.
- **System Behavior:** The system will treat the pile as a single complex candidate rather than guessing internal boundary lines between tangled fabrics.
- **Recommended User Guidance:** For multi-garment flat-lays, lay items flat with at least 5–10 cm of background space separating individual garments, or photograph items one at a time.

### 2.2 Extreme Low Light & Severe Color Casts
- **Limitation:** In near-pitch-black environments ($mean\_luminance < 10.0$), the system rejects the photo at ingestion (`The photograph is excessively dark. Try capturing with better lighting.`).
- **Limitation (Warm Tungsten/Fluorescent Lighting):** In rooms with extreme yellow/orange tungsten bulbs (2700K) without phone white-balance compensation, cream or white garments can be shifted into light beige/yellow in pixel space.
- **System Mitigation:** The CIELAB color clustering filters extreme luminance outliers, but cannot reconstruct true white balance if the raw camera sensor recorded pure yellow. The candidate review screen allows the user to tap and adjust the primary color with one click before saving.

### 2.3 Transparent & Sheer Fabrics (Chiffon, Organza, Net)
- **Limitation:** Extremely sheer or semi-transparent fabrics (e.g. sheer dupattas, lace sleeves) allow the underlying bedsheet or floor texture to show through the fabric weave.
- **System Mitigation:** U2-Net's soft alpha channel preserves the semi-transparent texture, but color clustering may include shades of the surface visible through the sheer weave. The user review interface explicitly presents `fabric_material` and `pattern` with `LOW` confidence score so the user can verify before registration.

### 2.4 Fabric Material vs Visual Appearance
- **Limitation:** Computer vision models analyze *visual surface appearance*, not tactile chemical composition. A polyester garment with a linen-weave visual texture or synthetic silk appearance cannot be chemically verified by a camera.
- **System Mitigation:** Fabric attributes are strictly labeled with "appearance" (e.g., `Cotton appearance`, `Silk appearance`, `Linen appearance`) and assigned `LOW` confidence scores to prompt user verification.

### 2.5 Local VLM Execution Latency
- **Limitation:** Running multimodal vision models locally on CPU (`moondream:latest` or `llama3.2-vision`) requires 15–35 seconds per candidate image depending on host CPU load and quantization.
- **System Mitigation:**
  1. The pipeline features asynchronous job processing with progressive status reporting (`ANALYZING` &rarr; `SEGMENTING` &rarr; `EXTRACTING` &rarr; `AWAITING_APPROVAL`).
  2. The mobile UI displays an animated step-by-step progress indicator and allows the user to browse other screens while the job runs.
  3. When an OpenRouter API key is configured, cloud multimodal calls complete in 1.5–3.0 seconds.

---

## 3. Best Practices for Optimal Garment Capture

To achieve optimal, studio-grade results in TESS Smart Capture:
1. **Spread the Garment Flat or Hang on a Hanger:** Ensure sleeves and hem are laid out naturally without being tucked underneath.
2. **Use Natural or Neutral Lighting:** Daylight near a window or balanced room lighting produces the most accurate CIELAB color clustering.
3. **Contrasting Background:** While U2-Net handles arbitrary backgrounds, photographing a dark garment against a lighter floor/bed (or vice versa) yields the sharpest textile edge isolation.
4. **Separate Multiple Items:** If capturing an outfit in a single shot, leave visible space between the top, pants, and accessories.

