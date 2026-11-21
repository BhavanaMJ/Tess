import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { FuturesScreen } from '../screens/FuturesScreen';
import { MascotProvider } from '../contexts/MascotContext';
import { apiService } from '../services/api';
import {
  FuturePrediction,
  SimulationResponse,
  LongTermForecastResponse,
  MultipleFuturesResponse,
  BehavioralAnalysisResponse,
  AccuracyMetricsResponse,
  InterventionEffectivenessResponse
} from '../types';

// Mock apiService
vi.mock('../services/api', () => ({
  apiService: {
    getFuturePredictions: vi.fn(),
    simulateFuture: vi.fn(),
    generateLongTermForecast: vi.fn(),
    generateMultipleFutures: vi.fn(),
    getBehavioralProfile: vi.fn(),
    getPredictionAccuracy: vi.fn(),
    getInterventionEffectiveness: vi.fn(),
    evaluatePredictions: vi.fn(),
    createAgentObjective: vi.fn()
  }
}));

describe('Phase D4.3 — Future Engine Workspace Tests', () => {
  const mockPredictions: FuturePrediction[] = [
    {
      id: 'pred-1',
      prediction_type: 'RISK',
      title: 'Overdue Deadline Cascading',
      description: 'Pending task WP-101 is blocking dependent integrations.',
      confidence: 'HIGH',
      probability: 0.82,
      time_horizon: '7d',
      evidence: ['Task WP-101 overdue by 24h', 'Velocity dropped 15%'],
      status: 'ACTIVE',
      created_at: new Date().toISOString()
    },
    {
      id: 'pred-2',
      prediction_type: 'OPPORTUNITY',
      title: 'Sprint Velocity Surplus',
      description: 'Early completion of core modules enables focus buffer.',
      confidence: 'MEDIUM',
      probability: 0.74,
      time_horizon: '3d',
      evidence: ['3 tasks finished ahead of target'],
      status: 'ACTIVE',
      created_at: new Date().toISOString()
    }
  ];

  const mockSimulation: SimulationResponse = {
    horizon: '24h',
    scenario: {
      title: 'Stable Trajectory with Focused Execution',
      summary: 'Completing prioritized work packages protects end-of-week release milestones.',
      events: [
        {
          title: 'Review WP-101 API Endpoint',
          description: 'Resolve token validation timeout.',
          relative_time: '+2h'
        },
        {
          title: 'Run Integration Tests',
          description: 'Verify 0 regression across modules.',
          relative_time: '+5h'
        }
      ]
    },
    alternative: {
      action: 'Shift focus to overdue blockers before starting new dialogue threads',
      expected_effect: 'Reduces cascade risk by 65% and clears critical path for tomorrow'
    }
  };

  const mockLongTermForecast: LongTermForecastResponse = {
    id: 'forecast-1',
    horizon: '30d',
    projected_backlog: 5,
    completion_forecast: 28,
    burnout_risk_score: 0.25,
    probability: 0.85,
    confidence: 'HIGH',
    uncertainty_range: {
      backlog_min: 3,
      backlog_max: 8,
      completion_min: 22,
      completion_max: 34
    },
    assumptions: ['Current completion rate holds', 'No sudden scope changes'],
    evidence: ['Historical velocity across past 4 sprints'],
    explanation: 'Disciplined workload protects burnout buffer.',
    created_at: new Date().toISOString()
  };

  beforeEach(() => {
    vi.clearAllMocks();
    (apiService.getFuturePredictions as any).mockResolvedValue(mockPredictions);
    (apiService.simulateFuture as any).mockResolvedValue(mockSimulation);
    (apiService.generateLongTermForecast as any).mockResolvedValue(mockLongTermForecast);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const renderFutures = (onNavigate?: (tab: any) => void) => {
    return render(
      <MascotProvider>
        <FuturesScreen onNavigate={onNavigate} />
      </MascotProvider>
    );
  };

  it('renders Future Engine workspace with transparency notice, horizon tabs, and predictions', async () => {
    renderFutures();

    await waitFor(() => {
      expect(apiService.getFuturePredictions).toHaveBeenCalled();
      expect(apiService.simulateFuture).toHaveBeenCalledWith('24h');
    });

    // Transparency guidance banner
    expect(screen.getByText(/Probabilistic Trajectory Engine/i)).toBeInTheDocument();
    expect(screen.getByText(/Simulations represent mathematical projections/i)).toBeInTheDocument();

    // Trajectory scenario
    expect(screen.getByText('Stable Trajectory with Focused Execution')).toBeInTheDocument();
    expect(screen.getByText('Review WP-101 API Endpoint')).toBeInTheDocument();

    // Predictions
    expect(screen.getByText('Overdue Deadline Cascading')).toBeInTheDocument();
    expect(screen.getByText('Sprint Velocity Surplus')).toBeInTheDocument();
  });

  it('renders counterfactual alternative scenario and handles "Discuss with TESS" action', async () => {
    const mockNavigate = vi.fn();
    renderFutures(mockNavigate);

    await waitFor(() => {
      expect(screen.getByText(/Alternative Scenario/i)).toBeInTheDocument();
      expect(screen.getByText(/Shift focus to overdue blockers/i)).toBeInTheDocument();
    });

    const discussBtn = screen.getByTitle('Discuss trajectory in Companion Chat');
    fireEvent.click(discussBtn);

    expect(mockNavigate).toHaveBeenCalledWith('chat');
  });

  it('triggers fresh simulation when selecting another horizon (3d or 7d)', async () => {
    (apiService.simulateFuture as any).mockImplementation(async (horizon: string) => {
      if (horizon === '3d') {
        return {
          horizon: '3d',
          scenario: {
            title: '3-Day Mid-Horizon Forecast',
            summary: 'Targeted delivery clears milestones.',
            events: []
          }
        };
      }
      return mockSimulation;
    });

    renderFutures();

    await waitFor(() => {
      expect(screen.getByText('Stable Trajectory with Focused Execution')).toBeInTheDocument();
    });

    const threeDayBtn = screen.getByText('3 Days');
    fireEvent.click(threeDayBtn);

    await waitFor(() => {
      expect(apiService.simulateFuture).toHaveBeenCalledWith('3d');
      expect(screen.getByText('3-Day Mid-Horizon Forecast')).toBeInTheDocument();
    });
  });

  it('switches to Long-Term Forecast tab and renders long-term trajectory metrics', async () => {
    renderFutures();

    await waitFor(() => {
      expect(screen.getByText('Stable Trajectory with Focused Execution')).toBeInTheDocument();
    });

    const longTermTab = screen.getByText('Long-Term Forecast');
    fireEvent.click(longTermTab);

    await waitFor(() => {
      expect(apiService.generateLongTermForecast).toHaveBeenCalledWith('30d');
      expect(screen.getByText(/Disciplined workload protects burnout buffer/i)).toBeInTheDocument();
    });
  });

  it('displays simulation error banner when simulation API fails', async () => {
    (apiService.simulateFuture as any).mockRejectedValueOnce(new Error('Simulation model timeout'));

    renderFutures();

    await waitFor(() => {
      expect(screen.getByText('Simulation model timeout')).toBeInTheDocument();
    });
  });
});
