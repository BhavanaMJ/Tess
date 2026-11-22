-- Migration 003: TESS Wardrobe Intelligence — Laundry Manager & Batch Lifecycle
-- Adds lifecycle tracking fields to wardrobe_items, creates laundry_batches,
-- laundry_batch_items, and wardrobe_laundry_history with strict Row Level Security (RLS).

-- 1. ADD LIFECYCLE FIELDS TO WARDROBE_ITEMS
ALTER TABLE public.wardrobe_items
    ADD COLUMN IF NOT EXISTS wear_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS wash_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_worn_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS last_washed_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS active_batch_id TEXT;

-- 2. LAUNDRY BATCHES TABLE
CREATE TABLE IF NOT EXISTS public.laundry_batches (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    batch_number TEXT NOT NULL,
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'CREATED' CHECK (status IN ('CREATED', 'WASHING', 'DRYING', 'COMPLETED', 'CANCELLED')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_laundry_batches_user_id ON public.laundry_batches(user_id);
CREATE INDEX IF NOT EXISTS idx_laundry_batches_status ON public.laundry_batches(user_id, status);

CREATE TRIGGER update_laundry_batches_modtime
BEFORE UPDATE ON public.laundry_batches
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

ALTER TABLE public.laundry_batches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own laundry batches"
    ON public.laundry_batches FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own laundry batches"
    ON public.laundry_batches FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own laundry batches"
    ON public.laundry_batches FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own laundry batches"
    ON public.laundry_batches FOR DELETE
    USING (auth.uid() = user_id);


-- 3. LAUNDRY BATCH ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.laundry_batch_items (
    id TEXT PRIMARY KEY,
    batch_id TEXT NOT NULL REFERENCES public.laundry_batches(id) ON DELETE CASCADE,
    garment_id TEXT NOT NULL REFERENCES public.wardrobe_items(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    removed_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'REMOVED', 'COMPLETED')),
    UNIQUE(batch_id, garment_id)
);

CREATE INDEX IF NOT EXISTS idx_laundry_batch_items_batch ON public.laundry_batch_items(batch_id);
CREATE INDEX IF NOT EXISTS idx_laundry_batch_items_garment ON public.laundry_batch_items(garment_id);
CREATE INDEX IF NOT EXISTS idx_laundry_batch_items_user ON public.laundry_batch_items(user_id);

ALTER TABLE public.laundry_batch_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own batch items"
    ON public.laundry_batch_items FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own batch items"
    ON public.laundry_batch_items FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own batch items"
    ON public.laundry_batch_items FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own batch items"
    ON public.laundry_batch_items FOR DELETE
    USING (auth.uid() = user_id);


-- 4. WARDROBE LAUNDRY HISTORY TABLE
CREATE TABLE IF NOT EXISTS public.wardrobe_laundry_history (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    garment_id TEXT NOT NULL REFERENCES public.wardrobe_items(id) ON DELETE CASCADE,
    batch_id TEXT REFERENCES public.laundry_batches(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL CHECK (event_type IN (
        'STATUS_CHANGE',
        'WEAR',
        'WASH_CYCLE_STARTED',
        'WASH_CYCLE_COMPLETED',
        'STORED',
        'BATCH_ASSIGNED',
        'BATCH_REMOVED',
        'MANUAL_OVERRIDE'
    )),
    previous_status TEXT,
    new_status TEXT,
    source TEXT DEFAULT 'MANUAL',
    notes TEXT,
    idempotency_key TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_laundry_history_user ON public.wardrobe_laundry_history(user_id);
CREATE INDEX IF NOT EXISTS idx_laundry_history_garment ON public.wardrobe_laundry_history(user_id, garment_id);
CREATE INDEX IF NOT EXISTS idx_laundry_history_batch ON public.wardrobe_laundry_history(batch_id);
CREATE INDEX IF NOT EXISTS idx_laundry_history_idempotency ON public.wardrobe_laundry_history(user_id, idempotency_key);

ALTER TABLE public.wardrobe_laundry_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own laundry history"
    ON public.wardrobe_laundry_history FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own laundry history"
    ON public.wardrobe_laundry_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own laundry history"
    ON public.wardrobe_laundry_history FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own laundry history"
    ON public.wardrobe_laundry_history FOR DELETE
    USING (auth.uid() = user_id);
