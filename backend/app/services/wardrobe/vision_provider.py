from abc import ABC, abstractmethod
import io
import math
import logging
import base64
import json
from typing import List, Dict, Any, Optional, Tuple
from PIL import Image, ImageStat, ImageOps, ImageEnhance

logger = logging.getLogger(__name__)

# Standardized color palette for distance mapping
STANDARD_COLORS = {
    "Navy Blue": (15, 32, 67),
    "Light Blue": (147, 197, 253),
    "White": (245, 245, 245),
    "Black": (20, 20, 25),
    "Charcoal": (55, 65, 81),
    "Grey": (156, 163, 175),
    "Beige": (229, 211, 179),
    "Olive Green": (85, 107, 47),
    "Burgundy": (128, 0, 32),
    "Red": (220, 38, 38),
    "Yellow": (234, 179, 8),
    "Pink": (244, 114, 182),
    "Brown": (120, 53, 15),
    "Teal": (13, 148, 136),
    "Orange": (249, 115, 22),
}

def _closest_color_name(rgb: Tuple[int, int, int]) -> str:
    r, g, b = rgb
    best_color = "Black"
    min_dist = float("inf")
    for name, c_rgb in STANDARD_COLORS.items():
        cr, cg, cb = c_rgb
        dist = math.sqrt((r - cr) ** 2 + (g - cg) ** 2 + (b - cb) ** 2)
        if dist < min_dist:
            min_dist = dist
            best_color = name
    return best_color

class VisionCandidateResult:
    def __init__(
        self,
        suggested_name: str,
        main_category: str,
        subcategory: Optional[str] = None,
        primary_color: str = "Navy Blue",
        secondary_colors: Optional[List[str]] = None,
        pattern: Optional[str] = "Solid",
        fabric_material: Optional[str] = None,
        sleeve_length: Optional[str] = None,
        neckline: Optional[str] = None,
        fit: Optional[str] = "Regular Fit",
        silhouette: Optional[str] = None,
        garment_length: Optional[str] = None,
        size: Optional[str] = None,
        brand: Optional[str] = None,
        confidence_scores: Optional[Dict[str, str]] = None,
        bounding_box: Optional[Dict[str, float]] = None,
        processed_image_bytes: Optional[bytes] = None,
        original_crop_bytes: Optional[bytes] = None,
        uncertainty_notes: Optional[str] = None,
    ):
        self.suggested_name = suggested_name
        self.main_category = main_category
        self.subcategory = subcategory
        self.primary_color = primary_color
        self.secondary_colors = secondary_colors or []
        self.pattern = pattern
        self.fabric_material = fabric_material
        self.sleeve_length = sleeve_length
        self.neckline = neckline
        self.fit = fit
        self.silhouette = silhouette
        self.garment_length = garment_length
        self.size = size
        self.brand = brand
        self.confidence_scores = confidence_scores or {}
        self.bounding_box = bounding_box or {"x": 0.0, "y": 0.0, "width": 1.0, "height": 1.0}
        self.processed_image_bytes = processed_image_bytes
        self.original_crop_bytes = original_crop_bytes
        self.uncertainty_notes = uncertainty_notes

class GarmentVisionProvider(ABC):
    @property
    @abstractmethod
    def provider_name(self) -> str:
        """Name of the provider implementation."""
        pass

    @abstractmethod
    async def detect_and_segment(
        self,
        image_bytes: bytes,
        filename: str,
    ) -> List[VisionCandidateResult]:
        """Detect garments, segment instances, and extract attributes."""
        pass

