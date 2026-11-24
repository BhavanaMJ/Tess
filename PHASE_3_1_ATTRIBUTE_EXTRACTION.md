# Phase 3.1 — Accurate Garment Attribute Extraction & Masked CIELAB Color Intelligence

**Document Version:** 1.0  
**Date:** November 24, 2026  
**Status:** Completed & Validated in Production  

---

## 1. Overview & Problem Definition

Extracting accurate visual attributes (color, pattern, neckline, sleeve length, fabric appearance, category) from mobile phone photographs presents significant computer vision challenges:
1. **Background Contamination:** Unsegmented pixel averages include bedsheets, floors, and walls into garment color calculations.
2. **Lighting Variations & Cast Shadows:** Direct sunlight, warm indoor lighting, or underexposure shift RGB values dramatically.
3. **RGB Distance Inaccuracy:** Euclidean distance in standard RGB space ($\sqrt{\Delta R^2 + \Delta G^2 + \Delta B^2}$) does not reflect human perceptual color vision.
4. **Complex Patterns & Prints:** Many garments have dominant base colors with contrasting floral, geometric, or embroidered elements that must not be averaged into a murky single color.

Phase 3.1 establishes a dual-engine attribute extraction pipeline:
- **Engine A (Color & Pattern):** Masked CIELAB $\Delta E$ (CIEDE2000) color clustering via `backend/app/services/wardrobe/color_analyzer.py`.
- **Engine B (Structural & Semantic Attributes):** Multimodal Visual Language Model (`moondream` / Gemini) running on the isolated catalogue photograph.

---

## 2. Masked CIELAB Color Intelligence

### 2.1 Pure Foreground Masking
Only pixels where $\alpha \ge 70$ in the segmented U2-Net RGBA mask are analyzed. This guarantees **zero** background pixels, floor tiles, or wall textures can contaminate color detection.

### 2.2 Luminance Filtering
To prevent cast shadows and specular reflections from distorting the garment's true dye color:
- When mean lightness $20.0 < L^* < 85.0$, pixels with $L^* < 10.0$ (deep shadow) and $L^* > 94.0$ (specular flare) are filtered out.
- For genuinely black ($L^* < 20.0$) or pure white ($L^* > 85.0$) garments, full dynamic range is preserved.

### 2.3 CIELAB K-Means Clustering
Garment pixels are converted to CIE $L^*a^*b^*$ space and clustered using K-Means ($K=3$).
For each cluster:
- Cluster percentage share is computed.
- Cluster centroid is matched to the standardized fashion palette using **CIEDE2000** perceptual color difference ($\Delta E_{00}$):

$$\Delta E_{00} = \sqrt{\left(\frac{\Delta L'}{k_L S_L}\right)^2 + \left(\frac{\Delta C'}{k_C S_C}\right)^2 + \left(\frac{\Delta H'}{k_H S_H}\right)^2 + R_T \left(\frac{\Delta C'}{k_C S_C}\right)\left(\frac{\Delta H'}{k_H S_H}\right)}$$

### 2.4 Standard Fashion Palette (Precomputed in CIELAB)
Includes: Black, Charcoal, Grey, Silver, White, Cream, Beige, Khaki, Camel, Brown, Rust, Navy Blue, Royal Blue, Light Blue, Teal, Turquoise, Olive Green, Sage Green, Forest Green, Emerald Green, Mint Green, Burgundy, Maroon, Wine, Red, Coral, Pink, Dusty Pink, Magenta, Purple, Lavender, Mustard, Yellow, Orange, Peach, Gold.

### 2.5 Distribution Rules:
- **Primary Color:** The highest-share color cluster.
- **Secondary Colors:** Clusters with $\ge 12\%$ share (distinct from primary).
- **Accent Colors:** Clusters with $3\% \le share < 12\%$.
- **Pattern:**
  - If Primary $\ge 82\%$ and no secondary $\ge 12\%$ &rarr; `Solid`.
  - If Secondary $\ge 12\%$ or multi-cluster spread &rarr; `Printed / Patterned` or `Floral` (refined by VLM).

---

## 3. Real Photograph Validation (User Kurta)

Running `GarmentColorAnalyzer` on the user's actual photograph `job_036aae3fb6cc.jpg`:

| Cluster | Share | RGB Centroid | CIELAB Centroid | Perceptual Color Match | Role |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **0** | **50.2%** | `[97, 36, 44]` | $L^*=23.8, a^*=28.5, b^*=9.1$ | **Wine** ($\Delta E=7.03$) | **Primary Color** |
| **1** | **33.5%** | `[151, 73, 97]` | $L^*=41.9, a^*=35.2, b^*=1.6$ | **Burgundy / Rose Wine** | **Co-Primary / Base** |
| **2** | **16.3%** | `[206, 132, 162]` | $L^*=63.8, a^*=32.3, b^*=-3.8$ | **Dusty Pink** | **Secondary (Floral Print)** |

- **Aggregated Primary Color:** `Wine` / `Maroon` (83.7% combined deep wine/berry base).
- **Secondary Color:** `Dusty Pink` (16.3% floral design on collar, cuffs, and chest).
- **Pattern:** `Printed / Patterned` / `Floral`.

---

## 4. Multimodal Semantic Attribute Extraction

The studio catalogue image is presented to the visual-language model (`moondream:latest` via Ollama):

```
System Prompt:
"Describe this clothing item in detail, including category (kurta/dress/shirt/trousers), 
sleeve length, collar or neckline, fabric appearance, and pattern."
```

### Multimodal Response on `job_036aae3fb6cc.jpg`:
> *"The image features a long-sleeved, maroon or burgundy-colored dress with a floral pattern. The dress has a collar and buttons down the front, suggesting it might be a shirt dress or a traditional kurta. The sleeves are long, and the cuffs are adorned with small, delicate flowers. The collar also features small floral designs."*

### Synthesized Attributes:
- **Suggested Name:** `Wine Floral Kurta`
- **Main Category:** `Ethnic Wear`
- **Subcategory:** `Kurta`
- **Primary Color:** `Wine`
- **Secondary Colors:** `["Dusty Pink"]`
- **Pattern:** `Floral`
- **Sleeve Length:** `Full Sleeves`
- **Neckline:** `Mandarin Collar`
- **Fit:** `Regular Fit`
- **Fabric Material:** `Cotton appearance`
- **Confidence Scores:**
  - Category: `HIGH`
  - Primary Color: `HIGH`
  - Pattern: `HIGH`
  - Sleeve Length: `HIGH`
  - Fabric Material: `LOW` (Prompted to user for verification)
