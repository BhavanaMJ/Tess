from abc import ABC, abstractmethod
import io
import math
import logging
import base64
import json
import re
from typing import List, Dict, Any, Optional, Tuple
import requests
from PIL import Image, ImageOps

from app.services.wardrobe.segmentation_service import GarmentSegmentationService, GarmentInstance
from app.services.wardrobe.color_analyzer import GarmentColorAnalyzer, match_color_rgb
from app.services.wardrobe.catalogue_generator import CatalogueGenerator

logger = logging.getLogger(__name__)

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


class LocalNeuralVisionProvider(GarmentVisionProvider):
    """
    Offline neural vision provider combining U2-Net background removal,
    CIELAB delta E 2000 color clustering, and silhouette geometry understanding.
    Zero external API dependency. Never falsely splits full garments into top/bottom.
    """
    def __init__(self):
        self.seg_service = GarmentSegmentationService()
        self.color_analyzer = GarmentColorAnalyzer()
        self.catalogue_generator = CatalogueGenerator()

    @property
    def provider_name(self) -> str:
        return "LOCAL_NEURAL_U2NET"

    async def detect_and_segment(
        self,
        image_bytes: bytes,
        filename: str,
    ) -> List[VisionCandidateResult]:
        try:
            raw_img = Image.open(io.BytesIO(image_bytes))
            raw_img = ImageOps.exif_transpose(raw_img)
            raw_img.load()
        except Exception as e:
            raise ValueError(f"Unable to decode photograph: {e}")

        # Neural segmentation into instances
        rgba_full, instances = self.seg_service.segment_image(raw_img)

        candidates: List[VisionCandidateResult] = []

        for inst in instances:
            # Color analysis in CIELAB
            color_res = self.color_analyzer.analyze_garment_colors(inst.rgba_crop)
            primary_col = color_res["primary_color"]
            secondary_cols = color_res["secondary_colors"]
            pattern = color_res["pattern"]

            # Silhouette geometry analysis
            w = inst.rgba_crop.width
            h = inst.rgba_crop.height
            aspect_ratio = float(h) / max(1.0, float(w))

            # Vertical position relative to original photo
            y_norm = inst.bounding_box.get("y", 0.0)

            # Classify category from silhouette
            if aspect_ratio >= 1.30:
                main_category = "Ethnic Wear"
                subcategory = "Kurta"
                sleeve_length = "Full Sleeves"
                neckline = "Mandarin Collar"
                fit = "Regular Fit"
                suggested_name = f"{primary_col} {pattern if pattern != 'Solid' else ''} Kurta".strip()
            elif aspect_ratio >= 1.05 and y_norm > 0.40:
                main_category = "Bottoms"
                subcategory = "Trousers"
                sleeve_length = None
                neckline = None
                fit = "Regular Fit"
                suggested_name = f"{primary_col} Tailored Trousers"
            elif aspect_ratio < 0.95:
                main_category = "Tops"
                subcategory = "Shirt"
                sleeve_length = "Short Sleeves"
                neckline = "Collared"
                fit = "Regular Fit"
                suggested_name = f"{primary_col} {pattern if pattern != 'Solid' else ''} Shirt".strip()
            else:
                main_category = "Tops"
                subcategory = "Shirt"
                sleeve_length = "Full Sleeves"
                neckline = "Standard Collar"
                fit = "Regular Fit"
                suggested_name = f"{primary_col} Casual Top"

            # Create studio catalogue image
            cat_bytes = self.catalogue_generator.create_catalogue_image(inst.rgba_crop)

            # Create original crop bytes
            crop_buf = io.BytesIO()
            inst.original_crop.convert("RGB").save(crop_buf, format="JPEG", quality=88)

            candidates.append(
                VisionCandidateResult(
                    suggested_name=suggested_name,
                    main_category=main_category,
                    subcategory=subcategory,
                    primary_color=primary_col,
                    secondary_colors=secondary_cols,
                    pattern=pattern,
                    fabric_material="Cotton appearance",
                    sleeve_length=sleeve_length,
                    neckline=neckline,
                    fit=fit,
                    confidence_scores={
                        "category": "HIGH",
                        "primary_color": "HIGH",
                        "pattern": "HIGH",
                        "sleeve_length": "MEDIUM",
                        "fabric_material": "LOW",
                    },
                    bounding_box=inst.bounding_box,
                    processed_image_bytes=cat_bytes,
                    original_crop_bytes=crop_buf.getvalue(),
                    uncertainty_notes="Processed with neural U2-Net segmentation & CIELAB color analysis. Please verify fabric details.",
                )
            )

        return candidates


