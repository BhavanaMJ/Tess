import io
import logging
from typing import List, Dict, Any, Tuple, Optional
import numpy as np
import cv2
from PIL import Image, ImageOps
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
    ):
        self.bounding_box = bounding_box
        self.rgba_crop = rgba_crop
        self.original_crop = original_crop
        self.area_coverage_pct = area_coverage_pct
        self.is_primary = is_primary


class GarmentSegmentationService:
    """
    Production-grade neural segmentation and instance separation service.
    - Uses U2-Net / rembg for background removal.
    - Applies connected-components and contour analysis to detect distinct garment instances.
    - Prevents single long garments (Kurta, Dress, Jumpsuit) from being falsely split into top/bottom.
    - Distinguishes multi-garment flat-lays or outfits when garments are genuinely distinct.
    """

    def __init__(self, session: Optional[Any] = None):
        self.session = session

    def _get_session(self) -> Any:
        return self.session or get_rembg_session()

    def segment_image(self, img: Image.Image) -> Tuple[Image.Image, List[GarmentInstance]]:
        """
        Processes image through U2-Net neural segmentation,
        analyzes connected components, and extracts garment instances.
        """
        # Ensure correct EXIF orientation
        img_oriented = ImageOps.exif_transpose(img)
        w, h = img_oriented.size

        # Neural background removal
        session = self._get_session()
        rgba_full = rembg.remove(img_oriented, session=session)
        if rgba_full.mode != "RGBA":
            rgba_full = rgba_full.convert("RGBA")

        alpha = np.array(rgba_full)[:, :, 3]
        total_pixels = float(w * h)

        # Threshold alpha to create binary mask
        binary_mask = (alpha >= 45).astype(np.uint8) * 255

        # Morphological opening then closing to eliminate speckles and fill weave holes
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        cleaned_mask = cv2.morphologyEx(binary_mask, cv2.MORPH_OPEN, kernel)
        cleaned_mask = cv2.morphologyEx(cleaned_mask, cv2.MORPH_CLOSE, kernel)

        # Connected components analysis
        num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(cleaned_mask)

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

        # Sort components by area descending
        valid_components.sort(key=lambda c: c["area"], reverse=True)

        # Instance Decision Logic:
        # If no components found (e.g. transparent image), treat whole image as single instance
        if not valid_components:
            pos = np.where(alpha > 20)
            if len(pos[0]) > 0:
                min_y, max_y = int(np.min(pos[0])), int(np.max(pos[0]))
                min_x, max_x = int(np.min(pos[1])), int(np.max(pos[1]))
            else:
                min_x, min_y, max_x, max_y = 0, 0, w, h

            bw = max(10, max_x - min_x)
            bh = max(10, max_y - min_y)
            box_dict = {"x": min_x / w, "y": min_y / h, "width": bw / w, "height": bh / h}
            crop_rgba = rgba_full.crop((min_x, min_y, max_x, max_y))
            crop_orig = img_oriented.crop((min_x, min_y, max_x, max_y))
            return rgba_full, [GarmentInstance(box_dict, crop_rgba, crop_orig, 1.0, is_primary=True)]

        # Check if single dominant garment:
        # A single continuous garment (like a Kurta, Dress, or single shirt) has its primary component
        # covering >= 70% of the total detected foreground mass, or components overlap significantly vertically.
        total_fg_area = sum(c["area"] for c in valid_components)
        primary_area_share = valid_components[0]["area"] / float(total_fg_area)

        # Check whether there are two genuinely distinct, non-overlapping items separated by empty space
        is_multi_instance = False
        if len(valid_components) >= 2 and primary_area_share < 0.70:
            second = valid_components[1]
            if second["area_pct"] >= 0.08:  # Second component is at least 8% of total frame
                # Check spatial separation: do bounding boxes overlap?
                b1 = valid_components[0]["bbox"]
                b2 = second["bbox"]
                overlap_x = max(0, min(b1[0] + b1[2], b2[0] + b2[2]) - max(b1[0], b2[0]))
                overlap_y = max(0, min(b1[1] + b1[3], b2[1] + b2[3]) - max(b1[1], b2[1]))
                intersection = overlap_x * overlap_y
                if intersection < 0.1 * min(b1[2] * b1[3], b2[2] * b2[3]):
                    # Truly separate items
                    is_multi_instance = True

        instances: List[GarmentInstance] = []

        if not is_multi_instance:
            # Single Garment: Combine all foreground pixels into one bounding box
            # This ensures hanging sleeves, collar details, and hem are preserved as ONE object.
            pos = np.where(cleaned_mask > 0)
            if len(pos[0]) > 0:
                min_y, max_y = int(np.min(pos[0])), int(np.max(pos[0]))
                min_x, max_x = int(np.min(pos[1])), int(np.max(pos[1]))
            else:
                min_x, min_y, max_x, max_y = 0, 0, w, h

            # Padding of 5px
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
            instances.append(GarmentInstance(box_dict, crop_rgba, crop_orig, primary_area_share, is_primary=True))

        else:
            # Multi-Garment: Process top components as distinct garments
            for comp in valid_components[:3]:
                if comp["area_pct"] < 0.05:
                    continue
                x, y, bw, bh = comp["bbox"]
                # Add margin
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
                instances.append(GarmentInstance(box_dict, crop_rgba, crop_orig, float(comp["area_pct"]), is_primary=(len(instances) == 0)))

        return rgba_full, instances
