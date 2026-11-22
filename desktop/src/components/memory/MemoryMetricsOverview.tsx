import React from 'react';
import { Memory } from '../../types';
import { Brain, Star, CheckCircle2, AlertCircle, Bookmark, Sparkles } from 'lucide-react';

interface MemoryMetricsOverviewProps {
  memories: Memory[];
  selectedCategory: string;
  onSelectCategory: (cat: string) => void;
}

export const MemoryMetricsOverview: React.FC<MemoryMetricsOverviewProps> = ({
  memories,
  selectedCategory,
  onSelectCategory
}) => {
  const total = memories.length;
  const confirmed = memories.filter((m) => m.is_confirmed !== false).length;
  const unconfirmed = memories.filter((m) => m.is_confirmed === false).length;
  const highImportance = memories.filter((m) => (m.importance || 3) >= 4).length;

  const metrics = [
    {
      id: 'ALL',
      label: 'Total Knowledge',
      count: total,
      icon: Brain,
      color: '#A78BFA',
      bgColor: 'rgba(139, 92, 246, 0.12)',
      borderColor: 'rgba(139, 92, 246, 0.3)'
    },
    {
      id: 'CONFIRMED',
      label: 'Confirmed Facts',
      count: confirmed,
      icon: CheckCircle2,
      color: '#34D399',
      bgColor: 'rgba(52, 211, 153, 0.12)',
      borderColor: 'rgba(52, 211, 153, 0.3)'
    },
    {
      id: 'UNCONFIRMED',
      label: 'Needs Review',
      count: unconfirmed,
      icon: AlertCircle,
      color: '#FBBF24',
      bgColor: 'rgba(251, 191, 36, 0.12)',
      borderColor: 'rgba(251, 191, 36, 0.3)'
    },
    {
      id: 'CORE',
      label: 'Core Directives',
      count: highImportance,
      icon: Star,
      color: '#22D3EE',
      bgColor: 'rgba(34, 211, 238, 0.12)',
      borderColor: 'rgba(34, 211, 238, 0.3)'
    }
  ];

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-5">
      {metrics.map((m) => {
        const Icon = m.icon;
        const isActive = selectedCategory === m.id;
        return (
          <button
            key={m.id}
            type="button"
            onClick={() => onSelectCategory(m.id)}
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

