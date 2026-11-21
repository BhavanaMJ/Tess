import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { TasksScreen } from '../screens/TasksScreen';
import { MascotProvider } from '../contexts/MascotContext';
import { apiService } from '../services/api';
import { ProductivityTask, ProductivitySummary } from '../types';

// Mock apiService
vi.mock('../services/api', () => ({
  apiService: {
    getProductivityTasks: vi.fn(),
    getProductivitySummary: vi.fn(),
    syncOpenProject: vi.fn()
  }
}));

describe('Phase D4.2 — Active Tasks Workspace Tests', () => {
  const mockSummary: ProductivitySummary = {
    total_active: 3,
    overdue: 1,
    due_today: 1,
    due_this_week: 1,
    completed_recently: 4
  };

  const mockTasks: ProductivityTask[] = [
    {
      id: 'task-1',
      user_id: 'user-1',
      source: 'openproject',
      external_id: '101',
      title: 'Fix Authentication Session Timeout',
      description: 'Implement refresh token auto-rotation and session recovery.',
      status: 'IN PROGRESS',
      priority: 'HIGH',
      project: 'Core Platform',
      assignee: 'Bhavana',
      due_date: new Date(Date.now() - 86400000).toISOString(), // Overdue
      completion_percent: 60,
      created_at: new Date(Date.now() - 172800000).toISOString()
    },
    {
      id: 'task-2',
      user_id: 'user-1',
      source: 'openproject',
      external_id: '102',
      title: 'Design Trajectory Simulation Visualizer',
      description: 'Build probabilistic timeline charts with risk indicators.',
      status: 'IN SPECIFICATION',
      priority: 'NORMAL',
      project: 'Future Engine',
      assignee: 'Bhavana',
      due_date: new Date(Date.now() + 86400000 * 2).toISOString(),
      completion_percent: 30,
      created_at: new Date(Date.now() - 86400000).toISOString()
    },
    {
      id: 'task-3',
      user_id: 'user-1',
      source: 'openproject',
      external_id: '103',
      title: 'Sync Productivity Work Packages API',
      description: 'Connect OpenProject backend with sync webhook listener.',
      status: 'DEVELOPED',
      priority: 'LOW',
      project: 'Integrations',
      assignee: 'System',
      due_date: new Date().toISOString(), // Today
      completion_percent: 100,
      created_at: new Date(Date.now() - 43200000).toISOString()
    }
  ];

  beforeEach(() => {
    vi.clearAllMocks();
    (apiService.getProductivityTasks as any).mockResolvedValue(mockTasks);
    (apiService.getProductivitySummary as any).mockResolvedValue(mockSummary);
    (apiService.syncOpenProject as any).mockResolvedValue({
      status: 'success',
      synced_tasks: 3
    });

    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn().mockImplementation(() => Promise.resolve())
      }
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const renderTasks = (onNavigateToChat?: (prompt?: string) => void) => {
    return render(
      <MascotProvider>
        <TasksScreen onNavigateToChat={onNavigateToChat} />
      </MascotProvider>
    );
  };

  it('renders Active Tasks workspace with metrics overview and task cards', async () => {
    renderTasks();

    expect(screen.getByTestId('tasks-screen-container')).toBeInTheDocument();

    await waitFor(() => {
      expect(apiService.getProductivityTasks).toHaveBeenCalled();
      expect(apiService.getProductivitySummary).toHaveBeenCalled();
    });

    // Overview cards
    expect(screen.getByText('Active Packages')).toBeInTheDocument();
    expect(screen.getByText('Overdue')).toBeInTheDocument();
    expect(screen.getAllByText('Due Today').length).toBeGreaterThan(0);

    // Task items
    expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    expect(screen.getByText('#101')).toBeInTheDocument();
    expect(screen.getByText('Design Trajectory Simulation Visualizer')).toBeInTheDocument();
    expect(screen.getByText('#102')).toBeInTheDocument();
    expect(screen.getByText('Sync Productivity Work Packages API')).toBeInTheDocument();
    expect(screen.getByText('#103')).toBeInTheDocument();
  });

  it('filters tasks using the search input', async () => {
    renderTasks();

    await waitFor(() => {
      expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    });

    const searchInput = screen.getByPlaceholderText(/Search work packages/i);
    fireEvent.change(searchInput, { target: { value: 'Trajectory' } });

    expect(screen.getByText('Design Trajectory Simulation Visualizer')).toBeInTheDocument();
    expect(screen.queryByText('Fix Authentication Session Timeout')).not.toBeInTheDocument();
    expect(screen.queryByText('Sync Productivity Work Packages API')).not.toBeInTheDocument();
  });

  it('filters tasks by clicking overview metrics cards', async () => {
    renderTasks();

    await waitFor(() => {
      expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    });

    // Click Overdue card
    const overdueCard = screen.getByText('Overdue').closest('button');
    expect(overdueCard).toBeInTheDocument();
    fireEvent.click(overdueCard!);

    // Only task-1 is overdue
    expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    expect(screen.queryByText('Design Trajectory Simulation Visualizer')).not.toBeInTheDocument();
  });

  it('filters tasks by priority dropdown', async () => {
    renderTasks();

    await waitFor(() => {
      expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    });

    const prioritySelect = screen.getByLabelText(/Filter priority/i);
    fireEvent.change(prioritySelect, { target: { value: 'HIGH' } });

    expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    expect(screen.queryByText('Design Trajectory Simulation Visualizer')).not.toBeInTheDocument();
    expect(screen.queryByText('Sync Productivity Work Packages API')).not.toBeInTheDocument();
  });

  it('sorts tasks using the sort dropdown', async () => {
    renderTasks();

    await waitFor(() => {
      expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    });

    const sortSelect = screen.getByLabelText(/Sort packages/i);
    fireEvent.change(sortSelect, { target: { value: 'TITLE' } });

    // In alphabetical order: Design..., Fix..., Sync...
    const cards = screen.getAllByTestId(/task-card-/);
    expect(cards[0]).toHaveTextContent('Design Trajectory Simulation Visualizer');
    expect(cards[1]).toHaveTextContent('Fix Authentication Session Timeout');
    expect(cards[2]).toHaveTextContent('Sync Productivity Work Packages API');
  });

  it('opens and closes task detail modal when a task card is clicked', async () => {
    renderTasks();

    await waitFor(() => {
      expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    });

    // Click task-1 card
    fireEvent.click(screen.getByTestId('task-card-task-1'));

    // Modal details
    expect(screen.getByText('Work Package Description')).toBeInTheDocument();
    expect(screen.getAllByText('Implement refresh token auto-rotation and session recovery.').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Core Platform').length).toBeGreaterThan(0);
    expect(screen.getByText('60%')).toBeInTheDocument();

    // Copy prompt
    const copyPromptBtn = screen.getByTitle('Copy prompt with task details');
    fireEvent.click(copyPromptBtn);
    expect(navigator.clipboard.writeText).toHaveBeenCalled();

    // Close modal
    const closeBtn = screen.getByTitle('Close dialog');
    fireEvent.click(closeBtn);

    await waitFor(() => {
      expect(screen.queryByText('Work Package Description')).not.toBeInTheDocument();
    });
  });

  it('handles "Discuss with TESS" action from task detail modal', async () => {
    const mockNavigate = vi.fn();
    renderTasks(mockNavigate);

    await waitFor(() => {
      expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    });

    fireEvent.click(screen.getByTestId('task-card-task-1'));

    const discussBtn = screen.getByText('Discuss with TESS');
    fireEvent.click(discussBtn);

    expect(mockNavigate).toHaveBeenCalledWith(
      expect.stringContaining('Fix Authentication Session Timeout')
    );
  });

  it('executes OpenProject sync and displays success message', async () => {
    renderTasks();

    await waitFor(() => {
      expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    });

    const syncBtn = screen.getByTitle('Synchronize tasks from OpenProject');
    fireEvent.click(syncBtn);

    await waitFor(() => {
      expect(apiService.syncOpenProject).toHaveBeenCalled();
      expect(screen.getByText(/Synchronized successfully/i)).toBeInTheDocument();
    });
  });

  it('handles OpenProject sync error gracefully', async () => {
    (apiService.syncOpenProject as any).mockRejectedValueOnce(new Error('OpenProject host unreachable'));

    renderTasks();

    await waitFor(() => {
      expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    });

    const syncBtn = screen.getByTitle('Synchronize tasks from OpenProject');
    fireEvent.click(syncBtn);

    await waitFor(() => {
      expect(screen.getByText(/OpenProject synchronization failed: OpenProject host unreachable/i)).toBeInTheDocument();
    });
  });

  it('displays empty state when no tasks match filters and provides reset', async () => {
    renderTasks();

    await waitFor(() => {
      expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
    });

    const searchInput = screen.getByPlaceholderText(/Search work packages/i);
    fireEvent.change(searchInput, { target: { value: 'Nonexistent query 99999' } });

    expect(screen.getByText('No packages match your active filters')).toBeInTheDocument();

    // Click Reset Filters
    const resetBtn = screen.getByText('Reset Filters');
    fireEvent.click(resetBtn);

    expect(screen.getByText('Fix Authentication Session Timeout')).toBeInTheDocument();
  });
});
