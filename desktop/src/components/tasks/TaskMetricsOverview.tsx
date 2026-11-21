import React from 'react';
import { ProductivitySummary } from '../../types';
import {
  Activity,
  AlertTriangle,
  Clock,
  Calendar,
  CheckCircle2
} from 'lucide-react';

interface TaskMetricsOverviewProps {
  summary: ProductivitySummary | null;
  totalTasks: number;
  activeFilter: string;
  onSelectFilter: (filter: string) => void;
}

export const TaskMetricsOverview: React.FC<TaskMetricsOverviewProps> = ({
  summary,
  totalTasks,
  activeFilter,
  onSelectFilter
}) => {
  const overdueCount = summary?.overdue ?? 0;
  const dueTodayCount = summary?.due_today ?? 0;
  const dueThisWeekCount = summary?.due_this_week ?? 0;
  const completedCount = summary?.completed_recently ?? 0;
  const totalActive = summary?.total_active ?? totalTasks;

  const metricCards = [
    {
      id: 'ALL',
      label: 'Active Packages',
      value: totalActive,
      icon: Activity,
      color: '#22D3EE',
      borderColor: 'var(--border, rgba(255, 255, 255, 0.08))',
      activeBorder: 'rgba(34, 211, 238, 0.5)',
      activeBg: 'rgba(34, 211, 238, 0.08)'
    },
    {
      id: 'OVERDUE',
      label: 'Overdue',
      value: overdueCount,
      icon: AlertTriangle,
      color: '#FB7185',
      borderColor: overdueCount > 0 ? 'rgba(251, 113, 133, 0.35)' : 'var(--border)',
      activeBorder: 'rgba(251, 113, 133, 0.6)',
      activeBg: 'rgba(251, 113, 133, 0.12)'
    },
    {
      id: 'DUE_TODAY',
      label: 'Due Today',
      value: dueTodayCount,
      icon: Clock,
      color: '#FBBF24',
      borderColor: dueTodayCount > 0 ? 'rgba(251, 191, 36, 0.35)' : 'var(--border)',
      activeBorder: 'rgba(251, 191, 36, 0.6)',
      activeBg: 'rgba(251, 191, 36, 0.12)'
    },
    {
      id: 'DUE_WEEK',
      label: 'Due This Week',
      value: dueThisWeekCount,
      icon: Calendar,
      color: '#35B9A5',
      borderColor: 'var(--border)',
      activeBorder: 'rgba(53, 185, 165, 0.6)',
      activeBg: 'rgba(53, 185, 165, 0.12)'
    },
    {
      id: 'COMPLETED',
      label: 'Recent Done (7d)',
      value: completedCount,
      icon: CheckCircle2,
      color: '#34D399',
      borderColor: 'var(--border)',
      activeBorder: 'rgba(52, 211, 153, 0.6)',
      activeBg: 'rgba(52, 211, 153, 0.12)'
    }
  ];

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 mb-6 select-none">
      {metricCards.map((card) => {
        const Icon = card.icon;
        const isSelected = activeFilter === card.id;

        return (
          <button
            key={card.id}
            type="button"
            onClick={() => onSelectFilter(card.id)}
            className="tess-card p-3 rounded-xl flex items-center justify-between text-left transition-all cursor-pointer group"
            style={{
              borderColor: isSelected ? card.activeBorder : card.borderColor,
              backgroundColor: isSelected ? card.activeBg : undefined
            }}
          >
            <div className="flex flex-col">
              <span className="text-[11px] font-mono uppercase tracking-wider text-muted">
                {card.label}
              </span>
              <span
                className="text-xl font-bold font-mono mt-1"
                style={{ color: card.value > 0 ? card.color : 'var(--text-muted)' }}
              >
                {card.value}
              </span>
            </div>
            <div
              className="p-2 rounded-lg flex items-center justify-center transition-transform group-hover:scale-110"
              style={{
                backgroundColor: `${card.color}15`,
                color: card.color
              }}
            >
              <Icon style={{ width: '1.1rem', height: '1.1rem' }} />
            </div>
          </button>
        );
      })}
    </div>
  );
};
