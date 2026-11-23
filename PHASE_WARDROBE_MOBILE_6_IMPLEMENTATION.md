# TESS Clothes Organizer — Phase 6: Outfit Calendar & Wear History Implementation

## 1. Executive Summary

Phase 6 introduces **Outfit Calendar, Wear History & Weather-Aware Planning** to the TESS mobile application and FastAPI backend. Building upon Phase 4 (Laundry Manager) and Phase 5 (Outfit Studio), this feature resolves the fundamental distinction between **planning** an outfit (scheduling intent) and **confirming** wear (updating physical garment status and wear telemetry).

### Key Architectural Tenets Implemented:
1. **Strict Separation of Intent vs Reality**:
   - Creating or updating an outfit plan never mutates garment laundry status, increment wear counts, or creates wear history entries.
   - Confirming actual wear transitions constituent garments to `WORN` via `LaundryService` (with source `OUTFIT_WEAR`), increments garment wear counts, increments outfit wear counts, and records wear history.
2. **Workflows A & B Supported**:
   - **Workflow A**: Confirms wearing a previously planned look. Marks the plan `is_worn=True` and updates garment lifecycle.
   - **Workflow B**: Spontaneous or alternate wear. Allows logging a different look than planned, or recording wear without prior planning.
3. **Three Interactive Calendar Views**:
   - **Daily View**: Comprehensive single-day view featuring full weather context, planned look, and confirmed wears.
   - **Weekly View**: 7-day strip summarizing weather forecast and planned/worn looks.
   - **Monthly View**: 7-column grid with custom day cells indicating plan indicators, wear confirmations, and today highlights.
4. **Calendar Intelligence & Repeated Outfit Warnings**:
   - Dynamically warns the user if an outfit was planned or worn within a 14-day window without blocking their decision.
   - Tracks recently worn garments and detects unused garments (unworn > 30 days).
5. **Weather-Aware Planning & Styling Recommendations**:
   - Integrated Open-Meteo public forecast with database caching.
   - Temperature, rain probability, wind, feels-like, and rule-based styling advice.
   - Graceful 14-day forecast horizon cutoff with clear messaging.

---

## 2. Directory Structure & Key Files

```text
backend/
├── app/
│   ├── api/
│   │   └── wardrobe_calendar.py         # REST endpoints for plans, wear, intelligence, weather
│   ├── schemas/
│   │   └── calendar.py                  # Pydantic models for calendar, plans, wear, weather
│   └── services/
│       └── wardrobe/
│           ├── calendar_service.py      # Core business logic for calendar, plans, & wear
│           └── weather_service.py       # Weather integration, caching, & styling generation
├── migrations/
│   └── 005_outfit_calendar.sql          # DB migration for plans, wear records, weather cache
├── schema.sql                           # Master schema with Migration 005 appended
└── tests/
    └── test_wardrobe_calendar.py        # 8 comprehensive pytest tests

flutter_app/
├── lib/features/wardrobe/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── actual_wear_record.dart
│   │   │   ├── calendar_intelligence.dart
│   │   │   ├── outfit_calendar_entry.dart
│   │   │   ├── outfit_plan.dart
│   │   │   └── weather_context.dart
│   │   └── repositories/
│   │       └── calendar_repository.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── actual_wear_model.dart
│   │   │   ├── outfit_calendar_model.dart
│   │   │   ├── outfit_plan_model.dart
│   │   │   └── weather_model.dart
│   │   ├── services/
│   │   │   └── calendar_api_service.dart
│   │   └── repositories/
│   │       └── calendar_repository_impl.dart
│   └── presentation/
│       ├── controllers/
│       │   └── calendar_controller.dart
│       ├── screens/
│       │   ├── actual_wear_screen.dart
│       │   ├── calendar_day_screen.dart
│       │   ├── outfit_calendar_screen.dart
│       │   ├── outfit_history_screen.dart
│       │   └── outfit_plan_screen.dart
│       └── widgets/
│           ├── actual_outfit_card.dart
│           ├── calendar_day_cell.dart
│           ├── planned_outfit_card.dart
│           ├── repeated_outfit_warning.dart
│           └── weather_context_card.dart
└── test/
    └── wardrobe_phase6_test.dart        # 8 comprehensive Flutter tests
```

