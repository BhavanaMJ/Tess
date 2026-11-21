import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ChatScreen } from '../screens/ChatScreen';
import { ChatMessageItem } from '../components/chat/ChatMessageItem';
import { MascotProvider } from '../contexts/MascotContext';
import { apiService } from '../services/api';
import { Conversation, Message } from '../types';

// Mock apiService
vi.mock('../services/api', () => ({
  apiService: {
    getConversations: vi.fn(),
    createConversation: vi.fn(),
    getMessages: vi.fn(),
    sendMessage: vi.fn(),
    voiceInteract: vi.fn(),
    analyzeScreen: vi.fn()
  }
}));

describe('Phase D4.1 — Companion Chat Screen & Workspaces', () => {
  const mockConversations: Conversation[] = [
    {
      id: 'conv-1',
      user_id: 'user-1',
      title: 'Strategic Priorities',
      created_at: new Date(Date.now() - 3600000).toISOString(),
      updated_at: new Date(Date.now() - 1800000).toISOString()
    },
    {
      id: 'conv-2',
      user_id: 'user-1',
      title: 'OpenProject Synchronizer',
      created_at: new Date(Date.now() - 86400000).toISOString(),
      updated_at: new Date(Date.now() - 86400000).toISOString()
    }
  ];

  const mockMessages: Message[] = [
    {
      id: 'msg-1',
      conversation_id: 'conv-1',
      role: 'user',
      content: 'What should I prioritize today?',
      created_at: new Date(Date.now() - 120000).toISOString()
    },
    {
      id: 'msg-2',
      conversation_id: 'conv-1',
      role: 'assistant',
      content: 'Here are your high impact focus items:\n\n- Complete **WP-104** API integration\n- Review pending PRs\n\n```python\n# Priority script\nprint("Focus mode")\n```',
      created_at: new Date(Date.now() - 60000).toISOString()
    }
  ];

  beforeEach(() => {
    vi.clearAllMocks();
    (apiService.getConversations as any).mockResolvedValue(mockConversations);
    (apiService.getMessages as any).mockResolvedValue(mockMessages);
    (apiService.createConversation as any).mockResolvedValue({
      id: 'conv-new',
      user_id: 'user-1',
      title: 'Companion Dialogue',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });
    (apiService.sendMessage as any).mockResolvedValue({
      response: 'I will help you execute this task immediately.'
    });

    // Mock clipboard
    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn().mockImplementation(() => Promise.resolve())
      }
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const renderWithMascot = (ui: React.ReactElement) => {
    return render(<MascotProvider>{ui}</MascotProvider>);
  };

  it('renders chat workspace, loads conversations and displays messages', async () => {
    renderWithMascot(<ChatScreen />);

    expect(screen.getByTestId('companion-chat-screen')).toBeInTheDocument();

    await waitFor(() => {
      expect(apiService.getConversations).toHaveBeenCalled();
      expect(screen.getAllByText('Strategic Priorities').length).toBeGreaterThan(0);
      expect(screen.getAllByText('OpenProject Synchronizer').length).toBeGreaterThan(0);
    });

    await waitFor(() => {
      expect(apiService.getMessages).toHaveBeenCalledWith('conv-1');
      expect(screen.getByText('What should I prioritize today?')).toBeInTheDocument();
      expect(screen.getByText('Here are your high impact focus items:')).toBeInTheDocument();
    });
  });

  it('renders formatted markdown including bold, bullet lists, and code blocks with copy action', async () => {
    const singleMsg: Message = {
      id: 'msg-format',
      conversation_id: 'conv-1',
      role: 'assistant',
      content: 'Summary:\n\n- Step one: `npm install`\n- Step two: run tests\n\n```bash\nnpm run test\n```',
      created_at: new Date().toISOString()
    };

    render(<ChatMessageItem message={singleMsg} />);

    expect(screen.getByText('Summary:')).toBeInTheDocument();
    expect(screen.getByText('Step one:')).toBeInTheDocument();
    expect(screen.getByText('npm install')).toBeInTheDocument();
    expect(screen.getByText('npm run test')).toBeInTheDocument();

    // Copy code button
    const copyBtn = screen.getByTitle('Copy code');
    fireEvent.click(copyBtn);
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('npm run test');
  });

  it('handles sending user messages with Enter key and updates messages stream', async () => {
    renderWithMascot(<ChatScreen />);

    await waitFor(() => {
      expect(screen.getAllByText('Strategic Priorities').length).toBeGreaterThan(0);
    });

    const textarea = screen.getByPlaceholderText(/Communicate with TESS/i);
    fireEvent.change(textarea, { target: { value: 'Schedule a focus block for 2pm' } });

    // Press Enter to submit
    fireEvent.keyDown(textarea, { key: 'Enter', shiftKey: false });

    await waitFor(() => {
      expect(apiService.sendMessage).toHaveBeenCalledWith('conv-1', 'Schedule a focus block for 2pm');
      expect(screen.getByText('Schedule a focus block for 2pm')).toBeInTheDocument();
      expect(screen.getByText('I will help you execute this task immediately.')).toBeInTheDocument();
    });
  });

  it('supports Shift+Enter for newlines without submitting message', async () => {
    renderWithMascot(<ChatScreen />);

    await waitFor(() => {
      expect(screen.getAllByText('Strategic Priorities').length).toBeGreaterThan(0);
    });

    const textarea = screen.getByPlaceholderText(/Communicate with TESS/i);
    fireEvent.change(textarea, { target: { value: 'Line 1' } });

    // Press Shift+Enter
    fireEvent.keyDown(textarea, { key: 'Enter', shiftKey: true });

    // sendMessage should NOT be called
    expect(apiService.sendMessage).not.toHaveBeenCalled();
  });

  it('prevents sending empty or whitespace-only messages', async () => {
    renderWithMascot(<ChatScreen />);

    await waitFor(() => {
      expect(screen.getAllByText('Strategic Priorities').length).toBeGreaterThan(0);
    });

    const textarea = screen.getByPlaceholderText(/Communicate with TESS/i);
    fireEvent.change(textarea, { target: { value: '   ' } });

    fireEvent.keyDown(textarea, { key: 'Enter', shiftKey: false });
    expect(apiService.sendMessage).not.toHaveBeenCalled();
  });

  it('handles message send error gracefully and provides inline retry', async () => {
    (apiService.sendMessage as any).mockRejectedValueOnce(new Error('Network connection timeout'));

    renderWithMascot(<ChatScreen />);

    await waitFor(() => {
      expect(screen.getAllByText('Strategic Priorities').length).toBeGreaterThan(0);
    });

    const textarea = screen.getByPlaceholderText(/Communicate with TESS/i);
    fireEvent.change(textarea, { target: { value: 'Trigger network timeout' } });
    fireEvent.keyDown(textarea, { key: 'Enter', shiftKey: false });

    await waitFor(() => {
      expect(screen.getByText(/Network connection timeout/i)).toBeInTheDocument();
    });

    // Verify retry button exists
    const retryButtons = screen.getAllByText(/Retry/i);
    expect(retryButtons.length).toBeGreaterThan(0);

    // Mock successful retry
    (apiService.sendMessage as any).mockResolvedValueOnce({ response: 'Recovered response after retry' });
    fireEvent.click(retryButtons[0]);

    await waitFor(() => {
      expect(screen.getByText('Recovered response after retry')).toBeInTheDocument();
    });
  });

  it('creates a new dialogue when "New Dialogue" is clicked', async () => {
    renderWithMascot(<ChatScreen />);

    await waitFor(() => {
      expect(screen.getAllByText('Strategic Priorities').length).toBeGreaterThan(0);
    });

    const newDialogueBtns = screen.getAllByTitle(/New Dialogue|Start a new companion dialogue/i);
    fireEvent.click(newDialogueBtns[0]);

    await waitFor(() => {
      expect(apiService.createConversation).toHaveBeenCalledWith('Companion Dialogue');
      expect(screen.getAllByText('Companion Dialogue').length).toBeGreaterThan(0);
    });
  });

  it('filters conversation list when typing in search input', async () => {
    renderWithMascot(<ChatScreen />);

    await waitFor(() => {
      expect(screen.getAllByText('Strategic Priorities').length).toBeGreaterThan(0);
      expect(screen.getAllByText('OpenProject Synchronizer').length).toBeGreaterThan(0);
    });

    const searchInput = screen.getByPlaceholderText(/Search dialogues/i);
    fireEvent.change(searchInput, { target: { value: 'OpenProject' } });

    expect(screen.getAllByText('OpenProject Synchronizer').length).toBeGreaterThan(0);
    // In sidebar, Strategic Priorities should be filtered out
    // But header might still display current active conversation title
    const sidebar = screen.getByText('Dialogues').closest('div')?.parentElement;
    expect(sidebar?.textContent).toContain('OpenProject Synchronizer');
    expect(sidebar?.textContent).not.toContain('Strategic Priorities');
  });

  it('collapses and expands conversation sidebar rail', async () => {
    renderWithMascot(<ChatScreen />);

    await waitFor(() => {
      expect(screen.getAllByText('Strategic Priorities').length).toBeGreaterThan(0);
    });

    // Collapse
    const collapseBtn = screen.getByTitle('Collapse Sidebar');
    fireEvent.click(collapseBtn);

    // Sidebar should be collapsed, showing expand button
    expect(screen.getByTitle('Expand Conversation Rail')).toBeInTheDocument();

    // Expand
    fireEvent.click(screen.getByTitle('Expand Conversation Rail'));
    expect(screen.getAllByText('Strategic Priorities').length).toBeGreaterThan(0);
  });

  it('renders interactive prompt starters in empty dialogue state and sends on click', async () => {
    (apiService.getMessages as any).mockResolvedValue([]);

    renderWithMascot(<ChatScreen />);

    await waitFor(() => {
      expect(screen.getByText(/TESS Continuous Dialogue/i)).toBeInTheDocument();
      expect(screen.getByText('Priority Check')).toBeInTheDocument();
      expect(screen.getByText('Trajectory Simulation')).toBeInTheDocument();
      expect(screen.getByText('Procrastination Audit')).toBeInTheDocument();
      expect(screen.getByText('Task Execution')).toBeInTheDocument();
    });

    // Click "Priority Check" prompt starter
    fireEvent.click(screen.getByText('Priority Check'));

    await waitFor(() => {
      expect(apiService.sendMessage).toHaveBeenCalledWith(
        'conv-1',
        'What should I prioritize today based on my goals?'
      );
    });
  });

  it('copies message text to clipboard when copy button is clicked', async () => {
    renderWithMascot(<ChatScreen />);

    await waitFor(() => {
      expect(screen.getByText('What should I prioritize today?')).toBeInTheDocument();
    });

    const copyButtons = screen.getAllByTitle('Copy message');
    expect(copyButtons.length).toBeGreaterThan(0);

    fireEvent.click(copyButtons[0]);
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('What should I prioritize today?');
  });
});
