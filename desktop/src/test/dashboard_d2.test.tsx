import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { HomeScreen } from '../screens/HomeScreen';
import { DashboardWelcome } from '../components/dashboard/DashboardWelcome';
import { ProductivityOverview } from '../components/dashboard/ProductivityOverview';
import { PriorityWorkspace } from '../components/dashboard/PriorityWorkspace';
import { ProductivityTrends } from '../components/dashboard/ProductivityTrends';
import { FutureTrajectoryPreview } from '../components/dashboard/FutureTrajectoryPreview';
import { InterventionPreview } from '../components/dashboard/InterventionPreview';
import { AgentActivityPreview } from '../components/dashboard/AgentActivityPreview';
import { DashboardQuickActions } from '../components/dashboard/DashboardQuickActions';
import { AuthProvider } from '../contexts/AuthContext';
import { MascotProvider } from '../contexts/MascotContext';
import { apiService } from '../services/api';
import { ProductivityTask, FuturePrediction, InterventionResponse, AgentPlan } from '../types';

describe('Phase D2 — Command Home: Live Command Centre Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  const renderWithProviders = (ui: React.ReactElement) => {
    return render(
      <AuthProvider>
        <MascotProvider>{ui}</MascotProvider>
      </AuthProvider>
    );
  };

  const sampleTasks: ProductivityTask[] = [
    {
      id: 'task-1',
      user_id: 'user-1',
      source: 'openproject',
      external_id: 'OP-101',
      title: 'Submit Milestone Report',
      status: 'IN_PROGRESS',
      priority: 'High',
      project: 'Core Platform',
      due_date: '2026-11-20T10:00:00Z', // Overdue
      created_at: '2026-11-15T10:00:00Z'
    },
    {
      id: 'task-2',
      user_id: 'user-1',
      source: 'openproject',
      external_id: 'OP-102',
      title: 'Review Security Patches',
      status: 'CLOSED',
      priority: 'Normal',
      project: 'Security',
      created_at: '2026-11-16T10:00:00Z'
    }
  ];

  const samplePredictions: FuturePrediction[] = [
    {
      id: 'pred-1',
      title: 'High workload risk in upcoming sprint',
      description: 'Probability of deadline slippage exceeds nominal threshold.',
      prediction_type: 'RISK',
      probability: 0.78,
      confidence: 'HIGH',
      time_horizon: '24h',
      evidence: ['3 overdue work packages', 'Active velocity slowdown'],
      reasoning: 'Consecutive backlog expansion detected without task closure.',
      status: 'ACTIVE',
      created_at: '2026-11-20T10:00:00Z'
    }
  ];

  const sampleInterventions: InterventionResponse[] = [
    {
      id: 'inv-1',
      prediction_id: 'pred-1',
      title: 'Rebalance sprint priorities',
      message: 'Postpone low-priority tasks to focus on the security milestone.',
      suggested_action: 'Reschedule OP-103 to next Tuesday',
      priority: 'URGENT',
      status: 'SENT',
      created_at: '2026-11-20T11:00:00Z'
    }
  ];

  const samplePlans: AgentPlan[] = [
    {
      id: 'plan-1',
      user_id: 'user-1',
      objective: 'Reschedule backlog tasks on OpenProject',
      status: 'READY',
      steps: [
        {
          id: 'step-1',
          plan_id: 'plan-1',
          step_order: 1,
          tool_name: 'openproject_reschedule',
          action_type: 'UPDATE',
          parameters: { task_id: 'OP-103', new_date: '2026-11-25' },
          risk_level: 'MEDIUM',
          status: 'PENDING'
        }
      ]
    }
  ];

  // ============================================================================
  // 1. DashboardWelcome Component
  // ============================================================================
  it('renders DashboardWelcome with time-aware greeting and contextual message', () => {
    const onNavigate = vi.fn();
    const onOpenCommandPalette = vi.fn();

    renderWithProviders(
      <DashboardWelcome
        user={{ id: 'u1', email: 'alice@example.com' }}
        mascotState="ATTENTION"
        overdueCount={1}
        activeInterventionsCount={1}
        hasRiskPredictions={true}
        onNavigate={onNavigate}
        onOpenCommandPalette={onOpenCommandPalette}
      />
    );

    expect(screen.getByText(/alice/i)).toBeInTheDocument();
    expect(screen.getByText(/Personal AI Command Centre/i)).toBeInTheDocument();
    expect(screen.getByText(/TESS detected a potential divergence in your trajectory/i)).toBeInTheDocument();

    // Quick buttons
    const talkBtn = screen.getByText('Talk to TESS');
    fireEvent.click(talkBtn);
    expect(onNavigate).toHaveBeenCalledWith('chat');

    const simBtn = screen.getByText('Simulate Trajectory');
    fireEvent.click(simBtn);
    expect(onNavigate).toHaveBeenCalledWith('futures');

    const searchBtn = screen.getByText(/Command Search/i);
    fireEvent.click(searchBtn);
    expect(onOpenCommandPalette).toHaveBeenCalledTimes(1);
  });

  // ============================================================================
  // 2. ProductivityOverview Component
  // ============================================================================
  it('renders ProductivityOverview with real metric values and navigates on click', () => {
    const onNavigate = vi.fn();
    render(
      <ProductivityOverview
        summary={{
          total_active: 5,
          overdue: 2,
          due_today: 1,
          due_this_week: 3,
          completed_recently: 4
        }}
        tasks={sampleTasks}
        onNavigate={onNavigate}
      />
    );

    expect(screen.getByText('ACTIVE TASKS')).toBeInTheDocument();
    expect(screen.getByText('5')).toBeInTheDocument();
    expect(screen.getByText('OVERDUE')).toBeInTheDocument();
    expect(screen.getByText('2')).toBeInTheDocument();
    expect(screen.getByText('DUE TODAY')).toBeInTheDocument();
    expect(screen.getByText('1')).toBeInTheDocument();
    expect(screen.getByText('DUE THIS WEEK')).toBeInTheDocument();
    expect(screen.getByText('3')).toBeInTheDocument();
    expect(screen.getByText('COMPLETED')).toBeInTheDocument();
    expect(screen.getByText('4')).toBeInTheDocument();

    // Click active tasks card
    fireEvent.click(screen.getByText('ACTIVE TASKS'));
    expect(onNavigate).toHaveBeenCalledWith('tasks');
  });

  // ============================================================================
  // 3. PriorityWorkspace (My Day) Component
  // ============================================================================
  it('renders PriorityWorkspace with urgent items from interventions and overdue tasks', () => {
    const onNavigate = vi.fn();
    render(
      <PriorityWorkspace
        tasks={sampleTasks}
        interventions={sampleInterventions}
        plans={samplePlans}
        onNavigate={onNavigate}
      />
    );

    expect(screen.getByText('MY DAY & PRIORITY WORKSPACE')).toBeInTheDocument();
    expect(screen.getByText('Rebalance sprint priorities')).toBeInTheDocument();
    expect(screen.getByText('Submit Milestone Report')).toBeInTheDocument();
    expect(screen.getByText('Reschedule backlog tasks on OpenProject')).toBeInTheDocument();

    // Click review intervention
    fireEvent.click(screen.getByText('Review Intervention'));
    expect(onNavigate).toHaveBeenCalledWith('interventions');
  });

  it('renders PriorityWorkspace empty state when there are no urgent items', () => {
    render(
      <PriorityWorkspace
        tasks={[]}
        interventions={[]}
        plans={[]}
        onNavigate={vi.fn()}
      />
    );

    expect(screen.getByText(/You are completely caught up!/i)).toBeInTheDocument();
  });

  // ============================================================================
  // 4. ProductivityTrends Component
  // ============================================================================
  it('calculates and renders ProductivityTrends completion velocity and priority distribution', () => {
    render(
      <ProductivityTrends
        summary={{
          total_active: 1,
          overdue: 1,
          due_today: 0,
          due_this_week: 0,
          completed_recently: 1
        }}
        tasks={sampleTasks}
      />
    );

    expect(screen.getByText(/Productivity Velocity & Distribution/i)).toBeInTheDocument();
    expect(screen.getByText('50%')).toBeInTheDocument(); // 1 closed out of 2 tasks = 50%
    expect(screen.getByText(/Closed \(1\)/i)).toBeInTheDocument();
    expect(screen.getByText(/Active \(1\)/i)).toBeInTheDocument();
    expect(screen.getByText(/Overdue \(1\)/i)).toBeInTheDocument();
  });

  // ============================================================================
  // 5. FutureTrajectoryPreview Component
  // ============================================================================
  it('renders FutureTrajectoryPreview with philosophy banner and prediction details', () => {
    const onNavigate = vi.fn();
    render(
      <FutureTrajectoryPreview
        predictions={samplePredictions}
        onNavigate={onNavigate}
      />
    );

    expect(
      screen.getByText(/"Show me the most likely version of myself that I'm currently creating."/i)
    ).toBeInTheDocument();
    expect(screen.getByText('High workload risk in upcoming sprint')).toBeInTheDocument();
    expect(screen.getByText('78% Prob')).toBeInTheDocument();

    // Expand details
    const detailsBtn = screen.getByText('Details');
    fireEvent.click(detailsBtn);
    expect(
      screen.getByText(/Consecutive backlog expansion detected without task closure/i)
    ).toBeInTheDocument();

    // Explore Engine button
    fireEvent.click(screen.getByText('Explore Engine'));
    expect(onNavigate).toHaveBeenCalledWith('futures');
  });

  // ============================================================================
  // 6. InterventionPreview Component
  // ============================================================================
  it('renders InterventionPreview with active items and response action', () => {
    const onNavigate = vi.fn();
    render(
      <InterventionPreview
        interventions={sampleInterventions}
        onNavigate={onNavigate}
      />
    );

    expect(screen.getByText('Proactive Interventions')).toBeInTheDocument();
    expect(screen.getByText('Rebalance sprint priorities')).toBeInTheDocument();
    expect(screen.getByText('Respond')).toBeInTheDocument();

    fireEvent.click(screen.getByText('Respond'));
    expect(onNavigate).toHaveBeenCalledWith('interventions');
  });

  // ============================================================================
  // 7. AgentActivityPreview Component
  // ============================================================================
  it('renders AgentActivityPreview with active plan status and objective', () => {
    const onNavigate = vi.fn();
    render(
      <AgentActivityPreview
        plans={samplePlans}
        onNavigate={onNavigate}
      />
    );

    expect(screen.getByText('Agent Workflows & Safeguards')).toBeInTheDocument();
    expect(screen.getByText('Reschedule backlog tasks on OpenProject')).toBeInTheDocument();
    expect(screen.getByText('READY')).toBeInTheDocument();

    fireEvent.click(screen.getByText('Agent Console'));
    expect(onNavigate).toHaveBeenCalledWith('agent');
  });

  // ============================================================================
  // 8. DashboardQuickActions Component
  // ============================================================================
  it('renders DashboardQuickActions and supports synchronizing tasks', async () => {
    vi.spyOn(apiService, 'syncOpenProject').mockResolvedValue({ status: 'ok', synced_tasks: 2 });
    const onRefreshData = vi.fn();

    render(
      <DashboardQuickActions
        onNavigate={vi.fn()}
        onRefreshData={onRefreshData}
      />
    );

    const syncBtn = screen.getByText('Sync Tasks');
    fireEvent.click(syncBtn);

    await waitFor(() => {
      expect(apiService.syncOpenProject).toHaveBeenCalled();
      expect(onRefreshData).toHaveBeenCalled();
    });
  });

  // ============================================================================
  // 9. HomeScreen Full Integration Test
  // ============================================================================
  it('loads real data and renders complete Command Home dashboard', async () => {
    vi.spyOn(apiService, 'getProductivitySummary').mockResolvedValue({
      total_active: 5,
      overdue: 1,
      due_today: 1,
      due_this_week: 2,
      completed_recently: 3
    });
    vi.spyOn(apiService, 'getProductivityTasks').mockResolvedValue(sampleTasks);
    vi.spyOn(apiService, 'getFuturePredictions').mockResolvedValue(samplePredictions);
    vi.spyOn(apiService, 'getInterventions').mockResolvedValue(sampleInterventions);
    vi.spyOn(apiService, 'getAgentPlans').mockResolvedValue(samplePlans);

    const onNavigate = vi.fn();
    renderWithProviders(<HomeScreen onNavigate={onNavigate} />);

    // Wait for data load
    await waitFor(() => {
      expect(screen.getByText('Personal AI Command Centre')).toBeInTheDocument();
    });

    // Check presence of key sections
    expect(screen.getByText('MY DAY & PRIORITY WORKSPACE')).toBeInTheDocument();
    expect(screen.getByText('Future Trajectory & Simulation')).toBeInTheDocument();
    expect(screen.getByText('Proactive Interventions')).toBeInTheDocument();
    expect(screen.getByText('Agent Workflows & Safeguards')).toBeInTheDocument();
  });

  it('handles partial failures gracefully without crashing dashboard', async () => {
    vi.spyOn(apiService, 'getProductivitySummary').mockResolvedValue({
      total_active: 2,
      overdue: 0,
      due_today: 0,
      due_this_week: 1,
      completed_recently: 1
    });
    vi.spyOn(apiService, 'getProductivityTasks').mockResolvedValue(sampleTasks);
    // Simulate failure on predictions and agent plans
    vi.spyOn(apiService, 'getFuturePredictions').mockRejectedValue(new Error('Prediction service timeout'));
    vi.spyOn(apiService, 'getInterventions').mockResolvedValue([]);
    vi.spyOn(apiService, 'getAgentPlans').mockRejectedValue(new Error('Agent service down'));

    renderWithProviders(<HomeScreen onNavigate={vi.fn()} />);

    // Successfully renders available sections
    await waitFor(() => {
      expect(screen.getByText('Personal AI Command Centre')).toBeInTheDocument();
    });
    expect(screen.getByText('MY DAY & PRIORITY WORKSPACE')).toBeInTheDocument();
  });
});