class OllamaVisionProvider(GarmentVisionProvider):
    """
    Multimodal Vision provider running local vision models (e.g. moondream / llama3.2-vision)
    via Ollama.
    Combines neural background removal with deep visual-language attribute understanding.
    """
    def __init__(self, base_url: str = "http://localhost:11434", model_name: str = "moondream:latest"):
        self.base_url = base_url.rstrip("/")
        self.model_name = model_name
        self.seg_service = GarmentSegmentationService()
        self.color_analyzer = GarmentColorAnalyzer()
        self.catalogue_generator = CatalogueGenerator()
        self.fallback_provider = LocalNeuralVisionProvider()

    @property
    def provider_name(self) -> str:
        return f"OLLAMA_VISION:{self.model_name}"

    def _query_vlm(self, image_bytes: bytes, prompt: str) -> Optional[str]:
        """Queries local Ollama vision endpoint."""
        try:
            b64_img = base64.b64encode(image_bytes).decode("utf-8")
            payload = {
                "model": self.model_name,
                "prompt": prompt,
                "images": [b64_img],
                "stream": False,
            }
            resp = requests.post(f"{self.base_url}/api/generate", json=payload, timeout=45)
            if resp.status_code == 200:
                return resp.json().get("response", "")
            logger.warning(f"[OllamaVision] Ollama returned status {resp.status_code}: {resp.text}")
            return None
        except Exception as e:
            logger.warning(f"[OllamaVision] Failed to query Ollama ({e})")
            return None

    def _parse_vlm_attributes(self, description: str, primary_col: str, fallback_subcat: str) -> Dict[str, Any]:
        """Extracts structured attributes from multimodal text output."""
        desc_lower = description.lower()

        # Category and Subcategory
        main_cat = "Tops"
        subcat = fallback_subcat

        if any(w in desc_lower for w in ["kurta", "kurti", "tunic", "ethnic", "sherwani", "salwar", "kameez"]):
            main_cat = "Ethnic Wear"
            subcat = "Kurta"
        elif any(w in desc_lower for w in ["dress", "gown", "frock", "maxi"]):
            main_cat = "Dresses"
            subcat = "Dress"
        elif any(w in desc_lower for w in ["jean", "denim pant", "trousers", "pants", "chinos", "leggings", "shorts", "skirt"]):
            main_cat = "Bottoms"
            if "jean" in desc_lower:
                subcat = "Jeans"
            elif "skirt" in desc_lower:
                subcat = "Skirt"
            elif "shorts" in desc_lower:
                subcat = "Shorts"
            else:
                subcat = "Trousers"
        elif any(w in desc_lower for w in ["jacket", "coat", "blazer", "cardigan", "hoodie", "sweater"]):
            main_cat = "Outerwear"
            if "blazer" in desc_lower:
                subcat = "Blazer"
            elif "jacket" in desc_lower:
                subcat = "Jacket"
            else:
                subcat = "Coat"
        elif any(w in desc_lower for w in ["t-shirt", "tee", "polo"]):
            main_cat = "Tops"
            subcat = "T-Shirt"
        elif any(w in desc_lower for w in ["shirt", "button-down", "blouse", "top"]):
            main_cat = "Tops"
            subcat = "Shirt"

        # Sleeve Length
        sleeve = "Full Sleeves"
        if any(w in desc_lower for w in ["sleeveless", "no sleeves", "tank"]):
            sleeve = "Sleeveless"
        elif any(w in desc_lower for w in ["short sleeve", "short-sleeved", "half sleeve"]):
            sleeve = "Short Sleeves"
        elif any(w in desc_lower for w in ["3/4 sleeve", "three-quarter", "three quarter"]):
            sleeve = "3/4 Sleeves"
        elif any(w in desc_lower for w in ["long sleeve", "full sleeve", "long-sleeved"]):
            sleeve = "Full Sleeves"

        # Neckline / Collar
        neckline = "Standard Collar"
        if any(w in desc_lower for w in ["mandarin", "chinese collar", "band collar", "nehru"]):
            neckline = "Mandarin Collar"
        elif any(w in desc_lower for w in ["round neck", "crew neck", "circle neck"]):
            neckline = "Crew Neck"
        elif any(w in desc_lower for w in ["v-neck", "v neck"]):
            neckline = "V-Neck"
        elif any(w in desc_lower for w in ["collar", "button-down", "polo"]):
            neckline = "Standard Collar"
        elif any(w in desc_lower for w in ["square neck"]):
            neckline = "Square Neck"

        # Pattern
        pattern = "Solid"
        if any(w in desc_lower for w in ["floral", "flower"]):
            pattern = "Floral"
        elif any(w in desc_lower for w in ["strip"]):
            pattern = "Striped"
        elif any(w in desc_lower for w in ["check", "plaid", "tartan"]):
            pattern = "Checked"
        elif any(w in desc_lower for w in ["print", "pattern", "polka", "geometric"]):
            pattern = "Printed / Patterned"
        elif any(w in desc_lower for w in ["embroider"]):
            pattern = "Embroidered"

        # Fabric Material
        fabric = "Cotton appearance"
        if "linen" in desc_lower:
            fabric = "Linen appearance"
        elif "silk" in desc_lower:
            fabric = "Silk appearance"
        elif "denim" in desc_lower:
            fabric = "Denim"
        elif "wool" in desc_lower:
            fabric = "Wool / Knit"
        elif "cotton" in desc_lower:
            fabric = "Cotton appearance"

        # Fit
        fit = "Regular Fit"
        if any(w in desc_lower for w in ["slim", "tight", "fitted"]):
            fit = "Slim Fit"
        elif any(w in desc_lower for w in ["loose", "relaxed", "oversized"]):
            fit = "Relaxed Fit"

        # Suggested Name
        pattern_prefix = f"{pattern} " if pattern not in ["Solid", None] else ""
        suggested_name = f"{primary_col} {pattern_prefix}{subcat}".strip()

        return {
            "suggested_name": suggested_name,
            "main_category": main_cat,
            "subcategory": subcat,
            "sleeve_length": sleeve if main_cat not in ["Bottoms"] else None,
            "neckline": neckline if main_cat not in ["Bottoms"] else None,
            "pattern": pattern,
            "fabric_material": fabric,
            "fit": fit,
        }

    async def detect_and_segment(
        self,
        image_bytes: bytes,
        filename: str,
    ) -> List[VisionCandidateResult]:
        try:
            raw_img = Image.open(io.BytesIO(image_bytes))
            raw_img = ImageOps.exif_transpose(raw_img)
            raw_img.load()
        except Exception as e:
            raise ValueError(f"Unable to decode photograph: {e}")

        # Step 1: Neural segmentation into physical garment instances
        rgba_full, instances = self.seg_service.segment_image(raw_img)

        candidates: List[VisionCandidateResult] = []

        for inst in instances:
            # Step 2: Accurate CIELAB color analysis on masked foreground
            color_res = self.color_analyzer.analyze_garment_colors(inst.rgba_crop)
            primary_col = color_res["primary_color"]
            secondary_cols = color_res["secondary_colors"]
            detected_pattern = color_res["pattern"]

            # Step 3: Studio catalogue framing
            cat_bytes = self.catalogue_generator.create_catalogue_image(inst.rgba_crop)

            # Step 4: Multimodal attribute extraction on the catalogue image
            prompt = (
                "Describe this clothing item in detail, including category (kurta/dress/shirt/trousers), "
                "sleeve length, collar or neckline, fabric appearance, and pattern."
            )
            vlm_text = self._query_vlm(cat_bytes, prompt)

            w = inst.rgba_crop.width
            h = inst.rgba_crop.height
            aspect_ratio = float(h) / max(1.0, float(w))
            fallback_subcat = "Kurta" if aspect_ratio >= 1.30 else "Shirt"

            if vlm_text:
                attrs = self._parse_vlm_attributes(vlm_text, primary_col, fallback_subcat)
                # If color analyzer detected a strong print and VLM agrees or says solid, refine pattern
                if detected_pattern != "Solid" and attrs["pattern"] == "Solid":
                    attrs["pattern"] = detected_pattern
                confidence = "HIGH"
                notes = f"Analyzed with {self.model_name}. Please verify fabric details."
            else:
                # Fallback to geometry
                attrs = {
                    "suggested_name": f"{primary_col} {detected_pattern if detected_pattern != 'Solid' else ''} {fallback_subcat}".strip(),
                    "main_category": "Ethnic Wear" if aspect_ratio >= 1.30 else "Tops",
                    "subcategory": fallback_subcat,
                    "sleeve_length": "Full Sleeves" if aspect_ratio >= 1.30 else "Short Sleeves",
                    "neckline": "Mandarin Collar" if aspect_ratio >= 1.30 else "Collared",
                    "pattern": detected_pattern,
                    "fabric_material": "Cotton appearance",
                    "fit": "Regular Fit",
                }
                confidence = "MEDIUM"
                notes = "Attributes inferred from neural segmentation and silhouette geometry. Please verify fabric details."

            crop_buf = io.BytesIO()
            inst.original_crop.convert("RGB").save(crop_buf, format="JPEG", quality=88)

            candidates.append(
                VisionCandidateResult(
                    suggested_name=attrs["suggested_name"],
                    main_category=attrs["main_category"],
                    subcategory=attrs["subcategory"],
                    primary_color=primary_col,
                    secondary_colors=secondary_cols,
                    pattern=attrs["pattern"],
                    fabric_material=attrs["fabric_material"],
                    sleeve_length=attrs["sleeve_length"],
                    neckline=attrs["neckline"],
                    fit=attrs["fit"],
                    confidence_scores={
                        "category": confidence,
                        "primary_color": "HIGH",
                        "pattern": "HIGH",
                        "sleeve_length": confidence,
                        "fabric_material": "LOW",
                    },
                    bounding_box=inst.bounding_box,
                    processed_image_bytes=cat_bytes,
                    original_crop_bytes=crop_buf.getvalue(),
                    uncertainty_notes=notes,
                )
            )

        return candidates


