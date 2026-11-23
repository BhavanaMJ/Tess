# Phase 7: Analytics Mathematical Definitions & Algorithmic Specifications
## Wardrobe Insights & Personal Style Intelligence

### 1. Wardrobe Utilisation Formula

**Strict Mathematical Definition:**
$$\text{Utilisation } (\%) = \left( \frac{\text{Unique Active Garments Worn in Period}}{\text{Total Active Garments}} \right) \times 100$$

- **Numerator**: The distinct count of non-archived garments that have at least one wear event logged within the requested temporal boundary ($[T_{\text{start}}, T_{\text{end}}]$).
- **Denominator**: Total active (`is_archived = false`) garments in the wardrobe.
- **Corner Cases**:
  - If $\text{Total Active Garments} == 0$, utilisation is defined as $0.0\%$.
  - Archived garments are excluded from both numerator and denominator.
  - Repeated wears of the same garment within the period increment the total wear counter, but contribute exactly 1 to unique worn garments.

---

### 2. Temporal Window Scopes

The analytics engine supports four strictly bounded time windows:

| Period Key | Dart Enum | Python Parameter | Scope |
| :--- | :--- | :--- | :--- |
| `7d` | `AnalyticsPeriod.days7` | `7d` | Past 7 rolling days from current UTC timestamp |
| `30d` | `AnalyticsPeriod.days30` | `30d` | Past 30 rolling days |
| `90d` | `AnalyticsPeriod.days90` | `90d` | Past 90 rolling days |
| `all` | `AnalyticsPeriod.allTime` | `all` | Unbounded historical wear logs |

---

### 3. Neglected & Unused Garments Classification

A garment is classified as neglected if it is active (`is_archived = false`) and meets either of two criteria:

1. **Never Recorded Wears**:
   $$\text{wear\_count} == 0 \lor \text{last\_worn\_date is NULL}$$
   *Neglect Reason*: `NeglectReason.neverRecorded` ("Never worn since adding to wardrobe").
2. **Dormant Beyond Threshold**:
   $$\text{Days Since Last Worn} \ge 60 \text{ days}$$
   *Neglect Reason*: `NeglectReason.notWornRecently` ("Not worn in over 60 days").

*Storage Status Awareness*: If the garment is clean, it is flagged as immediately wearable ("Clean and stored, ready for rotation"). If in laundry, it is flagged with laundry recovery advice.

---

### 4. Colour Palette Normalisation & Grouping

To avoid fragmenting analytics across hundreds of arbitrary colour shades entered by users or extracted by vision AI, the backend maps specific shade names into 11 canonical chromatic families:

```python
COLOR_FAMILY_MAP = {
    "navy": "Blue", "navy blue": "Blue", "sky blue": "Blue", "indigo": "Blue", "denim": "Blue", "royal blue": "Blue",
    "white": "White", "off-white": "White", "cream": "White", "ivory": "White",
    "black": "Black", "charcoal": "Black", "jet black": "Black",
    "grey": "Grey", "gray": "Grey", "heather grey": "Grey", "slate": "Grey",
    "red": "Red", "burgundy": "Red", "maroon": "Red", "crimson": "Red",
    "green": "Green", "olive": "Green", "sage": "Green", "emerald": "Green", "mint": "Green",
    "yellow": "Yellow", "mustard": "Yellow", "gold": "Yellow",
    "pink": "Pink", "blush": "Pink", "rose": "Pink", "fuchsia": "Pink",
    "brown": "Brown", "tan": "Brown", "khaki": "Brown", "beige": "Brown", "camel": "Brown",
    "purple": "Purple", "lavender": "Purple", "violet": "Purple", "plum": "Purple",
    "orange": "Orange", "coral": "Orange", "peach": "Orange", "rust": "Orange",
}
```

Garment count and percentage within each family are computed:
$$\text{Family Share } (\%) = \left( \frac{\text{Garments in Family}}{\text{Total Active Garments}} \right) \times 100$$

---

### 5. Capsule Wardrobe Versatility Score

The capsule versatility score evaluates the combinational density of a user's active wardrobe:

$$\text{Versatility Score } (g) = \min\left(100.0, \, \frac{\text{Compatible Pairings Count}(g)}{\max(1, \text{Target Pairings})} \times 100\right)$$

- **Anchor Garments**: Garments possessing versatility score $\ge 70.0\%$ and high pairing flexibility across complementary categories (e.g. Neutral Tops pairing with multiple Bottoms).
- **Capsule Ready Garments**: Garments that can seamlessly combine with 3 or more distinct complementary categories.
- **Potential Combinations**: Cartesians and verified historical pairings across active tops, bottoms, outerwear, and footwear.

---

### 6. Outfit Repetition & Interval Telemetry

Outfit repetition is computed across all confirmed wear history records:

$$\text{Wear Count}(\text{outfit}) = \sum \mathbf{1}_{\text{wear\_event}}$$
$$\text{Average Interval (Days)} = \frac{T_{\text{last}} - T_{\text{first}}}{\text{Wear Count} - 1}$$

If worn only once, interval is reported as $0.0$.
Identifies high-frequency signature uniforms versus rarely repeated novelty combinations.
