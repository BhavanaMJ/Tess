# TESS Clothes Organizer — Phase 6: Known Limitations & Phase 7 Transition

## 1. Known Technical Limitations

1. **Weather Forecast Horizon**:
   - In accordance with standard meteorology services (Open-Meteo), accurate daily forecasts are available up to 14 days in advance. Planning beyond this range appropriately displays: *"Weather forecast is not available for this date."*
2. **Geo-Location Permissions**:
   - Location defaults to `"Current Location"` with fallback coordinates. Native GPS permission prompting on iOS and Android can be refined in future device hardware integration phases.
3. **Combination Fingerprint Matching**:
   - Repetition detection matches on exact `outfit_id` and constituent item overlap across a 14-day lookback window. Partial garment substitution heuristics will be expanded with the Phase 7 Analytics Engine.

---

## 2. Phase 7 Roadmap Hand-off
The next phase is **Phase 7: Wardrobe Insights & Cost-Per-Wear Analytics**:
- Analytics computation engine utilizing confirmed wear counts from Phase 6.
- Cost-per-wear breakdown per garment.
- Category distribution and balance metrics.
- Wardrobe utilization index (active vs inactive percentage).
- Unworn garment reminders and style rotation recommendations.

