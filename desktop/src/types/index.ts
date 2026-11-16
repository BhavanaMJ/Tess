export type MascotState =
  | 'IDLE'
  | 'HAPPY'
  | 'CURIOUS'
  | 'LISTENING'
  | 'THINKING'
  | 'SPEAKING'
  | 'VIEWING'
  | 'BROWSING'
  | 'READING'
  | 'PLANNING'
  | 'CONFIRMING'
  | 'ACTING'
  | 'SUCCESS'
  | 'ERROR'
  | 'RESTING'
  | 'ATTENTION'
  | 'INTERVENING'
  | 'SLEEPING';

export interface User {
  id: string;
  email?: string;
  user_metadata?: Record<string, any>;
}

export interface Conversation {
  id: string;
  title: string;
  created_at: string;
  updated_at?: string;
}

export interface Message {
  id: string;
  conversation_id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  created_at: string;
}

export interface ProductivitySummary {
  total_active: number;
  overdue: number;
  due_today: number;
  due_this_week: number;
  completed_recently: number;
}

export interface ProductivityTask {
  id: string;
  user_id: string;
  source: string;
  external_id: string;
  title: string;
  description?: string;
  status?: string;
  priority?: string;
  assignee?: string;
  project?: string;
  due_date?: string;
  completion_percent?: number;
  created_at: string;
}

export interface FuturePrediction {
  id: string;
  prediction_type: string;
  title: string;
  description: string;
  confidence: string;
  probability: number;
  time_horizon: string;
  evidence: string[];
  reasoning?: string;
  status: string;
  created_at: string;
}

export interface FutureScenarioEvent {
  title: string;
  description: string;
  relative_time: string;
}

export interface FutureScenario {
  title: string;
  summary: string;
  events: FutureScenarioEvent[];
}

export interface AlternativePath {
  action: string;
  expected_effect: string;
}

export interface SimulationResponse {
  horizon: string;
  scenario: FutureScenario;
  alternative?: AlternativePath;
}

export interface InterventionResponse {
  id: string;
  prediction_id: string;
  title: string;
  message: string;
  suggested_action: string;
  priority: string;
  status: 'PENDING' | 'SENT' | 'ACTED' | 'DISMISSED' | 'EXPIRED';
  created_at: string;
}

export interface AgentStep {
  id: string;
  plan_id: string;
  step_order: number;
  tool_name: string;
  action_type: string;
  parameters: Record<string, any>;
  risk_level: 'LOW' | 'MEDIUM' | 'HIGH';
  status: 'PENDING' | 'RUNNING' | 'SUCCESS' | 'FAILED';
  result?: Record<string, any>;
  created_at?: string;
  confirmation?: {
    id: string;
    status: 'PENDING' | 'CONFIRMED' | 'CANCELLED' | 'EXPIRED';
    expires_at?: string;
    summary?: string;
  };
}

export interface AgentPlan {
  id: string;
  user_id: string;
  objective: string;
  status: 'PLANNING' | 'READY' | 'EXECUTING' | 'SUCCESS' | 'FAILED' | 'CANCELLED';
  created_at?: string;
  completed_at?: string;
  steps: AgentStep[];
}

export interface Memory {
  id: string;
  user_id: string;
  category: string;
  content: string;
  importance: number;
  is_confirmed?: boolean;
  provenance?: string;
  created_at: string;
  updated_at?: string;
}

export interface UserDevice {
  id: string;
  user_id: string;
  device_id: string;
  device_name: string;
  platform: string;
  last_seen_at: string;
  created_at: string;
}

export interface NotificationSettings {
  enabled: boolean;
  futureRisks: boolean;
  deadlines: boolean;
  interventions: boolean;
  agentResults: boolean;
  detailedPreviews: boolean;
}

// Phase 9: Advanced Future Intelligence
export interface BehavioralInsight {
  category: string;
  headline: string;
  observation: string;
  evidence: string[];
  data_quality: 'GOOD' | 'PRELIMINARY' | 'INSUFFICIENT';
  window_days: number;
}

export interface BehavioralAnalysisResponse {
  insights: BehavioralInsight[];
  metrics: Record<string, any>;
  data_quality: 'GOOD' | 'PRELIMINARY' | 'INSUFFICIENT';
  period_start: string;
  period_end: string;
}

