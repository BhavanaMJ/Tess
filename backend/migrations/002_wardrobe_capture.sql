-- Migration 002: Wardrobe Smart Capture Jobs & Garment Candidates
-- Phase 3 of TESS Wardrobe Intelligence

CREATE TABLE IF NOT EXISTS wardrobe_capture_jobs (
    id VARCHAR(64) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    original_image_ref TEXT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    current_stage VARCHAR(64) NOT NULL DEFAULT 'Validating photograph',
    progress_percent INTEGER NOT NULL DEFAULT 0,
    total_detected INTEGER NOT NULL DEFAULT 0,
    provider_type VARCHAR(64) NOT NULL DEFAULT 'DEVELOPMENT_LOCAL',
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wardrobe_garment_candidates (
    id VARCHAR(64) PRIMARY KEY,
    job_id VARCHAR(64) NOT NULL REFERENCES wardrobe_capture_jobs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    suggested_name VARCHAR(128) NOT NULL,
    main_category VARCHAR(64) NOT NULL,
    subcategory VARCHAR(64),
    primary_color VARCHAR(64) NOT NULL,
    secondary_colors TEXT[] DEFAULT '{}',
    pattern VARCHAR(64),
    fabric_material VARCHAR(64),
    sleeve_length VARCHAR(64),
    neckline VARCHAR(64),
    fit VARCHAR(64),
    silhouette VARCHAR(64),
    garment_length VARCHAR(64),
    size VARCHAR(32),
    brand VARCHAR(64),
    confidence_scores JSONB DEFAULT '{}'::jsonb,
    bounding_box JSONB DEFAULT '{}'::jsonb,
    processed_image_ref TEXT,
    original_crop_ref TEXT,
    is_included BOOLEAN NOT NULL DEFAULT true,
    is_approved BOOLEAN NOT NULL DEFAULT false,
    registered_garment_id VARCHAR(64),
    uncertainty_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_capture_jobs_user ON wardrobe_capture_jobs (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_capture_jobs_status ON wardrobe_capture_jobs (status);
CREATE INDEX IF NOT EXISTS idx_garment_candidates_job ON wardrobe_garment_candidates (job_id);
CREATE INDEX IF NOT EXISTS idx_garment_candidates_user ON wardrobe_garment_candidates (user_id);

-- Updated_at triggers
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_wardrobe_capture_jobs') THEN
        CREATE TRIGGER set_timestamp_wardrobe_capture_jobs
            BEFORE UPDATE ON wardrobe_capture_jobs
            FOR EACH ROW
            EXECUTE FUNCTION trigger_set_timestamp();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_wardrobe_garment_candidates') THEN
        CREATE TRIGGER set_timestamp_wardrobe_garment_candidates
            BEFORE UPDATE ON wardrobe_garment_candidates
            FOR EACH ROW
            EXECUTE FUNCTION trigger_set_timestamp();
    END IF;
END $$;

-- Enable Row-Level Security
ALTER TABLE wardrobe_capture_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE wardrobe_garment_candidates ENABLE ROW LEVEL SECURITY;

-- RLS Policies: strict user isolation
DROP POLICY IF EXISTS "Users can only access their own capture jobs" ON wardrobe_capture_jobs;
CREATE POLICY "Users can only access their own capture jobs"
    ON wardrobe_capture_jobs
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can only access their own garment candidates" ON wardrobe_garment_candidates;
CREATE POLICY "Users can only access their own garment candidates"
    ON wardrobe_garment_candidates
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

