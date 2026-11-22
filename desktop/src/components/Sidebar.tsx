import React, { useState, useEffect } from 'react';
import {
  Home,
  MessageSquare,
  CheckSquare,
  Compass,
  AlertTriangle,
  Bot,
  Brain,
  Settings,
  LogOut,
  ChevronLeft,
  ChevronRight,
  Search,
  Command
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { useMascot } from '../contexts/MascotContext';

export type ScreenTab =
  | 'home'
  | 'chat'
  | 'tasks'
  | 'futures'
  | 'interventions'
  | 'agent'
  | 'memory'
  | 'settings';

interface SidebarProps {
  currentTab: ScreenTab;
  onSelectTab: (tab: ScreenTab) => void;
  onOpenCommandPalette?: () => void;
  badgeCounts?: {
    interventions?: number;
    tasks?: number;
    agentPlans?: number;
  };
}

interface NavSection {
  title: string;
  items: {
    id: ScreenTab;
    label: string;
    icon: React.ComponentType<{ style?: React.CSSProperties; className?: string }>;
    badge?: number;
    badgeColor?: string;
    shortcut: string;
  }[];
}

const STORAGE_KEY = 'tess_desktop_sidebar_collapsed';

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  onOpenCommandPalette,
  badgeCounts = {}
}) => {
  const { signOut, user } = useAuth();
  const { state: mascotState } = useMascot();

  const [collapsed, setCollapsed] = useState<boolean>(() => {
    try {
      return localStorage.getItem(STORAGE_KEY) === 'true';
    } catch {
      return false;
    }
  });

  const toggleCollapsed = () => {
    setCollapsed((prev) => {
      const next = !prev;
      try {
        localStorage.setItem(STORAGE_KEY, String(next));
      } catch {}
      return next;
    });
  };

  const navSections: NavSection[] = [
    {
      title: 'WORKSPACE',
      items: [
        { id: 'home', label: 'Command Home', icon: Home, shortcut: '⌘1' },
        { id: 'chat', label: 'Companion Chat', icon: MessageSquare, shortcut: '⌘2' },
        { id: 'tasks', label: 'Active Tasks', icon: CheckSquare, badge: badgeCounts.tasks, shortcut: '⌘3' }
      ]
    },
    {
      title: 'INTELLIGENCE',
      items: [
        { id: 'futures', label: 'Future Engine', icon: Compass, badgeColor: '#22D3EE', shortcut: '⌘4' },
        {
          id: 'interventions',
          label: 'Interventions',
          icon: AlertTriangle,
          badge: badgeCounts.interventions,
          badgeColor: '#FB7185',
          shortcut: '⌘5'
        },
        {
          id: 'agent',
          label: 'Agent Activity',
          icon: Bot,
          badge: badgeCounts.agentPlans,
          badgeColor: '#A78BFA',
          shortcut: '⌘6'
        }
      ]
    },
    {
      title: 'SYSTEM & CONTEXT',
      items: [
        { id: 'memory', label: 'Memory Core', icon: Brain, shortcut: '⌘7' },
        { id: 'settings', label: 'System Settings', icon: Settings, shortcut: '⌘8' }
      ]
    }
  ];

  return (
    <aside
      className="flex flex-col justify-between select-none relative z-20 transition-all duration-300 ease-in-out shrink-0"
      style={{
        width: collapsed ? '72px' : '260px',
        backgroundColor: 'var(--bg-secondary)',
        borderRight: '1px solid var(--border)',
        height: '100%',
        padding: '1.25rem 0.65rem',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)'
      }}
    >
      <div className="flex flex-col gap-4">
        {/* TESS Brand Core & Header */}
        <div
          className={`flex items-center gap-3 px-2 py-2 cursor-pointer rounded-xl transition-all hover:bg-[rgba(255,255,255,0.03)] ${
            collapsed ? 'justify-center' : ''
          }`}
          onClick={() => onSelectTab('home')}
          title="TESS AI Operating System"
        >
          <div
            className="w-8 h-8 rounded-xl flex items-center justify-center shrink-0"
            style={{
              background: 'linear-gradient(135deg, #35B9A5 0%, #168F83 100%)',
              boxShadow: '0 0 12px rgba(53, 185, 165, 0.35)'
            }}
          >
            <span className="font-mono font-bold text-xs text-[#F4FFFB]">T</span>
          </div>
          {!collapsed && (
            <div className="overflow-hidden">
              <div className="flex items-center gap-1.5">
                <span className="font-bold text-sm tracking-widest text-primary font-mono">
                  TESS
                </span>
                <span className="text-[10px] px-1.5 py-0.2 rounded-full font-mono bg-[rgba(34,211,238,0.1)] text-[#22D3EE] border border-[rgba(34,211,238,0.3)]">
                  OS 2.0
                </span>
              </div>
              <div className="text-[11px] font-mono tracking-wider text-muted">
                AI Companion
              </div>
            </div>
          )}
        </div>

        {/* Global Command Palette Quick Trigger */}
        {onOpenCommandPalette && (
          <button
            onClick={onOpenCommandPalette}
            title={collapsed ? 'Quick Actions (⌘K)' : undefined}
            className={`flex items-center ${
              collapsed ? 'justify-center' : 'justify-between'
            } w-full text-xs font-medium cursor-pointer transition-all duration-200 rounded-lg group`}
            style={{
              padding: collapsed ? '0.65rem 0' : '0.55rem 0.75rem',
              backgroundColor: 'rgba(255, 255, 255, 0.03)',
              border: '1px solid var(--border)',
              color: 'var(--text-muted)'
            }}
          >
            <div className="flex items-center gap-2.5">
              <Search style={{ width: '0.95rem', height: '0.95rem', color: '#35B9A5' }} />
              {!collapsed && (
                <span className="group-hover:text-primary transition-colors">
                  Quick Search
                </span>
              )}
            </div>
            {!collapsed && (
              <kbd className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-[rgba(255,255,255,0.06)] border border-[rgba(255,255,255,0.1)] text-secondary">
                ⌘K
              </kbd>
            )}
          </button>
        )}

        {/* Categorized Navigation Sections */}
        <nav className="flex flex-col gap-4 overflow-y-auto no-scrollbar">
          {navSections.map((section) => (
            <div key={section.title} className="flex flex-col gap-1">
              {!collapsed && (
                <div className="px-2 pb-1 text-[10px] font-mono font-semibold tracking-wider text-muted uppercase">
                  {section.title}
                </div>
              )}
              {section.items.map((item) => {
                const Icon = item.icon;
                const isActive = currentTab === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => onSelectTab(item.id)}
                    title={collapsed ? `${item.label} (${item.shortcut})` : undefined}
                    className={`flex items-center ${
                      collapsed ? 'justify-center' : 'justify-between'
                    } w-full text-xs font-medium cursor-pointer transition-all duration-200 relative group`}
                    style={{
                      padding: collapsed ? '0.7rem 0' : '0.6rem 0.85rem',
                      borderRadius: '0.65rem',
                      border: isActive
                        ? '1px solid rgba(53, 185, 165, 0.4)'
                        : '1px solid transparent',
                      backgroundColor: isActive
                        ? 'rgba(53, 185, 165, 0.14)'
                        : 'transparent',
                      color: isActive ? 'var(--text-primary)' : 'var(--text-secondary)'
                    }}
                  >
                    {/* Active Accent Left Bar */}
                    {isActive && (
                      <div
                        className="absolute left-0 top-1.5 bottom-1.5 w-1 rounded-r-full"
                        style={{
                          backgroundColor: '#35B9A5',
                          boxShadow: '0 0 10px rgba(53, 185, 165, 0.6)'
                        }}
                      />
                    )}

                    <div className="flex items-center gap-3">
                      <Icon
                        style={{
                          width: '1.15rem',
                          height: '1.15rem',
                          color: isActive ? '#35B9A5' : 'var(--text-muted)'
                        }}
                      />
                      {!collapsed && (
                        <span className="tracking-wide">{item.label}</span>
                      )}
                    </div>

                    {!collapsed && (
                      <div className="flex items-center gap-1.5">
                        {item.badge !== undefined && item.badge > 0 && (
                          <span
                            className="font-mono text-[10px] font-bold px-1.5 py-0.5 rounded-full"
                            style={{
                              backgroundColor: `${item.badgeColor || '#8B5CF6'}25`,
                              color: item.badgeColor || '#A78BFA',
                              border: `1px solid ${item.badgeColor || '#8B5CF6'}50`
                            }}
                          >
                            {item.badge}
                          </span>
                        )}
                        <span className="text-[10px] font-mono text-muted/60 opacity-0 group-hover:opacity-100 transition-opacity">
                          {item.shortcut}
                        </span>
                      </div>
                    )}
                  </button>
                );
              })}
            </div>
          ))}
        </nav>
      </div>

      {/* Rail Footer: User Telemetry & Collapse Control */}
      <div className="flex flex-col gap-2 pt-3 border-t border-[rgba(255,255,255,0.06)]">
        {/* User Identity */}
        {!collapsed && user && (
          <div className="px-2 py-1.5 flex items-center justify-between rounded-lg bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.04)]">
            <div className="overflow-hidden">
              <div className="text-[11px] font-semibold text-primary truncate max-w-[130px]">
                {user.email?.split('@')[0]}
              </div>
              <div className="text-[10px] font-mono text-[#34D399] flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-[#34D399] animate-pulse" />
                ONLINE
              </div>
            </div>
            <button
              onClick={() => signOut()}
              title="Sign Out"
              className="p-1 rounded hover:bg-[rgba(251,113,133,0.15)] text-muted hover:text-[#FB7185] transition-colors cursor-pointer"
              style={{ background: 'none', border: 'none' }}
            >
              <LogOut style={{ width: '0.95rem', height: '0.95rem' }} />
            </button>
          </div>
        )}

        {/* Expand / Collapse Rail Toggle */}
        <button
          onClick={toggleCollapsed}
          className="flex items-center justify-center w-full py-1.5 text-muted hover:text-primary rounded-lg transition-colors hover:bg-[rgba(255,255,255,0.04)]"
          style={{ background: 'none', border: 'none', cursor: 'pointer' }}
          title={collapsed ? 'Expand Sidebar' : 'Collapse Sidebar'}
        >
          {collapsed ? (
            <ChevronRight style={{ width: '1.1rem', height: '1.1rem' }} />
          ) : (
            <div className="flex items-center gap-2 text-xs font-mono">
              <ChevronLeft style={{ width: '1rem', height: '1rem' }} />
              <span>COLLAPSE</span>
            </div>
          )}
        </button>
      </div>
    </aside>
  );
};
