-- TESS Phase 1: Database Schema

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- PROFILES TABLE
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT NOT NULL,
    display_name TEXT,
    proactive_enabled BOOLEAN DEFAULT TRUE,
    minimum_intervention_priority TEXT DEFAULT 'MEDIUM',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger for updated_at on profiles
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_modtime
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();


-- CONVERSATIONS TABLE
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_conversations_modtime
BEFORE UPDATE ON conversations
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();


-- MESSAGES TABLE
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- MEMORIES TABLE
CREATE TABLE memories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    content TEXT NOT NULL,
    importance INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_memories_modtime
BEFORE UPDATE ON memories
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();


-- DEVICE TOKENS TABLE
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    platform TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_device_tokens_modtime
BEFORE UPDATE ON device_tokens
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- RLS POLICIES
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own conversations" ON conversations FOR ALL USING (auth.uid() = user_id);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own messages" ON messages FOR ALL USING (
    conversation_id IN (SELECT id FROM conversations WHERE user_id = auth.uid())
);

ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own memories" ON memories FOR ALL USING (auth.uid() = user_id);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own tokens" ON device_tokens FOR ALL USING (auth.uid() = user_id);

-- PHASE 2: PRODUCTIVITY INTELLIGENCE

-- PRODUCTIVITY CONNECTIONS
CREATE TABLE productivity_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    base_url TEXT NOT NULL,
    credential_reference TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, provider)
);

CREATE TRIGGER update_prod_connections_modtime
BEFORE UPDATE ON productivity_connections
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- PRODUCTIVITY TASKS
CREATE TABLE productivity_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    source TEXT NOT NULL,
    external_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT,
    priority TEXT,
    assignee TEXT,
    project TEXT,
    start_date TIMESTAMPTZ,
    due_date TIMESTAMPTZ,
    completion_percent INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, source, external_id)
);

CREATE TRIGGER update_prod_tasks_modtime
BEFORE UPDATE ON productivity_tasks
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- PRODUCTIVITY EVENTS
CREATE TABLE productivity_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    source TEXT NOT NULL,
    event_type TEXT NOT NULL,
    external_id TEXT,
    payload JSONB,
    occurred_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS POLICIES FOR PHASE 2
ALTER TABLE productivity_connections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own connections" ON productivity_connections FOR ALL USING (auth.uid() = user_id);

ALTER TABLE productivity_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own tasks" ON productivity_tasks FOR ALL USING (auth.uid() = user_id);

ALTER TABLE productivity_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own events" ON productivity_events FOR ALL USING (auth.uid() = user_id);

-- PHASE 3: FUTURE ENGINE

-- FUTURE PREDICTIONS
CREATE TABLE future_predictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    prediction_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    probability NUMERIC,
    confidence TEXT,
    time_horizon TEXT,
    evidence JSONB,
    reasoning TEXT,
    source_context JSONB,
    status TEXT DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- FUTURE EVENTS
CREATE TABLE future_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    prediction_id UUID REFERENCES future_predictions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS POLICIES FOR PHASE 3
ALTER TABLE future_predictions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own predictions" ON future_predictions FOR ALL USING (auth.uid() = user_id);

ALTER TABLE future_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own future events" ON future_events FOR ALL USING (auth.uid() = user_id);

-- PHASE 4: MEET TOMORROW YOU

CREATE TABLE future_scenarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    summary TEXT,
    horizon TEXT,
    trajectory_type TEXT NOT NULL,
    probability NUMERIC,
    confidence TEXT,
    evidence JSONB,
    status TEXT DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

CREATE TABLE scenario_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scenario_id UUID REFERENCES future_scenarios(id) ON DELETE CASCADE,
    sequence INT NOT NULL,
    relative_time TEXT,
    title TEXT NOT NULL,
    description TEXT,
    source_prediction_id UUID REFERENCES future_predictions(id) ON DELETE SET NULL,
    confidence TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE counterfactuals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    scenario_id UUID REFERENCES future_scenarios(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    assumption TEXT NOT NULL,
    expected_effect TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS POLICIES FOR PHASE 4
ALTER TABLE future_scenarios ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own scenarios" ON future_scenarios FOR ALL USING (auth.uid() = user_id);

ALTER TABLE scenario_events ENABLE ROW LEVEL SECURITY;
-- Using exists clause to verify ownership through scenario
CREATE POLICY "Users can manage own scenario events" ON scenario_events FOR ALL 
USING (EXISTS (SELECT 1 FROM future_scenarios WHERE future_scenarios.id = scenario_events.scenario_id AND future_scenarios.user_id = auth.uid()));

ALTER TABLE counterfactuals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own counterfactuals" ON counterfactuals FOR ALL USING (auth.uid() = user_id);

-- PHASE 5: PROACTIVE TESS

CREATE TABLE interventions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    prediction_id UUID REFERENCES future_predictions(id) ON DELETE SET NULL,
    scenario_id UUID REFERENCES future_scenarios(id) ON DELETE SET NULL,
    type TEXT NOT NULL,
    priority TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    reason TEXT,
    value_score NUMERIC,
    status TEXT DEFAULT 'PENDING',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    viewed_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    deferred_until TIMESTAMPTZ
);