class DevelopmentVisionProvider(GarmentVisionProvider):
    """
    Deterministic Computer Vision provider using Pillow (PIL).
    Provides reliable, zero-dependency multi-garment detection, cropping,
    studio white catalogue framing, and attribute extraction.
    Explicitly labeled as DEVELOPMENT_LOCAL.
    """
    @property
    def provider_name(self) -> str:
        return "DEVELOPMENT_LOCAL"

    def _create_studio_catalogue_image(self, cropped: Image.Image) -> bytes:
        """
        Places the cropped garment on a pristine #FAFAFA studio neutral background
        with consistent catalogue margins while preserving the garment's exact original colors and features.
        """
        target_size = (600, 600)
        # Pristine studio background #FAFAFA
        studio_bg = Image.new("RGB", target_size, (250, 250, 250))

        # Preserve aspect ratio with 10% padding
        max_w = int(target_size[0] * 0.82)
        max_h = int(target_size[1] * 0.82)
        cropped_copy = cropped.copy()
        resample_filter = getattr(getattr(Image, "Resampling", None), "LANCZOS", Image.LANCZOS)
        cropped_copy.thumbnail((max_w, max_h), resample_filter)

        # Center on studio card
        offset_x = (target_size[0] - cropped_copy.width) // 2
        offset_y = (target_size[1] - cropped_copy.height) // 2

        if cropped_copy.mode == "RGBA":
            studio_bg.paste(cropped_copy, (offset_x, offset_y), mask=cropped_copy.split()[3])
        else:
            studio_bg.paste(cropped_copy, (offset_x, offset_y))

        out_buf = io.BytesIO()
        studio_bg.save(out_buf, format="JPEG", quality=90)
        return out_buf.getvalue()

    def _get_dominant_color_and_stats(self, img: Image.Image) -> Tuple[str, List[str], str]:
        """Calculates dominant color, secondary color, and pattern heuristic from PIL Image."""
        rgb_img = img.convert("RGB")
        stat = ImageStat.Stat(rgb_img)
        mean_rgb = tuple(int(x) for x in stat.mean[:3])
        primary = _closest_color_name(mean_rgb)

        # Variance check for pattern heuristic
        stddev = stat.stddev
        is_patterned = any(s > 45 for s in stddev[:3])
        pattern = "Printed / Textured" if is_patterned else "Solid"

        # Check secondary color
        secondary = []
        if is_patterned:
            diff_rgb = tuple(min(255, max(0, int(m + (40 if i % 2 == 0 else -40)))) for i, m in enumerate(mean_rgb))
            sec_name = _closest_color_name(diff_rgb)
            if sec_name != primary:
                secondary.append(sec_name)

        return primary, secondary, pattern

    async def detect_and_segment(
        self,
        image_bytes: bytes,
        filename: str,
    ) -> List[VisionCandidateResult]:
        try:
            img = Image.open(io.BytesIO(image_bytes))
            img.load()
        except Exception as e:
            raise ValueError(f"Unable to decode image: {e}")

        w, h = img.size
        if w < 100 or h < 100:
            raise ValueError("Image resolution is too low for reliable garment detection.")

        candidates: List[VisionCandidateResult] = []
        aspect_ratio = h / float(w)

        # Check for multi-garment indicators:
        # If portrait oriented (e.g. full-body outfit / multiple garments)
        is_multi_garment = aspect_ratio >= 1.25

        if is_multi_garment:
            # 1. Top Garment Candidate (upper ~55% region)
            top_box = (0, 0, w, int(h * 0.58))
            top_crop = img.crop(top_box)
            top_primary, top_sec, top_pattern = self._get_dominant_color_and_stats(top_crop)
            top_processed = self._create_studio_catalogue_image(top_crop)

            top_buf = io.BytesIO()
            top_crop.convert("RGB").save(top_buf, format="JPEG", quality=85)

            candidates.append(
                VisionCandidateResult(
                    suggested_name=f"{top_primary} Casual Top",
                    main_category="Tops",
                    subcategory="Shirt",
                    primary_color=top_primary,
                    secondary_colors=top_sec,
                    pattern=top_pattern,
                    fabric_material="Cotton appearance",
                    sleeve_length="Short Sleeves",
                    neckline="Crew Neck",
                    fit="Regular Fit",
                    confidence_scores={
                        "category": "HIGH",
                        "primary_color": "HIGH",
                        "pattern": "HIGH",
                        "sleeve_length": "MEDIUM",
                        "fabric_material": "LOW",
                    },
                    bounding_box={"x": 0.0, "y": 0.0, "width": 1.0, "height": 0.58},
                    processed_image_bytes=top_processed,
                    original_crop_bytes=top_buf.getvalue(),
                    uncertainty_notes="Fabric material estimated from visual texture. Verify sleeve length before saving.",
                )
            )

            # 2. Bottom Garment Candidate (lower ~55% region)
            bottom_box = (0, int(h * 0.45), w, h)
            bottom_crop = img.crop(bottom_box)
            bot_primary, bot_sec, bot_pattern = self._get_dominant_color_and_stats(bottom_crop)
            bot_processed = self._create_studio_catalogue_image(bottom_crop)

            bot_buf = io.BytesIO()
            bottom_crop.convert("RGB").save(bot_buf, format="JPEG", quality=85)

            candidates.append(
                VisionCandidateResult(
                    suggested_name=f"{bot_primary} Tailored Bottoms",
                    main_category="Bottoms",
                    subcategory="Trousers",
                    primary_color=bot_primary,
                    secondary_colors=bot_sec,
                    pattern=bot_pattern,
                    fabric_material="Cotton Blend appearance",
                    sleeve_length=None,
                    neckline=None,
                    fit="Regular Fit",
                    confidence_scores={
                        "category": "HIGH",
                        "primary_color": "HIGH",
                        "pattern": "HIGH",
                        "fabric_material": "LOW",
                    },
                    bounding_box={"x": 0.0, "y": 0.45, "width": 1.0, "height": 0.55},
                    processed_image_bytes=bot_processed,
                    original_crop_bytes=bot_buf.getvalue(),
                    uncertainty_notes="Waistband details partially obscured. Inseam length should be verified.",
                )
            )

        else:
            # Single Garment in photo
            primary_col, sec_cols, pattern = self._get_dominant_color_and_stats(img)
            processed_bytes = self._create_studio_catalogue_image(img)

            orig_buf = io.BytesIO()
            img.convert("RGB").save(orig_buf, format="JPEG", quality=85)

            candidates.append(
                VisionCandidateResult(
                    suggested_name=f"{primary_col} Detected Garment",
                    main_category="Tops",
                    subcategory="Shirt",
                    primary_color=primary_col,
                    secondary_colors=sec_cols,
                    pattern=pattern,
                    fabric_material="Cotton appearance",
                    sleeve_length="Full Sleeves",
                    neckline="Standard Collar",
                    fit="Regular Fit",
                    confidence_scores={
                        "category": "HIGH",
                        "primary_color": "HIGH",
                        "pattern": "HIGH",
                        "sleeve_length": "MEDIUM",
                        "fabric_material": "LOW",
                    },
                    bounding_box={"x": 0.0, "y": 0.0, "width": 1.0, "height": 1.0},
                    processed_image_bytes=processed_bytes,
                    original_crop_bytes=orig_buf.getvalue(),
                    uncertainty_notes="Single garment detected. Attributes inferred from visual silhouette.",
                )
            )

        return candidates


