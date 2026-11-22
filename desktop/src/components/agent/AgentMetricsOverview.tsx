import React from 'react';
import { AgentPlan } from '../../types';
import { Bot, Clock, CheckCircle2, AlertOctagon, Play, ShieldAlert } from 'lucide-react';

interface AgentMetricsOverviewProps {
  plans: AgentPlan[];
  selectedFilter: string;
  onSelectFilter: (filter: string) => void;
}

export const AgentMetricsOverview: React.FC<AgentMetricsOverviewProps> = ({
  plans,
  selectedFilter,
  onSelectFilter
}) => {
  const total = plans.length;
  const ready = plans.filter((p) => p.status === 'READY').length;
  const executing = plans.filter((p) => p.status === 'EXECUTING').length;
  const completed = plans.filter((p) => p.status === 'SUCCESS').length;
  const failed = plans.filter((p) => p.status === 'FAILED' || p.status === 'CANCELLED').length;

  const metrics = [
    {
      id: 'ALL',
      label: 'Total Plans',
      count: total,
      icon: Bot,
      color: '#A78BFA',
      bgColor: 'rgba(139, 92, 246, 0.12)',
      borderColor: 'rgba(139, 92, 246, 0.3)'
    },
    {
      id: 'READY',
      label: 'Awaiting Action',
      count: ready,
      icon: Clock,
      color: '#22D3EE',
      bgColor: 'rgba(34, 211, 238, 0.12)',
      borderColor: 'rgba(34, 211, 238, 0.3)'
    },
    {
      id: 'EXECUTING',
      label: 'Executing Now',
      count: executing,
      icon: Play,
      color: '#FBBF24',
      bgColor: 'rgba(251, 191, 36, 0.12)',
      borderColor: 'rgba(251, 191, 36, 0.3)'
    },
    {
      id: 'SUCCESS',
      label: 'Completed',
      count: completed,
      icon: CheckCircle2,
      color: '#34D399',
      bgColor: 'rgba(52, 211, 153, 0.12)',
      borderColor: 'rgba(52, 211, 153, 0.3)'
    },
    {
      id: 'FAILED',
      label: 'Failed / Cancelled',
      count: failed,
      icon: AlertOctagon,
      color: '#FB7185',
      bgColor: 'rgba(251, 113, 133, 0.12)',
      borderColor: 'rgba(251, 113, 133, 0.3)'
    }
  ];

  return (
    <div className="grid grid-cols-2 md:grid-cols-5 gap-3 mb-5">
      {metrics.map((m) => {
        const Icon = m.icon;
        const isActive = selectedFilter === m.id;
        return (
          <button
            key={m.id}
            type="button"
            onClick={() => onSelectFilter(m.id)}
            className="tess-card p-3.5 flex items-center justify-between text-left transition-all cursor-pointer hover:border-[rgba(139,92,246,0.4)]"
            style={{
              backgroundColor: isActive ? m.bgColor : 'var(--bg-secondary)',
              borderColor: isActive ? m.borderColor : 'var(--border)'
            }}
          >
            <div>
              <div className="text-[11px] font-mono text-muted uppercase tracking-wider">
                {m.label}
              </div>
              <div className="text-xl font-bold font-mono mt-0.5" style={{ color: m.color }}>
                {m.count}
              </div>
            </div>
            <div
              className="p-2 rounded-xl flex items-center justify-center shrink-0"
              style={{ backgroundColor: m.bgColor, color: m.color }}
            >
              <Icon style={{ width: '1.15rem', height: '1.15rem' }} />
            </div>
          </button>
        );
      })}
    </div>
  );
};

