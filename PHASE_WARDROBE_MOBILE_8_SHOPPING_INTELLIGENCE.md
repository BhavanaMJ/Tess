# Phase 8: Shopping Intelligence & Wardrobe Gap Analysis
## Algorithmic Specifications & Philosophy

### 1. Product Philosophy

> *"Before buying something new, understand whether your existing wardrobe already meets that need."*

Traditional fashion applications push generic affiliate links and seasonal marketing trends to encourage consumption. TESS adopts the inverse philosophy:
- **Intention Over Impulse**: Every purchase is assessed through the lens of actual utility.
- **Empirical Wardrobe Data**: Decisions are rooted in real inventory counts, existing laundry states, and historical wear frequencies.
- **Explainable Assessments**: No black-box scores; every recommendation displays concrete supporting factors and owned pieces.

---

### 2. Wardrobe Gap Analysis Formulation

A wardrobe gap is defined as a structural deficiency that prevents existing clothes from being worn effectively.

#### Detection Criteria:
1. **Upper-to-Lower Ratio Imbalance**:
   $$\text{Upper Count} = \text{Count}(\text{Tops}) + \text{Count}(\text{Ethnic wear})$$
   If $\text{Upper Count} \ge 4$ and $\text{Count}(\text{Bottoms}) \le 2$:
   - Severity: `HIGH`
   - Combinations Gained: $\text{Upper Count} \times 2$
   - Explanation: Kurtas and tops remain underutilized because they lack neutral pairing anchors.
2. **Missing Classic Neutral Anchors**:
   If user owns no black, navy, or beige bottoms:
   - Severity: `MEDIUM`
   - Combinations Gained: $\text{Count}(\text{Non-neutral Tops})$
3. **Layering Piece Void**:
   If $\text{Upper Count} \ge 6$ and $\text{Count}(\text{Outerwear}) == 0$:
   - Severity: `MEDIUM`
   - Suggestion: Light neutral cardigan or unstructured blazer.
4. **Footwear Anchors**:
   If total garments $\ge 8$ and $\text{Count}(\text{Footwear}) \le 1$:
   - Severity: `LOW`
   - Suggestion: Clean minimalist sneaker or versatile loafer.

---

### 3. Purchase Decision Assessment Scoring Formula

Each prospective purchase is scored dynamically from $10$ to $98$:

$$\text{Score} = \text{Base}(50) + \Delta_{\text{Gap}} + \Delta_{\text{Color}} + \Delta_{\text{Versatility}} + \Delta_{\text{Priority}} - \Delta_{\text{Duplicate}}$$

| Factor | Condition | Impact |
| :--- | :--- | :--- |
| **Duplicate Function** | User already owns exact category + color | $-35$ |
| **Category Saturation**| User already owns $\ge 3$ similar pieces | $-20$ |
| **Category Gap** | Fills an identified wardrobe gap | $+25$ |
| **Color Diversity** | Introduces an unrepresented palette family | $+15$ |
| **High Versatility** | Compatible with $\ge 5$ existing garments | $+20$ |
| **Moderate Versatility** | Compatible with $2-4$ existing garments | $+10$ |
| **Isolated Piece** | Compatible with $0$ existing garments | $-15$ |
| **High Priority** | User marked item as `HIGH` priority | $+10$ |
| **Low Priority** | User marked item as `LOW` priority | $-5$ |

#### Outcome Classification:
- $\text{Score} \ge 70.0$: `STRONG_ADDITION` ("Strong Wardrobe Addition")
- $40.0 \le \text{Score} < 70.0$: `POTENTIALLY_USEFUL` ("Potentially Useful Addition")
- $\text{Score} < 40.0$ or Exact Duplicate: `CONSIDER_ALTERNATIVES` ("Consider Existing Wardrobe Alternatives")
- Missing Essential Attributes: `INSUFFICIENT_INFO` ("Insufficient Information to Assess")

