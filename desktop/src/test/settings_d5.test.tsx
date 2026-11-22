import React from 'react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { SettingsScreen } from '../screens/SettingsScreen';
import { MascotProvider } from '../contexts/MascotContext';
import { AuthProvider } from '../contexts/AuthContext';
import { apiService } from '../services/api';
import * as notifService from '../services/notifications';

const mockPreferences = {
  personality: 'FRIENDLY' as const,
  communication_style: 'BALANCED' as const,
  encouragement_style: 'GENTLE' as const,
  formality: 'NEUTRAL' as const,
  mascot_theme: 'PURPLE' as const,
  animation_level: 'NORMAL' as const,
  quiet_mode: false,
  progression_enabled: true,
  current_stage: 1,
  interaction_count: 8
};

const mockRoutines = [
  {
    id: 'routine-1',
    user_id: 'user-test',
    routine_name: 'Morning Briefing',
    routine_type: 'MORNING_BRIEFING',
    preferred_time: '08:30',
    days_of_week: ['MON', 'TUE', 'WED', 'THU', 'FRI'],
    timezone: 'UTC',
    enabled: true
  }
];

const mockMilestones = [
  {
    id: 'milestone-1',
    user_id: 'user-test',
    milestone_type: 'FIRST_ROUTINE',
    title: 'First Personal Routine',
    description: 'Scheduled morning briefing with TESS',
    stage_unlocked: 1,
    achieved_at: '2026-11-20T10:00:00Z'
  }
];

const mockDevices = [
  {
    id: 'dev-1',
    user_id: 'user-test',
    device_id: 'device-workstation',
    device_name: 'Linux Workstation',
    platform: 'linux',
    last_seen_at: '2026-11-22T12:00:00Z',
    created_at: '2026-11-01T00:00:00Z'
  }
];

