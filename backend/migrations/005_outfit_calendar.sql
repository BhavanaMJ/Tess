-- Migration 005: Outfit Calendar, Actual Wear Records & Weather Cache
-- Date: 2026-11-22
-- Implements separation of Planned Outfits vs Actual Outfits, calendar intelligence, and weather caching.

-- 1. OUTFIT PLANS TABLE (Intent / Scheduled Future Wear)
CREATE TABLE IF NOT EXISTS public.outfit_plans (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    outfit_id TEXT NOT NULL REFERENCES public.outfits(id) ON DELETE CASCADE,
    planned_date DATE NOT NULL,
    occasion VARCHAR(60) NOT NULL DEFAULT 'Casual',
    notes TEXT,
    is_worn BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outfit_plans_user_date ON public.outfit_plans(user_id, planned_date);
CREATE INDEX IF NOT EXISTS idx_outfit_plans_outfit ON public.outfit_plans(outfit_id);

ALTER TABLE public.outfit_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own outfit plans" ON public.outfit_plans
    FOR ALL USING (auth.uid() = user_id);

-- 2. OUTFIT CALENDAR WEAR RECORDS (Confirmed Reality / Actual Outfits)
CREATE TABLE IF NOT EXISTS public.outfit_calendar_wear_records (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    outfit_id TEXT NOT NULL REFERENCES public.outfits(id) ON DELETE CASCADE,
    plan_id TEXT REFERENCES public.outfit_plans(id) ON DELETE SET NULL,
    wear_history_id TEXT REFERENCES public.outfit_wear_history(id) ON DELETE SET NULL,
    actual_worn_date DATE NOT NULL,
    worn_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    idempotency_key VARCHAR(128),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calendar_wear_user_date ON public.outfit_calendar_wear_records(user_id, actual_worn_date);
CREATE INDEX IF NOT EXISTS idx_calendar_wear_outfit ON public.outfit_calendar_wear_records(outfit_id);
CREATE INDEX IF NOT EXISTS idx_calendar_wear_plan ON public.outfit_calendar_wear_records(plan_id);
CREATE INDEX IF NOT EXISTS idx_calendar_wear_idempotency ON public.outfit_calendar_wear_records(user_id, idempotency_key);

ALTER TABLE public.outfit_calendar_wear_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own calendar wear records" ON public.outfit_calendar_wear_records
    FOR ALL USING (auth.uid() = user_id);

-- 3. WEATHER CACHE TABLE
CREATE TABLE IF NOT EXISTS public.weather_cache (
    id TEXT PRIMARY KEY,
    location_query TEXT NOT NULL,
    forecast_date DATE NOT NULL,
    temperature_celsius NUMERIC(4, 1) NOT NULL,
    feels_like_celsius NUMERIC(4, 1),
    condition_code TEXT NOT NULL,
    condition_text TEXT NOT NULL,
    rain_probability INT NOT NULL DEFAULT 0,
    wind_kph NUMERIC(5, 1),
    humidity INT,
    styling_suggestion TEXT,
    fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uq_weather_location_date UNIQUE (location_query, forecast_date)
);

CREATE INDEX IF NOT EXISTS idx_weather_lookup ON public.weather_cache(location_query, forecast_date);
