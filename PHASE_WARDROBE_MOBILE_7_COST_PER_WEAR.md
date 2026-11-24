# Phase 7: Cost-Per-Wear (CPW) Mathematical & Financial Specifications

### 1. Cost-Per-Wear Core Formulation

Cost-Per-Wear is calculated dynamically using real purchase price and accumulated wear frequency:

$$\text{CPW}(g) = \frac{\text{purchase\_price}(g)}{\text{wear\_count}(g)}$$

#### Fundamental Constraints:
1. **Missing Purchase Price**:
   If $\text{purchase\_price}$ is `null`, then $\text{CPW}$ is `null`. It is **never** defaulted to $0.00$ to prevent falsifying cost efficiency.
2. **Unrecorded Wears / Unrealised Value**:
   If $\text{purchase\_price} > 0$ and $\text{wear\_count} == 0$, $\text{CPW}$ is `null`. The garment's financial status is categorized as `unrecordedWears`.
3. **Currency Preservation**:
   All financial aggregations preserve currency integrity (default `INR` ₹).

---

### 2. Value Tier Categorization

Every garment is evaluated against dynamic thresholds:

| Value Tier Enum | Criteria | UI Visual Badge | Semantic Meaning |
| :--- | :--- | :--- | :--- |
| `exceptionalValue` | $\text{CPW} \le 200$ | Emerald Glow (`#10B981`) | Exceptional return on wardrobe investment |
| `goodValue` | $200 < \text{CPW} \le 500$ | Soft Violet (`#8B5CF6`) | Healthy usage relative to acquisition cost |
| `fairValue` | $500 < \text{CPW} \le 1200$ | Electric Cyan (`#22D3EE`) | Moderate usage; continue wearing to improve CPW |
| `lowValue` | $\text{CPW} > 1200$ | Muted Amber (`#F59E0B`) | High acquisition cost relative to wears; needs rotation |
| `unrecordedWears` | $\text{price} > 0 \land \text{wears} == 0$ | Warning Rose (`#F43F5E`) | Capital invested without any logged wears |
| `missingPrice` | $\text{purchase\_price}$ is null | Text Muted (`#64748B`) | Price unrecorded; excluded from investment totals |

---

### 3. Investment Aggregations

- **Total Wardrobe Investment**:
  $$\text{Total Investment} = \sum_{g \in \text{Priced Garments}} \text{purchase\_price}(g)$$
- **Garments With Price vs Without Price**:
  Tracked explicitly to show the user coverage percentage of their financial wardrobe data.
- **Average Cost-Per-Wear**:
  $$\text{Average CPW} = \frac{\sum_{g \in \text{Worn Priced Garments}} \text{purchase\_price}(g)}{\sum_{g \in \text{Worn Priced Garments}} \text{wear\_count}(g)}$$
  Or computed as the mean of valid CPWs across active garments.
- **Top & Lowest Performers**:
  - `best_value_garments`: Top 5 garments sorted by lowest CPW ascending.
  - `highest_cost_per_wear_garments`: Top 5 garments sorted by highest CPW descending.