describe('Phase D5.3 — System Settings Workspace Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.spyOn(apiService, 'getCompanionPreferences').mockResolvedValue(mockPreferences as any);
    vi.spyOn(apiService, 'getCompanionRoutines').mockResolvedValue(mockRoutines as any);
    vi.spyOn(apiService, 'getCompanionMilestones').mockResolvedValue(mockMilestones as any);
    vi.spyOn(apiService, 'getCompanionActivity').mockResolvedValue([]);
    vi.spyOn(apiService, 'getUserDevices').mockResolvedValue(mockDevices as any);
    vi.spyOn(apiService, 'updateCompanionPreferences').mockImplementation(async (updates) => ({
      ...mockPreferences,
      ...updates
    } as any));
    vi.spyOn(apiService, 'createCompanionRoutine').mockImplementation(async (data: any) => ({
      id: 'routine-new',
      user_id: 'user-test',
      routine_name: data.routine_name,
      routine_type: data.routine_type,
      preferred_time: data.preferred_time,
      days_of_week: data.days_of_week || ['MON'],
      timezone: 'UTC',
      enabled: true
    }));
    vi.spyOn(apiService, 'updateCompanionRoutine').mockImplementation(async (id, updates: any) => ({
      ...mockRoutines[0],
      ...updates
    }));
    vi.spyOn(apiService, 'deleteCompanionRoutine').mockResolvedValue(undefined);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('renders Settings workspace with navigation tabs and active sections', async () => {
    render(
      <AuthProvider>
        <MascotProvider>
          <SettingsScreen />
        </MascotProvider>
      </AuthProvider>
    );

    // Navigation Tabs
    expect(await screen.findByRole('button', { name: /Companion & Demeanor/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Routines & Automation/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Mascot & Notifications/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Connected Devices/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Account & System/i })).toBeInTheDocument();

    // Section Content
    expect(await screen.findByText('Living AI Companion & Personality')).toBeInTheDocument();
    expect(screen.getByText('Adaptive Personality Preset')).toBeInTheDocument();
    expect(screen.getByText(/Personal Routines Intelligence/)).toBeInTheDocument();
  });

  it('switches navigation tab to focus on a specific settings section', async () => {
    render(
      <AuthProvider>
        <MascotProvider>
          <SettingsScreen />
        </MascotProvider>
      </AuthProvider>
    );

    await screen.findByText('Living AI Companion & Personality');

    // Click Devices tab
    const devicesTab = screen.getByRole('button', { name: /Connected Devices/i });
    fireEvent.click(devicesTab);

    // Devices section should be visible
    expect(screen.getByText('Linux Workstation')).toBeInTheDocument();
    // Companion section should be filtered out
    expect(screen.queryByText('Living AI Companion & Personality')).not.toBeInTheDocument();
  });

  it('updates companion personality preset to CALM', async () => {
    render(
      <AuthProvider>
        <MascotProvider>
          <SettingsScreen />
        </MascotProvider>
      </AuthProvider>
    );

    await screen.findByText('Living AI Companion & Personality');

    const calmBtn = screen.getByRole('button', { name: 'CALM' });
    fireEvent.click(calmBtn);

    await waitFor(() => {
      expect(apiService.updateCompanionPreferences).toHaveBeenCalledWith({ personality: 'CALM' });
    });

    expect(await screen.findByText(/Companion preferences updated/i)).toBeInTheDocument();
  });

  it('schedules a new personal routine and adds it to list', async () => {
    render(
      <AuthProvider>
        <MascotProvider>
          <SettingsScreen />
        </MascotProvider>
      </AuthProvider>
    );

    await screen.findByText(/Personal Routines Intelligence/);

    const nameInput = screen.getByPlaceholderText(/Routine name \(e\.g\. Morning Briefing\)/i);
    fireEvent.change(nameInput, { target: { value: 'Evening Review' } });

    const createBtn = screen.getByRole('button', { name: /Create Routine/i });
    fireEvent.click(createBtn);

    await waitFor(() => {
      expect(apiService.createCompanionRoutine).toHaveBeenCalledWith({
        routine_name: 'Evening Review',
        routine_type: 'MORNING_BRIEFING',
        preferred_time: '08:30',
        days_of_week: ['MON', 'TUE', 'WED', 'THU', 'FRI'],
        timezone: 'UTC'
      });
    });

    expect(await screen.findByText(/Routine "Evening Review" scheduled/i)).toBeInTheDocument();
  });

  it('toggles routine enabled status', async () => {
    render(
      <AuthProvider>
        <MascotProvider>
          <SettingsScreen />
        </MascotProvider>
      </AuthProvider>
    );

    await screen.findByText('Morning Briefing');

    const checkbox = screen.getByTitle('Enabled');
    fireEvent.click(checkbox);

    await waitFor(() => {
      expect(apiService.updateCompanionRoutine).toHaveBeenCalledWith('routine-1', { enabled: false });
    });
  });

  it('deletes a routine', async () => {
    render(
      <AuthProvider>
        <MascotProvider>
          <SettingsScreen />
        </MascotProvider>
      </AuthProvider>
    );

    await screen.findByText('Morning Briefing');

    const deleteBtn = screen.getByTitle('Delete routine');
    fireEvent.click(deleteBtn);

    await waitFor(() => {
      expect(apiService.deleteCompanionRoutine).toHaveBeenCalledWith('routine-1');
    });

    expect(await screen.findByText('Routine removed')).toBeInTheDocument();
  });

  it('toggles desktop notifications preference', async () => {
    const saveSpy = vi.spyOn(notifService, 'saveNotificationSettings');

    render(
      <AuthProvider>
        <MascotProvider>
          <SettingsScreen />
        </MascotProvider>
      </AuthProvider>
    );

    const masterCheckbox = await screen.findByLabelText(/Enable Desktop Notifications/i);
    fireEvent.click(masterCheckbox);

    await waitFor(() => {
      expect(saveSpy).toHaveBeenCalled();
    });

    expect(await screen.findByText(/Notification preferences saved/i)).toBeInTheDocument();
  });

  it('toggles floating companion mascot window visibility', async () => {
    render(
      <AuthProvider>
        <MascotProvider>
          <SettingsScreen />
        </MascotProvider>
      </AuthProvider>
    );

    // Initial state check
    const toggleBtn = await screen.findByRole('button', { name: /Hide Mascot|Show Mascot/i });
    expect(toggleBtn).toBeInTheDocument();
    fireEvent.click(toggleBtn);
  });
});
