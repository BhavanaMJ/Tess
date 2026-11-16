import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';

import App from '../App';
import { Mascot, getMascotDetails } from '../components/Mascot';
import { FloatingMascotWindow } from '../mascot/FloatingMascotWindow';
import { HomeScreen } from '../screens/HomeScreen';
import { TasksScreen } from '../screens/TasksScreen';
import { FuturesScreen } from '../screens/FuturesScreen';
import { InterventionsScreen } from '../screens/InterventionsScreen';
import { AgentActivityScreen } from '../screens/AgentActivityScreen';
import { MemoryScreen } from '../screens/MemoryScreen';
import { SettingsScreen } from '../screens/SettingsScreen';
import {
  getNotificationSettings,
  saveNotificationSettings,
  notifyDesktop
} from '../services/notifications';
import { apiService, setSessionToken } from '../services/api';
import { mockSendNotification } from './setup';

describe('TESS Phase 7 — Desktop Application & Mascot Test Suite', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  // ============================================================================
  // 1. Mascot Visuals, States & Details
  // ============================================================================
  it('correctly maps mascot states to faces and colors', () => {
    expect(getMascotDetails('IDLE').face).toBe('•_•');
    expect(getMascotDetails('LISTENING').face).toBe('O_o');
    expect(getMascotDetails('THINKING').face).toBe('O_O');
    expect(getMascotDetails('SPEAKING').face).toBe('^o^');
    expect(getMascotDetails('VIEWING').face).toBe('◉_◉');
    expect(getMascotDetails('BROWSING').face).toBe('•‿•');
    expect(getMascotDetails('READING').face).toBe('•_•');
    expect(getMascotDetails('ATTENTION').face).toBe('O_O!');
    expect(getMascotDetails('INTERVENING').face).toBe('O_O!');
    expect(getMascotDetails('PLANNING').face).toBe('-_-');
    expect(getMascotDetails('CONFIRMING').face).toBe('?_?');
    expect(getMascotDetails('ACTING').face).toBe('-_-');
    expect(getMascotDetails('SUCCESS').face).toBe('^_^!!');
    expect(getMascotDetails('ERROR').face).toBe('X_X');
    expect(getMascotDetails('SLEEPING').face).toBe('u_u');
    expect(getMascotDetails('RESTING').face).toBe('u_u');
  });

  it('renders mascot component with face and optional label', () => {
    const { container } = render(<Mascot state="CONFIRMING" size="md" showLabel={true} />);
    expect(container.textContent).toContain('?_?');
    expect(container.textContent).toContain('Requires Confirmation');
  });

  // ============================================================================
  // 2. Floating Mascot Window Experience
  // ============================================================================
  it('renders floating mascot window with drag region and click interaction', async () => {
    const { container } = render(<FloatingMascotWindow />);
    expect(container.querySelector('[data-tauri-drag-region]')).toBeInTheDocument();
    expect(container.textContent).toContain('TESS');

    const mascotCard = container.querySelector('.group');
    expect(mascotCard).toBeInTheDocument();
    if (mascotCard) {
      fireEvent.click(mascotCard);
    }
  });

  // ============================================================================
  // 3. Desktop Notification Engine
  // ============================================================================
  it('persists and loads notification settings', () => {
    const initial = getNotificationSettings();
    expect(initial.enabled).toBe(true);
    expect(initial.futureRisks).toBe(true);

    saveNotificationSettings({
      ...initial,
      enabled: false,
      deadlines: false
    });

    const updated = getNotificationSettings();
    expect(updated.enabled).toBe(false);
    expect(updated.deadlines).toBe(false);
  });

  it('triggers desktop notification when enabled', async () => {
    saveNotificationSettings({
      enabled: true,
      futureRisks: true,
      deadlines: true,
      interventions: true,
      agentResults: true,
      detailedPreviews: true
    });

    await notifyDesktop('Overdue Alert', 'Worklog is pending on task 1', 'deadlines');
    expect(mockSendNotification).toHaveBeenCalledWith({
      title: '🐾 Overdue Alert',
      body: 'Worklog is pending on task 1'
    });
  });

  it('masks private information when detailed previews are disabled', async () => {
    saveNotificationSettings({
      enabled: true,
      futureRisks: true,
      deadlines: true,
      interventions: true,
      agentResults: true,
      detailedPreviews: false
    });

    await notifyDesktop('Private Secret Alert', 'Sensitive client data', 'interventions');
    expect(mockSendNotification).toHaveBeenCalledWith({
      title: '🐾 Private Secret Alert',
      body: 'TESS has an update requiring your attention.'
    });
  });

  // ============================================================================
  // 4. Centralized API Service Integration Tests
  // ============================================================================
  it('attaches Bearer token in API requests when session is present', async () => {
    setSessionToken({
      access_token: 'valid-jwt-token-xyz',
      refresh_token: 'refresh',
      expires_in: 3600,
      token_type: 'bearer',
      user: { id: 'user-1' } as any
    });

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => [{ id: 'conv-1', title: 'Desktop Chat', created_at: 'now' }]
    });
    global.fetch = mockFetch;

    const convs = await apiService.getConversations();
    expect(convs).toHaveLength(1);

    const callArgs = mockFetch.mock.calls[0];
    expect(callArgs[1].headers.Authorization).toBe('Bearer valid-jwt-token-xyz');
  });

  it('handles 401 unauthorized gracefully', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 401,
      json: async () => ({ detail: 'Invalid credentials' })
    });

    await expect(apiService.getConversations()).rejects.toThrow('Unauthorized');
  });

  it('handles 403 confirmation required / permission denied gracefully', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 403,
      json: async () => ({ detail: 'Step requires confirmation' })
    });

    await expect(apiService.executeAgentPlan('plan-1')).rejects.toThrow('Step requires confirmation');
  });

  it('handles future simulation request', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        horizon: '24h',
        scenario: { title: 'Projected Tomorrow', summary: 'Summary', events: [] }
      })
    });

    const sim = await apiService.simulateFuture('24h');
    expect(sim.horizon).toBe('24h');
    expect(sim.scenario.title).toBe('Projected Tomorrow');
  });

  it('registers device with platform metadata', async () => {
    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ status: 'success' })
    });
    global.fetch = mockFetch;

    await apiService.registerDevice('dev-123', 'TESS Desktop (linux)', 'linux');
    const body = JSON.parse(mockFetch.mock.calls[0][1].body);
    expect(body.device_id).toBe('dev-123');
    expect(body.platform).toBe('linux');
  });

  it('manages Agent objectives, confirmations and execution', async () => {
    const mockPlan = {
      id: 'p-1',
      user_id: 'u-1',
      objective: 'Update OpenProject worklog',
      status: 'READY',
      steps: []
    };

    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => mockPlan
    });

    const plan = await apiService.createAgentObjective('Update OpenProject worklog');
    expect(plan.id).toBe('p-1');

    // Confirm
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ status: 'success' })
    });
    const confRes = await apiService.confirmAgentPlan('p-1');
    expect(confRes.status).toBe('success');

    // Execute
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ status: 'success', results: [] })
    });
    const execRes = await apiService.executeAgentPlan('p-1');
    expect(execRes.status).toBe('success');
  });

  it('handles Phase 8 voice transcription and screen analysis requests', async () => {
    // Voice transcription
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ transcript: 'Show me my tasks' })
    });
    const audioBlob = new Blob(['mock audio'], { type: 'audio/wav' });
    const transRes = await apiService.voiceTranscribe(audioBlob);
    expect(transRes.transcript).toBe('Show me my tasks');

    // Screen analysis
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        query: 'Explain this error',
        analysis: 'Error analysis: stack trace in index.ts line 42',
        dimensions: { width: 1920, height: 1080 },
        suggestions: ['Check index.ts']
      })
    });
    const imgBlob = new Blob(['mock image'], { type: 'image/jpeg' });
    const screenRes = await apiService.analyzeScreen(imgBlob, 'Explain this error');
    expect(screenRes.analysis).toContain('Error analysis');
    expect(screenRes.dimensions.width).toBe(1920);
  });

  // ============================================================================
  // 5. Desktop Application Startup & Navigation
  // ============================================================================
  it('renders main application startup loading state', () => {
    const { container } = render(<App />);
    expect(container).toBeInTheDocument();
  });

  it('renders Tasks screen with productivity summary and filters', async () => {
    global.fetch = vi.fn().mockImplementation((url: string) => {
      if (url.includes('/summary')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({ total_active: 5, overdue: 1, due_today: 2, due_this_week: 1, completed_recently: 3 })
        });
      }
      return Promise.resolve({
        ok: true,
        status: 200,
        json: async () => [
          { id: '1', external_id: '101', title: 'Task 101', due_date: '2026-11-20', status: 'IN PROGRESS', priority: 'HIGH' }
        ]
      });
    });

    const { findByText } = render(<TasksScreen />);
    expect(await findByText('Task 101')).toBeInTheDocument();
    expect(await findByText('#101')).toBeInTheDocument();
  });

  it('renders Futures screen with probability and timeline events', async () => {
    global.fetch = vi.fn().mockImplementation((url: string) => {
      if (url.includes('/predictions')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => [
            { id: 'pred-1', prediction_type: 'RISK', title: 'Overdue Surge', description: 'Overdue tasks increase', probability: 0.85, confidence: 'HIGH', evidence: [] }
          ]
        });
      }
      return Promise.resolve({
        ok: true,
        status: 200,
        json: async () => ({
          horizon: '24h',
          scenario: {
            title: 'Probable 24h Trajectory',
            summary: 'Active work packages due',
            events: [{ title: 'Morning check', description: 'Review worklog', relative_time: '+2h' }]
          }
        })
      });
    });

    const { findByText } = render(<FuturesScreen />);
    expect(await findByText('Probable 24h Trajectory')).toBeInTheDocument();
    expect(await findByText('Overdue Surge')).toBeInTheDocument();
    expect(await findByText('85% (HIGH)')).toBeInTheDocument();
  });

  it('renders Interventions screen with FIX IT, LATER, and DISMISS actions', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => [
        {
          id: 'inv-1',
          prediction_id: 'p-1',
          title: 'Unlogged Hours Alert',
          message: 'You have not logged hours for today on OpenProject.',
          suggested_action: 'Update worklog with 2 hours',
          priority: 'HIGH',
          status: 'SENT',
          created_at: new Date().toISOString()
        }
      ]
    });

    const onNavigate = vi.fn();
    const { findByText } = render(<InterventionsScreen onNavigate={onNavigate} />);
    expect(await findByText('Unlogged Hours Alert')).toBeInTheDocument();
    expect(await findByText('FIX IT WITH AGENT')).toBeInTheDocument();
    expect(await findByText('Later')).toBeInTheDocument();
    expect(await findByText('Dismiss')).toBeInTheDocument();
  });

  it('renders Agent Activity screen with step details and risk badge', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => [
        {
          id: 'plan-1',
          user_id: 'u-1',
          objective: 'Update OpenProject worklog with 2 hours',
          status: 'READY',
          steps: [
            {
              id: 'step-1',
              plan_id: 'plan-1',
              step_order: 1,
              tool_name: 'openproject_update_worklog',
              action_type: 'UPDATE_WORKLOG',
              parameters: { task_id: '42', hours: 2.0, comment: 'Logged hours' },
              risk_level: 'MEDIUM',
              status: 'PENDING',
              confirmation: { id: 'c-1', status: 'PENDING' }
            }
          ]
        }
      ]
    });

    const { findByText, findAllByText } = render(<AgentActivityScreen />);
    const matches = await findAllByText('Update OpenProject worklog with 2 hours');
    expect(matches.length).toBeGreaterThan(0);
    expect(await findByText('openproject_update_worklog')).toBeInTheDocument();
    expect(await findByText('MEDIUM RISK')).toBeInTheDocument();
  });

  it('renders Memory screen and supports adding memories', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => [
        { id: 'm-1', user_id: 'u-1', category: 'preference', content: 'Prefers morning syncs', importance: 3, created_at: 'now' }
      ]
    });

    const { findByText } = render(<MemoryScreen />);
    expect(await findByText('Prefers morning syncs')).toBeInTheDocument();
    expect(await findByText('preference')).toBeInTheDocument();
  });

  it('renders Settings screen with notification toggles and devices list', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => [
        { id: 'd-1', user_id: 'u-1', device_id: 'dev-desktop-1', device_name: 'Workstation', platform: 'linux', last_seen_at: '2026-11-13T10:00:00Z', created_at: 'now' }
      ]
    });

    const { findByText } = render(<SettingsScreen />);
    expect(await findByText('Floating Companion Mascot')).toBeInTheDocument();
    expect(await findByText('Enable Desktop Notifications')).toBeInTheDocument();
    expect(await findByText('Workstation')).toBeInTheDocument();
  });

  it('handles Phase 9 API calls for behavioral intel, forecasts, multiple futures, and accuracy', async () => {
    global.fetch = vi.fn().mockImplementation((url: string) => {
      if (url.includes('/future/behavior')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            insights: [{ category: 'velocity', headline: 'Velocity is Steady', observation: 'Completes 1.2 tasks/day', evidence: ['10 tasks in 14d'], data_quality: 'GOOD', window_days: 30 }],
            metrics: { completion_rate: 0.8, overdue_rate: 0.1 },
            data_quality: 'GOOD',
            period_start: new Date().toISOString(),
            period_end: new Date().toISOString()
          })
        });
      }
      if (url.includes('/future/forecast') && !url.includes('limit=')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            id: 'f-1',
            horizon: '30d',
            projected_backlog: 5,
            completion_forecast: 15,
            burnout_risk_score: 0.25,
            probability: 0.85,
            confidence: 'HIGH',
            uncertainty_range: { backlog_min: 3, backlog_max: 8, completion_min: 12, completion_max: 18 },
            assumptions: ['Steady inflow'],
            evidence: ['Historical velocity'],
            explanation: 'Sustainable pace projected.',
            created_at: new Date().toISOString()
          })
        });
      }
      if (url.includes('/future/scenarios')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            horizon: '30d',
            current_trajectory: { title: 'Autopilot Path', summary: 'Backlog grows slightly', events: [] },
            improved_trajectory: { title: 'Optimized Path', summary: 'Zero overdue tasks', events: [] },
            alternative_trajectory: { title: 'Pivot Path', summary: 'Scope reduced', events: [] }
          })
        });
      }
      if (url.includes('/future/evaluate')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => [
            { id: 'eval-1', prediction_id: 'p-1', horizon: '24h', predicted_outcome: 'Overdue task', actual_outcome: 'Task completed', status: 'NOT_CONFIRMED', brier_score: 0.72, evaluated_at: new Date().toISOString() }
          ]
        });
      }
      if (url.includes('/future/accuracy')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            total_evaluated: 10,
            overall_accuracy: 0.8,
            brier_calibration_score: 0.08,
            accuracy_by_horizon: { '24h': 0.85, '7d': 0.75 },
            accuracy_by_type: { 'RISK': 0.8 },
            recent_evaluations: []
          })
        });
      }
      if (url.includes('/future/intervention-effectiveness')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            total_interventions: 12,
            accepted_count: 9,
            dismissed_count: 3,
            actions_completed_count: 8,
            acceptance_rate: 0.75,
            action_conversion_rate: 0.67,
            insights: ['High morning responsiveness']
          })
        });
      }
      return Promise.resolve({ ok: true, status: 200, json: async () => ({}) });
    });

    const behavior = await apiService.getBehavioralProfile(30);
    expect(behavior.data_quality).toBe('GOOD');
    expect(behavior.insights[0].headline).toBe('Velocity is Steady');

    const forecast = await apiService.generateLongTermForecast('30d');
    expect(forecast.projected_backlog).toBe(5);
    expect(forecast.confidence).toBe('HIGH');

    const scenarios = await apiService.generateMultipleFutures('30d', 'Clear backlog');
    expect(scenarios.improved_trajectory.title).toBe('Optimized Path');

    const evals = await apiService.evaluatePredictions();
    expect(evals[0].status).toBe('NOT_CONFIRMED');

    const accuracy = await apiService.getPredictionAccuracy();
    expect(accuracy.brier_calibration_score).toBe(0.08);

    const effectiveness = await apiService.getInterventionEffectiveness();
    expect(effectiveness.acceptance_rate).toBe(0.75);
  });

  it('renders Futures screen with Phase 9 tabs and navigation', async () => {
    global.fetch = vi.fn().mockImplementation((url: string) => {
      if (url.includes('/future/predictions')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => [
            {
              id: 'p-1',
              prediction_type: 'RISK',
              title: 'Overdue Surge',
              description: 'Cascading deadline delays.',
              confidence: 'HIGH',
              probability: 0.85,
              time_horizon: '7d',
              evidence: ['Overdue tasks'],
              status: 'ACTIVE',
              created_at: new Date().toISOString()
            }
          ]
        });
      }
      if (url.includes('/future/simulate')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            horizon: '24h',
            scenario: {
              title: 'Probable 24h Trajectory',
              summary: 'Active work packages due',
              events: [{ title: 'Check tasks', description: 'Review worklog', relative_time: '+2h' }]
            }
          })
        });
      }
      if (url.includes('/future/forecast')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            id: 'f-1',
            horizon: '30d',
            projected_backlog: 7,
            completion_forecast: 20,
            burnout_risk_score: 0.2,
            probability: 0.88,
            confidence: 'HIGH',
            uncertainty_range: { backlog_min: 4, backlog_max: 10, completion_min: 15, completion_max: 25 },
            assumptions: ['Linear inflow'],
            evidence: ['Consistent velocity'],
            explanation: 'Healthy task balance projected.',
            created_at: new Date().toISOString()
          })
        });
      }
      return Promise.resolve({ ok: true, status: 200, json: async () => ({}) });
    });

    const { findByText } = render(<FuturesScreen />);
    expect(await findByText('TESS Future Intelligence System')).toBeInTheDocument();
    expect(await findByText('Probable 24h Trajectory')).toBeInTheDocument();
    expect(await findByText('Long-Term Forecast')).toBeInTheDocument();
    expect(await findByText('Multiple Selves')).toBeInTheDocument();
    expect(await findByText('Behavioral Intel')).toBeInTheDocument();
    expect(await findByText('Accuracy & Learning')).toBeInTheDocument();
  });

  it('handles Phase 10 API calls for companion profile, routines, preferences, and memory update', async () => {
    global.fetch = vi.fn().mockImplementation((url: string, options: any = {}) => {
      if (url.includes('/companion/profile')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            preferences: { personality: 'FRIENDLY', current_stage: 1, mascot_theme: 'PURPLE' },
            current_stage: 1,
            stage_name: 'TESS Seed',
            interaction_count: 5,
            active_routines_count: 1,
            total_milestones: 1,
            quiet_mode_active: false,
            personality_description: 'Warm and friendly',
            available_stages: []
          })
        });
      }
      if (url.includes('/companion/preferences')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            personality: options.method === 'PUT' ? JSON.parse(options.body).personality : 'FRIENDLY',
            communication_style: 'BALANCED',
            mascot_theme: 'PURPLE',
            quiet_mode: false,
            current_stage: 1,
            interaction_count: 5
          })
        });
      }
      if (url.includes('/companion/routines')) {
        if (options.method === 'POST') {
          return Promise.resolve({
            ok: true,
            status: 200,
            json: async () => ({
              id: 'r-1',
              user_id: 'u-1',
              routine_name: JSON.parse(options.body).routine_name,
              routine_type: 'MORNING_BRIEFING',
              preferred_time: '08:30',
              days_of_week: ['MON', 'TUE'],
              timezone: 'UTC',
              enabled: true
            })
          });
        }
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => [
            { id: 'r-1', user_id: 'u-1', routine_name: 'Morning Briefing', routine_type: 'MORNING_BRIEFING', preferred_time: '08:30', days_of_week: ['MON'], timezone: 'UTC', enabled: true }
          ]
        });
      }
      if (url.includes('/memories/m-1') && options.method === 'PUT') {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            id: 'm-1',
            user_id: 'u-1',
            category: 'preference',
            content: 'Updated memory content',
            importance: 4,
            is_confirmed: true,
            provenance: 'USER_STATED',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
        });
      }
      return Promise.resolve({ ok: true, status: 200, json: async () => ({}) });
    });

    const profile = await apiService.getCompanionProfile();
    expect(profile.stage_name).toBe('TESS Seed');

    const prefs = await apiService.getCompanionPreferences();
    expect(prefs.personality).toBe('FRIENDLY');

    const updatedPrefs = await apiService.updateCompanionPreferences({ personality: 'CALM' });
    expect(updatedPrefs.personality).toBe('CALM');

    const routines = await apiService.getCompanionRoutines();
    expect(routines[0].routine_name).toBe('Morning Briefing');

    const createdRoutine = await apiService.createCompanionRoutine({
      routine_name: 'Evening Wind-down',
      routine_type: 'EVENING_REVIEW',
      preferred_time: '19:00'
    });
    expect(createdRoutine.routine_name).toBe('Evening Wind-down');

    const updatedMemory = await apiService.updateMemory('m-1', { content: 'Updated memory content', importance: 4 });
    expect(updatedMemory.content).toBe('Updated memory content');
  });

  it('renders Settings screen with Phase 10 companion personality and routines controls', async () => {
    global.fetch = vi.fn().mockImplementation((url: string) => {
      if (url.includes('/devices')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => [
            { id: 'd-1', user_id: 'u-1', device_id: 'dev-desktop-1', device_name: 'Workstation', platform: 'linux', last_seen_at: '2026-11-13T10:00:00Z', created_at: 'now' }
          ]
        });
      }
      if (url.includes('/companion/preferences')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => ({
            personality: 'FRIENDLY',
            communication_style: 'BALANCED',
            mascot_theme: 'PURPLE',
            quiet_mode: false,
            current_stage: 1,
            interaction_count: 5
          })
        });
      }
      if (url.includes('/companion/routines')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => [
            { id: 'r-1', user_id: 'u-1', routine_name: 'Morning Briefing', routine_type: 'MORNING_BRIEFING', preferred_time: '08:30', days_of_week: ['MON', 'TUE', 'WED', 'THU', 'FRI'], timezone: 'UTC', enabled: true }
          ]
        });
      }
      if (url.includes('/companion/milestones')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => [
            { id: 'm-1', user_id: 'u-1', milestone_type: 'FIRST_ROUTINE', title: 'First Personal Routine', description: 'Established morning briefing', stage_unlocked: 1, achieved_at: new Date().toISOString() }
          ]
        });
      }
      return Promise.resolve({ ok: true, status: 200, json: async () => [] });
    });

    const { findByText } = render(<SettingsScreen />);
    expect(await findByText('Living AI Companion & Personality')).toBeInTheDocument();
    expect(await findByText('Adaptive Personality Preset')).toBeInTheDocument();
    expect(await findByText(/Personal Routines Intelligence/)).toBeInTheDocument();
  });
});
