import { createClient, Session } from '@supabase/supabase-js';
import {
  Conversation,
  Message,
  ProductivitySummary,
  ProductivityTask,
  FuturePrediction,
  SimulationResponse,
  InterventionResponse,
  AgentPlan,
  Memory,
  UserDevice,
  BehavioralAnalysisResponse,
  LongTermForecastResponse,
  MultipleFuturesResponse,
  PredictionEvaluationItem,
  AccuracyMetricsResponse,
  InterventionEffectivenessResponse,
  CompanionPreferences,
  CompanionRoutine,
  CompanionRoutineCreate,
  CompanionMilestone,
  CompanionActivity,
  CompanionProfileResponse
} from '../types';

// Environment variables via Vite
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://mock.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'mock-anon-key';
export const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8000';

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: false
  }
});

let currentSession: Session | null = null;

export const setSessionToken = (session: Session | null) => {
  currentSession = session;
};

const getHeaders = async (): Promise<HeadersInit> => {
  if (!currentSession) {
    const { data } = await supabase.auth.getSession();
    currentSession = data.session;
  }
  const token = currentSession?.access_token;
  return {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {})
  };
};

const handleResponse = async <T>(response: Response): Promise<T> => {
  if (response.status === 401) {
    throw new Error('Unauthorized: Session expired or invalid. Please sign in again.');
  }
  if (response.status === 403) {
    let detail = 'Forbidden: Action requires confirmation or permission denied.';
    try {
      const err = await response.json();
      if (err?.detail) detail = err.detail;
    } catch (_) {}
    throw new Error(detail);
  }
  if (!response.ok) {
    let detail = `API error: ${response.status}`;
    try {
      const err = await response.json();
      if (err?.detail) {
        detail = typeof err.detail === 'string' ? err.detail : JSON.stringify(err.detail);
      }
    } catch (_) {}
    throw new Error(detail);
  }
  return response.json();
};

const DEFAULT_TIMEOUT_MS = 15000;

export const fetchWithTimeout = async (
  url: string,
  options: RequestInit = {},
  timeoutMs: number = DEFAULT_TIMEOUT_MS
): Promise<Response> => {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await globalThis.fetch(url, {
      ...options,
      signal: options.signal || controller.signal
    });
    return res;
  } catch (error: any) {
    if (error?.name === 'AbortError') {
      throw new Error(`Request timed out after ${timeoutMs / 1000}s: ${url}`);
    }
    throw error;
  } finally {
    clearTimeout(id);
  }
};

const safeFetch = fetchWithTimeout;