export interface LongTermForecastResponse {
  id: string;
  horizon: '30d' | '90d' | '365d';
  projected_backlog: number;
  completion_forecast: number;
  burnout_risk_score: number;
  probability: number;
  confidence: string;
  uncertainty_range: {
    backlog_min: number;
    backlog_max: number;
    completion_min: number;
    completion_max: number;
  };
  assumptions: string[];
  evidence: string[];
  explanation: string;
  created_at: string;
}

export interface MultipleFuturesResponse {
  horizon: '30d' | '90d' | '365d';
  current_trajectory: FutureScenario;
  improved_trajectory: FutureScenario;
  alternative_trajectory: FutureScenario;
}

export interface PredictionEvaluationItem {
  id: string;
  prediction_id: string;
  horizon: string;
  predicted_outcome: string;
  actual_outcome: string;
  status: 'PENDING' | 'EVALUATED' | 'CONFIRMED' | 'PARTIALLY_CONFIRMED' | 'NOT_CONFIRMED' | 'INSUFFICIENT_DATA';
  brier_score?: number | null;
  evaluated_at: string;
}

export interface AccuracyMetricsResponse {
  total_evaluated: number;
  overall_accuracy: number;
  brier_calibration_score: number;
  accuracy_by_horizon: Record<string, number>;
  accuracy_by_type: Record<string, number>;
  recent_evaluations: PredictionEvaluationItem[];
}

export interface InterventionEffectivenessResponse {
  total_interventions: number;
  accepted_count: number;
  dismissed_count: number;
  actions_completed_count: number;
  acceptance_rate: number;
  action_conversion_rate: number;
  insights: string[];
}

// Phase 10: Living AI Companion
export interface CompanionPreferences {
  id?: string;
  user_id?: string;
  personality: 'CALM' | 'FRIENDLY' | 'PROFESSIONAL' | 'PLAYFUL' | 'FOCUSED' | 'CUSTOM';
  communication_style: 'CONCISE' | 'BALANCED' | 'DETAILED';
  proactivity_level: 'LOW' | 'BALANCED' | 'PROACTIVE';
  encouragement_style: 'GENTLE' | 'ENERGETIC' | 'PRAGMATIC';
  formality: 'CASUAL' | 'NEUTRAL' | 'FORMAL';
  mascot_theme: 'PURPLE' | 'CYAN' | 'AMBER' | 'EMERALD' | 'ROSE' | 'INDIGO';
  expression_style: 'EXPRESSIVE' | 'CLASSIC' | 'MINIMAL';
  animation_level: 'MINIMAL' | 'NORMAL' | 'LIVELY';
  sound_enabled: boolean;
  quiet_mode: boolean;
  quiet_hours_start: string;
  quiet_hours_end: string;
  progression_enabled: boolean;
  current_stage: number;
  interaction_count: number;
  created_at?: string;
  updated_at?: string;
}

export interface CompanionRoutine {
  id: string;
  user_id: string;
  routine_name: string;
  routine_type: string;
  preferred_time: string;
  days_of_week: string[];
  timezone: string;
  enabled: boolean;
  last_run_at?: string;
  created_at?: string;
  updated_at?: string;
}

export interface CompanionRoutineCreate {
  routine_name: string;
  routine_type: string;
  preferred_time: string;
  days_of_week?: string[];
  timezone?: string;
  enabled?: boolean;
}

export interface CompanionMilestone {
  id: string;
  user_id: string;
  milestone_type: string;
  title: string;
  description: string;
  stage_unlocked: number;
  achieved_at: string;
}

export interface CompanionActivity {
  id: string;
  user_id: string;
  activity_type: string;
  summary: string;
  metadata?: Record<string, any>;
  created_at: string;
}

export interface CompanionProfileResponse {
  preferences: CompanionPreferences;
  current_stage: number;
  stage_name: string;
  interaction_count: number;
  active_routines_count: number;
  total_milestones: number;
  quiet_mode_active: boolean;
  personality_description: string;
  available_stages: Array<{
    stage: number;
    name: string;
    description: string;
    min_interactions: number;
    min_milestones: number;
    unlocked_features: string[];
  }>;
}



