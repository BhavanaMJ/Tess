import React, { useState, useEffect, useRef, useMemo } from 'react';
import {
  Search,
  Home,
  MessageSquare,
  CheckSquare,
  Compass,
  AlertTriangle,
  Bot,
  Brain,
  Settings,
  RefreshCw,
  Eye,
  LogOut,
  ArrowRight,
  Sparkles,
  Command,
  X,
  Loader2,
  Sun,
  Moon
} from 'lucide-react';
import { useTheme } from '../contexts/ThemeContext';
import { ScreenTab } from './Sidebar';
import { apiService } from '../services/api';
import { ProductivityTask, Memory, FuturePrediction, Conversation } from '../types';

export interface CommandItem {
  id: string;
  title: string;
  subtitle?: string;
  category: 'Navigation' | 'Tasks' | 'Memories' | 'Predictions' | 'Conversations' | 'Actions';
  icon: React.ComponentType<{ style?: React.CSSProperties; className?: string }>;
  shortcut?: string;
  action: () => void;
  badge?: string;
  badgeColor?: string;
}

interface CommandPaletteProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigate: (tab: ScreenTab) => void;
  onRefresh?: () => void;
  onToggleMascot?: () => void;
}

export const CommandPalette: React.FC<CommandPaletteProps> = ({
  isOpen,
  onClose,
  onNavigate,
  onRefresh,
  onToggleMascot
}) => {
  const [query, setQuery] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const { theme, toggleTheme } = useTheme();
  const inputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);

  // Live remote search data state
  const [tasks, setTasks] = useState<ProductivityTask[]>([]);
  const [memories, setMemories] = useState<Memory[]>([]);
  const [predictions, setPredictions] = useState<FuturePrediction[]>([]);
  const [conversations, setConversations] = useState<Conversation[]>([]);

  // Focus input on open
  useEffect(() => {
    if (isOpen) {
      setQuery('');
      setSelectedIndex(0);
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [isOpen]);

  // Global Ctrl+K / Cmd+K and Escape listeners
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && (e.key === 'k' || e.key === 'K')) {
        e.preventDefault();
        if (isOpen) {
          onClose();
        }
      } else if (e.key === 'Escape' && isOpen) {
        e.preventDefault();
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  // Fetch searchable records on mount/open
  useEffect(() => {
    if (!isOpen) return;

    let isMounted = true;
    setIsLoading(true);

    Promise.allSettled([
      apiService.getProductivityTasks(),
      apiService.getMemories(),
      apiService.getFuturePredictions(),
      apiService.getConversations()
    ])
      .then(([tasksRes, memRes, predRes, convRes]) => {
        if (!isMounted) return;
        if (tasksRes.status === 'fulfilled') setTasks(tasksRes.value || []);
        if (memRes.status === 'fulfilled') setMemories(memRes.value || []);
        if (predRes.status === 'fulfilled') setPredictions(predRes.value || []);
        if (convRes.status === 'fulfilled') setConversations(convRes.value || []);
      })
      .finally(() => {
        if (isMounted) setIsLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [isOpen]);

  // Navigation Items
  const navCommands = useMemo<CommandItem[]>(() => [
    {
      id: 'nav-home',
      title: 'Command Home',
      subtitle: 'Overview of productivity, trajectories & alerts',
      category: 'Navigation',
      icon: Home,
      shortcut: '⌘1',
      action: () => {
        onNavigate('home');
        onClose();
      }
    },
    {
      id: 'nav-chat',
      title: 'Companion Chat',
      subtitle: 'Conversational stream & cognitive interactions',
      category: 'Navigation',
      icon: MessageSquare,
      shortcut: '⌘2',
      action: () => {
        onNavigate('chat');
        onClose();
      }
    },
    {
      id: 'nav-tasks',
      title: 'Active Tasks',
      subtitle: 'Manage priorities, work packages & deadlines',
      category: 'Navigation',
      icon: CheckSquare,
      shortcut: '⌘3',
      action: () => {
        onNavigate('tasks');
        onClose();
      }
    },
    {
      id: 'nav-futures',
      title: 'Future Engine',
      subtitle: 'Simulate trajectories & counterfactual scenarios',
      category: 'Navigation',
      icon: Compass,
      shortcut: '⌘4',
      action: () => {
        onNavigate('futures');
        onClose();
      }
    },
    {
      id: 'nav-interventions',
      title: 'Proactive Interventions',
      subtitle: 'Review timely recommendations and preventive actions',
      category: 'Navigation',
      icon: AlertTriangle,
      shortcut: '⌘5',
      action: () => {
        onNavigate('interventions');
        onClose();
      }
    },
    {
      id: 'nav-agent',
      title: 'Agent Activity',
      subtitle: 'Plan approval, step execution & audit logs',
      category: 'Navigation',
      icon: Bot,
      shortcut: '⌘6',
      action: () => {
        onNavigate('agent');
        onClose();
      }
    },
    {
      id: 'nav-memory',
      title: 'Memory Core',
      subtitle: 'Persistent preferences, habits & context items',
      category: 'Navigation',
      icon: Brain,
      shortcut: '⌘7',
      action: () => {
        onNavigate('memory');
        onClose();
      }
    },
    {
      id: 'nav-settings',
      title: 'System Settings',
      subtitle: 'Companion personality, notifications & devices',
      category: 'Navigation',
      icon: Settings,
      shortcut: '⌘8',
      action: () => {
        onNavigate('settings');
        onClose();
      }
    }
  ], [onNavigate, onClose]);

  // Quick Action Items
  const actionCommands = useMemo<CommandItem[]>(() => [
    {
      id: 'action-refresh',
      title: 'Refresh System Telemetry',
      subtitle: 'Synchronize tasks, memories, and forecasts from backend',
      category: 'Actions',
      icon: RefreshCw,
      shortcut: '⌘R',
      action: () => {
        if (onRefresh) onRefresh();
        onClose();
      }
    },
    {
      id: 'action-mascot',
      title: 'Toggle Floating Mascot Window',
      subtitle: 'Launch or bring the desktop companion to the front',
      category: 'Actions',
      icon: Eye,
      action: () => {
        if (onToggleMascot) onToggleMascot();
        onClose();
      }
    },
    {
      id: 'action-theme',
      title: theme === 'dark' ? 'Switch to Light Theme' : 'Switch to Dark Theme',
      subtitle: `Toggle application visual appearance (currently ${theme} mode)`,
      category: 'Actions',
      icon: theme === 'dark' ? Sun : Moon,
      shortcut: '⌘T',
      action: () => {
        toggleTheme();
        onClose();
      }
    }
  ], [onRefresh, onToggleMascot, onClose, theme, toggleTheme]);

  // Search Results across Live Data
  const searchResults = useMemo<CommandItem[]>(() => {
    const q = query.trim().toLowerCase();
    if (!q) return [];

    const items: CommandItem[] = [];

    // 1. Search Tasks
    tasks.forEach((t) => {
      const titleMatch = t.title.toLowerCase().includes(q);
      const descMatch = (t.description || '').toLowerCase().includes(q);
      const idMatch = t.external_id?.toLowerCase().includes(q);
      if (titleMatch || descMatch || idMatch) {
        items.push({
          id: `task-${t.id}`,
          title: t.title,
          subtitle: `Status: ${t.status} • Priority: ${t.priority || 'Normal'}`,
          category: 'Tasks',
          icon: CheckSquare,
          badge: t.status,
          badgeColor: t.status === 'CLOSED' ? '#34D399' : '#22D3EE',
          action: () => {
            onNavigate('tasks');
            onClose();
          }
        });
      }
    });

    // 2. Search Memories
    memories.forEach((m) => {
      if (m.content.toLowerCase().includes(q) || m.category.toLowerCase().includes(q)) {
        items.push({
          id: `mem-${m.id}`,
          title: m.content,
          subtitle: `Category: ${m.category} • Importance: ${m.importance}/5`,
          category: 'Memories',
          icon: Brain,
          badge: m.category,
          badgeColor: '#A78BFA',
          action: () => {
            onNavigate('memory');
            onClose();
          }
        });
      }
    });

    // 3. Search Predictions
    predictions.forEach((p) => {
      if (p.title.toLowerCase().includes(q) || (p.description || '').toLowerCase().includes(q)) {
        items.push({
          id: `pred-${p.id}`,
          title: p.title,
          subtitle: `${p.time_horizon} Horizon • ${p.probability}% Probability`,
          category: 'Predictions',
          icon: Compass,
          badge: p.prediction_type,
          badgeColor: p.prediction_type === 'RISK' ? '#FB7185' : '#22D3EE',
          action: () => {
            onNavigate('futures');
            onClose();
          }
        });
      }
    });

    // 4. Search Conversations
    conversations.forEach((c) => {
      if (c.title.toLowerCase().includes(q)) {
        items.push({
          id: `conv-${c.id}`,
          title: c.title,
          subtitle: `Conversation Thread • Updated ${c.updated_at ? new Date(c.updated_at).toLocaleDateString() : 'Recently'}`,
          category: 'Conversations',
          icon: MessageSquare,
          badge: 'Thread',
          badgeColor: '#8B5CF6',
          action: () => {
            onNavigate('chat');
            onClose();
          }
        });
      }
    });

    return items;
  }, [query, tasks, memories, predictions, conversations, onNavigate, onClose]);

  // Combined and Filtered Commands
  const displayedItems = useMemo<CommandItem[]>(() => {
    const q = query.trim().toLowerCase();
    if (!q) {
      return [...navCommands, ...actionCommands];
    }

    const filteredNav = navCommands.filter(
      (c) => c.title.toLowerCase().includes(q) || (c.subtitle && c.subtitle.toLowerCase().includes(q))
    );
    const filteredActions = actionCommands.filter(
      (c) => c.title.toLowerCase().includes(q) || (c.subtitle && c.subtitle.toLowerCase().includes(q))
    );

    return [...filteredNav, ...searchResults, ...filteredActions];
  }, [query, navCommands, actionCommands, searchResults]);

  // Reset selected index when results change
  useEffect(() => {
    setSelectedIndex(0);
  }, [displayedItems.length]);

  // Keyboard navigation
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (displayedItems.length === 0) return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % displayedItems.length);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + displayedItems.length) % displayedItems.length);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      const selected = displayedItems[selectedIndex];
      if (selected) {
        selected.action();
      }
    }
  };

  // Scroll active item into view
  useEffect(() => {
    if (listRef.current) {
      const activeEl = listRef.current.querySelector('[data-active="true"]');
      if (activeEl && typeof activeEl.scrollIntoView === 'function') {
        activeEl.scrollIntoView({ block: 'nearest' });
      }
    }
  }, [selectedIndex]);

  if (!isOpen) return null;

  // Group items by category for visual organization
  const groupedCategories = displayedItems.reduce<Record<string, CommandItem[]>>((acc, item) => {
    if (!acc[item.category]) acc[item.category] = [];
    acc[item.category].push(item);
    return acc;
  }, {});

  let globalCounter = 0;

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center pt-[12vh] px-4 animate-in fade-in duration-150"
      style={{
        backgroundColor: 'rgba(5, 6, 10, 0.75)',
        backdropFilter: 'blur(8px)',
        WebkitBackdropFilter: 'blur(8px)'
      }}
      onClick={onClose}
    >
      <div
        className="w-full max-w-2xl rounded-2xl overflow-hidden shadow-2xl flex flex-col animate-in zoom-in-95 duration-150"
        style={{
          backgroundColor: 'var(--bg-surface-elevated)',
          border: '1px solid var(--border)',
          boxShadow: '0 20px 60px rgba(0, 0, 0, 0.5), 0 0 30px rgba(53, 185, 165, 0.15)',
          maxHeight: '70vh'
        }}
        onClick={(e) => e.stopPropagation()}
        onKeyDown={handleKeyDown}
      >
        {/* Search Input Bar */}
        <div
          className="flex items-center px-4 py-3.5 gap-3 border-b"
          style={{ borderColor: 'var(--border-subtle)' }}
        >
          <Search style={{ width: '1.2rem', height: '1.2rem', color: '#35B9A5' }} />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search commands, tasks, memories, predictions..."
            className="flex-1 bg-transparent border-none outline-none text-sm text-primary placeholder-muted font-medium"
            style={{ color: 'var(--text-primary)' }}
          />
          {isLoading && (
            <Loader2 style={{ width: '1rem', height: '1rem', color: '#35B9A5', animation: 'spin 1s linear infinite' }} />
          )}
          {query ? (
            <button
              onClick={() => setQuery('')}
              className="p-1 rounded text-muted hover:text-primary transition-colors cursor-pointer"
              style={{ background: 'none', border: 'none' }}
              title="Clear input"
            >
              <X style={{ width: '0.95rem', height: '0.95rem' }} />
            </button>
          ) : (
            <kbd
              className="text-[10px] font-mono px-2 py-0.5 rounded border text-muted"
              style={{
                backgroundColor: 'rgba(255, 255, 255, 0.05)',
                borderColor: 'rgba(255, 255, 255, 0.1)'
              }}
            >
              ESC
            </kbd>
          )}
        </div>

        {/* Results Stream */}
        <div
          ref={listRef}
          className="flex-1 overflow-y-auto p-2 space-y-4"
          style={{ maxHeight: 'calc(70vh - 110px)' }}
        >
          {displayedItems.length === 0 ? (
            <div className="py-12 text-center text-muted">
              <Command style={{ width: '2rem', height: '2rem', margin: '0 auto 0.75rem', opacity: 0.4 }} />
              <div className="text-sm font-semibold text-secondary">No matching results found</div>
              <div className="text-xs text-muted mt-1">
                Try searching for specific tasks, memories, or navigation sections.
              </div>
            </div>
          ) : (
            Object.entries(groupedCategories).map(([category, items]) => (
              <div key={category} className="space-y-1">
                <div className="px-3 py-1 text-[11px] font-mono font-semibold tracking-wider uppercase text-muted">
                  {category}
                </div>
                {items.map((item) => {
                  const currentIndex = globalCounter++;
                  const isSelected = currentIndex === selectedIndex;
                  const Icon = item.icon;

                  return (
                    <div
                      key={item.id}
                      data-active={isSelected}
                      onClick={item.action}
                      onMouseEnter={() => setSelectedIndex(currentIndex)}
                      className="flex items-center justify-between px-3 py-2.5 rounded-xl cursor-pointer transition-all duration-150"
                      style={{
                        backgroundColor: isSelected
                          ? 'rgba(53, 185, 165, 0.14)'
                          : 'transparent',
                        border: isSelected
                          ? '1px solid rgba(53, 185, 165, 0.35)'
                          : '1px solid transparent'
                      }}
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <div
                          className="p-1.5 rounded-lg flex-shrink-0"
                          style={{
                            backgroundColor: isSelected
                              ? 'rgba(53, 185, 165, 0.22)'
                              : 'var(--border-subtle)',
                            color: isSelected ? '#35B9A5' : 'var(--text-muted)'
                          }}
                        >
                          <Icon style={{ width: '1rem', height: '1rem' }} />
                        </div>
                        <div className="min-w-0">
                          <div className="text-xs font-semibold text-primary truncate">
                            {item.title}
                          </div>
                          {item.subtitle && (
                            <div className="text-[11px] text-muted truncate mt-0.5">
                              {item.subtitle}
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="flex items-center gap-2 flex-shrink-0 ml-3">
                        {item.badge && (
                          <span
                            className="text-[10px] font-mono px-2 py-0.5 rounded-full font-semibold border"
                            style={{
                              backgroundColor: `${item.badgeColor || '#8B5CF6'}18`,
                              borderColor: `${item.badgeColor || '#8B5CF6'}40`,
                              color: item.badgeColor || '#A78BFA'
                            }}
                          >
                            {item.badge}
                          </span>
                        )}
                        {item.shortcut && (
                          <kbd
                            className="text-[10px] font-mono px-1.5 py-0.5 rounded border text-muted"
                            style={{
                              backgroundColor: 'rgba(255, 255, 255, 0.04)',
                              borderColor: 'rgba(255, 255, 255, 0.08)'
                            }}
                          >
                            {item.shortcut}
                          </kbd>
                        )}
                        {isSelected && (
                          <ArrowRight style={{ width: '0.85rem', height: '0.85rem', color: '#35B9A5' }} />
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            ))
          )}
        </div>

        {/* Footer Shortcut Hints */}
        <div
          className="flex items-center justify-between px-4 py-2.5 text-[11px] font-mono text-muted border-t"
          style={{
            backgroundColor: 'var(--bg-surface)',
            borderColor: 'var(--border-subtle)'
          }}
        >
          <div className="flex items-center gap-3">
            <span>
              <kbd className="px-1.5 py-0.5 rounded bg-[rgba(255,255,255,0.06)] border border-[rgba(255,255,255,0.1)] mr-1">
                ↑↓
              </kbd>
              Navigate
            </span>
            <span>
              <kbd className="px-1.5 py-0.5 rounded bg-[rgba(255,255,255,0.06)] border border-[rgba(255,255,255,0.1)] mr-1">
                ↵
              </kbd>
              Select
            </span>
            <span>
              <kbd className="px-1.5 py-0.5 rounded bg-[rgba(255,255,255,0.06)] border border-[rgba(255,255,255,0.1)] mr-1">
                ESC
              </kbd>
              Close
            </span>
          </div>
          <div className="flex items-center gap-1.5 text-[#35B9A5]">
            <Sparkles style={{ width: '0.75rem', height: '0.75rem' }} />
            <span>TESS Global Command</span>
          </div>
        </div>
      </div>
    </div>
  );
};