export const apiService = {
  // Health
  async healthCheck() {
    const res = await safeFetch(`${BACKEND_URL}/health`);
    return handleResponse<{ status: string }>(res);
  },

  // Conversations & Chat
  async getConversations(): Promise<Conversation[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/conversations`, { headers });
    return handleResponse<Conversation[]>(res);
  },

  async createConversation(title: string = 'Desktop Conversation'): Promise<Conversation> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/conversations`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ title })
    });
    return handleResponse<Conversation>(res);
  },

  async getMessages(conversationId: string): Promise<Message[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/conversations/${conversationId}/messages`, { headers });
    return handleResponse<Message[]>(res);
  },

  async sendMessage(conversationId: string, message: string): Promise<{ response: string }> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/conversations/${conversationId}/messages`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ message })
    });
    return handleResponse<{ response: string }>(res);
  },

  // Productivity
  async getProductivitySummary(): Promise<ProductivitySummary> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/productivity/summary`, { headers });
    return handleResponse<ProductivitySummary>(res);
  },

  async getProductivityTasks(): Promise<ProductivityTask[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/productivity/tasks`, { headers });
    return handleResponse<ProductivityTask[]>(res);
  },

  async syncOpenProject(): Promise<{ status: string; synced_tasks?: number }> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/productivity/integrations/openproject/sync`, {
      method: 'POST',
      headers
    });
    return handleResponse<{ status: string; synced_tasks?: number }>(res);
  },

  // Future Engine
  async getFuturePredictions(): Promise<FuturePrediction[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/future/predictions`, { headers });
    return handleResponse<FuturePrediction[]>(res);
  },

  async simulateFuture(horizon: '24h' | '3d' | '7d'): Promise<SimulationResponse> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/future/simulate`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ horizon })
    });
    return handleResponse<SimulationResponse>(res);
  },

  // Proactive Interventions
  async getInterventions(): Promise<InterventionResponse[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/proactive/interventions`, { headers });
    return handleResponse<InterventionResponse[]>(res);
  },

  async respondIntervention(id: string, action: 'ACTED' | 'LATER' | 'DISMISS'): Promise<{ status: string }> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/proactive/interventions/${id}/respond`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ action })
    });
    return handleResponse<{ status: string }>(res);
  },

  // Phase 6: Agent & Action Layer
  async getAgentPlans(): Promise<AgentPlan[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/agent/plans`, { headers });
    return handleResponse<AgentPlan[]>(res);
  },

  async getAgentPlan(planId: string): Promise<AgentPlan> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/agent/plans/${planId}`, { headers });
    return handleResponse<AgentPlan>(res);
  },

  async createAgentObjective(objective: string): Promise<AgentPlan> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/agent/objectives`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ objective })
    });
    return handleResponse<AgentPlan>(res);
  },

  async confirmAgentPlan(planId: string): Promise<{ status: string }> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/agent/plans/${planId}/confirm`, {
      method: 'POST',
      headers
    });
    return handleResponse<{ status: string }>(res);
  },

  async cancelAgentPlan(planId: string): Promise<{ status: string }> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/agent/plans/${planId}/cancel`, {
      method: 'POST',
      headers
    });
    return handleResponse<{ status: string }>(res);
  },

  async executeAgentPlan(planId: string): Promise<{ status: string; results?: any[] }> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/agent/plans/${planId}/execute`, {
      method: 'POST',
      headers
    });
    return handleResponse<{ status: string; results?: any[] }>(res);
  },

  // Memory
  async getMemories(): Promise<Memory[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/memories`, { headers });
    return handleResponse<Memory[]>(res);
  },

  async createMemory(category: string, content: string, importance: number = 3): Promise<Memory> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/memories`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ category, content, importance })
    });
    return handleResponse<Memory>(res);
  },

  async deleteMemory(memoryId: string): Promise<void> {
    const headers = await getHeaders();
    await safeFetch(`${BACKEND_URL}/api/v1/memories/${memoryId}`, {
      method: 'DELETE',
      headers
    });
  },

  async updateMemory(memoryId: string, updates: { category?: string; content?: string; importance?: number; is_confirmed?: boolean; provenance?: string }): Promise<Memory> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/memories/${memoryId}`, {
      method: 'PUT',
      headers,
      body: JSON.stringify(updates)
    });
    return handleResponse<Memory>(res);
  },

  // Device Registry (Phase 7 Cross-Device)
  async registerDevice(deviceId: string, deviceName: string, platform: string): Promise<{ status: string }> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/devices/register`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        device_id: deviceId,
        device_name: deviceName,
        platform
      })
    });
    return handleResponse<{ status: string }>(res);
  },

  async getUserDevices(): Promise<UserDevice[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/devices`, { headers });
    return handleResponse<UserDevice[]>(res);
  },

  // Phase 8: Voice Assistant
  async voiceTranscribe(audioBlob: Blob): Promise<{ transcript: string }> {
    if (!currentSession) {
      const { data } = await supabase.auth.getSession();
      currentSession = data.session;
    }
    const token = currentSession?.access_token;
    const formData = new FormData();
    formData.append('file', audioBlob, 'voice.wav');

    const res = await safeFetch(`${BACKEND_URL}/api/v1/voice/transcribe`, {
      method: 'POST',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: formData
    });
    return handleResponse<{ transcript: string }>(res);
  },

  async voiceSynthesize(text: string): Promise<Blob> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/voice/synthesize`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ text })
    });
    if (!res.ok) throw new Error(`Speech synthesis failed: ${res.status}`);
    return res.blob();
  },

  async voiceInteract(audioBlob: Blob): Promise<{ transcript: string; response_text: string; audio_base64: string }> {
    if (!currentSession) {
      const { data } = await supabase.auth.getSession();
      currentSession = data.session;
    }
    const token = currentSession?.access_token;
    const formData = new FormData();
    formData.append('file', audioBlob, 'voice.wav');

    const res = await safeFetch(`${BACKEND_URL}/api/v1/voice/interact`, {
      method: 'POST',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: formData
    });
    return handleResponse<{ transcript: string; response_text: string; audio_base64: string }>(res);
  },

  // Phase 8: Screen Understanding
  async analyzeScreen(imageBlob: Blob, query: string): Promise<{ query: string; analysis: string; dimensions: { width: number; height: number }; suggestions: string[] }> {
    if (!currentSession) {
      const { data } = await supabase.auth.getSession();
      currentSession = data.session;
    }
    const token = currentSession?.access_token;
    const formData = new FormData();
    formData.append('file', imageBlob, 'screen.jpg');
    formData.append('query', query);

    const res = await safeFetch(`${BACKEND_URL}/api/v1/screen/analyze`, {
      method: 'POST',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: formData
    });
    return handleResponse<{ query: string; analysis: string; dimensions: { width: number; height: number }; suggestions: string[] }>(res);
  },

  // Phase 9: Advanced Future Intelligence
  async getBehavioralProfile(windowDays: number = 30): Promise<BehavioralAnalysisResponse> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/future/behavior?window_days=${windowDays}`, { headers });
    return handleResponse<BehavioralAnalysisResponse>(res);
  },

  async generateLongTermForecast(horizon: '30d' | '90d' | '365d' = '30d'): Promise<LongTermForecastResponse> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/future/forecast`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ horizon })
    });
    return handleResponse<LongTermForecastResponse>(res);
  },

  async generateMultipleFutures(horizon: '30d' | '90d' | '365d' = '30d', userGoal?: string): Promise<MultipleFuturesResponse> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/future/scenarios`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ horizon, user_goal: userGoal })
    });
    return handleResponse<MultipleFuturesResponse>(res);
  },

  async evaluatePredictions(): Promise<PredictionEvaluationItem[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/future/evaluate`, {
      method: 'POST',
      headers
    });
    return handleResponse<PredictionEvaluationItem[]>(res);
  },

  async getPredictionAccuracy(): Promise<AccuracyMetricsResponse> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/future/accuracy`, { headers });
    return handleResponse<AccuracyMetricsResponse>(res);
  },

  async getInterventionEffectiveness(): Promise<InterventionEffectivenessResponse> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/future/intervention-effectiveness`, { headers });
    return handleResponse<InterventionEffectivenessResponse>(res);
  },

  // Phase 10: Living AI Companion
  async getCompanionProfile(): Promise<CompanionProfileResponse> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/companion/profile`, { headers });
    return handleResponse<CompanionProfileResponse>(res);
  },

  async getCompanionPreferences(): Promise<CompanionPreferences> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/companion/preferences`, { headers });
    return handleResponse<CompanionPreferences>(res);
  },

  async updateCompanionPreferences(updates: Partial<CompanionPreferences>): Promise<CompanionPreferences> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/companion/preferences`, {
      method: 'PUT',
      headers,
      body: JSON.stringify(updates)
    });
    return handleResponse<CompanionPreferences>(res);
  },

  async getCompanionRoutines(): Promise<CompanionRoutine[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/companion/routines`, { headers });
    return handleResponse<CompanionRoutine[]>(res);
  },

  async createCompanionRoutine(routine: CompanionRoutineCreate): Promise<CompanionRoutine> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/companion/routines`, {
      method: 'POST',
      headers,
      body: JSON.stringify(routine)
    });
    return handleResponse<CompanionRoutine>(res);
  },

  async updateCompanionRoutine(routineId: string, updates: Partial<CompanionRoutine>): Promise<CompanionRoutine> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/companion/routines/${routineId}`, {
      method: 'PUT',
      headers,
      body: JSON.stringify(updates)
    });
    return handleResponse<CompanionRoutine>(res);
  },

  async deleteCompanionRoutine(routineId: string): Promise<void> {
    const headers = await getHeaders();
    await safeFetch(`${BACKEND_URL}/api/v1/companion/routines/${routineId}`, {
      method: 'DELETE',
      headers
    });
  },

  async checkDueRoutines(): Promise<{ due_routines: any[]; count: number }> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/companion/routines/check`, {
      method: 'POST',
      headers
    });
    return handleResponse<{ due_routines: any[]; count: number }>(res);
  },

  async getCompanionMilestones(): Promise<CompanionMilestone[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/companion/milestones`, { headers });
    return handleResponse<CompanionMilestone[]>(res);
  },

  async getCompanionActivity(limit: number = 20): Promise<CompanionActivity[]> {
    const headers = await getHeaders();
    const res = await safeFetch(`${BACKEND_URL}/api/v1/companion/activity?limit=${limit}`, { headers });
    return handleResponse<CompanionActivity[]>(res);
  }
};

