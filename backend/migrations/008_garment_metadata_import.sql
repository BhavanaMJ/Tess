-- Migration 008: AI Garment Catalogue & Metadata Generator Schema Extension
-- Adds extensible JSONB storage and metadata provenance for Phase 3.4 ChatGPT import workflow.

ALTER TABLE public.wardrobe_items
    ADD COLUMN IF NOT EXISTS metadata_payload JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS metadata_version VARCHAR(16) DEFAULT '1.1',
    ADD COLUMN IF NOT EXISTS import_provenance VARCHAR(64) DEFAULT 'CHATGPT_IMPORT';

-- GIN index for high-performance JSONB querying and attribute indexing
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_metadata_payload
    ON public.wardrobe_items USING GIN (metadata_payload);

