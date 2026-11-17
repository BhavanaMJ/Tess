import React, { useState } from 'react';
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
  ShieldCheck
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { Mascot } from './Mascot';
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
  badgeCounts?: {
    interventions?: number;
    tasks?: number;
    agentPlans?: number;
  };
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  badgeCounts = {}
}) => {
  const { signOut, user } = useAuth();
  const { state: mascotState } = useMascot();
  const [collapsed, setCollapsed] = useState(false);

  const navItems = [
    { id: 'home' as ScreenTab, label: 'Command Home', icon: Home },
    { id: 'chat' as ScreenTab, label: 'Companion Chat', icon: MessageSquare },
    { id: 'tasks' as ScreenTab, label: 'Active Tasks', icon: CheckSquare, badge: badgeCounts.tasks },
    { id: 'futures' as ScreenTab, label: 'Future Engine', icon: Compass, badgeColor: '#22D3EE' },
    { id: 'interventions' as ScreenTab, label: 'Interventions', icon: AlertTriangle, badge: badgeCounts.interventions, badgeColor: '#FB7185' },
    { id: 'agent' as ScreenTab, label: 'Agent Activity', icon: Bot, badge: badgeCounts.agentPlans, badgeColor: '#A78BFA' },
    { id: 'memory' as ScreenTab, label: 'Memory Core', icon: Brain },
    { id: 'settings' as ScreenTab, label: 'System Settings', icon: Settings }
  ];

  return (
    <aside
      className="flex flex-col justify-between select-none relative z-20 transition-all duration-300 ease-in-out"
      style={{
        width: collapsed ? '74px' : '250px',
        backgroundColor: 'var(--bg-secondary)',
        borderRight: '1px solid var(--border)',
        height: '100%',
        padding: '1.25rem 0.65rem',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)'
      }}
    >
      <div>
        {/* TESS Brand Core & Mascot Header */}
        <div
          className={`flex items-center gap-3 px-2 py-2 cursor-pointer rounded-xl transition-all ${
            collapsed ? 'justify-center' : ''
          }`}
          onClick={() => onSelectTab('home')}
          title="TESS AI Operating System"
        >
          <Mascot state={mascotState} size="sm" />
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

        <div style={{ height: '1.5rem' }} />

        {/* Futuristic Rail Navigation */}
        <nav className="flex flex-col gap-1.5">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => onSelectTab(item.id)}
                title={collapsed ? item.label : undefined}
                className={`flex items-center ${
                  collapsed ? 'justify-center' : 'justify-between'
                } w-full text-xs font-medium cursor-pointer transition-all duration-200 relative group`}
                style={{
                  padding: collapsed ? '0.75rem 0' : '0.65rem 0.85rem',
                  borderRadius: '0.65rem',
                  border: isActive
                    ? '1px solid rgba(139, 92, 246, 0.4)'
                    : '1px solid transparent',
                  backgroundColor: isActive
                    ? 'rgba(139, 92, 246, 0.12)'
                    : 'transparent',
                  color: isActive ? '#F8FAFC' : 'var(--text-secondary)'
                }}
              >
                {/* Active Neon Accent Left Bar */}
                {isActive && (
                  <div
                    className="absolute left-0 top-1.5 bottom-1.5 w-1 rounded-r-full"
                    style={{
                      backgroundColor: '#8B5CF6',
                      boxShadow: '0 0 10px #8B5CF6'
                    }}
                  />
                )}

                <div className="flex items-center gap-3">
                  <Icon
                    style={{
                      width: '1.15rem',
                      height: '1.15rem',
                      color: isActive ? '#A78BFA' : 'var(--text-muted)'
                    }}
                  />
                  {!collapsed && (
                    <span className="tracking-wide">{item.label}</span>
                  )}
                </div>

                {!collapsed && item.badge !== undefined && item.badge > 0 && (
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
              </button>
            );
          })}
        </nav>
      </div>

      {/* Rail Footer: User Telemetry & Collapse Control */}
      <div className="flex flex-col gap-2 pt-3 border-t border-[rgba(255,255,255,0.06)]">
        {/* User Identity */}
        {!collapsed && user && (
          <div className="px-2 py-1.5 flex items-center justify-between rounded-lg bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.04)]">
            <div className="overflow-hidden">
              <div className="text-[11px] font-semibold text-primary truncate">
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
              className="p-1 rounded hover:bg-[rgba(251,113,133,0.15)] text-muted hover:text-[#FB7185] transition-colors"
              style={{ background: 'none', border: 'none' }}
            >
              <LogOut style={{ width: '0.95rem', height: '0.95rem' }} />
            </button>
          </div>
        )}

        {/* Expand / Collapse Rail Toggle */}
        <button
          onClick={() => setCollapsed(!collapsed)}
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
