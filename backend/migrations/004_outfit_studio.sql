-- Migration 004: Outfit Studio, Recommendations & Wear History
-- Date: 2026-11-22
-- Applies schema for outfits, outfit items, outfit recommendations and wear history.

-- 1. OUTFITS TABLE
CREATE TABLE IF NOT EXISTS public.outfits (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(140) NOT NULL,
    description TEXT,
    occasion VARCHAR(60) NOT NULL DEFAULT 'Casual',
    notes TEXT,
    is_favourite BOOLEAN NOT NULL DEFAULT FALSE,
    creation_source VARCHAR(40) NOT NULL DEFAULT 'MANUAL' CHECK (creation_source IN ('AUTOMATIC', 'GUIDED', 'MANUAL')),
    styling_explanation TEXT,
    wear_count INT NOT NULL DEFAULT 0,
    last_worn_date TIMESTAMPTZ,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outfits_user ON public.outfits(user_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_outfits_occasion ON public.outfits(user_id, occasion);
CREATE INDEX IF NOT EXISTS idx_outfits_favourite ON public.outfits(user_id, is_favourite);

ALTER TABLE public.outfits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own outfits" ON public.outfits
    FOR ALL USING (auth.uid() = user_id);

-- 2. OUTFIT ITEMS JUNCTION TABLE
CREATE TABLE IF NOT EXISTS public.outfit_items (
    id TEXT PRIMARY KEY,
    outfit_id TEXT NOT NULL REFERENCES public.outfits(id) ON DELETE CASCADE,
    garment_id TEXT NOT NULL REFERENCES public.wardrobe_items(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    position INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_outfit_garment UNIQUE (outfit_id, garment_id)
);

CREATE INDEX IF NOT EXISTS idx_outfit_items_outfit ON public.outfit_items(outfit_id);
CREATE INDEX IF NOT EXISTS idx_outfit_items_garment ON public.outfit_items(garment_id);
CREATE INDEX IF NOT EXISTS idx_outfit_items_user ON public.outfit_items(user_id);

ALTER TABLE public.outfit_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own outfit items" ON public.outfit_items
    FOR ALL USING (auth.uid() = user_id);

-- 3. OUTFIT WEAR HISTORY
CREATE TABLE IF NOT EXISTS public.outfit_wear_history (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    outfit_id TEXT REFERENCES public.outfits(id) ON DELETE SET NULL,
    worn_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    idempotency_key VARCHAR(128),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outfit_wear_user ON public.outfit_wear_history(user_id);
CREATE INDEX IF NOT EXISTS idx_outfit_wear_outfit ON public.outfit_wear_history(outfit_id);
CREATE INDEX IF NOT EXISTS idx_outfit_wear_idempotency ON public.outfit_wear_history(user_id, idempotency_key);

ALTER TABLE public.outfit_wear_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own outfit wear history" ON public.outfit_wear_history
    FOR ALL USING (auth.uid() = user_id);

-- 4. OUTFIT RECOMMENDATION SNAPSHOTS
CREATE TABLE IF NOT EXISTS public.outfit_recommendations (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    occasion VARCHAR(60),
    combination_fingerprint TEXT NOT NULL,
    explanation TEXT NOT NULL,
    garment_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    feedback VARCHAR(30) CHECK (feedback IN ('SAVED', 'REJECTED', 'DISLIKED', 'PENDING')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outfit_recs_user ON public.outfit_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_outfit_recs_fingerprint ON public.outfit_recommendations(user_id, combination_fingerprint);

ALTER TABLE public.outfit_recommendations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own outfit recommendations" ON public.outfit_recommendations
    FOR ALL USING (auth.uid() = user_id);