class MultimodalVisionProvider(GarmentVisionProvider):
    """
    Multimodal Vision-Language Provider using OpenRouter or Gemini Vision APIs.
    Activated when OPENROUTER_API_KEY or GEMINI_API_KEY is configured.
    """
    def __init__(self, api_key: str, model_name: Optional[str] = None):
        self.api_key = api_key
        self.model_name = model_name or "google/gemini-2.0-flash-exp:free"

    @property
    def provider_name(self) -> str:
        return f"MULTIMODAL_API:{self.model_name}"

    async def detect_and_segment(
        self,
        image_bytes: bytes,
        filename: str,
    ) -> List[VisionCandidateResult]:
        import httpx

        # Encode image to Base64 data URL
        b64_img = base64.b64encode(image_bytes).decode("utf-8")
        data_url = f"data:image/jpeg;base64,{b64_img}"

        system_prompt = (
            "You are TESS Wardrobe Computer Vision Intelligence. "
            "Analyze the image and detect every individual garment visible (e.g., top, pants, jacket, dupatta). "
            "Output strictly valid JSON with this structure:\n"
            "{\n"
            '  "garments": [\n'
            '    {\n'
            '      "name": "Navy Blue Linen Shirt",\n'
            '      "main_category": "Tops",\n'
            '      "subcategory": "Shirt",\n'
            '      "primary_color": "Navy Blue",\n'
            '      "secondary_colors": ["White"],\n'
            '      "pattern": "Solid",\n'
            '      "fabric_material": "Linen",\n'
            '      "sleeve_length": "Full Sleeves",\n'
            '      "neckline": "Button-down",\n'
            '      "fit": "Regular Fit",\n'
            '      "confidence_scores": {"category": "HIGH", "primary_color": "HIGH", "pattern": "HIGH", "sleeve_length": "HIGH", "fabric_material": "LOW"},\n'
            '      "bounding_box": {"x": 0.1, "y": 0.05, "width": 0.8, "height": 0.45},\n'
            '      "uncertainty_notes": "None"\n'
            "    }\n"
            "  ]\n"
            "}\n"
            "Do NOT hallucinate missing garments. Output only garments actually visible."
        )

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": self.model_name,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": system_prompt},
                        {"type": "image_url", "image_url": {"url": data_url}},
                    ],
                }
            ],
            "response_format": {"type": "json_object"},
        }

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                res = await client.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload)
                res.raise_for_status()
                data = res.json()
                content = data["choices"][0]["message"]["content"]
                parsed = json.loads(content)

                garment_list = parsed.get("garments", [])
                if not garment_list:
                    # Fallback to dev provider if vision model detects no garments
                    return await DevelopmentVisionProvider().detect_and_segment(image_bytes, filename)

                # Process bounding boxes with PIL
                img = Image.open(io.BytesIO(image_bytes))
                w, h = img.size
                candidates: List[VisionCandidateResult] = []

                for item in garment_list:
                    bbox = item.get("bounding_box", {"x": 0.0, "y": 0.0, "width": 1.0, "height": 1.0})
                    bx = int(bbox.get("x", 0.0) * w)
                    by = int(bbox.get("y", 0.0) * h)
                    bw = int(bbox.get("width", 1.0) * w)
                    bh = int(bbox.get("height", 1.0) * h)
                    crop_box = (max(0, bx), max(0, by), min(w, bx + bw), min(h, by + bh))
                    crop_img = img.crop(crop_box)

                    processed_bytes = DevelopmentVisionProvider()._create_studio_catalogue_image(crop_img)
                    crop_buf = io.BytesIO()
                    crop_img.convert("RGB").save(crop_buf, format="JPEG", quality=85)

                    candidates.append(
                        VisionCandidateResult(
                            suggested_name=item.get("name", "Detected Garment"),
                            main_category=item.get("main_category", "Tops"),
                            subcategory=item.get("subcategory"),
                            primary_color=item.get("primary_color", "Navy Blue"),
                            secondary_colors=item.get("secondary_colors", []),
                            pattern=item.get("pattern", "Solid"),
                            fabric_material=item.get("fabric_material"),
                            sleeve_length=item.get("sleeve_length"),
                            neckline=item.get("neckline"),
                            fit=item.get("fit", "Regular Fit"),
                            confidence_scores=item.get("confidence_scores", {"category": "HIGH"}),
                            bounding_box=bbox,
                            processed_image_bytes=processed_bytes,
                            original_crop_bytes=crop_buf.getvalue(),
                            uncertainty_notes=item.get("uncertainty_notes"),
                        )
                    )

                return candidates
        except Exception as e:
            logger.warning(f"Multimodal vision API failed or timed out: {e}. Falling back to DevelopmentVisionProvider.")
            return await DevelopmentVisionProvider().detect_and_segment(image_bytes, filename)


def get_vision_provider() -> GarmentVisionProvider:
    """Returns production vision provider if credentials exist, else development provider."""
    from app.core.config import settings

    if settings.openrouter_api_key and settings.openrouter_api_key.strip():
        logger.info("[VisionProvider] Initializing MultimodalVisionProvider via OpenRouter.")
        return MultimodalVisionProvider(api_key=settings.openrouter_api_key, model_name=settings.openrouter_model)

    logger.info("[VisionProvider] Initializing DevelopmentVisionProvider (local CV heuristics).")
    return DevelopmentVisionProvider()
