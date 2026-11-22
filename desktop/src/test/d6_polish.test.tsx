import React, { useState } from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ThemeProvider, useTheme } from '../contexts/ThemeContext';
import { Header } from '../components/Header';
import { Layout } from '../components/Layout';
import { MascotProvider } from '../contexts/MascotContext';
import { AuthProvider } from '../contexts/AuthContext';
import { apiService } from '../services/api';

// Mock apiService while preserving supabase export
vi.mock('../services/api', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../services/api')>();
  return {
    ...actual,
    apiService: {
      ...actual.apiService,
      getProductivitySummary: vi.fn().mockResolvedValue({ total_active: 5, overdue: 1 }),
      getInterventions: vi.fn().mockResolvedValue([]),
      getAgentPlans: vi.fn().mockResolvedValue([]),
      checkDueRoutines: vi.fn().mockResolvedValue({ count: 0, due_routines: [] }),
      getProductivityTasks: vi.fn().mockResolvedValue([]),
      getMemories: vi.fn().mockResolvedValue([]),
      getFuturePredictions: vi.fn().mockResolvedValue([]),
      getConversations: vi.fn().mockResolvedValue([])
    }
  };
});

// Mock @tauri-apps/api/core
vi.mock('@tauri-apps/api/core', () => ({
  invoke: vi.fn().mockResolvedValue([1200, 650])
}));

const ThemeTestConsumer: React.FC = () => {
  const { theme, toggleTheme, setTheme } = useTheme();
  return (
    <div>
      <span data-testid="current-theme">{theme}</span>
      <button onClick={toggleTheme}>Toggle Theme</button>
      <button onClick={() => setTheme('light')}>Set Light</button>
      <button onClick={() => setTheme('dark')}>Set Dark</button>
    </div>
  );
};

describe('Phase D6 — Final Polish & Quality Assurance Tests', () => {
  beforeEach(() => {
    localStorage.clear();
    document.documentElement.removeAttribute('data-theme');
    document.documentElement.classList.remove('theme-light');
    vi.clearAllMocks();
  });

  it('provides ThemeContext and persists light/dark theme preference to localStorage and DOM', () => {
    render(
      <ThemeProvider>
        <ThemeTestConsumer />
      </ThemeProvider>
    );

    expect(screen.getByTestId('current-theme').textContent).toBe('dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
    expect(document.documentElement.classList.contains('theme-light')).toBe(false);

    // Toggle to Light
    fireEvent.click(screen.getByText('Toggle Theme'));
    expect(screen.getByTestId('current-theme').textContent).toBe('light');
    expect(document.documentElement.getAttribute('data-theme')).toBe('light');
    expect(document.documentElement.classList.contains('theme-light')).toBe(true);
    expect(localStorage.getItem('tess_desktop_theme')).toBe('light');

    // Toggle back to Dark
    fireEvent.click(screen.getByText('Toggle Theme'));
    expect(screen.getByTestId('current-theme').textContent).toBe('dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
    expect(document.documentElement.classList.contains('theme-light')).toBe(false);
    expect(localStorage.getItem('tess_desktop_theme')).toBe('dark');
  });

  it('renders Theme Toggle in Header and toggles between Light and Dark mode', () => {
    render(
      <ThemeProvider>
        <MascotProvider>
          <Header title="Dashboard" subtitle="System Overview" />
        </MascotProvider>
      </ThemeProvider>
    );

    const toggleBtn = screen.getByRole('button', { name: /Switch to Light Theme/i });
    expect(toggleBtn).toBeDefined();

    fireEvent.click(toggleBtn);
    expect(document.documentElement.getAttribute('data-theme')).toBe('light');
    expect(screen.getByRole('button', { name: /Switch to Dark Theme/i })).toBeDefined();
  });

  it('supports global ⌘K keyboard shortcut to open command palette', async () => {
    render(
      <AuthProvider>
        <ThemeProvider>
          <MascotProvider>
            <Layout />
          </MascotProvider>
        </ThemeProvider>
      </AuthProvider>
    );

    // Initially command palette is not visible
    expect(screen.queryByPlaceholderText(/Search commands, tasks, memories/i)).toBeNull();

    // Fire ⌘K
    fireEvent.keyDown(window, { key: 'k', metaKey: true });

    await waitFor(() => {
      expect(screen.getByPlaceholderText(/Search commands, tasks, memories/i)).toBeDefined();
    });

    // Fire ESC to close
    fireEvent.keyDown(window, { key: 'Escape' });
    await waitFor(() => {
      expect(screen.queryByPlaceholderText(/Search commands, tasks, memories/i)).toBeNull();
    });
  });

  it('guards ⌘1-⌘8 shortcuts when user is focused inside an input element', async () => {
    const TestInputWrapper: React.FC = () => {
      return (
        <div>
          <input data-testid="test-input" defaultValue="Working on notes" />
        </div>
      );
    };

    render(
      <AuthProvider>
        <ThemeProvider>
          <MascotProvider>
            <Layout />
            <TestInputWrapper />
          </MascotProvider>
        </ThemeProvider>
      </AuthProvider>
    );

    // Initial screen should be Dashboard
    expect(screen.getByText('Dashboard')).toBeDefined();

    // Focus input and fire ⌘3 (Tasks)
    const input = screen.getByTestId('test-input');
    input.focus();
    fireEvent.keyDown(input, { key: '3', metaKey: true });

    // Should STILL be on Dashboard because typing in input guarded the navigation
    expect(screen.getByText('Dashboard')).toBeDefined();

    // Unfocus input and fire ⌘3
    input.blur();
    fireEvent.keyDown(window, { key: '3', metaKey: true });

    // Now navigation succeeds
    await waitFor(() => {
      expect(screen.getByText('Productivity Tasks')).toBeDefined();
    });
  });

  it('verifies single persistent mascot character invariant across layout', () => {
    const { container } = render(
      <AuthProvider>
        <ThemeProvider>
          <MascotProvider>
            <Layout />
          </MascotProvider>
        </ThemeProvider>
      </AuthProvider>
    );

    // The layout shell should render the status pill in the header
    expect(screen.getByTitle(/Open TESS Companion Panel/i)).toBeDefined();

    // Zero mascot SVGs should be mounted directly inside the MainApp/Layout screen
    // because FloatingMascotWindow is the single dedicated window
    const mascotElements = container.querySelectorAll('.tess-mascot-container');
    expect(mascotElements.length).toBe(0);
  });
});
