# Phase 3.2 — Runtime Failure Investigation & Pipeline Audit

**Document Version:** 1.0  
**Date:** November 24, 2026  
**Status:** Root Causes Confirmed & Documented  

---

## 1. Reproduction of Real-World Gallery Upload Failure

Using the actual photograph uploaded by the user (`job_708668026b74.jpg`, $1440 \times 1920$ JPEG, size 570,560 bytes) through the end-to-end workflow, the exact runtime failure was reproduced and traced:

- **Original Image:** Phone photograph of a maroon/wine kurta draped over a black office chair in a cluttered room.
- **Job ID:** `job_c6e3d167cf02`
- **Candidate ID:** `cand_eb00edb154f7`
- **Reported Provider in API:** `OLLAMA_VISION:moondream:latest`
- **Actual Runtime Reality:** Ollama timed out after 45 seconds (`HTTPConnectionPool(host='localhost', port=11434): Read timed out`). The system **silently fell back to local geometry heuristics** while still returning `provider_type: OLLAMA_VISION:moondream:latest` to Flutter!
- **Processed Image Reference:** `/api/v1/wardrobe/capture/images/d6dd3895-95c9-414b-8f08-863ba3985492/processed/job_c6e3d167cf02_cand_eb00edb154f7.jpg`

---

## 2. Five Critical Root Causes Identified

### Root Cause 1: Image Never Rendered in Flutter UI
In `flutter_app/lib/features/wardrobe/presentation/widgets/garment_image_placeholder.dart` (Line 69):
```dart
child: imageUrl != null && imageUrl!.startsWith('http')
    ? Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallback(),
      )
    : _buildFallback(),
```
- The backend returns relative URL `/api/v1/wardrobe/capture/images/...`.
- Flutter rejected any URL not starting with `http`, immediately displaying `_buildFallback()` (a generic icon).
- Even if a full URL were provided, `GarmentImagePlaceholder` did not resolve relative URLs against `AppConfig.resolveDefaultBackendUrl()`.

### Root Cause 2: HTTP 401 Unauthorized on Image Serving
In `backend/app/api/wardrobe_capture.py` (Line 123):
```python
@router.get("/images/{user_id}/{folder}/{filename}")
def serve_capture_image(
    user_id: str,
    folder: str,
    filename: str,
    user: Any = Depends(get_current_user),  # <--- CRITICAL BUG
):
```
- Standard web browser `<img src="...">` tags and Flutter `Image.network(...)` do not send `Authorization: Bearer <token>` request headers by default.
- Any attempt to load the image failed with **HTTP 401 Unauthorized**.
- Private media serving must support signed temporary access tokens or query-based access tokens for secure browser/mobile image rendering.

### Root Cause 3: Incomplete Background/Object Removal (The Office Chair Artifact)
- Inspection of `job_708668026b74_cand_fe4146c867d6.jpg` revealed that the black mesh backrest and armrest of the office chair were **still attached to the garment cutout**.
- **Why:** U2-Net is a general Salient Object Detection (SOD) model. When a garment is draped over an office chair, U2-Net treats the high-contrast chair + garment as a single salient object.
- **Impact:** The resulting cutout is not an isolated garment; it is a garment stuck to a severed office chair.
- **Required Fix:** A garment-specific color segmentation and contour isolation pass to separate the fabric from underlying furniture, plus alpha matte refinement.

### Root Cause 4: Silent Timeout & Fake Provider Reporting
In `backend/app/services/wardrobe/vision_provider.py`:
- `OllamaVisionProvider._query_vlm` timed out after 45s on local CPU (`moondream:latest`).
- The exception was caught, logging a warning, and silently fell back to geometric aspect-ratio estimation.
- The response still returned `provider_type: OLLAMA_VISION:moondream:latest`, misleading both the frontend and the user into believing full AI analysis took place.
- **Required Fix:** Explicit processing quality states (`FULL_AI_PROCESSING`, `LOCAL_NEURAL_PROCESSING`, `LIMITED_PROCESSING`, `NEEDS_MANUAL_REVIEW`, `PROCESSING_FAILED`).

### Root Cause 5: Lack of Catalogue Post-Processing & Normalization
- The cutout was pasted directly onto `#FAFAFA` without:
  1. Straightening/leveling rotated or tilted garments.
  2. Edge defringing/de-haloing (dark gray borders from the ambient background remained around the cuffs and hem).
  3. Natural soft grounding shadow or clean studio cut.
- Result: An unpolished raw cutout rather than a professional catalogue photo.

---

## 3. Image Pipeline Trace

| Pipeline Stage | Input Artifact | Output Artifact | Audit Finding |
| :--- | :--- | :--- | :--- |
| **1. Flutter Gallery Picker** | Device photo library | Selected `XFile` bytes | Bytes intact ($1440 \times 1920$, 570 KB) |
| **2. Flutter Multipart Upload** | `POST /api/v1/wardrobe/capture/jobs` | Job created | Correct multipart field `image` |
| **3. Backend Storage** | Uploaded bytes | `originals/job_c6e3d167cf02.jpg` | Saved accurately with EXIF orientation |
| **4. U2-Net Segmentation** | Original photo | Raw RGBA mask | Foreground detected, but **chair back included** |
| **5. Connected Components** | Binary alpha mask | 1 candidate | Correctly avoided splitting Kurta |
| **6. CIELAB Color Analyzer** | Masked pixels | Wine primary, Dusty Pink secondary | Color math accurate on fabric |
| **7. Ollama VLM** | Catalogue image bytes | Timeout (45s) | **Timed out on CPU; silent fallback** |
| **8. Catalogue Generator** | Raw cutout | $800 \times 800$ `#FAFAFA` | Cutout has chair back + gray halo |
| **9. Image Serving** | GET `/images/...` | HTTP 401 / relative URL | **Flutter never displayed image** |

---

## 4. Immediate Remediation Strategy

1. **Flutter Image URL Resolution:** Update `GarmentImagePlaceholder` to prepend backend `apiBaseUrl` and attach auth query token if needed.
2. **Backend Image Serving:** Allow token-based query access (`?token=...`) or signed public session serving for capture previews.
3. **Garment Isolation & Furniture Elimination:** Implement dual-stage segmentation (U2-Net SOD + K-Means Color/Texture Filtering) to subtract the office chair / bed frame from the garment.
4. **Catalogue Refinement:** Implement edge alpha defringing, soft thresholding, and garment upright alignment.
5. **Processing Quality States:** Expose `quality_state` in `CaptureJobResponse` (`FULL_AI_PROCESSING`, `LOCAL_NEURAL_PROCESSING`, `LIMITED_PROCESSING`, `NEEDS_MANUAL_REVIEW`).
6. **Developer Diagnostic Screen:** Build a dedicated `/wardrobe/capture/debug` screen showing original, mask, cutout, and catalogue side-by-side.