ALTER TABLE interventions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own interventions" ON interventions FOR ALL USING (auth.uid() = user_id);

-- PHASE 6: AGENT LAYER

CREATE TABLE agent_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    objective TEXT NOT NULL,
    status TEXT DEFAULT 'PLANNING',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE agent_steps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID REFERENCES agent_plans(id) ON DELETE CASCADE,
    step_order INT NOT NULL,
    tool_name TEXT NOT NULL,
    action_type TEXT NOT NULL,
    parameters JSONB,
    risk_level TEXT NOT NULL,
    status TEXT DEFAULT 'PENDING',
    result JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE action_confirmations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES agent_plans(id) ON DELETE CASCADE,
    step_id UUID REFERENCES agent_steps(id) ON DELETE CASCADE,
    summary TEXT NOT NULL,
    status TEXT DEFAULT 'PENDING',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ
);

ALTER TABLE agent_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own agent plans" ON agent_plans FOR ALL USING (auth.uid() = user_id);

ALTER TABLE agent_steps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own agent steps" ON agent_steps FOR ALL 
USING (EXISTS (SELECT 1 FROM agent_plans WHERE agent_plans.id = agent_steps.plan_id AND agent_plans.user_id = auth.uid()));

ALTER TABLE action_confirmations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own confirmations" ON action_confirmations FOR ALL USING (auth.uid() = user_id);

-- PHASE 7: CROSS-DEVICE COMPANION (DEVICE REGISTRY)

CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    device_name TEXT NOT NULL,
    platform TEXT NOT NULL,
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, device_id)
);

ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own devices" ON user_devices FOR ALL USING (auth.uid() = user_id);

-- PHASE 9: ADVANCED FUTURE INTELLIGENCE

CREATE TABLE behavioral_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    features JSONB NOT NULL,
    data_quality TEXT NOT NULL DEFAULT 'GOOD',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE behavioral_snapshots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own behavioral snapshots" ON behavioral_snapshots FOR ALL USING (auth.uid() = user_id);

CREATE TABLE prediction_evaluations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    prediction_id UUID REFERENCES future_predictions(id) ON DELETE CASCADE,
    predicted_outcome JSONB NOT NULL,
    actual_outcome JSONB,
    evaluation_status TEXT NOT NULL DEFAULT 'PENDING',
    evaluation_method TEXT,
    evaluated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE prediction_evaluations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own prediction evaluations" ON prediction_evaluations FOR ALL USING (auth.uid() = user_id);

CREATE TABLE forecast_model_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name TEXT NOT NULL,
    model_version TEXT NOT NULL,
    configuration JSONB,
    evaluation_metrics JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE intervention_evaluations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    intervention_id UUID REFERENCES interventions(id) ON DELETE CASCADE,
    related_prediction_id UUID REFERENCES future_predictions(id) ON DELETE SET NULL,
    observed_outcome JSONB,
    evaluation_status TEXT NOT NULL DEFAULT 'EVALUATED',
    evaluated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE intervention_evaluations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own intervention evaluations" ON intervention_evaluations FOR ALL USING (auth.uid() = user_id);

-- PHASE 10: LIVING AI COMPANION

CREATE TABLE IF NOT EXISTS companion_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    personality TEXT NOT NULL DEFAULT 'FRIENDLY',
    communication_style TEXT NOT NULL DEFAULT 'BALANCED',
    proactivity_level TEXT NOT NULL DEFAULT 'BALANCED',
    encouragement_style TEXT NOT NULL DEFAULT 'GENTLE',
    formality TEXT NOT NULL DEFAULT 'NEUTRAL',
    mascot_theme TEXT NOT NULL DEFAULT 'PURPLE',
    expression_style TEXT NOT NULL DEFAULT 'EXPRESSIVE',
    animation_level TEXT NOT NULL DEFAULT 'NORMAL',
    sound_enabled BOOLEAN DEFAULT FALSE,
    quiet_mode BOOLEAN DEFAULT FALSE,
    quiet_hours_start TEXT DEFAULT '22:00',
    quiet_hours_end TEXT DEFAULT '08:00',
    progression_enabled BOOLEAN DEFAULT TRUE,
    current_stage INT DEFAULT 1,
    interaction_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE companion_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own companion preferences" ON companion_preferences FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS companion_routines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    routine_name TEXT NOT NULL,
    routine_type TEXT NOT NULL,
    preferred_time TEXT NOT NULL,
    days_of_week JSONB NOT NULL DEFAULT '["MON","TUE","WED","THU","FRI"]'::jsonb,
    timezone TEXT NOT NULL DEFAULT 'UTC',
    enabled BOOLEAN DEFAULT TRUE,
    last_run_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE companion_routines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own companion routines" ON companion_routines FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS companion_milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    milestone_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    stage_unlocked INT DEFAULT 1,
    achieved_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE companion_milestones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own companion milestones" ON companion_milestones FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS companion_activity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL,
    summary TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE companion_activity ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own companion activity" ON companion_activity FOR ALL USING (auth.uid() = user_id);

