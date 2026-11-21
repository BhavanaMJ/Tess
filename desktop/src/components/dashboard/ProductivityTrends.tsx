import React from 'react';
import { BarChart3, TrendingUp, CheckCircle, Clock } from 'lucide-react';
import { ProductivitySummary, ProductivityTask } from '../../types';

interface ProductivityTrendsProps {
  summary: ProductivitySummary | null;
  tasks: ProductivityTask[];
}

export const ProductivityTrends: React.FC<ProductivityTrendsProps> = ({
  summary,
  tasks
}) => {
  const totalTasks = tasks.length;
  
  // Real status calculations
  const closedCount = tasks.filter((t) => t.status === 'CLOSED').length;
  const inProgressCount = tasks.filter((t) => t.status === 'IN_PROGRESS').length;
  const overdueCount = summary?.overdue ?? tasks.filter((t) => {
    if (!t.due_date || t.status === 'CLOSED') return false;
    return new Date(t.due_date) < new Date();
  }).length;
  const openCount = totalTasks - closedCount;

  const completionRate = totalTasks > 0 ? Math.round((closedCount / totalTasks) * 100) : 0;
  const activeRate = totalTasks > 0 ? Math.round((inProgressCount / totalTasks) * 100) : 0;
  const overdueRate = totalTasks > 0 ? Math.round((overdueCount / totalTasks) * 100) : 0;

  // Priority distribution
  const highPriority = tasks.filter(
    (t) => t.priority?.toLowerCase() === 'high' || t.priority?.toLowerCase() === 'urgent'
  ).length;
  const normalPriority = tasks.filter(
    (t) => !t.priority || t.priority?.toLowerCase() === 'normal'
  ).length;
  const lowPriority = tasks.filter(
    (t) => t.priority?.toLowerCase() === 'low'
  ).length;

  return (
    <div className="tess-card p-5 h-full flex flex-col justify-between">
      <div>
        {/* Section Header */}
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-[rgba(255,255,255,0.06)]">
          <div className="flex items-center gap-2">
            <BarChart3 style={{ width: '1rem', height: '1rem', color: '#35B9A5' }} />
            <span className="text-xs font-bold text-primary font-mono tracking-wider uppercase">
              Productivity Velocity & Distribution
            </span>
          </div>
          <span className="text-[11px] font-mono text-muted">
            {totalTasks} total work packages
          </span>
        </div>

        {totalTasks === 0 ? (
          <div className="py-8 text-center text-muted">
            <Clock style={{ width: '1.5rem', height: '1.5rem', margin: '0 auto', opacity: 0.5 }} />
            <div className="text-xs font-semibold text-secondary mt-2">No Task Telemetry Available</div>
            <p className="text-[11px] text-muted mt-1 max-w-xs mx-auto">
              Sync work packages from OpenProject to observe completion velocity and status distribution.
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {/* Completion Velocity Metric Box */}
            <div className="p-3 rounded-xl bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.05)]">
              <div className="flex items-center justify-between text-xs mb-1.5">
                <span className="text-muted font-medium">Work Package Completion Rate</span>
                <span className="font-mono font-bold text-[#34D399]">{completionRate}%</span>
              </div>

              {/* Multi-Segment Status Progress Bar */}
              <div className="w-full h-2 rounded-full overflow-hidden flex bg-[rgba(255,255,255,0.06)]">
                <div
                  style={{ width: `${completionRate}%`, backgroundColor: '#34D399' }}
                  title={`Completed: ${closedCount} (${completionRate}%)`}
                />
                <div
                  style={{ width: `${activeRate}%`, backgroundColor: '#35B9A5' }}
                  title={`In Progress: ${inProgressCount} (${activeRate}%)`}
                />
                <div
                  style={{ width: `${overdueRate}%`, backgroundColor: '#FB7185' }}
                  title={`Overdue: ${overdueCount} (${overdueRate}%)`}
                />
              </div>

              <div className="flex items-center justify-between text-[10px] font-mono text-muted mt-2 pt-1">
                <span className="flex items-center gap-1">
                  <span className="w-2 h-2 rounded-full bg-[#34D399]" /> Closed ({closedCount})
                </span>
                <span className="flex items-center gap-1">
                  <span className="w-2 h-2 rounded-full bg-[#35B9A5]" /> Active ({openCount})
                </span>
                <span className="flex items-center gap-1">
                  <span className="w-2 h-2 rounded-full bg-[#FB7185]" /> Overdue ({overdueCount})
                </span>
              </div>
            </div>

            {/* Priority Distribution Breakdown */}
            <div>
              <div className="text-[11px] font-mono font-semibold text-muted uppercase tracking-wider mb-2">
                Workload by Priority
              </div>
              <div className="grid grid-cols-3 gap-2">
                <div className="p-2.5 rounded-lg bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.05)] text-center">
                  <div className="text-[10px] font-mono text-[#FB7185]">HIGH</div>
                  <div className="text-lg font-bold font-mono text-primary mt-0.5">{highPriority}</div>
                </div>
                <div className="p-2.5 rounded-lg bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.05)] text-center">
                  <div className="text-[10px] font-mono text-[#35B9A5]">NORMAL</div>
                  <div className="text-lg font-bold font-mono text-primary mt-0.5">{normalPriority}</div>
                </div>
                <div className="p-2.5 rounded-lg bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.05)] text-center">
                  <div className="text-[10px] font-mono text-muted">LOW</div>
                  <div className="text-lg font-bold font-mono text-primary mt-0.5">{lowPriority}</div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Footer Insight */}
      <div className="pt-3 border-t border-[rgba(255,255,255,0.06)] text-[11px] font-mono text-muted flex items-center justify-between">
        <span className="flex items-center gap-1 text-secondary">
          <TrendingUp style={{ width: '0.85rem', height: '0.85rem', color: '#35B9A5' }} />
          <span>Velocity: {summary?.completed_recently ?? closedCount} recently completed</span>
        </span>
      </div>
    </div>
  );
};

