import React from 'react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { AgentActivityScreen } from '../screens/AgentActivityScreen';
import { MascotProvider } from '../contexts/MascotContext';
import { apiService } from '../services/api';
import { AgentPlan } from '../types';

const mockPlans: AgentPlan[] = [
  {
    id: 'plan-101',
    user_id: 'user-test',
    objective: 'Update worklog: 2 hours on task #101',
    status: 'READY',
    created_at: '2026-11-22T10:00:00Z',
    steps: [
      {
        id: 'step-101-1',
        plan_id: 'plan-101',
        step_order: 1,
        tool_name: 'openproject_update_worklog',
        action_type: 'UPDATE_WORKLOG',
        parameters: { task_id: '101', hours: 2, comment: 'Logged 2 hours' },
        risk_level: 'MEDIUM',
        status: 'PENDING',
        confirmation: {
          id: 'conf-1',
          status: 'PENDING',
          summary: 'Update OpenProject worklog with 2 hours on task #101',
          expires_at: '2026-11-22T10:30:00Z'
        }
      }
    ]
  },
  {
    id: 'plan-102',
    user_id: 'user-test',
    objective: 'Prepare briefing notes for meeting tomorrow',
    status: 'SUCCESS',
    created_at: '2026-11-22T09:00:00Z',
    completed_at: '2026-11-22T09:02:00Z',
    steps: [
      {
        id: 'step-102-1',
        plan_id: 'plan-102',
        step_order: 1,
        tool_name: 'calendar_list_events',
        action_type: 'CALENDAR_LIST',
        parameters: { days_ahead: 2 },
        risk_level: 'LOW',
        status: 'SUCCESS',
        result: { events: [{ title: 'Sync' }] }
      },
      {
        id: 'step-102-2',
        plan_id: 'plan-102',
        step_order: 2,
        tool_name: 'gmail_read',
        action_type: 'GMAIL_READ',
        parameters: { query: 'meeting' },
        risk_level: 'LOW',
        status: 'SUCCESS',
        result: { messages_count: 3 }
      }
    ]
  },
  {
    id: 'plan-103',
    user_id: 'user-test',
    objective: 'Browse https://github.com for updates',
    status: 'FAILED',
    created_at: '2026-11-22T08:00:00Z',
    steps: [
      {
        id: 'step-103-1',
        plan_id: 'plan-103',
        step_order: 1,
        tool_name: 'browser_navigate',
        action_type: 'BROWSER_NAVIGATE',
        parameters: { url: 'https://github.com' },
        risk_level: 'LOW',
        status: 'FAILED'
      }
    ]
  }
];

