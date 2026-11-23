-- Migration 006: Wardrobe Insights, Usage Analytics & Personal Style Intelligence
-- Date: 2026-11-22
-- Extends wardrobe items with currency support, introduces style preferences/memory, and adds analytics indexes.

-- 1. ADD PURCHASE CURRENCY TO WARDROBE ITEMS
ALTER TABLE public.wardrobe_items ADD COLUMN IF NOT EXISTS purchase_currency VARCHAR(10) DEFAULT 'INR';

-- 2. CREATE WARDROBE STYLE PREFERENCES TABLE (Personal Style Memory)
CREATE TABLE IF NOT EXISTS public.wardrobe_style_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    preferred_colors TEXT[] DEFAULT '{}',
    preferred_categories TEXT[] DEFAULT '{}',
    preferred_occasions TEXT[] DEFAULT '{}',
    avoided_combinations JSONB DEFAULT '[]'::jsonb,
    style_persona VARCHAR(80) DEFAULT 'Casual Classic',
    favorite_pairing_rules JSONB DEFAULT '[]'::jsonb,
    notes TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for wardrobe_style_preferences
ALTER TABLE public.wardrobe_style_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own style preferences" ON public.wardrobe_style_preferences
    FOR ALL USING (auth.uid() = user_id);

-- 3. ANALYTICS & QUERY ACCELERATION INDEXES
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_price ON public.wardrobe_items(user_id, purchase_price);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_color ON public.wardrobe_items(user_id, primary_color);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_wear_count ON public.wardrobe_items(user_id, wear_count);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_last_worn ON public.wardrobe_items(user_id, last_worn_date);
CREATE INDEX IF NOT EXISTS idx_calendar_wear_actual_date ON public.outfit_calendar_wear_records(user_id, actual_worn_date);
