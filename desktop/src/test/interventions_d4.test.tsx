import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { InterventionsScreen } from '../screens/InterventionsScreen';
import { MascotProvider } from '../contexts/MascotContext';
import { apiService } from '../services/api';
import { InterventionResponse } from '../types';

// Mock apiService
vi.mock('../services/api', () => ({
  apiService: {
    getInterventions: vi.fn(),
    respondIntervention: vi.fn(),
    createAgentObjective: vi.fn()
  }
}));

describe('Phase D4.4 — Interventions Workspace Tests', () => {
  const mockInterventions: InterventionResponse[] = [
    {
      id: 'inv-1',
      prediction_id: 'p-1',
      title: 'Unlogged Hours Alert',
      message: 'You have not logged hours for today on OpenProject work package #WP-104.',
      suggested_action: 'Update work package log with 2.5 hours',
      priority: 'HIGH',
      status: 'SENT',
      created_at: new Date().toISOString()
    },
    {
      id: 'inv-2',
      prediction_id: 'p-2',
      title: 'Burnout Risk Warning',
      message: 'Sustained late evening code commits detected over consecutive days.',
      suggested_action: 'Schedule a 45-minute focus recovery buffer tomorrow morning',
      priority: 'NORMAL',
      status: 'SENT',
      created_at: new Date(Date.now() - 3600000).toISOString()
    },
    {
      id: 'inv-3',
      prediction_id: 'p-3',
      title: 'Sprint Backlog Scope Creep',
      message: 'Scope expansion detected without revised milestone deadline.',
      suggested_action: 'Defer non-essential ticket to next iteration',
      priority: 'LOW',
      status: 'ACTED',
      created_at: new Date(Date.now() - 86400000).toISOString()
    }
  ];

  beforeEach(() => {
    vi.clearAllMocks();
    (apiService.getInterventions as any).mockResolvedValue(mockInterventions);
    (apiService.respondIntervention as any).mockResolvedValue({ status: 'ok' });
    (apiService.createAgentObjective as any).mockResolvedValue({ id: 'plan-1' });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const renderInterventions = (onNavigate = vi.fn()) => {
    return render(
      <MascotProvider>
        <InterventionsScreen onNavigate={onNavigate} />
      </MascotProvider>
    );
  };

  it('renders Interventions workspace with metrics cards and active alerts', async () => {
    renderInterventions();

    expect(screen.getByTestId('interventions-screen-container')).toBeInTheDocument();

    await waitFor(() => {
      expect(apiService.getInterventions).toHaveBeenCalled();
    });

    // Metrics cards
    expect(screen.getByText('Active Alerts')).toBeInTheDocument();
    expect(screen.getByText('Resolved Fixes')).toBeInTheDocument();
    expect(screen.getByText('Total History')).toBeInTheDocument();

    // Active intervention cards
    expect(screen.getByText('Unlogged Hours Alert')).toBeInTheDocument();
    expect(screen.getByText('Burnout Risk Warning')).toBeInTheDocument();
    expect(screen.getAllByText('FIX IT WITH AGENT').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Later').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Dismiss').length).toBeGreaterThan(0);
  });

  it('dispatches agent objective when "FIX IT WITH AGENT" is clicked', async () => {
    const onNavigate = vi.fn();
    renderInterventions(onNavigate);

    await waitFor(() => {
      expect(screen.getByText('Unlogged Hours Alert')).toBeInTheDocument();
    });

    const fixItButtons = screen.getAllByText('FIX IT WITH AGENT');
    fireEvent.click(fixItButtons[0]);

    await waitFor(() => {
      expect(apiService.createAgentObjective).toHaveBeenCalledWith(
        expect.stringContaining('Unlogged Hours Alert')
      );
      expect(apiService.respondIntervention).toHaveBeenCalledWith('inv-1', 'ACTED');
    });
  });

  it('handles "Later" action to postpone intervention', async () => {
    renderInterventions();

    await waitFor(() => {
      expect(screen.getByText('Unlogged Hours Alert')).toBeInTheDocument();
    });

    const laterButtons = screen.getAllByText('Later');
    fireEvent.click(laterButtons[0]);

    await waitFor(() => {
      expect(apiService.respondIntervention).toHaveBeenCalledWith('inv-1', 'LATER');
    });
  });

  it('handles "Dismiss" action to dismiss intervention', async () => {
    renderInterventions();

    await waitFor(() => {
      expect(screen.getByText('Unlogged Hours Alert')).toBeInTheDocument();
    });

    const dismissButtons = screen.getAllByText('Dismiss');
    fireEvent.click(dismissButtons[0]);

    await waitFor(() => {
      expect(apiService.respondIntervention).toHaveBeenCalledWith('inv-1', 'DISMISS');
    });
  });

  it('opens rationale detail modal when "Rationale Details" is clicked', async () => {
    renderInterventions();

    await waitFor(() => {
      expect(screen.getByText('Unlogged Hours Alert')).toBeInTheDocument();
    });

    const detailButtons = screen.getAllByTitle(/Inspect why TESS suggested this intervention/i);
    fireEvent.click(detailButtons[0]);

    // Modal contents
    expect(screen.getByText('Why TESS Suggested This (Evidence Rationale)')).toBeInTheDocument();
    expect(screen.getByText(/Contributing Trigger:/i)).toBeInTheDocument();
    expect(screen.getByText(/Expected Impact:/i)).toBeInTheDocument();

    // Close modal
    const closeBtn = screen.getByTitle('Close dialog');
    fireEvent.click(closeBtn);

    await waitFor(() => {
      expect(screen.queryByText('Why TESS Suggested This (Evidence Rationale)')).not.toBeInTheDocument();
    });
  });

  it('switches tabs to show Resolved Fixes and All History', async () => {
    renderInterventions();

    await waitFor(() => {
      expect(screen.getByText('Unlogged Hours Alert')).toBeInTheDocument();
    });

    // Switch to Resolved Fixes
    const resolvedTab = screen.getByText(/Resolved \(1\)/i);
    fireEvent.click(resolvedTab);

    expect(screen.getByText('Sprint Backlog Scope Creep')).toBeInTheDocument();
    expect(screen.queryByText('Unlogged Hours Alert')).not.toBeInTheDocument();

    // Switch to All History
    const allTab = screen.getByText('All History');
    fireEvent.click(allTab);

    expect(screen.getByText('Sprint Backlog Scope Creep')).toBeInTheDocument();
    expect(screen.getByText('Unlogged Hours Alert')).toBeInTheDocument();
  });

  it('displays calm empty state when no active interventions exist', async () => {
    (apiService.getInterventions as any).mockResolvedValue([]);

    renderInterventions();

    await waitFor(() => {
      expect(screen.getByText('No Active Divergences')).toBeInTheDocument();
      expect(screen.getByText(/TESS has not detected any critical risks/i)).toBeInTheDocument();
    });
  });
});