describe('Phase D5.1 — Agent Activity Workspace Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.spyOn(apiService, 'getAgentPlans').mockResolvedValue(mockPlans);
    vi.spyOn(apiService, 'createAgentObjective').mockResolvedValue({
      id: 'plan-new',
      user_id: 'user-test',
      objective: 'Send email to team@project.org',
      status: 'READY',
      created_at: new Date().toISOString(),
      steps: [
        {
          id: 'step-new-1',
          plan_id: 'plan-new',
          step_order: 1,
          tool_name: 'gmail_send_email',
          action_type: 'GMAIL_SEND',
          parameters: { to: 'team@project.org' },
          risk_level: 'HIGH',
          status: 'PENDING',
          confirmation: {
            id: 'conf-new-1',
            status: 'PENDING',
            summary: 'Send email to team@project.org'
          }
        }
      ]
    });
    vi.spyOn(apiService, 'confirmAgentPlan').mockResolvedValue({ status: 'success' });
    vi.spyOn(apiService, 'executeAgentPlan').mockResolvedValue({ status: 'SUCCESS' });
    vi.spyOn(apiService, 'cancelAgentPlan').mockResolvedValue({ status: 'cancelled' });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('renders Agent Activity workspace with metrics overview cards and plans list', async () => {
    render(
      <MascotProvider>
        <AgentActivityScreen />
      </MascotProvider>
    );

    // Check Metrics Cards
    expect(await screen.findByText('Total Plans')).toBeInTheDocument();
    expect(screen.getByText('Awaiting Action')).toBeInTheDocument();
    expect(screen.getByText('Executing Now')).toBeInTheDocument();
    expect(screen.getByText('Completed')).toBeInTheDocument();

    // Check Plan Objectives rendered
    expect((await screen.findAllByText('Update worklog: 2 hours on task #101')).length).toBeGreaterThan(0);
    expect(screen.getByText('Prepare briefing notes for meeting tomorrow')).toBeInTheDocument();
    expect(screen.getByText('Browse https://github.com for updates')).toBeInTheDocument();
  });

  it('filters plans by status pills (e.g. Completed, Failed)', async () => {
    render(
      <MascotProvider>
        <AgentActivityScreen />
      </MascotProvider>
    );

    await screen.findByText('Prepare briefing notes for meeting tomorrow');

    // Click Success tab filter
    const successTab = screen.getByRole('button', { name: /Success/i });
    fireEvent.click(successTab);

    // Completed plan should be visible
    expect(screen.getByText('Prepare briefing notes for meeting tomorrow')).toBeInTheDocument();
    // Non-success plan should be filtered out
    expect(screen.queryByText('Browse https://github.com for updates')).not.toBeInTheDocument();
  });

  it('searches plans by objective or tool name in filter bar', async () => {
    render(
      <MascotProvider>
        <AgentActivityScreen />
      </MascotProvider>
    );

    await screen.findByText('Browse https://github.com for updates');

    const searchInput = screen.getByPlaceholderText(/Search by objective, tool, or plan ID/i);
    fireEvent.change(searchInput, { target: { value: 'github' } });

    expect(screen.getByText('Browse https://github.com for updates')).toBeInTheDocument();
    expect(screen.queryByText('Prepare briefing notes for meeting tomorrow')).not.toBeInTheDocument();
  });

  it('dispatches autonomous objective creation and populates input using starter pill', async () => {
    render(
      <MascotProvider>
        <AgentActivityScreen />
      </MascotProvider>
    );

    await screen.findByText('Prepare briefing notes for meeting tomorrow');

    // Click starter button
    const starterButton = screen.getByText('Send email to team@project.org');
    fireEvent.click(starterButton);

    const input = screen.getByPlaceholderText(/Update worklog/i) as HTMLInputElement;
    expect(input.value).toBe('Send email to team@project.org');

    // Submit form
    const generateBtn = screen.getByRole('button', { name: /Generate Agent Plan/i });
    fireEvent.click(generateBtn);

    await waitFor(() => {
      expect(apiService.createAgentObjective).toHaveBeenCalledWith('Send email to team@project.org');
    });

    expect(await screen.findByText(/Plan created successfully/i)).toBeInTheDocument();
  });

  it('confirms action safeguards when "Confirm Action" is clicked', async () => {
    render(
      <MascotProvider>
        <AgentActivityScreen />
      </MascotProvider>
    );

    await screen.findByText('Prepare briefing notes for meeting tomorrow');

    // Find and click Confirm Action in inspector
    const confirmButtons = screen.getAllByRole('button', { name: /Confirm/i });
    fireEvent.click(confirmButtons[0]);

    await waitFor(() => {
      expect(apiService.confirmAgentPlan).toHaveBeenCalledWith('plan-101');
    });

    expect(await screen.findByText(/Action confirmed. You can now execute the plan./i)).toBeInTheDocument();
  });

  it('executes autonomous plan and updates status when "Execute Plan" is clicked', async () => {
    render(
      <MascotProvider>
        <AgentActivityScreen />
      </MascotProvider>
    );

    await screen.findByText('Prepare briefing notes for meeting tomorrow');

    const executeBtn = screen.getByRole('button', { name: /Execute Plan/i });
    fireEvent.click(executeBtn);

    await waitFor(() => {
      expect(apiService.executeAgentPlan).toHaveBeenCalledWith('plan-101');
    });

    expect(await screen.findByText(/Execution finished with status: SUCCESS/i)).toBeInTheDocument();
  });

  it('cancels an active plan when "Cancel Plan" is clicked', async () => {
    render(
      <MascotProvider>
        <AgentActivityScreen />
      </MascotProvider>
    );

    await screen.findByText('Prepare briefing notes for meeting tomorrow');

    const cancelBtn = screen.getByRole('button', { name: /Cancel Plan/i });
    fireEvent.click(cancelBtn);

    await waitFor(() => {
      expect(apiService.cancelAgentPlan).toHaveBeenCalledWith('plan-101');
    });

    expect(await screen.findByText(/Plan cancelled./i)).toBeInTheDocument();
  });

  it('opens and closes the detailed execution timeline modal', async () => {
    render(
      <MascotProvider>
        <AgentActivityScreen />
      </MascotProvider>
    );

    await screen.findByText('Prepare briefing notes for meeting tomorrow');

    // Click Timeline link on the card
    const timelineLink = screen.getAllByRole('button', { name: /Timeline/i })[0];
    fireEvent.click(timelineLink);

    // Modal should be open
    expect(await screen.findByText(/Execution Plan Steps/i)).toBeInTheDocument();
    expect(screen.getByText(/Audited by TESS Safety Layer/i)).toBeInTheDocument();

    // Close modal
    const closeBtn = screen.getByRole('button', { name: 'Close' });
    fireEvent.click(closeBtn);

    await waitFor(() => {
      expect(screen.queryByText(/Audited by TESS Safety Layer/i)).not.toBeInTheDocument();
    });
  });

  it('displays error alert when plan generation fails', async () => {
    vi.spyOn(apiService, 'createAgentObjective').mockRejectedValueOnce(
      new Error('Unsupported agent objective')
    );

    render(
      <MascotProvider>
        <AgentActivityScreen />
      </MascotProvider>
    );

    await screen.findByText('Prepare briefing notes for meeting tomorrow');

    const input = screen.getByPlaceholderText(/Update worklog/i);
    fireEvent.change(input, { target: { value: 'Fly to the moon' } });

    const generateBtn = screen.getByRole('button', { name: /Generate Agent Plan/i });
    fireEvent.click(generateBtn);

    expect(await screen.findByText('Unsupported agent objective')).toBeInTheDocument();
  });
});
