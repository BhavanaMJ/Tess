-- Migration 001: TESS Wardrobe Intelligence Schema
-- Creates wardrobe_categories and wardrobe_items tables with strict Row Level Security (RLS)

-- 1. WARDROBE CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS public.wardrobe_categories (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon_name TEXT,
    parent_category_id TEXT REFERENCES public.wardrobe_categories(id),
    subcategories TEXT[] DEFAULT '{}',
    order_index INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for wardrobe_categories
ALTER TABLE public.wardrobe_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read categories"
    ON public.wardrobe_categories FOR SELECT
    USING (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY "Users can insert own categories"
    ON public.wardrobe_categories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories"
    ON public.wardrobe_categories FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own categories"
    ON public.wardrobe_categories FOR DELETE
    USING (auth.uid() = user_id);


-- 2. WARDROBE ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.wardrobe_items (
    id TEXT PRIMARY KEY, -- e.g. 'CLO-001' or UUID
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    main_category TEXT NOT NULL,
    subcategory TEXT,
    original_image_ref TEXT,
    processed_image_ref TEXT,
    thumbnail_ref TEXT,
    primary_color TEXT NOT NULL DEFAULT 'Unknown',
    secondary_colors TEXT[] DEFAULT '{}',
    pattern TEXT,
    fabric_material TEXT,
    neckline TEXT,
    sleeve_length TEXT,
    fit TEXT,
    silhouette TEXT,
    garment_length TEXT,
    size TEXT,
    brand TEXT,
    purchase_date DATE,
    purchase_price NUMERIC(10, 2),
    occasions TEXT[] DEFAULT '{}',
    seasons TEXT[] DEFAULT '{}',
    laundry_status TEXT CHECK (laundry_status IN ('CLEAN', 'WORN', 'WASHING', 'DRYING', 'STORED') OR laundry_status IS NULL),
    is_favorite BOOLEAN DEFAULT FALSE,
    notes TEXT,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for high-performance user queries & filters
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_user_id ON public.wardrobe_items(user_id);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_category ON public.wardrobe_items(user_id, main_category);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_laundry ON public.wardrobe_items(user_id, laundry_status);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_archived ON public.wardrobe_items(user_id, is_archived);

-- Trigger for updated_at on wardrobe_items
CREATE TRIGGER update_wardrobe_items_modtime
BEFORE UPDATE ON public.wardrobe_items
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- RLS for wardrobe_items
ALTER TABLE public.wardrobe_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wardrobe items"
    ON public.wardrobe_items FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wardrobe items"
    ON public.wardrobe_items FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wardrobe items"
    ON public.wardrobe_items FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own wardrobe items"
    ON public.wardrobe_items FOR DELETE
    USING (auth.uid() = user_id);
