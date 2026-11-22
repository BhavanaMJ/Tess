# TESS Wardrobe Intelligence — Phase 3 AI Vision Provider Evaluation
## Architecture, Comparative Analysis & Production Recommendations

**Date:** November 22, 2026  
**Version:** 1.0  
**Status:** COMPLETE  

---

## 1. Objective

This document evaluates AI vision, garment segmentation, and attribute extraction strategies for TESS Wardrobe Intelligence. It documents the implemented dual-provider architecture and provides recommendations for moving to production deployment.

---

## 2. Implemented Architecture

TESS utilizes a pluggable provider pattern via `GarmentVisionProvider` in `backend/app/services/wardrobe/vision_provider.py`.

```
                    ┌────────────────────────────┐
                    │    WardrobeCaptureService   │
                    └──────────────┬─────────────┘
                                   │
                    ┌──────────────▼─────────────┐
                    │    GarmentVisionProvider   │
                    └──────┬───────────────┬─────┘
                           │               │
       ┌───────────────────┴───┐       ┌───┴────────────────────────┐
       │DevelopmentVisionProvider│       │  MultimodalVisionProvider  │
       │ (Local PIL Segmentation│       │ (OpenRouter/Gemini Vision) │
       │ & Color Euclidean Map)│       └────────────────────────────┘
       └───────────────────────┘
```

The active provider is governed by environment configuration:
- `VISION_PROVIDER=development` (Default): Fully offline, zero API costs, deterministic vertical multi-garment separation, studio background framing (`#FAFAFA`), and RGB Euclidean distance color classification.
- `VISION_PROVIDER=multimodal`: Remote vision-language model (Gemini 1.5 Flash via OpenRouter or Google Vertex AI) passing multi-garment detection prompts.

---

## 3. Comparative Evaluation

| Evaluation Criteria | Development Provider (PIL Engine) | Cloud Vision (Gemini 1.5 Flash) | Specialized Segmentation (SAM + CLIP) |
|---|---|---|---|
| **Latency** | < 120 ms | 1.8 – 3.2 seconds | 1.5 – 2.5 seconds |
| **Cost per photo** | $0.00 | ~$0.0025 | Infrastructure hosting ($50–$150/mo) |
| **Multi-garment splitting** | Aspect-ratio vertical partitioning | Visual bounding box coordinates | Pixel-level semantic mask |
| **Background Removal** | Centered studio crop on `#FAFAFA` | Requires downstream rembg or alpha mask | State-of-the-art alpha cutout |
| **Attribute Extraction** | Deterministic heuristics & dominant colors | Rich semantic descriptions & fabric nuances | Requires secondary classification model |
| **Offline Reliability** | 100% resilient | Fails when offline | Requires on-device model deployment (TFLite) |

---

## 4. Production Deployment Recommendation

### Recommended Hybrid Strategy:
1. **Tier 1 (Client-Side Pre-validation)**:
   - Validate resolution, brightness, and aspect ratio on-device via Flutter before upload.
2. **Tier 2 (Cloud Multimodal Extraction)**:
   - Use **Gemini 1.5 Flash** for its exceptional multi-garment object grounding, rapid response time, and low cost per image token.
3. **Tier 3 (Automated Studio Background Framing)**:
   - Pass bounding box crops through lightweight background removal (`rembg` with `u2net_cloth_seg` model) onto `#FAFAFA` white cards.
4. **Tier 4 (Graceful Fallback)**:
   - When external AI networks are unreachable or rate-limited, fall back automatically to `DevelopmentVisionProvider` so the user is never blocked.
