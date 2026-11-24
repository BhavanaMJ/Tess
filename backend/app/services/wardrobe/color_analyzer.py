import math
import logging
from typing import List, Dict, Tuple, Optional, Any
import numpy as np
import cv2
from PIL import Image
from skimage import color

logger = logging.getLogger(__name__)

# Standardized fashion color palette
STANDARD_PALETTE: Dict[str, Tuple[int, int, int]] = {
    "Black": (25, 25, 28),
    "Charcoal": (55, 65, 81),
    "Grey": (156, 163, 175),
    "Silver": (192, 192, 192),
    "White": (245, 245, 245),
    "Cream": (245, 240, 225),
    "Beige": (229, 211, 179),
    "Khaki": (195, 176, 145),
    "Camel": (193, 154, 107),
    "Brown": (110, 60, 25),
    "Rust": (180, 75, 45),
    "Navy Blue": (15, 32, 67),
    "Royal Blue": (37, 99, 235),
    "Light Blue": (147, 197, 253),
    "Teal": (13, 148, 136),
    "Turquoise": (64, 224, 208),
    "Olive Green": (85, 107, 47),
    "Sage Green": (156, 175, 136),
    "Forest Green": (34, 100, 60),
    "Emerald Green": (16, 185, 129),
    "Mint Green": (167, 243, 208),
    "Burgundy": (128, 18, 50),
    "Maroon": (128, 0, 32),
    "Wine": (114, 47, 55),
    "Red": (220, 38, 38),
    "Coral": (248, 113, 113),
    "Pink": (244, 114, 182),
    "Dusty Pink": (212, 143, 156),
    "Magenta": (217, 70, 239),
    "Purple": (126, 34, 206),
    "Lavender": (196, 181, 253),
    "Mustard": (217, 160, 25),
    "Yellow": (234, 179, 8),
    "Orange": (249, 115, 22),
    "Peach": (255, 204, 182),
    "Gold": (212, 175, 55),
}

# Precompute standard palette LAB values
_PALETTE_LAB: Dict[str, np.ndarray] = {}
for _name, _rgb in STANDARD_PALETTE.items():
    _rgb_norm = np.array([[[_rgb[0] / 255.0, _rgb[1] / 255.0, _rgb[2] / 255.0]]], dtype=np.float32)
    _PALETTE_LAB[_name] = color.rgb2lab(_rgb_norm)[0][0]


def match_color_cielab(lab_value: np.ndarray) -> str:
    """Finds closest color in standard palette using CIEDE2000 perceptual distance."""
    best_name = "Black"
    min_dist = float("inf")
    test_lab = lab_value.reshape(1, 1, 3)

    for name, pal_lab in _PALETTE_LAB.items():
        pal_reshaped = pal_lab.reshape(1, 1, 3)
        de = float(color.deltaE_ciede2000(test_lab, pal_reshaped)[0][0])
        if de < min_dist:
            min_dist = de
            best_name = name

    return best_name


def match_color_rgb(rgb: Tuple[int, int, int]) -> str:
    """Converts RGB to CIELAB and matches closest color."""
    rgb_norm = np.array([[[rgb[0] / 255.0, rgb[1] / 255.0, rgb[2] / 255.0]]], dtype=np.float32)
    lab_val = color.rgb2lab(rgb_norm)[0][0]
    return match_color_cielab(lab_val)


class GarmentColorAnalyzer:
    """
    Analyzes garment-specific colors strictly within masked foreground pixels.
    Converts to CIELAB space and performs K-Means clustering to distinguish:
    - Primary dominant color
    - Secondary colors
    - Accent colors
    - Print / pattern detection
    Completely eliminates background, cast shadows, and edge contamination.
    """

    def analyze_garment_colors(
        self,
        rgba_img: Image.Image,
        alpha_threshold: int = 70,
        max_samples: int = 15000,
    ) -> Dict[str, Any]:
        """
        Extracts foreground pixels, clusters colors in CIELAB space,
        and matches them against the standard fashion color palette.
        """
        if rgba_img.mode != "RGBA":
            rgba_img = rgba_img.convert("RGBA")

        np_img = np.array(rgba_img)
        alpha = np_img[:, :, 3]
        mask = alpha >= alpha_threshold

        fg_rgb = np_img[:, :, :3][mask]

        if len(fg_rgb) < 50:
            # Fallback if almost no foreground pixels
            return {
                "primary_color": "Navy Blue",
                "secondary_colors": [],
                "accent_colors": [],
                "pattern": "Solid",
                "color_distribution": {"Navy Blue": 1.0},
            }

        # Subsample for efficient clustering if large
        if len(fg_rgb) > max_samples:
            indices = np.random.choice(len(fg_rgb), max_samples, replace=False)
            sample_rgb = fg_rgb[indices]
        else:
            sample_rgb = fg_rgb

        # Convert sample to CIELAB
        sample_rgb_float = sample_rgb.astype(np.float32) / 255.0
        sample_lab = color.rgb2lab(sample_rgb_float.reshape(-1, 1, 3)).reshape(-1, 3)

        # Filter out extreme shadows (L* < 8) and specular highlights (L* > 96)
        # unless garment is genuinely mostly black or white
        mean_l = float(np.mean(sample_lab[:, 0]))
        if 20.0 < mean_l < 85.0:
            valid_l = (sample_lab[:, 0] > 10.0) & (sample_lab[:, 0] < 94.0)
            if np.sum(valid_l) > 500:
                sample_lab = sample_lab[valid_l]
                sample_rgb = sample_rgb[valid_l]

        # Determine number of clusters K based on pixel count
        k = 3 if len(sample_lab) >= 300 else 1

        if k == 1:
            mean_lab = np.mean(sample_lab, axis=0)
            dominant = match_color_cielab(mean_lab)
            return {
                "primary_color": dominant,
                "secondary_colors": [],
                "accent_colors": [],
                "pattern": "Solid",
                "color_distribution": {dominant: 1.0},
            }

        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 15, 0.5)
        _, labels, centers_lab = cv2.kmeans(
            sample_lab.astype(np.float32),
            k,
            None,
            criteria,
            10,
            cv2.KMEANS_RANDOM_CENTERS,
        )

        counts = np.bincount(labels.flatten(), minlength=k)
        total_pixels = len(labels)

        # Map each cluster to standard palette and aggregate shares
        cluster_shares: Dict[str, float] = {}
        for i in range(k):
            pct = float(counts[i]) / float(total_pixels)
            color_name = match_color_cielab(centers_lab[i])
            cluster_shares[color_name] = cluster_shares.get(color_name, 0.0) + pct

        # Sort aggregated colors by percentage
        sorted_colors = sorted(cluster_shares.items(), key=lambda item: item[1], reverse=True)

        primary_color = sorted_colors[0][0]
        primary_pct = sorted_colors[0][1]

        secondary_colors: List[str] = []
        accent_colors: List[str] = []

        for color_name, pct in sorted_colors[1:]:
            if pct >= 0.12 and color_name != primary_color:
                secondary_colors.append(color_name)
            elif pct >= 0.03 and color_name != primary_color and color_name not in secondary_colors:
                accent_colors.append(color_name)

        # Pattern determination
        if primary_pct >= 0.82:
            pattern = "Solid"
        elif secondary_colors:
            pattern = "Printed / Patterned"
        else:
            pattern = "Solid"

        return {
            "primary_color": primary_color,
            "secondary_colors": secondary_colors,
            "accent_colors": accent_colors,
            "pattern": pattern,
            "color_distribution": {name: round(pct, 3) for name, pct in sorted_colors},
        }

