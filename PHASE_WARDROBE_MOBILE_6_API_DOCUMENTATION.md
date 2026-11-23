# TESS Clothes Organizer — Phase 6: API Documentation

## 1. Base URLs and Authentication
All endpoints require JWT Bearer authorization header: `Authorization: Bearer <token>`. Multi-tenant isolation is enforced at the service and database RLS layer.

---

## 2. Calendar Endpoints

### 2.1 Outfit Plans

#### `POST /api/v1/wardrobe/calendar/plans`
Creates an outfit plan for a specific calendar date.
- **Request Body**:
  ```json
  {
    "outfit_id": "string",
    "planned_date": "2026-11-25",
    "occasion": "Work",
    "notes": "Optional styling notes"
  }
  ```
- **Response**: `201 Created` with `OutfitPlanResponse`.
- **Invariant**: Garments remain in their current laundry status; wear counts are not incremented.

#### `GET /api/v1/wardrobe/calendar/plans/upcoming`
Retrieves upcoming outfit plans.
- **Query Params**: `limit` (default: 10).
- **Response**: `200 OK` with `List[OutfitPlanResponse]`.

#### `GET /api/v1/wardrobe/calendar/plans/{plan_id}`
Retrieves a single outfit plan.
- **Response**: `200 OK` or `404 Not Found`.

#### `PUT /api/v1/wardrobe/calendar/plans/{plan_id}`
Updates plan details (date, occasion, notes).
- **Request Body**:
  ```json
  {
    "planned_date": "2026-11-26",
    "occasion": "Formal",
    "notes": "Updated notes"
  }
  ```
- **Response**: `200 OK` with `OutfitPlanResponse`.

#### `DELETE /api/v1/wardrobe/calendar/plans/{plan_id}`
Removes a planned outfit.
- **Response**: `200 OK` with status success.

---

### 2.2 Actual Wear Confirmation

#### `POST /api/v1/wardrobe/calendar/wear`
Confirms actual physical wear of an outfit.
- **Request Body**:
  ```json
  {
    "outfit_id": "string",
    "actual_worn_date": "2026-11-22",
    "plan_id": "optional_plan_id",
    "idempotency_key": "optional_uuid",
    "notes": "Presentation morning"
  }
  ```
- **Response**: `201 Created` with `ActualWearResponse`.
- **Side Effects**:
  - Updates linked `OutfitPlan.is_worn = True`.
  - Calls `OutfitService.wear_outfit`, which calls `LaundryService.update_garment_laundry_status` with `source="OUTFIT_WEAR"`.
  - Garments transition to `WORN`.
  - Garment `wear_count` incremented by 1.
  - Outfit `wear_count` incremented by 1.
  - Inserts record into `outfit_calendar_wear_records` and `outfit_wear_history`.

#### `GET /api/v1/wardrobe/calendar/history`
Retrieves chronological wear history.
- **Query Params**: `limit` (default: 50).
- **Response**: `200 OK` with `List[ActualWearResponse]`.

---

### 2.3 Calendar Views

#### `GET /api/v1/wardrobe/calendar/day/{date_str}`
Returns day details for date `YYYY-MM-DD`.
- **Response**:
  ```json
  {
    "date": "2026-11-22",
    "plans": [...],
    "actual_wears": [...],
    "has_plan": true,
    "has_actual_wear": false,
    "weather": { ... }
  }
  ```

#### `GET /api/v1/wardrobe/calendar/week`
Returns 7 days starting from `start_date=YYYY-MM-DD`.
- **Response**: `200 OK` with `CalendarWeekResponse`.

#### `GET /api/v1/wardrobe/calendar/month`
Returns all days in given month `year=2026&month=11`.
- **Response**: `200 OK` with `CalendarMonthResponse`.

---

### 2.4 Calendar Intelligence

#### `GET /api/v1/wardrobe/calendar/intelligence/repetition`
Checks if an outfit was planned or worn within `window_days` (default: 14).
- **Query Params**: `outfit_id`, `date`, `window_days`.
- **Response**:
  ```json
  {
    "is_repeated": true,
    "last_worn_date": "2026-11-20",
    "last_planned_or_worn_date": "2026-11-20",
    "days_since": 2,
    "repetition_count": 1,
    "message": "You wore this outfit on 2026-11-20. Consider styling with an alternative piece to keep your look fresh."
  }
  ```

#### `GET /api/v1/wardrobe/calendar/intelligence/recently-worn`
Returns recently worn individual garments.

#### `GET /api/v1/wardrobe/calendar/intelligence/unused`
Returns garments unworn or inactive for over `days_threshold` (default: 30 days).

---

### 2.5 Weather Endpoint

#### `GET /api/v1/wardrobe/weather/{date_str}`
Retrieves cached or Open-Meteo weather summary with styling suggestions.
- **Query Params**: `location`, `lat`, `lon`.
- **Response**:
  ```json
  {
    "location": "Current Location",
    "date": "2026-11-22",
    "temperature_c": 18.5,
    "feels_like_c": 17.5,
    "condition_code": "PARTLY_CLOUDY",
    "condition_text": "Partly cloudy",
    "rain_probability": 15,
    "styling_suggestion": "Mild conditions. Light jacket recommended.",
    "is_forecast_available": true
  }
  ```