-- Add optional columns to memories for continuity provenance and user confirmation
ALTER TABLE memories ADD COLUMN IF NOT EXISTS is_confirmed BOOLEAN DEFAULT TRUE;
ALTER TABLE memories ADD COLUMN IF NOT EXISTS provenance TEXT DEFAULT 'USER_STATED';

-- PHASE: WARDROBE INTELLIGENCE
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

ALTER TABLE public.wardrobe_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read categories" ON public.wardrobe_categories FOR SELECT USING (user_id IS NULL OR user_id = auth.uid());
CREATE POLICY "Users can manage own categories" ON public.wardrobe_categories FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.wardrobe_items (
    id TEXT PRIMARY KEY,
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

CREATE INDEX IF NOT EXISTS idx_wardrobe_items_user_id ON public.wardrobe_items(user_id);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_category ON public.wardrobe_items(user_id, main_category);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_laundry ON public.wardrobe_items(user_id, laundry_status);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_archived ON public.wardrobe_items(user_id, is_archived);

ALTER TABLE public.wardrobe_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own wardrobe items" ON public.wardrobe_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own wardrobe items" ON public.wardrobe_items FOR ALL USING (auth.uid() = user_id);

-- WARDROBE INTELLIGENCE PHASE 3: SMART CAPTURE & GARMENT DETECTION

CREATE TABLE IF NOT EXISTS public.wardrobe_capture_jobs (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    original_image_ref TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING',
    current_stage TEXT NOT NULL DEFAULT 'Validating photograph',
    progress_percent INT NOT NULL DEFAULT 0,
    total_detected INT NOT NULL DEFAULT 0,
    provider_type TEXT NOT NULL DEFAULT 'DEVELOPMENT_LOCAL',
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.wardrobe_garment_candidates (
    id TEXT PRIMARY KEY,
    job_id TEXT NOT NULL REFERENCES public.wardrobe_capture_jobs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    suggested_name TEXT NOT NULL,
    main_category TEXT NOT NULL,
    subcategory TEXT,
    primary_color TEXT NOT NULL,
    secondary_colors TEXT[] DEFAULT '{}',
    pattern TEXT,
    fabric_material TEXT,
    sleeve_length TEXT,
    neckline TEXT,
    fit TEXT,
    silhouette TEXT,
    garment_length TEXT,
    size TEXT,
    brand TEXT,
    confidence_scores JSONB DEFAULT '{}'::jsonb,
    bounding_box JSONB DEFAULT '{}'::jsonb,
    processed_image_ref TEXT,
    original_crop_ref TEXT,
    is_included BOOLEAN NOT NULL DEFAULT TRUE,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    registered_garment_id TEXT,
    uncertainty_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_capture_jobs_user ON public.wardrobe_capture_jobs (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_capture_jobs_status ON public.wardrobe_capture_jobs (status);
CREATE INDEX IF NOT EXISTS idx_garment_candidates_job ON public.wardrobe_garment_candidates (job_id);
CREATE INDEX IF NOT EXISTS idx_garment_candidates_user ON public.wardrobe_garment_candidates (user_id);

ALTER TABLE public.wardrobe_capture_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own capture jobs" ON public.wardrobe_capture_jobs FOR ALL USING (auth.uid() = user_id);

ALTER TABLE public.wardrobe_garment_candidates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own garment candidates" ON public.wardrobe_garment_candidates FOR ALL USING (auth.uid() = user_id);

-- PHASE 4: LAUNDRY MANAGER & BATCH MANAGEMENT
ALTER TABLE public.wardrobe_items
    ADD COLUMN IF NOT EXISTS wear_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS wash_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_worn_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS last_washed_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS active_batch_id TEXT;

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

ALTER TABLE public.laundry_batches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own laundry batches" ON public.laundry_batches FOR ALL USING (auth.uid() = user_id);

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
CREATE POLICY "Users can manage own batch items" ON public.laundry_batch_items FOR ALL USING (auth.uid() = user_id);

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
CREATE POLICY "Users can manage own laundry history" ON public.wardrobe_laundry_history FOR ALL USING (auth.uid() = user_id);






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


-- Migration 006: Wardrobe Insights, Usage Analytics & Personal Style Intelligence
ALTER TABLE public.wardrobe_items ADD COLUMN IF NOT EXISTS purchase_currency VARCHAR(10) DEFAULT 'INR';

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

ALTER TABLE public.wardrobe_style_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own style preferences" ON public.wardrobe_style_preferences
    FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_wardrobe_items_price ON public.wardrobe_items(user_id, purchase_price);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_color ON public.wardrobe_items(user_id, primary_color);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_wear_count ON public.wardrobe_items(user_id, wear_count);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_last_worn ON public.wardrobe_items(user_id, last_worn_date);
CREATE INDEX IF NOT EXISTS idx_calendar_wear_actual_date ON public.outfit_calendar_wear_records(user_id, actual_worn_date);
