import React from 'react';
import {
  CheckSquare,
  ShieldAlert,
  Clock,
  Calendar,
  TrendingUp,
  Activity
} from 'lucide-react';
import { ProductivitySummary, ProductivityTask } from '../../types';
import { ScreenTab } from '../Sidebar';

interface ProductivityOverviewProps {
  summary: ProductivitySummary | null;
  tasks: ProductivityTask[];
  onNavigate: (tab: ScreenTab) => void;
}

export const ProductivityOverview: React.FC<ProductivityOverviewProps> = ({
  summary,
  tasks,
  onNavigate
}) => {
  const activeCount = summary?.total_active ?? tasks.filter((t) => t.status !== 'CLOSED').length;

  const overdueCount = summary?.overdue ?? tasks.filter((t) => {
    if (!t.due_date || t.status === 'CLOSED') return false;
    return new Date(t.due_date) < new Date();
  }).length;

  const dueTodayCount = summary?.due_today ?? tasks.filter((t) => {
    if (!t.due_date || t.status === 'CLOSED') return false;
    const taskDate = new Date(t.due_date).toDateString();
    return taskDate === new Date().toDateString();
  }).length;

  const dueThisWeekCount = summary?.due_this_week ?? 0;
  const completedRecentCount = summary?.completed_recently ?? tasks.filter((t) => t.status === 'CLOSED').length;

  const metrics = [
    {
      id: 'active',
      title: 'ACTIVE TASKS',
      value: activeCount,
      sublabel: 'Open work packages',
      icon: Activity,
      color: '#35B9A5',
      borderColor: 'rgba(53, 185, 165, 0.3)',
      hoverBorder: 'rgba(53, 185, 165, 0.6)',
      tooltip: 'Total active work packages tracked in TESS & OpenProject'
    },
    {
      id: 'overdue',
      title: 'OVERDUE',
      value: overdueCount,
      sublabel: overdueCount > 0 ? 'Requires intervention' : 'All deadlines met',
      icon: ShieldAlert,
      color: '#FB7185',
      borderColor: overdueCount > 0 ? 'rgba(251, 113, 133, 0.45)' : 'var(--border)',
      hoverBorder: 'rgba(251, 113, 133, 0.7)',
      tooltip: 'Tasks past their deadline that risk milestone slippage'
    },
    {
      id: 'due-today',
      title: 'DUE TODAY',
      value: dueTodayCount,
      sublabel: 'Immediate focus',
      icon: Clock,
      color: '#FBBF24',
      borderColor: dueTodayCount > 0 ? 'rgba(251, 191, 36, 0.4)' : 'var(--border)',
      hoverBorder: 'rgba(251, 191, 36, 0.65)',
      tooltip: 'Items due by end of the current day'
    },
    {
      id: 'due-week',
      title: 'DUE THIS WEEK',
      value: dueThisWeekCount,
      sublabel: '7-day horizon',
      icon: Calendar,
      color: '#22D3EE',
      borderColor: 'var(--border)',
      hoverBorder: 'rgba(34, 211, 238, 0.5)',
      tooltip: 'Work packages scheduled across the next 7 days'
    },
    {
      id: 'completed',
      title: 'COMPLETED',
      value: completedRecentCount,
      sublabel: 'Recent momentum',
      icon: TrendingUp,
      color: '#34D399',
      borderColor: 'var(--border)',
      hoverBorder: 'rgba(52, 211, 153, 0.5)',
      tooltip: 'Work packages completed recently demonstrating execution velocity'
    }
  ];

  return (
    <section aria-label="Productivity Metrics" className="w-full">
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        {metrics.map((metric) => {
          const Icon = metric.icon;
          return (
            <div
              key={metric.id}
              role="button"
              tabIndex={0}
              onClick={() => onNavigate('tasks')}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault();
                  onNavigate('tasks');
                }
              }}
              title={metric.tooltip}
              className="tess-card p-4 cursor-pointer transition-all duration-200 hover:-translate-y-0.5 focus:outline-none focus:ring-1 focus:ring-[#35B9A5]"
              style={{
                borderColor: metric.borderColor,
                backgroundColor: 'var(--bg-secondary)'
              }}
            >
              <div className="flex items-center justify-between text-[11px] font-mono tracking-wider font-semibold">
                <span className="truncate pr-1 text-muted">{metric.title}</span>
                <Icon style={{ width: '0.95rem', height: '0.95rem', color: metric.color, flexShrink: 0 }} />
              </div>

              <div
                className="text-2xl font-bold mt-1.5 font-mono tracking-tight"
                style={{ color: metric.value > 0 ? metric.color : 'var(--text-primary)' }}
              >
                {metric.value}
              </div>

              <div className="text-[11px] text-muted mt-1 truncate">
                {metric.sublabel}
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
};
