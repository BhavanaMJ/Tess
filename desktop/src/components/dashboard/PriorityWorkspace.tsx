import React from 'react';
import {
  AlertTriangle,
  Clock,
  CheckCircle2,
  ArrowRight,
  ShieldAlert,
  Bot,
  Zap,
  CheckSquare
} from 'lucide-react';
import { ProductivityTask, InterventionResponse, AgentPlan } from '../../types';
import { ScreenTab } from '../Sidebar';

interface PriorityWorkspaceProps {
  tasks: ProductivityTask[];
  interventions: InterventionResponse[];
  plans: AgentPlan[];
  onNavigate: (tab: ScreenTab) => void;
}

interface PriorityItem {
  id: string;
  type: 'TASK_OVERDUE' | 'TASK_TODAY' | 'TASK_HIGH' | 'INTERVENTION' | 'AGENT_APPROVAL';
  title: string;
  subtitle: string;
  priorityLabel: string;
  priorityColor: string;
  badge?: string;
  dateText?: string;
  actionText: string;
  action: () => void;
}

export const PriorityWorkspace: React.FC<PriorityWorkspaceProps> = ({
  tasks,
  interventions,
  plans,
  onNavigate
}) => {
  const items: PriorityItem[] = [];

  // 1. Pending Sent Interventions (highest urgency)
  const activeInvs = interventions.filter((i) => i.status === 'SENT');
  activeInvs.forEach((inv) => {
    items.push({
      id: `inv-${inv.id}`,
      type: 'INTERVENTION',
      title: inv.title,
      subtitle: inv.message,
      priorityLabel: 'URGENT INTERVENTION',
      priorityColor: '#FB7185',
      badge: 'PROACTIVE',
      actionText: 'Review Intervention',
      action: () => onNavigate('interventions')
    });
  });

  // 2. Overdue Tasks
  const overdueTasks = tasks.filter((t) => {
    if (!t.due_date || t.status === 'CLOSED') return false;
    return new Date(t.due_date) < new Date();
  });
  overdueTasks.forEach((t) => {
    items.push({
      id: `task-od-${t.id}`,
      type: 'TASK_OVERDUE',
      title: t.title,
      subtitle: `${t.project || 'OpenProject'} • Priority: ${t.priority || 'High'}`,
      priorityLabel: 'OVERDUE',
      priorityColor: '#FB7185',
      dateText: t.due_date,
      actionText: 'Open Task',
      action: () => onNavigate('tasks')
    });
  });

  // 3. Due Today Tasks
  const todayStr = new Date().toDateString();
  const dueTodayTasks = tasks.filter((t) => {
    if (!t.due_date || t.status === 'CLOSED') return false;
    return new Date(t.due_date).toDateString() === todayStr;
  });
  dueTodayTasks.forEach((t) => {
    if (!overdueTasks.some((od) => od.id === t.id)) {
      items.push({
        id: `task-td-${t.id}`,
        type: 'TASK_TODAY',
        title: t.title,
        subtitle: `${t.project || 'OpenProject'} • ${t.priority || 'Normal'} priority`,
        priorityLabel: 'DUE TODAY',
        priorityColor: '#FBBF24',
        dateText: t.due_date,
        actionText: 'Open Task',
        action: () => onNavigate('tasks')
      });
    }
  });

  // 4. Pending Agent Approvals
  const pendingPlans = plans.filter((p) => p.status === 'READY');
  pendingPlans.forEach((plan) => {
    items.push({
      id: `plan-${plan.id}`,
      type: 'AGENT_APPROVAL',
      title: plan.objective,
      subtitle: `${plan.steps?.length || 0} step(s) awaiting user confirmation`,
      priorityLabel: 'APPROVAL NEEDED',
      priorityColor: '#A78BFA',
      badge: 'AUTONOMOUS',
      actionText: 'Confirm Plan',
      action: () => onNavigate('agent')
    });
  });

  // 5. High Priority Tasks (if under 6 items)
  if (items.length < 5) {
    const highTasks = tasks.filter((t) => {
      const isHigh = t.priority?.toLowerCase() === 'high' || t.priority?.toLowerCase() === 'urgent';
      const notIncluded = !items.some((item) => item.id.includes(t.id));
      return isHigh && t.status !== 'CLOSED' && notIncluded;
    });
    highTasks.slice(0, 3).forEach((t) => {
      items.push({
        id: `task-hi-${t.id}`,
        type: 'TASK_HIGH',
        title: t.title,
        subtitle: `${t.project || 'OpenProject'} • High impact milestone`,
        priorityLabel: 'HIGH PRIORITY',
        priorityColor: '#35B9A5',
        dateText: t.due_date,
        actionText: 'Inspect',
        action: () => onNavigate('tasks')
      });
    });
  }

  return (
    <div className="tess-card p-5 flex flex-col justify-between h-full">
      <div>
        {/* Header */}
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-[rgba(255,255,255,0.06)]">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-lg bg-[rgba(53,185,165,0.12)] border border-[rgba(53,185,165,0.3)] flex items-center justify-center">
              <Zap style={{ width: '0.95rem', height: '0.95rem', color: '#35B9A5' }} />
            </div>
            <div>
              <h3 className="text-sm font-bold text-primary font-mono tracking-wide m-0">
                MY DAY & PRIORITY WORKSPACE
              </h3>
              <p className="text-[11px] text-muted m-0">
                What deserves your attention right now
              </p>
            </div>
          </div>

          <button
            onClick={() => onNavigate('tasks')}
            className="text-xs font-mono text-[#35B9A5] hover:text-[#BDF2E4] flex items-center gap-1 cursor-pointer transition-colors"
            style={{ background: 'none', border: 'none' }}
          >
            <span>All Tasks</span>
            <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
          </button>
        </div>

        {/* Priority Item List */}
        {items.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-10 px-4 text-center">
            <div className="w-12 h-12 rounded-full bg-[rgba(52,211,153,0.12)] border border-[rgba(52,211,153,0.3)] flex items-center justify-center mb-3">
              <CheckCircle2 style={{ width: '1.75rem', height: '1.75rem', color: '#34D399' }} />
            </div>
            <h4 className="text-sm font-semibold text-primary m-0">
              You are completely caught up!
            </h4>
            <p className="text-xs text-muted max-w-sm mt-1 leading-relaxed">
              No overdue items, active interventions, or pending approvals require your attention today. You can focus on proactive planning or exploration.
            </p>
            <button
              onClick={() => onNavigate('chat')}
              className="mt-4 px-3.5 py-1.5 rounded-lg text-xs font-semibold bg-[rgba(53,185,165,0.15)] text-[#35B9A5] border border-[rgba(53,185,165,0.3)] hover:bg-[rgba(53,185,165,0.25)] transition-colors cursor-pointer"
            >
              Plan Next Milestone with TESS
            </button>
          </div>
        ) : (
          <div className="space-y-2.5">
            {items.slice(0, 5).map((item) => (
              <div
                key={item.id}
                onClick={item.action}
                role="button"
                tabIndex={0}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    item.action();
                  }
                }}
                className="p-3 rounded-xl transition-all duration-200 cursor-pointer hover:bg-[rgba(255,255,255,0.03)] border flex items-center justify-between gap-3 group"
                style={{
                  backgroundColor: 'var(--bg-secondary)',
                  borderColor: item.priorityColor === '#FB7185' ? 'rgba(251, 113, 133, 0.35)' : 'var(--border)'
                }}
              >
                <div className="flex items-start gap-2.5 min-w-0">
                  <div className="pt-0.5 shrink-0">
                    {item.type === 'INTERVENTION' ? (
                      <ShieldAlert style={{ width: '1rem', height: '1rem', color: '#FB7185' }} />
                    ) : item.type === 'AGENT_APPROVAL' ? (
                      <Bot style={{ width: '1rem', height: '1rem', color: '#A78BFA' }} />
                    ) : item.type === 'TASK_OVERDUE' ? (
                      <Clock style={{ width: '1rem', height: '1rem', color: '#FB7185' }} />
                    ) : (
                      <CheckSquare style={{ width: '1rem', height: '1rem', color: item.priorityColor }} />
                    )}
                  </div>

                  <div className="min-w-0">
                    <div className="flex items-center gap-2 mb-0.5">
                      <span
                        className="text-[9px] font-mono font-bold px-1.5 py-0.2 rounded"
                        style={{
                          backgroundColor: `${item.priorityColor}20`,
                          color: item.priorityColor,
                          border: `1px solid ${item.priorityColor}40`
                        }}
                      >
                        {item.priorityLabel}
                      </span>
                      {item.badge && (
                        <span className="text-[9px] font-mono text-muted bg-[rgba(255,255,255,0.05)] px-1.5 py-0.2 rounded">
                          {item.badge}
                        </span>
                      )}
                    </div>
                    <div className="text-xs font-semibold text-primary truncate group-hover:text-[#BDF2E4] transition-colors">
                      {item.title}
                    </div>
                    <div className="text-[11px] text-muted truncate mt-0.5">
                      {item.subtitle}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2 shrink-0">
                  {item.dateText && (
                    <span className="text-[10px] font-mono text-muted hidden sm:inline-block">
                      {item.dateText}
                    </span>
                  )}
                  <span className="text-xs font-mono text-[#35B9A5] flex items-center gap-1 group-hover:translate-x-0.5 transition-transform">
                    {item.actionText}
                    <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {items.length > 5 && (
        <div className="pt-3 mt-3 border-t border-[rgba(255,255,255,0.06)] flex justify-between items-center text-xs font-mono text-muted">
          <span>+{items.length - 5} more prioritized items</span>
          <button
            onClick={() => onNavigate('tasks')}
            className="text-[#35B9A5] hover:underline cursor-pointer"
            style={{ background: 'none', border: 'none' }}
          >
            Review all in Tasks
          </button>
        </div>
      )}
    </div>
  );
};
