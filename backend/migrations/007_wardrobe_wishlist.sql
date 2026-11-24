-- Migration 007: Wardrobe Wishlist, Shopping Intelligence & Wardrobe Gap Analysis
-- Creates wishlist_items table with purchase priority, status tracking, and wardrobe conversion linkage.

CREATE TABLE IF NOT EXISTS public.wishlist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(50),
    reference_image_path TEXT,
    expected_price NUMERIC(10, 2),
    expected_currency VARCHAR(10) DEFAULT 'INR',
    purchase_priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' CHECK (purchase_priority IN ('HIGH', 'MEDIUM', 'LOW')),
    occasion VARCHAR(50),
    desired_colour VARCHAR(50),
    desired_pattern VARCHAR(50),
    description TEXT,
    notes TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'CONSIDERING' CHECK (status IN ('CONSIDERING', 'SHORTLISTED', 'PURCHASED', 'NOT_INTERESTED')),
    purchased_at TIMESTAMPTZ,
    actual_purchase_price NUMERIC(10, 2),
    actual_purchase_currency VARCHAR(10) DEFAULT 'INR',
    converted_garment_id VARCHAR(50) REFERENCES public.wardrobe_items(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Row-Level Security
ALTER TABLE public.wishlist_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wishlist items"
    ON public.wishlist_items FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wishlist items"
    ON public.wishlist_items FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wishlist items"
    ON public.wishlist_items FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own wishlist items"
    ON public.wishlist_items FOR DELETE
    USING (auth.uid() = user_id);

-- Indexes for fast filtering and joins
CREATE INDEX IF NOT EXISTS idx_wishlist_items_user_status
    ON public.wishlist_items(user_id, status);

CREATE INDEX IF NOT EXISTS idx_wishlist_items_user_priority
    ON public.wishlist_items(user_id, purchase_priority);

CREATE INDEX IF NOT EXISTS idx_wishlist_items_converted_garment
    ON public.wishlist_items(converted_garment_id);

CREATE INDEX IF NOT EXISTS idx_wishlist_items_created
    ON public.wishlist_items(user_id, created_at DESC);

