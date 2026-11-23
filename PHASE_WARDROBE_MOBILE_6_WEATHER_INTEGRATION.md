# TESS Clothes Organizer — Phase 6: Weather Integration Architecture

## 1. Overview
The TESS Weather Context engine provides real-time and forecast weather telemetry to inform outfit planning and styling advice.

## 2. API Selection & Security
- **Provider**: Open-Meteo (`https://api.open-meteo.com/v1/forecast`).
- **No Credentials Exposed**: All weather queries are handled server-side through `WeatherService`. The mobile client interacts exclusively with `GET /api/v1/wardrobe/weather/{date}`.
- **Forecast Horizon**: Supports up to 14 days of forecast data. Dates beyond 14 days or earlier than 7 days in the past return `is_forecast_available: false` with the standard message: `"Weather forecast is not available for this date."`

---

## 3. Caching Strategy
1. **L1 In-Memory Cache**: `_SESSION_WEATHER_CACHE` keyed by `location:date`.
2. **L2 Database Cache**: Supabase `weather_cache` table prevents redundant upstream network calls.
3. **Deterministic Simulation Fallback**: During automated testing (`PYTEST_CURRENT_TEST` or offline), deterministic calculations based on the day of the year generate consistent test conditions without incurring network latency.

---

## 4. Rule-Based Styling Engine
The styling suggestion generator synthesizes temperature, precipitation probability, wind speed, and weather condition codes:

| Condition / Metric | Rule Trigger | Generated Recommendation |
|---|---|---|
| Temperature | `< 10°C` | Cold temperatures. Heavy coat, knitwear, and thermal layers recommended. |
| Temperature | `10°C - 17.9°C` | Mild/Cool weather. Light jacket, layered cardigan, or sweater recommended. |
| Temperature | `18°C - 24.9°C` | Pleasant conditions. Breathable cotton, tees, or casual shirts recommended. |
| Temperature | `>= 25°C` | Warm weather. Lightweight linen, breathable shorts or dresses recommended. |
| Rain Probability | `>= 40%` or code contains `RAIN` | Rain expected—carry an umbrella or water-resistant outerwear. |
| Wind Speed | `> 30 km/h` | Breezy conditions—consider a wind-resistant shell layer. |

