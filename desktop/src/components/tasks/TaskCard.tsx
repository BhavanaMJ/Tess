import React from 'react';
import { ProductivityTask } from '../../types';
import {
  Folder,
  User,
  Clock,
  AlertTriangle,
  ChevronRight,
  Sparkles
} from 'lucide-react';

interface TaskCardProps {
  task: ProductivityTask;
  isSelected?: boolean;
  onSelect: (task: ProductivityTask) => void;
}

export const TaskCard: React.FC<TaskCardProps> = ({
  task,
  isSelected = false,
  onSelect
}) => {
  const isOverdue = !!task.due_date && new Date(task.due_date) < new Date();
  const isHighPriority = (task.priority || '').toUpperCase() === 'HIGH';

  const formatDueDate = (dateStr?: string) => {
    if (!dateStr) return null;
    try {
      const d = new Date(dateStr);
      if (isNaN(d.getTime())) return dateStr;
      return d.toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' });
    } catch {
      return dateStr;
    }
  };

  return (
    <div
      onClick={() => onSelect(task)}
      className={`tess-card p-4 rounded-xl flex items-center justify-between transition-all cursor-pointer group border ${
        isSelected
          ? 'border-[rgba(53,185,165,0.6)] bg-[rgba(53,185,165,0.06)] shadow-md'
          : isOverdue
          ? 'border-[rgba(251,113,133,0.35)] hover:border-[rgba(251,113,133,0.5)]'
          : 'border-[rgba(255,255,255,0.08)] hover:border-[rgba(139,92,246,0.4)]'
      }`}
      data-testid={`task-card-${task.id}`}
    >
      {/* Left Details */}
      <div className="flex items-start gap-3.5 flex-1 min-w-0 pr-4">
        {/* External ID Badge */}
        <span className="font-mono text-xs px-2.5 py-1 rounded-lg font-bold shrink-0 bg-[rgba(139,92,246,0.12)] text-[#A78BFA] border border-[rgba(139,92,246,0.3)] mt-0.5">
          #{task.external_id}
        </span>

        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <h4 className="text-xs sm:text-sm font-semibold text-primary truncate tracking-tight m-0 group-hover:text-[#35B9A5] transition-colors">
              {task.title}
            </h4>
          </div>

          {task.description && (
            <p className="text-xs text-muted mt-1 mb-0 line-clamp-1 leading-relaxed">
              {task.description}
            </p>
          )}

          {/* Metadata Row */}
          <div className="flex flex-wrap items-center gap-2.5 mt-2 text-[11px] text-muted font-mono">
            {task.project && (
              <span className="flex items-center gap-1 text-secondary">
                <Folder style={{ width: '0.75rem', height: '0.75rem', opacity: 0.7 }} />
                <span>{task.project}</span>
              </span>
            )}

            {task.assignee && (
              <span className="flex items-center gap-1 text-secondary">
                <User style={{ width: '0.75rem', height: '0.75rem', opacity: 0.7 }} />
                <span>{task.assignee}</span>
              </span>
            )}

            {task.status && (
              <span className="px-2 py-0.5 rounded-md bg-[rgba(255,255,255,0.05)] text-[10px] text-secondary border border-[rgba(255,255,255,0.08)] uppercase tracking-wider">
                {task.status}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Right Details: Due Date, Priority & Chevron */}
      <div className="flex items-center gap-3 flex-shrink-0">
        {task.due_date && (
          <div
            className={`flex items-center gap-1 text-xs font-mono px-2.5 py-1 rounded-lg border ${
              isOverdue
                ? 'bg-[rgba(251,113,133,0.12)] text-[#FB7185] border-[rgba(251,113,133,0.3)]'
                : 'bg-[rgba(255,255,255,0.03)] text-secondary border-[rgba(255,255,255,0.08)]'
            }`}
          >
            {isOverdue ? (
              <AlertTriangle style={{ width: '0.8rem', height: '0.8rem' }} />
            ) : (
              <Clock style={{ width: '0.8rem', height: '0.8rem' }} />
            )}
            <span>{formatDueDate(task.due_date)}</span>
          </div>
        )}

        {task.priority && (
          <span
            className="text-[10px] font-mono font-bold px-2.5 py-1 rounded-full uppercase tracking-wider border"
            style={{
              backgroundColor: isHighPriority
                ? 'rgba(251, 113, 133, 0.15)'
                : 'rgba(255, 255, 255, 0.04)',
              color: isHighPriority ? '#FB7185' : 'var(--text-muted)',
              borderColor: isHighPriority
                ? 'rgba(251, 113, 133, 0.35)'
                : 'var(--border, rgba(255, 255, 255, 0.08))'
            }}
          >
            {task.priority}
          </span>
        )}

        <ChevronRight
          style={{ width: '1rem', height: '1rem', color: 'var(--text-muted)' }}
          className="group-hover:translate-x-1 group-hover:text-primary transition-all"
        />
      </div>
    </div>
  );
};
