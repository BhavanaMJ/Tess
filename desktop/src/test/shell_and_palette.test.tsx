import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { Sidebar } from '../components/Sidebar';
import { Header } from '../components/Header';
import { CommandPalette } from '../components/CommandPalette';
import { AuthProvider } from '../contexts/AuthContext';
import { MascotProvider } from '../contexts/MascotContext';
import { apiService } from '../services/api';

describe('D1 — Advanced Desktop Shell & Command Palette Tests', () => {
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

  // ============================================================================
  // 1. Sidebar Tests
  // ============================================================================
  it('renders Sidebar with semantic navigation sections and items', () => {
    const onSelectTab = vi.fn();
    const onOpenCommandPalette = vi.fn();

    renderWithProviders(
      <Sidebar
        currentTab="home"
        onSelectTab={onSelectTab}
        onOpenCommandPalette={onOpenCommandPalette}
        badgeCounts={{ tasks: 3, interventions: 1 }}
      />
    );

    // Verify Brand
    expect(screen.getByText('TESS')).toBeInTheDocument();
    expect(screen.getByText('OS 2.0')).toBeInTheDocument();

    // Verify Semantic Sections
    expect(screen.getByText('WORKSPACE')).toBeInTheDocument();
    expect(screen.getByText('INTELLIGENCE')).toBeInTheDocument();
    expect(screen.getByText('SYSTEM & CONTEXT')).toBeInTheDocument();

    // Verify Nav items
    expect(screen.getByText('Command Home')).toBeInTheDocument();
    expect(screen.getByText('Active Tasks')).toBeInTheDocument();
    expect(screen.getByText('Future Engine')).toBeInTheDocument();
    expect(screen.getByText('Memory Core')).toBeInTheDocument();

    // Verify badge counts
    expect(screen.getByText('3')).toBeInTheDocument();
    expect(screen.getByText('1')).toBeInTheDocument();

    // Click navigation item
    fireEvent.click(screen.getByText('Active Tasks'));
    expect(onSelectTab).toHaveBeenCalledWith('tasks');

    // Click Command Palette trigger
    const quickSearchBtn = screen.getByText('Quick Search');
    fireEvent.click(quickSearchBtn);
    expect(onOpenCommandPalette).toHaveBeenCalledTimes(1);
  });

  it('collapses and expands sidebar and persists state to localStorage', () => {
    renderWithProviders(
      <Sidebar currentTab="home" onSelectTab={vi.fn()} />
    );

    expect(screen.getByText('COLLAPSE')).toBeInTheDocument();
    const collapseBtn = screen.getByTitle('Collapse Sidebar');
    fireEvent.click(collapseBtn);

    // Collapsed state persisted
    expect(localStorage.getItem('tess_desktop_sidebar_collapsed')).toBe('true');
    expect(screen.queryByText('WORKSPACE')).not.toBeInTheDocument();

    // Expand again
    const expandBtn = screen.getByTitle('Expand Sidebar');
    fireEvent.click(expandBtn);
    expect(localStorage.getItem('tess_desktop_sidebar_collapsed')).toBe('false');
    expect(screen.getByText('WORKSPACE')).toBeInTheDocument();
  });

  // ============================================================================
  // 2. Header Tests
  // ============================================================================
  it('renders Header with breadcrumb, sync badge, and command palette trigger', () => {
    const onRefresh = vi.fn();
    const onOpenPalette = vi.fn();

    renderWithProviders(
      <Header
        title="Productivity Tasks"
        subtitle="Manage work packages and deadlines"
        isSyncing={false}
        onRefresh={onRefresh}
        onOpenCommandPalette={onOpenPalette}
      />
    );

    // Breadcrumb
    expect(screen.getByLabelText('Breadcrumb')).toBeInTheDocument();
    expect(screen.getByText('Productivity Tasks')).toBeInTheDocument();
    expect(screen.getByText('Manage work packages and deadlines')).toBeInTheDocument();

    // Sync Badge
    expect(screen.getByText('LIVE')).toBeInTheDocument();

    // Command palette trigger
    const searchTrigger = screen.getByTitle('Open Command Palette (Ctrl+K or ⌘K)');
    fireEvent.click(searchTrigger);
    expect(onOpenPalette).toHaveBeenCalledTimes(1);

    // Refresh button
    const refreshBtn = screen.getByTitle('Refresh System Data');
    fireEvent.click(refreshBtn);
    expect(onRefresh).toHaveBeenCalledTimes(1);
  });

  // ============================================================================
  // 3. Command Palette & Global Search Tests
  // ============================================================================
  it('does not render CommandPalette when isOpen is false', () => {
    const { container } = render(
      <CommandPalette
        isOpen={false}
        onClose={vi.fn()}
        onNavigate={vi.fn()}
      />
    );
    expect(container.firstChild).toBeNull();
  });

  it('renders CommandPalette and searches real tasks and memories', async () => {
    vi.spyOn(apiService, 'getProductivityTasks').mockResolvedValue([
      {
        id: 'task-1',
        user_id: 'user-1',
        title: 'Review Project Architecture',
        status: 'IN_PROGRESS',
        priority: 'High',
        source: 'openproject',
        external_id: 'OP-101',
        created_at: new Date().toISOString()
      } as any
    ]);
    vi.spyOn(apiService, 'getMemories').mockResolvedValue([
      {
        id: 'mem-1',
        user_id: 'user-1',
        content: 'Prefers dark mode and concise summaries',
        category: 'Preferences',
        importance: 5,
        created_at: new Date().toISOString()
      } as any
    ]);
    vi.spyOn(apiService, 'getFuturePredictions').mockResolvedValue([
      {
        id: 'pred-1',
        title: 'Backend API latency spike warning',
        description: 'High latency risk',
        prediction_type: 'RISK',
        probability: 78,
        confidence: 0.85,
        time_horizon: '24h',
        status: 'ACTIVE',
        created_at: new Date().toISOString()
      } as any
    ]);
    vi.spyOn(apiService, 'getConversations').mockResolvedValue([]);

    const onNavigate = vi.fn();
    const onClose = vi.fn();

    render(
      <CommandPalette
        isOpen={true}
        onClose={onClose}
        onNavigate={onNavigate}
      />
    );

    expect(screen.getByPlaceholderText(/Search commands, tasks, memories/i)).toBeInTheDocument();

    // Default view shows navigation commands
    expect(screen.getByText('Command Home')).toBeInTheDocument();
    expect(screen.getByText('Companion Chat')).toBeInTheDocument();

    // Wait for async fetch
    await waitFor(() => {
      expect(apiService.getProductivityTasks).toHaveBeenCalled();
    });

    // Search for the task
    const input = screen.getByPlaceholderText(/Search commands, tasks, memories/i);
    fireEvent.change(input, { target: { value: 'Architecture' } });

    // Verify task is found in search results
    await waitFor(() => {
      expect(screen.getByText('Review Project Architecture')).toBeInTheDocument();
    });

    // Click the search result item
    fireEvent.click(screen.getByText('Review Project Architecture'));
    expect(onNavigate).toHaveBeenCalledWith('tasks');
    expect(onClose).toHaveBeenCalled();
  });

  it('closes CommandPalette when Escape is pressed', () => {
    const onClose = vi.fn();
    render(
      <CommandPalette
        isOpen={true}
        onClose={onClose}
        onNavigate={vi.fn()}
      />
    );

    fireEvent.keyDown(window, { key: 'Escape' });
    expect(onClose).toHaveBeenCalled();
  });
});
