import io
import logging
from typing import List, Dict, Any, Tuple, Optional
import numpy as np
import cv2
from PIL import Image, ImageOps
from skimage import color
import rembg

logger = logging.getLogger(__name__)

# Cached rembg session for high throughput
_REMBG_SESSION: Optional[Any] = None

def get_rembg_session() -> Any:
    global _REMBG_SESSION
    if _REMBG_SESSION is None:
        try:
            logger.info("[SegmentationService] Initializing U2-Net session...")
            _REMBG_SESSION = rembg.new_session("u2net")
        except Exception as e:
            logger.warning(f"[SegmentationService] Failed to load u2net session ({e}), falling back to default rembg session.")
            _REMBG_SESSION = rembg.new_session()
    return _REMBG_SESSION


class GarmentInstance:
    """Represents a physically segmented garment instance within an uploaded photograph."""
    def __init__(
        self,
        bounding_box: Dict[str, float],
        rgba_crop: Image.Image,
        original_crop: Image.Image,
        area_coverage_pct: float,
        is_primary: bool = True,
        mask_crop: Optional[Image.Image] = None,
    ):
        self.bounding_box = bounding_box
        self.rgba_crop = rgba_crop
        self.original_crop = original_crop
        self.area_coverage_pct = area_coverage_pct
        self.is_primary = is_primary
        self.mask_crop = mask_crop


