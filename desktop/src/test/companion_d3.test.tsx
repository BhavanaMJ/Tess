import React from 'react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, waitFor, act } from '@testing-library/react';
import { Mascot, getMascotDetails } from '../components/Mascot';
import { MascotProvider, useMascot, EMOTION_PRIORITIES } from '../contexts/MascotContext';
import { CompanionPanel } from '../components/companion/CompanionPanel';
import { FloatingMascotWindow } from '../mascot/FloatingMascotWindow';
import { apiService } from '../services/api';
import { MascotState } from '../types';

// Mock apiService
vi.mock('../services/api', () => ({
  apiService: {
    getInterventions: vi.fn(),
    getAgentPlans: vi.fn(),
    getCompanionPreferences: vi.fn().mockResolvedValue({
      mascot_theme: 'TEAL',
      animation_level: 'NORMAL',
      current_stage: 1,
      quiet_mode: false
    })
  }
}));

describe('Phase D3 — Contextual TESS Companion Experience Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  // ============================================================================
  // 1. Emotion States & Visual Details Mapping
  // ============================================================================
  it('correctly maps all 9 official TESS v2.0 emotion states', () => {
    const officialEmotions: MascotState[] = [
      'IDLE',
      'THINKING',
      'HAPPY',
      'ATTENTION',
      'PLANNING',
      'CONFIRMING',
      'ACTING',
      'SUCCESS',
      'ERROR'
    ];

    officialEmotions.forEach((emotion) => {
      const details = getMascotDetails(emotion);
      expect(details).toBeDefined();
      expect(details.face).toBeDefined();
      expect(details.label).toBeDefined();
      expect(details.color).toMatch(/^#[0-9A-Fa-f]{6}$/);
    });

    expect(getMascotDetails('HAPPY').label).toBe('Happy');
    expect(getMascotDetails('THINKING').label).toBe('Thinking...');
    expect(getMascotDetails('ATTENTION').label).toBe('Needs Attention');
    expect(getMascotDetails('PLANNING').label).toBe('Planning');
    expect(getMascotDetails('CONFIRMING').label).toBe('Requires Confirmation');
    expect(getMascotDetails('ACTING').label).toBe('Executing Action');
    expect(getMascotDetails('SUCCESS').label).toBe('Completed');
    expect(getMascotDetails('ERROR').label).toBe('Error Occurred');
    expect(getMascotDetails('IDLE').label).toBe('Idle');
  });

  it('verifies emotion priority hierarchy', () => {
    expect(EMOTION_PRIORITIES.ERROR).toBeGreaterThan(EMOTION_PRIORITIES.ATTENTION);
    expect(EMOTION_PRIORITIES.ATTENTION).toBeGreaterThan(EMOTION_PRIORITIES.ACTING);
    expect(EMOTION_PRIORITIES.ACTING).toBeGreaterThan(EMOTION_PRIORITIES.THINKING);
    expect(EMOTION_PRIORITIES.THINKING).toBeGreaterThan(EMOTION_PRIORITIES.IDLE);
  });

  it('renders Mascot SVG component with accessibility attributes', () => {
    const { container } = render(
      <Mascot state="THINKING" size="lg" showLabel={true} />
    );

    const mascotEl = screen.getByRole('img');
    expect(mascotEl).toBeInTheDocument();
    expect(mascotEl).toHaveAttribute('aria-label', 'TESS AI Companion (Thinking...)');
    expect(container.textContent).toContain('Thinking...');
    // Verifies bean SVG presence
    expect(container.querySelector('svg')).toBeInTheDocument();
    expect(container.querySelector('linearGradient#tessBodyGradient')).toBeInTheDocument();
  });

  // ============================================================================
  // 2. Authoritative MascotContext & Timed Emotion Transitions
  // ============================================================================
  it('manages state transitions and reverts temporary emotions to baseline', () => {
    const Consumer = () => {
      const { state, setState, triggerEmotion } = useMascot();
      return (
        <div>
          <span data-testid="mascot-state">{state}</span>
          <button onClick={() => setState('ATTENTION')}>Set Alert</button>
          <button onClick={() => triggerEmotion('HAPPY', 3000)}>Celebrate</button>
        </div>
      );
    };

    render(
      <MascotProvider>
        <Consumer />
      </MascotProvider>
    );

    expect(screen.getByTestId('mascot-state').textContent).toBe('IDLE');

    // Trigger alert
    fireEvent.click(screen.getByText('Set Alert'));
    expect(screen.getByTestId('mascot-state').textContent).toBe('ATTENTION');

    // Trigger temporary celebration
    fireEvent.click(screen.getByText('Celebrate'));
    expect(screen.getByTestId('mascot-state').textContent).toBe('HAPPY');

    // Fast forward 3000ms -> should revert back to ATTENTION baseline
    act(() => {
      vi.advanceTimersByTime(3000);
    });

    expect(screen.getByTestId('mascot-state').textContent).toBe('ATTENTION');
  });

  it('prevents stale timeouts from overriding newer emotions', () => {
    const Consumer = () => {
      const { state, triggerEmotion, setState } = useMascot();
      return (
        <div>
          <span data-testid="mascot-state">{state}</span>
          <button onClick={() => triggerEmotion('HAPPY', 2000)}>Trigger Happy</button>
          <button onClick={() => setState('ERROR')}>Trigger Error</button>
        </div>
      );
    };

    render(
      <MascotProvider>
        <Consumer />
      </MascotProvider>
    );

    // 1. Trigger Happy (scheduled for 2000ms revert)
    fireEvent.click(screen.getByText('Trigger Happy'));
    expect(screen.getByTestId('mascot-state').textContent).toBe('HAPPY');

    // 2. Advance 1000ms, then trigger ERROR
    act(() => {
      vi.advanceTimersByTime(1000);
    });
    fireEvent.click(screen.getByText('Trigger Error'));
    expect(screen.getByTestId('mascot-state').textContent).toBe('ERROR');

    // 3. Advance past original 2000ms timer
    act(() => {
      vi.advanceTimersByTime(1500);
    });

    // Should still be ERROR, not clobbered by the older Happy timer!
    expect(screen.getByTestId('mascot-state').textContent).toBe('ERROR');
  });

  // ============================================================================
  // 3. Interactive Companion Panel Tests
  // ============================================================================
  it('does not render CompanionPanel when isOpen is false', () => {
    const { container } = render(
      <CompanionPanel isOpen={false} onClose={vi.fn()} onNavigate={vi.fn()} />
    );
    expect(container.firstChild).toBeNull();
  });

  it('renders CompanionPanel with context and handles navigation shortcuts', async () => {
    (apiService.getInterventions as any).mockResolvedValueOnce([
      {
        id: 'inv-1',
        title: 'Review schedule divergence',
        message: 'Tasks are falling behind',
        suggested_action: 'Reschedule low priority tasks',
        priority: 'URGENT',
        status: 'SENT'
      }
    ]);
    (apiService.getAgentPlans as any).mockResolvedValueOnce([]);

    const onClose = vi.fn();
    const onNavigate = vi.fn();

    render(
      <MascotProvider>
        <CompanionPanel isOpen={true} onClose={onClose} onNavigate={onNavigate} />
      </MascotProvider>
    );

    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText('TESS COMPANION')).toBeInTheDocument();
    expect(screen.getByText('Chat Stream')).toBeInTheDocument();
    expect(screen.getByText('Simulate Future')).toBeInTheDocument();
    expect(screen.getByText('Tasks & Deadlines')).toBeInTheDocument();
    expect(screen.getByText('Agent Console')).toBeInTheDocument();

    // Click navigation shortcut
    fireEvent.click(screen.getByText('Chat Stream'));
    expect(onNavigate).toHaveBeenCalledWith('chat');
    expect(onClose).toHaveBeenCalled();
  });

  it('closes CompanionPanel on Escape key press', () => {
    const onClose = vi.fn();
    render(
      <MascotProvider>
        <CompanionPanel isOpen={true} onClose={onClose} onNavigate={vi.fn()} />
      </MascotProvider>
    );

    fireEvent.keyDown(window, { key: 'Escape' });
    expect(onClose).toHaveBeenCalled();
  });

  // ============================================================================
  // 4. Floating Mascot Window Integration
  // ============================================================================
  it('opens main window and companion panel on click', () => {
    render(
      <MascotProvider>
        <FloatingMascotWindow />
      </MascotProvider>
    );

    const mascotCard = screen.getByTitle(/Left click to open TESS Companion/i);
    expect(mascotCard).toBeInTheDocument();

    // Click mascot
    fireEvent.click(mascotCard);
  });
});
