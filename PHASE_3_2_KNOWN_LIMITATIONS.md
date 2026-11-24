# Phase 3.2 — Known Limitations & Operational Guidelines
## Edge Cases, Hardware Dependencies & Recommended User Practices

**Document Version:** 1.0  
**Date:** November 24, 2026  
**Status:** Documented  

---

## 1. Hardware Dependencies for Local Multimodal AI

### Local CPU vs. Dedicated GPU Latency
- When running `moondream:latest` via Ollama on an Intel/AMD x86_64 host without a CUDA-capable GPU, CLIP visual patch encoding of high-resolution images takes $40 - 55\text{ seconds}$.
- If multiple requests are dispatched concurrently, socket read timeouts may occur.
- **System Safeguard:** When a timeout occurs, TESS gracefully degrades to `LOCAL_NEURAL_PROCESSING` within $<650\text{ ms}$, using U2-Net ONNX and deterministic CIELAB color extraction without blocking or crashing.
- **Recommendation:** In production or power-user environments, we strongly recommend deploying an API key for cloud vision (`OPENROUTER_API_KEY` or `GEMINI_API_KEY`), which reduces end-to-end processing latency to $<2.5\text{ seconds}$ with superior semantic nuance.

---

## 2. Challenging Computer Vision Scenarios

### 1. Chromatically Identical Furniture
- **Scenario:** A solid maroon garment draped over an identical maroon fabric sofa or blanket.
- **Limitation:** CIELAB color-distance filtering ($\Delta E$) differentiates foreground from background based on chroma and hue divergence. If the garment and furniture share identical fabric color, the boundary must rely entirely on spatial SOD gradients. Minor perimeter bleeding may occur.
- **Guidance:** Lay garments flat on contrasting surfaces (e.g. white sheet, wooden floor, or neutral bedspread).

### 2. Semi-Transparent & Sheer Fabrics
- **Scenario:** Organza, chiffon, or sheer lace garments where underlying background patterns bleed through the textile fibers.
- **Limitation:** The background removal mask may misinterpret the underlying pattern as garment texture, or over-suppress thin translucent sleeves.
- **Guidance:** The user can edit attributes directly on the review screen or use the Developer Diagnostics view to verify transparency.

### 3. Extreme Ambient Color Casts
- **Scenario:** Deep amber/tungsten evening lighting or colored party LEDs.
- **Limitation:** Severe color casts shift the apparent CIELAB white point, potentially turning a white shirt slightly cream or yellow.
- **Mitigation:** The pipeline uses adaptive interior luminance normalization to correct for lighting shifts, but extreme mono-wavelength lighting may still require manual user adjustment in the attribute editor.

---

## 3. Recommended Photography Best Practices for Users

For optimal results when registering clothes in TESS Smart Capture:
1. **Flat Lay:** Lay the clothing item flat on a bed or floor with sleeves naturally extended.
2. **Contrast:** Place light clothes on dark backgrounds, and dark clothes on light backgrounds.
3. **Natural Light:** Photograph during daylight or under even, white room lighting.
4. **Single Garment per Frame:** While multiple garments are supported, capturing one garment at a time ensures maximum catalogue quality, perfect auto-leveling, and 100% attribute confidence.
