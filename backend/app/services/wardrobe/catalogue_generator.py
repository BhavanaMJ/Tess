import io
import logging
from typing import Tuple, Optional
import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)

class CatalogueGenerator:
    """
    Transforms segmented garments into clean, professional, catalogue-style studio photographs.
    - Preserves garment proportions, colors, and full design details (sleeves, neckline, hem).
    - Removes all original background noise and clutter.
    - Centers the garment on a pristine neutral studio canvas (#FAFAFA).
    - Uses Lanczos anti-aliasing resampling for crisp fabric textures.
    """

    DEFAULT_CANVAS_SIZE = (800, 800)
    DEFAULT_BG_COLOR = (250, 250, 250)  # Pristine studio #FAFAFA

    def create_catalogue_image(
        self,
        rgba_img: Image.Image,
        canvas_size: Tuple[int, int] = DEFAULT_CANVAS_SIZE,
        bg_color: Tuple[int, int, int] = DEFAULT_BG_COLOR,
        padding_ratio: float = 0.14,  # 14% padding keeps margins clean and details fully visible
        output_format: str = "JPEG",
        quality: int = 92,
    ) -> bytes:
        """
        Creates a studio catalogue image from a transparent RGBA garment.
        """
        if rgba_img.mode != "RGBA":
            rgba_img = rgba_img.convert("RGBA")

        # Find tight bounding box of visible garment pixels
        alpha = np.array(rgba_img)[:, :, 3]
        pos = np.where(alpha > 25)

        if len(pos[0]) > 0:
            ymin, ymax = int(np.min(pos[0])), int(np.max(pos[0]))
            xmin, xmax = int(np.min(pos[1])), int(np.max(pos[1]))

            # Add 6px breathing room if possible
            h, w = alpha.shape
            ymin = max(0, ymin - 6)
            ymax = min(h, ymax + 6)
            xmin = max(0, xmin - 6)
            xmax = min(w, xmax + 6)

            cropped = rgba_img.crop((xmin, ymin, xmax, ymax))
        else:
            cropped = rgba_img

        # Create studio background canvas
        studio_canvas = Image.new("RGB", canvas_size, bg_color)

        # Scale garment to fit within bounded inner frame preserving exact aspect ratio
        max_w = int(canvas_size[0] * (1.0 - padding_ratio))
        max_h = int(canvas_size[1] * (1.0 - padding_ratio))

        garment_copy = cropped.copy()
        resample_filter = getattr(getattr(Image, "Resampling", None), "LANCZOS", Image.LANCZOS)
        garment_copy.thumbnail((max_w, max_h), resample_filter)

        # Center on canvas
        offset_x = (canvas_size[0] - garment_copy.width) // 2
        offset_y = (canvas_size[1] - garment_copy.height) // 2

        # Paste with alpha mask
        if garment_copy.mode == "RGBA":
            studio_canvas.paste(garment_copy, (offset_x, offset_y), mask=garment_copy.split()[3])
        else:
            studio_canvas.paste(garment_copy, (offset_x, offset_y))

        out_buf = io.BytesIO()
        if output_format.upper() == "JPEG":
            studio_canvas.save(out_buf, format="JPEG", quality=quality, optimize=True)
        else:
            studio_canvas.save(out_buf, format="PNG", optimize=True)

        return out_buf.getvalue()

    def create_transparent_png(
        self,
        rgba_img: Image.Image,
        max_dimension: int = 1000,
    ) -> bytes:
        """Returns isolated garment as a transparent PNG for flexible UI layering."""
        if rgba_img.mode != "RGBA":
            rgba_img = rgba_img.convert("RGBA")

        alpha = np.array(rgba_img)[:, :, 3]
        pos = np.where(alpha > 25)

        if len(pos[0]) > 0:
            ymin, ymax = int(np.min(pos[0])), int(np.max(pos[0]))
            xmin, xmax = int(np.min(pos[1])), int(np.max(pos[1]))
            cropped = rgba_img.crop((xmin, ymin, xmax, ymax))
        else:
            cropped = rgba_img

        resample_filter = getattr(getattr(Image, "Resampling", None), "LANCZOS", Image.LANCZOS)
        cropped.thumbnail((max_dimension, max_dimension), resample_filter)

        out_buf = io.BytesIO()
        cropped.save(out_buf, format="PNG", optimize=True)
        return out_buf.getvalue()

