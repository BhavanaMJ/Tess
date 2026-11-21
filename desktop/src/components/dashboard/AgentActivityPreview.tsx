import React from 'react';
import { Bot, ArrowRight, Terminal, CheckCircle2, AlertCircle } from 'lucide-react';
import { AgentPlan } from '../../types';
import { ScreenTab } from '../Sidebar';

interface AgentActivityPreviewProps {
  plans: AgentPlan[];
  onNavigate: (tab: ScreenTab) => void;
}

export const AgentActivityPreview: React.FC<AgentActivityPreviewProps> = ({
  plans,
  onNavigate
}) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'SUCCESS':
        return { bg: 'rgba(52, 211, 153, 0.15)', text: '#34D399', border: 'rgba(52, 211, 153, 0.3)' };
      case 'READY':
        return { bg: 'rgba(167, 139, 250, 0.15)', text: '#A78BFA', border: 'rgba(167, 139, 250, 0.3)' };
      case 'EXECUTING':
        return { bg: 'rgba(34, 211, 238, 0.15)', text: '#22D3EE', border: 'rgba(34, 211, 238, 0.3)' };
      case 'FAILED':
      case 'CANCELLED':
        return { bg: 'rgba(251, 113, 133, 0.15)', text: '#FB7185', border: 'rgba(251, 113, 133, 0.3)' };
      default:
        return { bg: 'rgba(251, 191, 36, 0.15)', text: '#FBBF24', border: 'rgba(251, 191, 36, 0.3)' };
    }
  };

  return (
    <div className="tess-card p-5 h-full flex flex-col justify-between">
      <div>
        {/* Section Header */}
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-[rgba(255,255,255,0.06)]">
          <div className="flex items-center gap-2">
            <Bot style={{ width: '1.1rem', height: '1.1rem', color: '#A78BFA' }} />
            <span className="text-xs font-bold text-primary font-mono tracking-wider uppercase">
              Agent Workflows & Safeguards
            </span>
          </div>
          <button
            onClick={() => onNavigate('agent')}
            className="text-xs font-mono text-[#A78BFA] hover:underline flex items-center gap-1 cursor-pointer"
            style={{ background: 'none', border: 'none' }}
          >
            <span>Agent Console</span>
            <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
          </button>
        </div>

        {/* Content */}
        {plans.length === 0 ? (
          <div className="py-7 text-center">
            <Terminal style={{ width: '1.5rem', height: '1.5rem', color: 'var(--text-muted)', margin: '0 auto', opacity: 0.5 }} />
            <div className="text-xs font-semibold text-primary mt-2">
              Agent Layer Standing By
            </div>
            <p className="text-[11px] text-muted mt-1 max-w-xs mx-auto">
              No autonomous multi-step plans executing. Trigger agent objectives directly or through proactive interventions.
            </p>
            <button
              onClick={() => onNavigate('agent')}
              className="mt-3 px-3 py-1.5 rounded-lg text-xs font-semibold bg-[rgba(167,139,250,0.15)] text-[#A78BFA] border border-[rgba(167,139,250,0.3)] hover:bg-[rgba(167,139,250,0.25)] transition-all cursor-pointer"
            >
              Compose Agent Objective
            </button>
          </div>
        ) : (
          <div className="space-y-2.5">
            {plans.slice(0, 3).map((plan) => {
              const statusStyle = getStatusColor(plan.status);
              return (
                <div
                  key={plan.id}
                  onClick={() => onNavigate('agent')}
                  role="button"
                  tabIndex={0}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault();
                      onNavigate('agent');
                    }
                  }}
                  className="p-3 rounded-xl border flex items-center justify-between gap-3 cursor-pointer hover:bg-[rgba(255,255,255,0.03)] transition-colors group"
                  style={{
                    backgroundColor: 'var(--bg-secondary)',
                    borderColor: 'var(--border)'
                  }}
                >
                  <div className="min-w-0">
                    <div className="text-xs font-semibold text-primary truncate group-hover:text-[#BDF2E4] transition-colors">
                      {plan.objective}
                    </div>
                    <div className="text-[10px] font-mono text-muted mt-0.5">
                      {plan.steps?.length || 0} planned step(s) • Human confirmation required
                    </div>
                  </div>

                  <span
                    className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full shrink-0"
                    style={{
                      backgroundColor: statusStyle.bg,
                      color: statusStyle.text,
                      border: `1px solid ${statusStyle.border}`
                    }}
                  >
                    {plan.status}
                  </span>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <div className="pt-3 border-t border-[rgba(255,255,255,0.06)] text-[11px] font-mono text-muted flex items-center justify-between">
        <span>{plans.length} total recorded plan(s)</span>
        <button
          onClick={() => onNavigate('agent')}
          className="text-[#A78BFA] hover:underline cursor-pointer"
          style={{ background: 'none', border: 'none' }}
        >
          Review All Plans
        </button>
      </div>
    </div>
  );
};

