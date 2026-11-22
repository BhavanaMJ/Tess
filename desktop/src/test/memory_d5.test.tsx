import React from 'react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryScreen } from '../screens/MemoryScreen';
import { MascotProvider } from '../contexts/MascotContext';
import { apiService } from '../services/api';
import { Memory } from '../types';

const mockMemories: Memory[] = [
  {
    id: 'mem-1',
    user_id: 'user-test',
    category: 'preference',
    content: 'Prefers 90-minute morning focus blocks without interruptions',
    importance: 4,
    is_confirmed: true,
    provenance: 'USER_STATED',
    created_at: '2026-11-20T08:00:00Z'
  },
  {
    id: 'mem-2',
    user_id: 'user-test',
    category: 'goal',
    content: 'Launch Phase D5 Intelligence modules by end of sprint',
    importance: 5,
    is_confirmed: true,
    provenance: 'USER_STATED',
    created_at: '2026-11-21T09:00:00Z'
  },
  {
    id: 'mem-3',
    user_id: 'user-test',
    category: 'workflow',
    content: 'Tends to work late on Thursdays before Friday deployments',
    importance: 2,
    is_confirmed: false,
    provenance: 'INFERRED',
    created_at: '2026-11-22T07:00:00Z'
  }
];

describe('Phase D5.2 — Memory Core Workspace Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.spyOn(apiService, 'getMemories').mockResolvedValue(mockMemories);
    vi.spyOn(apiService, 'createMemory').mockImplementation(async (cat, content, imp = 3) => ({
      id: 'mem-new',
      user_id: 'user-test',
      category: cat,
      content,
      importance: imp || 3,
      is_confirmed: true,
      provenance: 'USER_STATED',
      created_at: new Date().toISOString()
    }));
    vi.spyOn(apiService, 'updateMemory').mockImplementation(async (id, updates) => {
      const existing = mockMemories.find((m) => m.id === id) || mockMemories[0];
      return { ...existing, ...updates };
    });
    vi.spyOn(apiService, 'deleteMemory').mockResolvedValue(undefined);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('renders Memory Core workspace with metrics cards and knowledge items', async () => {
    render(
      <MascotProvider>
        <MemoryScreen />
      </MascotProvider>
    );

    // Metrics Overview
    expect(await screen.findByText('Total Knowledge')).toBeInTheDocument();
    expect(screen.getByText('Confirmed Facts')).toBeInTheDocument();
    expect(screen.getByText('Needs Review')).toBeInTheDocument();
    expect(screen.getByText('Core Directives')).toBeInTheDocument();

    // Memory cards
    expect(await screen.findByText('Prefers 90-minute morning focus blocks without interruptions')).toBeInTheDocument();
    expect(screen.getByText('Launch Phase D5 Intelligence modules by end of sprint')).toBeInTheDocument();
    expect(screen.getByText('Tends to work late on Thursdays before Friday deployments')).toBeInTheDocument();
  });

  it('filters memories by category filter pills', async () => {
    render(
      <MascotProvider>
        <MemoryScreen />
      </MascotProvider>
    );

    await screen.findByText('Prefers 90-minute morning focus blocks without interruptions');

    // Filter by Goals
    const goalPill = screen.getByRole('button', { name: /Goals/i });
    fireEvent.click(goalPill);

    expect(screen.getByText('Launch Phase D5 Intelligence modules by end of sprint')).toBeInTheDocument();
    expect(screen.queryByText('Prefers 90-minute morning focus blocks without interruptions')).not.toBeInTheDocument();
  });

  it('searches memories using search query input', async () => {
    render(
      <MascotProvider>
        <MemoryScreen />
      </MascotProvider>
    );

    await screen.findByText('Prefers 90-minute morning focus blocks without interruptions');

    const searchInput = screen.getByPlaceholderText(/Search memories by content/i);
    fireEvent.change(searchInput, { target: { value: 'Thursdays' } });

    expect(screen.getByText('Tends to work late on Thursdays before Friday deployments')).toBeInTheDocument();
    expect(screen.queryByText('Launch Phase D5 Intelligence modules by end of sprint')).not.toBeInTheDocument();
  });

  it('encodes a new memory into long-term store', async () => {
    render(
      <MascotProvider>
        <MemoryScreen />
      </MascotProvider>
    );

    await screen.findByText('Prefers 90-minute morning focus blocks without interruptions');

    const input = screen.getByPlaceholderText(/I work best in 90-minute blocks/i);
    fireEvent.change(input, { target: { value: 'Always prioritize accessibility in UI components' } });

    const submitBtn = screen.getByRole('button', { name: /Save Memory/i });
    fireEvent.click(submitBtn);

    await waitFor(() => {
      expect(apiService.createMemory).toHaveBeenCalledWith(
        'preference',
        'Always prioritize accessibility in UI components',
        3
      );
    });

    expect(await screen.findByText(/Memory encoded into long-term cognitive store/i)).toBeInTheDocument();
  });

  it('uses template starters to prefill memory form', async () => {
    render(
      <MascotProvider>
        <MemoryScreen />
      </MascotProvider>
    );

    await screen.findByText('Prefers 90-minute morning focus blocks without interruptions');

    // Click starter button
    const starterBtn = screen.getByText(/Prioritize OpenProject tasks with high risk of overdue/i);
    fireEvent.click(starterBtn);

    const input = screen.getByPlaceholderText(/I work best in 90-minute blocks/i) as HTMLInputElement;
    expect(input.value).toBe('Prioritize OpenProject tasks with high risk of overdue');
  });

  it('toggles confirmation status between confirmed and unconfirmed', async () => {
    render(
      <MascotProvider>
        <MemoryScreen />
      </MascotProvider>
    );

    await screen.findByText('Prefers 90-minute morning focus blocks without interruptions');

    // Click confirmation toggle button for unconfirmed item
    const unconfirmedToggle = screen.getByText('UNCONFIRMED');
    fireEvent.click(unconfirmedToggle);

    await waitFor(() => {
      expect(apiService.updateMemory).toHaveBeenCalledWith('mem-3', { is_confirmed: true });
    });
  });

  it('opens and closes memory detail inspection modal', async () => {
    render(
      <MascotProvider>
        <MemoryScreen />
      </MascotProvider>
    );

    await screen.findByText('Prefers 90-minute morning focus blocks without interruptions');

    // Click memory content to open inspector
    const memoryItem = screen.getByText('Launch Phase D5 Intelligence modules by end of sprint');
    fireEvent.click(memoryItem);

    // Modal open
    expect(await screen.findByText(/Cognitive Continuity Inspector/i)).toBeInTheDocument();
    expect(screen.getByText(/Prompt Continuity Formatting/i)).toBeInTheDocument();

    // Close modal
    const cancelBtn = screen.getByRole('button', { name: 'Cancel' });
    fireEvent.click(cancelBtn);

    await waitFor(() => {
      expect(screen.queryByText(/Cognitive Continuity Inspector/i)).not.toBeInTheDocument();
    });
  });

  it('deletes a memory item', async () => {
    // Mock confirm dialog
    vi.spyOn(window, 'confirm').mockReturnValue(true);

    render(
      <MascotProvider>
        <MemoryScreen />
      </MascotProvider>
    );

    await screen.findByText('Prefers 90-minute morning focus blocks without interruptions');

    // Click delete button on first card
    const deleteButtons = screen.getAllByTitle('Delete memory');
    fireEvent.click(deleteButtons[0]);

    await waitFor(() => {
      expect(apiService.deleteMemory).toHaveBeenCalledWith('mem-1');
    });

    expect(await screen.findByText('Memory deleted.')).toBeInTheDocument();
  });
});