class GarmentSegmentationService:
    """
    Production-grade neural segmentation and instance separation service.
    - Uses U2-Net for initial salient foreground separation.
    - Applies color-guided furniture/chair removal in CIELAB space.
    - Fills internal fold shadows and removes detached noise specks.
    - Generates smooth, anti-aliased garment contours.
    - Prevents single long garments (Kurta, Dress, Jumpsuit) from being falsely split.
    """

    def __init__(self, session: Optional[Any] = None):
        self.session = session

    def _get_session(self) -> Any:
        return self.session or get_rembg_session()

    def _refine_garment_mask(self, np_rgb: np.ndarray, raw_alpha: np.ndarray) -> np.ndarray:
        """
        Subtracted underlying furniture (e.g. black office chair frames, chair mesh, bed rails)
        and refines edges without erasing real fabric or embroidery.
        """
        h, w, _ = np_rgb.shape
        binary_alpha = raw_alpha.copy()

        # Convert RGB to CIELAB space
        rgb_float = np_rgb.astype(np.float32) / 255.0
        lab = color.rgb2lab(rgb_float)
        L = lab[:, :, 0]
        a = lab[:, :, 1]
        b = lab[:, :, 2]
        chroma = np.sqrt(a**2 + b**2)

        # Find core garment region: center 40% vertical and horizontal box of foreground
        fg_pos = np.where(binary_alpha > 50)
        if len(fg_pos[0]) > 500:
            min_y, max_y = int(np.min(fg_pos[0])), int(np.max(fg_pos[0]))
            min_x, max_x = int(np.min(fg_pos[1])), int(np.max(fg_pos[1]))
            cy1, cy2 = int(min_y + 0.25 * (max_y - min_y)), int(min_y + 0.65 * (max_y - min_y))
            cx1, cx2 = int(min_x + 0.25 * (max_x - min_x)), int(min_x + 0.75 * (max_x - min_x))

            core_mask = (binary_alpha[cy1:cy2, cx1:cx2] > 60)
            core_pixels = lab[cy1:cy2, cx1:cx2][core_mask]

            if len(core_pixels) > 200:
                median_fabric = np.median(core_pixels, axis=0)
                diff = lab - median_fabric.reshape(1, 1, 3)
                dist_from_fabric = np.sqrt(np.sum(diff**2, axis=-1))

                # Protect white or light embroidery / lace / stitching
                is_embroidery = (L > 65) & (binary_alpha > 40)

                # Furniture detection:
                # 1. Dark (L < 28)
                # 2. Low chroma (C* < 18, grey/black plastic/mesh)
                # 3. Far from fabric color (dist > 28)
                # 4. Not embroidery
                is_furniture = (binary_alpha > 50) & (L < 28) & (chroma < 18) & (dist_from_fabric > 26) & (~is_embroidery)
                binary_alpha[is_furniture] = 0

        # Remove faint ambient smudges (alpha < 75)
        binary_alpha[binary_alpha < 75] = 0

        # Morphological opening and closing
        kernel_sm = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        kernel_cl = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
        cleaned = cv2.morphologyEx(binary_alpha, cv2.MORPH_OPEN, kernel_sm)
        cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_CLOSE, kernel_cl)

        # Fill internal holes (shadowed weave or folds < 8,000 pixels)
        contours, _ = cv2.findContours((cleaned > 40).astype(np.uint8), cv2.RETR_CCOMP, cv2.CHAIN_APPROX_SIMPLE)
        filled = cleaned.copy()
        for c in contours:
            area = cv2.contourArea(c)
            if area < 8000:
                cv2.drawContours(filled, [c], -1, 255, -1)

        # Discard detached small background specks (< 12,000 pixels)
        num_labels, labels, stats, _ = cv2.connectedComponentsWithStats((filled > 40).astype(np.uint8))
        keep_mask = np.zeros_like(filled)
        for i in range(1, num_labels):
            if stats[i, cv2.CC_STAT_AREA] >= 12000:
                keep_mask[labels == i] = filled[labels == i]

        # Gentle Gaussian blur for smooth anti-aliased edge feathering
        smoothed = cv2.GaussianBlur(keep_mask, (3, 3), 0)
        return smoothed

    def segment_image(self, img: Image.Image) -> Tuple[Image.Image, List[GarmentInstance]]:
        """
        Processes image through U2-Net neural segmentation,
        applies color-guided furniture elimination, and extracts garment instances.
        """
        # Ensure correct EXIF orientation
        img_oriented = ImageOps.exif_transpose(img)
        w, h = img_oriented.size
        np_rgb = np.array(img_oriented.convert("RGB"))

        # Neural background removal
        session = self._get_session()
        rgba_raw = rembg.remove(img_oriented, session=session)
        if rgba_raw.mode != "RGBA":
            rgba_raw = rgba_raw.convert("RGBA")

        raw_alpha = np.array(rgba_raw)[:, :, 3]

        # Apply precision refinement (subtracting chair/bed furniture & defringing)
        refined_alpha = self._refine_garment_mask(np_rgb, raw_alpha)

        # Recompose clean RGBA image
        clean_rgba_arr = np.dstack([np_rgb, refined_alpha])
        rgba_full = Image.fromarray(clean_rgba_arr)

        total_pixels = float(w * h)

        # Connected components analysis on refined mask
        num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats((refined_alpha >= 45).astype(np.uint8))

        valid_components = []
        for i in range(1, num_labels):
            area = stats[i, cv2.CC_STAT_AREA]
            area_pct = area / total_pixels
            if area_pct >= 0.025:  # Must cover at least 2.5% of the frame
                x = stats[i, cv2.CC_STAT_LEFT]
                y = stats[i, cv2.CC_STAT_TOP]
                bw = stats[i, cv2.CC_STAT_WIDTH]
                bh = stats[i, cv2.CC_STAT_HEIGHT]
                valid_components.append({
                    "id": i,
                    "area": area,
                    "area_pct": area_pct,
                    "bbox": (x, y, bw, bh),
                    "centroid": centroids[i],
                })

        valid_components.sort(key=lambda c: c["area"], reverse=True)

        # Instance Decision Logic
        if not valid_components:
            pos = np.where(refined_alpha > 20)
            if len(pos[0]) > 0:
                min_y, max_y = int(np.min(pos[0])), int(np.max(pos[0]))
                min_x, max_x = int(np.min(pos[1])), int(np.max(pos[1]))
            else:
                min_x, min_y, max_x, max_y = 0, 0, w, h

            bw = max(10, max_x - min_x)
            bh = max(10, max_y - min_y)
            box_dict = {"x": float(min_x / w), "y": float(min_y / h), "width": float(bw / w), "height": float(bh / h)}
            crop_rgba = rgba_full.crop((min_x, min_y, max_x, max_y))
            crop_orig = img_oriented.crop((min_x, min_y, max_x, max_y))
            mask_crop = Image.fromarray(refined_alpha[min_y:max_y, min_x:max_x])
            return rgba_full, [GarmentInstance(box_dict, crop_rgba, crop_orig, 1.0, is_primary=True, mask_crop=mask_crop)]

        # Check if single dominant garment
        total_fg_area = sum(c["area"] for c in valid_components)
        primary_area_share = valid_components[0]["area"] / float(total_fg_area)

        is_multi_instance = False
        if len(valid_components) >= 2 and primary_area_share < 0.70:
            second = valid_components[1]
            if second["area_pct"] >= 0.08:
                b1 = valid_components[0]["bbox"]
                b2 = second["bbox"]
                overlap_x = max(0, min(b1[0] + b1[2], b2[0] + b2[2]) - max(b1[0], b2[0]))
                overlap_y = max(0, min(b1[1] + b1[3], b2[1] + b2[3]) - max(b1[1], b2[1]))
                intersection = overlap_x * overlap_y
                if intersection < 0.1 * min(b1[2] * b1[3], b2[2] * b2[3]):
                    is_multi_instance = True

        instances: List[GarmentInstance] = []

        if not is_multi_instance:
            # Single Garment: Combine all foreground pixels into one bounding box
            pos = np.where(refined_alpha > 0)
            if len(pos[0]) > 0:
                min_y, max_y = int(np.min(pos[0])), int(np.max(pos[0]))
                min_x, max_x = int(np.min(pos[1])), int(np.max(pos[1]))
            else:
                min_x, min_y, max_x, max_y = 0, 0, w, h

            min_x = max(0, min_x - 5)
            min_y = max(0, min_y - 5)
            max_x = min(w, max_x + 5)
            max_y = min(h, max_y + 5)

            bw = max(10, max_x - min_x)
            bh = max(10, max_y - min_y)

            box_dict = {
                "x": float(round(min_x / float(w), 4)),
                "y": float(round(min_y / float(h), 4)),
                "width": float(round(bw / float(w), 4)),
                "height": float(round(bh / float(h), 4)),
            }

            crop_rgba = rgba_full.crop((min_x, min_y, max_x, max_y))
            crop_orig = img_oriented.crop((min_x, min_y, max_x, max_y))
            mask_crop = Image.fromarray(refined_alpha[min_y:max_y, min_x:max_x])
            instances.append(GarmentInstance(box_dict, crop_rgba, crop_orig, primary_area_share, is_primary=True, mask_crop=mask_crop))

        else:
            # Multi-Garment: Process separated components
            for comp in valid_components[:3]:
                if comp["area_pct"] < 0.05:
                    continue
                x, y, bw, bh = comp["bbox"]
                pad_x = int(bw * 0.05)
                pad_y = int(bh * 0.05)
                cx1 = max(0, x - pad_x)
                cy1 = max(0, y - pad_y)
                cx2 = min(w, x + bw + pad_x)
                cy2 = min(h, y + bh + pad_y)

                cbw = cx2 - cx1
                cbh = cy2 - cy1

                box_dict = {
                    "x": float(round(cx1 / float(w), 4)),
                    "y": float(round(cy1 / float(h), 4)),
                    "width": float(round(cbw / float(w), 4)),
                    "height": float(round(cbh / float(h), 4)),
                }

                crop_rgba = rgba_full.crop((cx1, cy1, cx2, cy2))
                crop_orig = img_oriented.crop((cx1, cy1, cx2, cy2))
                mask_crop = Image.fromarray(refined_alpha[cy1:cy2, cx1:cx2])
                instances.append(GarmentInstance(box_dict, crop_rgba, crop_orig, float(comp["area_pct"]), is_primary=(len(instances) == 0), mask_crop=mask_crop))

        return rgba_full, instances
