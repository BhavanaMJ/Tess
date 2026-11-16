import React from 'react';
import {
  Home,
  MessageSquare,
  CheckSquare,
  Compass,
  AlertTriangle,
  Bot,
  Brain,
  Settings,
  LogOut
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

  const navItems = [
    { id: 'home' as ScreenTab, label: 'Home', icon: Home },
    { id: 'chat' as ScreenTab, label: 'Chat', icon: MessageSquare },
    { id: 'tasks' as ScreenTab, label: 'Tasks', icon: CheckSquare, badge: badgeCounts.tasks },
    { id: 'futures' as ScreenTab, label: 'Futures', icon: Compass },
    { id: 'interventions' as ScreenTab, label: 'Interventions', icon: AlertTriangle, badge: badgeCounts.interventions, badgeColor: '#EF4444' },
    { id: 'agent' as ScreenTab, label: 'Agent Activity', icon: Bot, badge: badgeCounts.agentPlans },
    { id: 'memory' as ScreenTab, label: 'Memory', icon: Brain },
    { id: 'settings' as ScreenTab, label: 'Settings', icon: Settings }
  ];

  return (
    <aside
      className="flex flex-col justify-between"
      style={{
        width: '240px',
        backgroundColor: 'var(--bg-secondary)',
        borderRight: '1px solid var(--border)',
        height: '100%',
        padding: '1.25rem 0.75rem'
      }}
    >
      <div>
        {/* TESS Brand & Mascot Mini */}
        <div
          className="flex items-center gap-3 px-3 py-2 cursor-pointer"
          onClick={() => onSelectTab('home')}
        >
          <Mascot state={mascotState} size="sm" />
          <div>
            <div className="font-bold text-base tracking-wide" style={{ color: 'var(--text-primary)' }}>
              TESS
            </div>
            <div className="text-xs" style={{ color: 'var(--accent)' }}>
              AI Companion
            </div>
          </div>
        </div>

        <div style={{ height: '1.5rem' }} />

        {/* Navigation list */}
        <nav className="flex flex-col gap-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => onSelectTab(item.id)}
                className="flex items-center justify-between w-full text-sm font-medium"
                style={{
                  padding: '0.65rem 0.85rem',
                  borderRadius: '0.5rem',
                  border: 'none',
                  backgroundColor: isActive ? 'var(--bg-card)' : 'transparent',
                  color: isActive ? 'var(--accent-light)' : 'var(--text-secondary)',
                  cursor: 'pointer',
                  textAlign: 'left',
                  transition: 'all 0.15s'
                }}
              >
                <div className="flex items-center gap-3">
                  <Icon style={{ width: '1.15rem', height: '1.15rem' }} />
                  <span>{item.label}</span>
                </div>
                {item.badge && item.badge > 0 ? (
                  <span
                    className="text-xs px-2 py-0.5 rounded-full font-bold"
                    style={{
                      backgroundColor: item.badgeColor ? `${item.badgeColor}25` : 'var(--accent)25',
                      color: item.badgeColor || 'var(--accent-light)'
                    }}
                  >
                    {item.badge}
                  </span>
                ) : null}
              </button>
            );
          })}
        </nav>
      </div>

      {/* User footer & sign out */}
      <div style={{ borderTop: '1px solid var(--border)', paddingTop: '0.75rem' }}>
        <div
          className="flex items-center justify-between px-2 py-1"
          style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}
        >
          <div className="truncate" style={{ maxWidth: '140px' }} title={user?.email || 'Authenticated'}>
            {user?.email || 'Active User'}
          </div>
          <button
            onClick={signOut}
            title="Sign out"
            style={{
              background: 'transparent',
              border: 'none',
              color: 'var(--text-muted)',
              cursor: 'pointer',
              padding: '0.25rem'
            }}
          >
            <LogOut style={{ width: '1rem', height: '1rem' }} />
          </button>
        </div>
      </div>
    </aside>
  );
};

