import React from 'react';
import { ShieldAlert, ArrowRight, CheckCircle, Zap } from 'lucide-react';
import { InterventionResponse } from '../../types';
import { ScreenTab } from '../Sidebar';

interface InterventionPreviewProps {
  interventions: InterventionResponse[];
  onNavigate: (tab: ScreenTab) => void;
}

export const InterventionPreview: React.FC<InterventionPreviewProps> = ({
  interventions,
  onNavigate
}) => {
  const activeInterventions = interventions.filter((i) => i.status === 'SENT');

  return (
    <div
      className="tess-card p-5 h-full flex flex-col justify-between"
      style={{
        borderColor: activeInterventions.length > 0 ? 'rgba(251, 113, 133, 0.4)' : 'rgba(52, 211, 153, 0.25)',
        background: activeInterventions.length > 0
          ? 'linear-gradient(135deg, rgba(251, 113, 133, 0.08) 0%, rgba(17, 20, 38, 0.85) 100%)'
          : 'var(--bg-secondary)'
      }}
    >
      <div>
        {/* Section Header */}
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-[rgba(255,255,255,0.06)]">
          <div className="flex items-center gap-2">
            <ShieldAlert
              style={{
                width: '1.1rem',
                height: '1.1rem',
                color: activeInterventions.length > 0 ? '#FB7185' : '#34D399'
              }}
            />
            <span className="text-xs font-bold text-primary font-mono tracking-wider uppercase">
              Proactive Interventions
            </span>
          </div>
          <button
            onClick={() => onNavigate('interventions')}
            className="text-xs font-mono text-[#35B9A5] hover:underline flex items-center gap-1 cursor-pointer"
            style={{ background: 'none', border: 'none' }}
          >
            <span>History</span>
            <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
          </button>
        </div>

        {/* Content */}
        {activeInterventions.length === 0 ? (
          <div className="py-7 text-center">
            <div className="w-10 h-10 rounded-full bg-[rgba(52,211,153,0.12)] border border-[rgba(52,211,153,0.3)] flex items-center justify-center mx-auto mb-2.5">
              <CheckCircle style={{ width: '1.25rem', height: '1.25rem', color: '#34D399' }} />
            </div>
            <div className="text-xs font-semibold text-primary">
              Trajectory Aligned
            </div>
            <p className="text-[11px] text-muted mt-1 max-w-xs mx-auto">
              No active divergence detected. TESS continuous monitoring is evaluating deadlines and routine fidelity.
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {activeInterventions.slice(0, 2).map((inv) => (
              <div
                key={inv.id}
                className="p-3.5 rounded-xl border"
                style={{
                  backgroundColor: 'rgba(0, 0, 0, 0.35)',
                  borderColor: 'rgba(251, 113, 133, 0.35)'
                }}
              >
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs font-semibold text-primary truncate pr-2">
                    {inv.title}
                  </span>
                  <span className="text-[9px] font-mono font-bold px-1.5 py-0.2 rounded bg-[rgba(251,113,133,0.2)] text-[#FB7185] border border-[rgba(251,113,133,0.4)]">
                    {inv.priority || 'URGENT'}
                  </span>
                </div>

                <p className="text-[11px] text-secondary leading-relaxed m-0 mb-3">
                  {inv.message}
                </p>

                <div className="p-2 rounded-lg bg-[rgba(255,255,255,0.03)] border border-[rgba(255,255,255,0.06)] flex items-center justify-between gap-2">
                  <div className="text-[10px] text-muted truncate">
                    <span className="text-secondary font-medium">Recommended: </span>
                    {inv.suggested_action}
                  </div>
                  <button
                    onClick={() => onNavigate('interventions')}
                    className="px-2.5 py-1 rounded text-[11px] font-mono font-semibold bg-[#FB7185] text-white hover:bg-[#F43F5E] transition-all cursor-pointer shrink-0"
                    style={{ border: 'none' }}
                  >
                    Respond
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="pt-3 border-t border-[rgba(255,255,255,0.06)] text-[11px] font-mono text-muted flex items-center justify-between">
        <span>{activeInterventions.length} active intervention(s) pending</span>
        <button
          onClick={() => onNavigate('interventions')}
          className="text-[#35B9A5] hover:underline cursor-pointer"
          style={{ background: 'none', border: 'none' }}
        >
          Manage All
        </button>
      </div>
    </div>
  );
};
