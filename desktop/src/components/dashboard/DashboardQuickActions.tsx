import React, { useState } from 'react';
import {
  MessageSquare,
  CheckSquare,
  Compass,
  AlertTriangle,
  Bot,
  Brain,
  RefreshCw,
  Check
} from 'lucide-react';
import { ScreenTab } from '../Sidebar';
import { apiService } from '../../services/api';

interface DashboardQuickActionsProps {
  onNavigate: (tab: ScreenTab) => void;
  onRefreshData?: () => void;
}

export const DashboardQuickActions: React.FC<DashboardQuickActionsProps> = ({
  onNavigate,
  onRefreshData
}) => {
  const [isSyncing, setIsSyncing] = useState(false);
  const [syncSuccess, setSyncSuccess] = useState(false);

  const handleSyncOpenProject = async () => {
    setIsSyncing(true);
    setSyncSuccess(false);
    try {
      await apiService.syncOpenProject();
      setSyncSuccess(true);
      if (onRefreshData) {
        onRefreshData();
      }
      setTimeout(() => setSyncSuccess(false), 3000);
    } catch (_) {
      // Handled gracefully
    } finally {
      setIsSyncing(false);
    }
  };

  const actions = [
    {
      id: 'chat',
      label: 'Companion Chat',
      icon: MessageSquare,
      color: '#35B9A5',
      action: () => onNavigate('chat')
    },
    {
      id: 'tasks',
      label: 'Active Tasks',
      icon: CheckSquare,
      color: '#22D3EE',
      action: () => onNavigate('tasks')
    },
    {
      id: 'futures',
      label: 'Simulate Trajectory',
      icon: Compass,
      color: '#A99AD9',
      action: () => onNavigate('futures')
    },
    {
      id: 'interventions',
      label: 'Review Interventions',
      icon: AlertTriangle,
      color: '#FB7185',
      action: () => onNavigate('interventions')
    },
    {
      id: 'agent',
      label: 'Agent Console',
      icon: Bot,
      color: '#A78BFA',
      action: () => onNavigate('agent')
    },
    {
      id: 'memory',
      label: 'Memory Core',
      icon: Brain,
      color: '#34D399',
      action: () => onNavigate('memory')
    }
  ];

  return (
    <div className="tess-card p-4">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <span className="text-[11px] font-mono font-bold text-muted uppercase tracking-wider">
            Quick Actions:
          </span>
          <div className="flex flex-wrap items-center gap-2">
            {actions.map((item) => {
              const Icon = item.icon;
              return (
                <button
                  key={item.id}
                  onClick={item.action}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium cursor-pointer transition-all duration-150 hover:bg-[rgba(255,255,255,0.06)] hover:text-primary"
                  style={{
                    backgroundColor: 'rgba(255, 255, 255, 0.02)',
                    border: '1px solid var(--border)',
                    color: 'var(--text-secondary)'
                  }}
                >
                  <Icon style={{ width: '0.85rem', height: '0.85rem', color: item.color }} />
                  <span>{item.label}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Sync OpenProject Integration Trigger */}
        <button
          onClick={handleSyncOpenProject}
          disabled={isSyncing}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-mono font-semibold transition-all duration-200 cursor-pointer shrink-0"
          style={{
            backgroundColor: syncSuccess ? 'rgba(52, 211, 153, 0.15)' : 'rgba(53, 185, 165, 0.1)',
            borderColor: syncSuccess ? 'rgba(52, 211, 153, 0.4)' : 'rgba(53, 185, 165, 0.35)',
            borderWidth: '1px',
            borderStyle: 'solid',
            color: syncSuccess ? '#34D399' : '#35B9A5'
          }}
          title="Synchronize tasks from OpenProject backend"
        >
          {syncSuccess ? (
            <>
              <Check style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Synced</span>
            </>
          ) : (
            <>
              <RefreshCw
                style={{
                  width: '0.85rem',
                  height: '0.85rem',
                  animation: isSyncing ? 'spin 1s linear infinite' : 'none'
                }}
              />
              <span>{isSyncing ? 'Syncing...' : 'Sync Tasks'}</span>
            </>
          )}
        </button>
      </div>
    </div>
  );
};
