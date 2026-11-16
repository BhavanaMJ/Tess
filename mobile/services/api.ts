import { supabase } from '../lib/supabase';
import { Platform } from 'react-native';

const DEFAULT_URL = Platform.OS === 'android' ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
export const BACKEND_URL = process.env.EXPO_PUBLIC_BACKEND_URL || DEFAULT_URL;

const getHeaders = async () => {
  const { data: { session }, error } = await supabase.auth.getSession();
  if (error || !session || !session.access_token) {
    throw new Error('Authentication required: No active session. Please log in.');
  }
  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${session.access_token}`
  };
};

const handleResponse = async (response: Response) => {
  if (response.status === 401) {
    throw new Error('Unauthorized: Session has expired or is invalid. Please sign in again.');
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
    let errorDetail = `API error: ${response.status}`;
    try {
      const errJson = await response.json();
      if (errJson?.detail) {
        errorDetail = typeof errJson.detail === 'string' ? errJson.detail : JSON.stringify(errJson.detail);
      }
    } catch (_) {}
    throw new Error(errorDetail);
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
      signal: options.signal || (controller.signal as any)
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
  getBackendUrl() {
    return BACKEND_URL;
  },

  async healthCheck() {
    try {
      const response = await safeFetch(`${BACKEND_URL}/health`);
      if (!response.ok) throw new Error('Backend not available');
      return await response.json();
    } catch (error) {
      console.error('Health check failed', error);
      throw error;
    }
  },

  async chat(conversationId: string, message: string) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/conversations/${conversationId}/messages`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ message }),
    });
    return handleResponse(response);
  },

  async getConversations() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/conversations`, { headers });
    return handleResponse(response);
  },

  async createConversation(title: string = "New Conversation") {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/conversations`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ title })
    });
    return handleResponse(response);
  },

  async getMessages(conversationId: string) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/conversations/${conversationId}/messages`, { headers });
    return handleResponse(response);
  },

  async testOpenProject(baseUrl: string, token: string) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/productivity/integrations/openproject/test`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ base_url: baseUrl, api_token: token })
    });
    return handleResponse(response);
  },

  async syncOpenProject() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/productivity/integrations/openproject/sync`, {
      method: 'POST',
      headers,
    });
    return handleResponse(response);
  },

  async getProductivitySummary() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/productivity/summary`, { headers });
    return handleResponse(response);
  },
  
  async getProductivityTasks() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/productivity/tasks`, { headers });
    return handleResponse(response);
  },

  async analyzeFuture() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/future/analyze`, {
      method: 'POST',
      headers,
    });
    return handleResponse(response);
  },

  async getFuturePredictions() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/future/predictions`, { headers });
    return handleResponse(response);
  },

  // Phase 6: Agent & Action Layer Endpoints
  async createObjective(objective: string) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/agent/objectives`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ objective }),
    });
    return handleResponse(response);
  },

  async getPlan(planId: string) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/agent/plans/${planId}`, {
      method: 'GET',
      headers,
    });
    return handleResponse(response);
  },

  async confirmPlan(planId: string) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/agent/plans/${planId}/confirm`, {
      method: 'POST',
      headers,
    });
    return handleResponse(response);
  },

  async cancelPlan(planId: string) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/agent/plans/${planId}/cancel`, {
      method: 'POST',
      headers,
    });
    return handleResponse(response);
  },

  async executePlan(planId: string) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/agent/plans/${planId}/execute`, {
      method: 'POST',
      headers,
    });
    return handleResponse(response);
  },

  // Proactive Interventions Endpoints
  async getInterventions() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/proactive/interventions`, {
      method: 'GET',
      headers,
    });
    return handleResponse(response);
  },

  async respondIntervention(interventionId: string, action: string) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/proactive/interventions/${interventionId}/respond`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ action }),
    });
    return handleResponse(response);
  },

  // Phase 10: Living AI Companion
  async getCompanionProfile() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/companion/profile`, {
      method: 'GET',
      headers,
    });
    return handleResponse(response);
  },

  async getCompanionPreferences() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/companion/preferences`, {
      method: 'GET',
      headers,
    });
    return handleResponse(response);
  },

  async updateCompanionPreferences(updates: any) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/companion/preferences`, {
      method: 'PUT',
      headers,
      body: JSON.stringify(updates),
    });
    return handleResponse(response);
  },

  async getCompanionRoutines() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/companion/routines`, {
      method: 'GET',
      headers,
    });
    return handleResponse(response);
  },

  async createCompanionRoutine(routine: any) {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/companion/routines`, {
      method: 'POST',
      headers,
      body: JSON.stringify(routine),
    });
    return handleResponse(response);
  },

  async getCompanionMilestones() {
    const headers = await getHeaders();
    const response = await safeFetch(`${BACKEND_URL}/api/v1/companion/milestones`, {
      method: 'GET',
      headers,
    });
    return handleResponse(response);
  }
};
