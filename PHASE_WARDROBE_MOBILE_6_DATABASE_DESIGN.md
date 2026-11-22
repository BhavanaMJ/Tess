# TESS Clothes Organizer — Phase 6: Database Design

## 1. Migration Overview
Migration file: `backend/migrations/005_outfit_calendar.sql`
Appended to master schema: `backend/schema.sql`

---

## 2. Table Specifications

### 2.1 `outfit_plans`
Stores planned outfits for future or target dates.
```sql
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
```

### 2.2 `outfit_calendar_wear_records`
Stores confirmed actual wear events tied to calendar dates.
```sql
CREATE TABLE IF NOT EXISTS public.outfit_calendar_wear_records (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    outfit_id TEXT NOT NULL REFERENCES public.outfits(id) ON DELETE CASCADE,
    plan_id TEXT REFERENCES public.outfit_plans(id) ON DELETE SET NULL,
    actual_worn_date DATE NOT NULL,
    worn_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    idempotency_key TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 2.3 `weather_cache`
Proxies and caches remote weather forecasts by location and date to minimize external API calls.
```sql
CREATE TABLE IF NOT EXISTS public.weather_cache (
    id TEXT PRIMARY KEY,
    location VARCHAR(120) NOT NULL,
    date DATE NOT NULL,
    temperature_c NUMERIC(4, 1) NOT NULL,
    feels_like_c NUMERIC(4, 1),
    condition_code VARCHAR(40) NOT NULL,
    condition_text VARCHAR(80) NOT NULL,
    rain_probability INT DEFAULT 0,
    wind_kph NUMERIC(5, 1),
    humidity INT,
    styling_suggestion TEXT,
    cached_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 3. Indexes & Constraints
```sql
CREATE INDEX IF NOT EXISTS idx_outfit_plans_user_date ON public.outfit_plans(user_id, planned_date);
CREATE INDEX IF NOT EXISTS idx_calendar_wear_user_date ON public.outfit_calendar_wear_records(user_id, actual_worn_date);
CREATE INDEX IF NOT EXISTS idx_weather_cache_loc_date ON public.weather_cache(location, date);
CREATE UNIQUE INDEX IF NOT EXISTS idx_calendar_wear_idempotency ON public.outfit_calendar_wear_records(user_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
```

---

## 4. Row Level Security (RLS)
RLS is enabled on `outfit_plans` and `outfit_calendar_wear_records`:
```sql
ALTER TABLE public.outfit_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own plans"
ON public.outfit_plans FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

ALTER TABLE public.outfit_calendar_wear_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own calendar wear records"
ON public.outfit_calendar_wear_records FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
```