class MultimodalVisionProvider(GarmentVisionProvider):
    """
    Multimodal Vision-Language Provider using OpenRouter API.
    Activated when OPENROUTER_API_KEY is configured.
    """
    def __init__(self, api_key: str, model_name: Optional[str] = None):
        self.api_key = api_key
        self.model_name = model_name or "google/gemini-2.0-flash-exp:free"
        self.seg_service = GarmentSegmentationService()
        self.color_analyzer = GarmentColorAnalyzer()
        self.catalogue_generator = CatalogueGenerator()
        self.fallback_provider = LocalNeuralVisionProvider()

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
            "Analyze the image and detect every individual garment visible (e.g. kurta, dress, shirt, trousers, jacket). "
            "Output strictly valid JSON with this structure:\n"
            "{\n"
            '  "garments": [\n'
            '    {\n'
            '      "name": "Wine Floral Kurta",\n'
            '      "main_category": "Ethnic Wear",\n'
            '      "subcategory": "Kurta",\n'
            '      "primary_color": "Wine",\n'
            '      "secondary_colors": ["Dusty Pink"],\n'
            '      "pattern": "Floral",\n'
            '      "fabric_material": "Cotton appearance",\n'
            '      "sleeve_length": "Full Sleeves",\n'
            '      "neckline": "Mandarin Collar",\n'
            '      "fit": "Regular Fit",\n'
            '      "confidence_scores": {"category": "HIGH", "primary_color": "HIGH", "pattern": "HIGH", "sleeve_length": "HIGH", "fabric_material": "LOW"},\n'
            '      "bounding_box": {"x": 0.1, "y": 0.05, "width": 0.8, "height": 0.9},\n'
            '      "uncertainty_notes": "None"\n'
            "    }\n"
            "  ]\n"
            "}\n"
            "Do NOT split single garments like dresses, kurtas, or jumpsuits into top and bottom. Output each distinct clothing item as one garment."
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
                    return await self.fallback_provider.detect_and_segment(image_bytes, filename)

                # Segment image with U2-Net for high-quality catalogue output
                raw_img = Image.open(io.BytesIO(image_bytes))
                raw_img = ImageOps.exif_transpose(raw_img)
                w, h = raw_img.size

                rgba_full, instances = self.seg_service.segment_image(raw_img)

                candidates: List[VisionCandidateResult] = []
                for i, item in enumerate(garment_list):
                    inst = instances[i] if i < len(instances) else instances[0]
                    cat_bytes = self.catalogue_generator.create_catalogue_image(inst.rgba_crop)

                    crop_buf = io.BytesIO()
                    inst.original_crop.convert("RGB").save(crop_buf, format="JPEG", quality=88)

                    # Enhance colors with CIELAB analyzer
                    color_res = self.color_analyzer.analyze_garment_colors(inst.rgba_crop)
                    primary_col = item.get("primary_color") or color_res["primary_color"]
                    sec_cols = item.get("secondary_colors") or color_res["secondary_colors"]

                    candidates.append(
                        VisionCandidateResult(
                            suggested_name=item.get("name", f"{primary_col} Detected Garment"),
                            main_category=item.get("main_category", "Tops"),
                            subcategory=item.get("subcategory"),
                            primary_color=primary_col,
                            secondary_colors=sec_cols,
                            pattern=item.get("pattern", color_res["pattern"]),
                            fabric_material=item.get("fabric_material", "Cotton appearance"),
                            sleeve_length=item.get("sleeve_length"),
                            neckline=item.get("neckline"),
                            fit=item.get("fit", "Regular Fit"),
                            confidence_scores=item.get("confidence_scores", {"category": "HIGH", "primary_color": "HIGH"}),
                            bounding_box=inst.bounding_box,
                            processed_image_bytes=cat_bytes,
                            original_crop_bytes=crop_buf.getvalue(),
                            uncertainty_notes=item.get("uncertainty_notes"),
                        )
                    )

                return candidates
        except Exception as e:
            logger.warning(f"[MultimodalVisionProvider] API call failed: {e}. Falling back to LocalNeuralVisionProvider.")
            return await self.fallback_provider.detect_and_segment(image_bytes, filename)


def get_vision_provider() -> GarmentVisionProvider:
    """
    Returns production vision provider in order of capability:
    1. OpenRouter (if API key is present)
    2. Ollama Vision (if local Ollama is available)
    3. Local Neural U2-Net (offline neural segmentation + CIELAB color + silhouette)
    """
    from app.core.config import settings

    if settings.openrouter_api_key and settings.openrouter_api_key.strip():
        logger.info("[VisionProvider] Initializing MultimodalVisionProvider via OpenRouter.")
        return MultimodalVisionProvider(api_key=settings.openrouter_api_key, model_name=settings.openrouter_model)

    # Check if Ollama is accessible
    try:
        r = requests.get(f"{settings.ollama_base_url}/api/tags", timeout=1.5)
        if r.status_code == 200:
            logger.info(f"[VisionProvider] Initializing OllamaVisionProvider with {settings.ollama_vision_model}.")
            return OllamaVisionProvider(base_url=settings.ollama_base_url, model_name=settings.ollama_vision_model)
    except Exception:
        pass

    logger.info("[VisionProvider] Initializing LocalNeuralVisionProvider (U2-Net + CIELAB).")
    return LocalNeuralVisionProvider()
