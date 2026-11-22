import React from 'react';
import { InterventionResponse } from '../../types';
import {
  X,
  ShieldAlert,
  Wrench,
  Clock,
  XCircle,
  Sparkles,
  CheckCircle2,
  AlertTriangle
} from 'lucide-react';

interface InterventionDetailModalProps {
  intervention: InterventionResponse | null;
  actingId: string | null;
  onClose: () => void;
  onFixIt: (inv: InterventionResponse) => void;
  onRespond: (id: string, action: 'ACTED' | 'LATER' | 'DISMISS') => void;
}

export const InterventionDetailModal: React.FC<InterventionDetailModalProps> = ({
  intervention,
  actingId,
  onClose,
  onFixIt,
  onRespond
}) => {
  if (!intervention) return null;

  const isHigh =
    intervention.priority === 'HIGH' || intervention.priority === 'CRITICAL';
  const isActing = actingId === intervention.id;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in"
      onClick={onClose}
    >
      <div
        className="w-full max-w-lg rounded-2xl border flex flex-col max-h-[90vh] overflow-hidden shadow-2xl"
        style={{
          backgroundColor: 'var(--bg-secondary, #0B0D18)',
          borderColor: 'var(--border, rgba(255, 255, 255, 0.12))'
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="p-5 border-b border-[rgba(255,255,255,0.08)] flex items-start justify-between gap-4">
          <div className="flex items-start gap-3 flex-1 min-w-0">
            <div
              className="p-2 rounded-xl flex items-center justify-center shrink-0 mt-0.5"
              style={{
                backgroundColor: isHigh
                  ? 'rgba(251, 113, 133, 0.15)'
                  : 'rgba(251, 191, 36, 0.15)',
                color: isHigh ? '#FB7185' : '#FBBF24'
              }}
            >
              <ShieldAlert style={{ width: '1.25rem', height: '1.25rem' }} />
            </div>

            <div className="min-w-0">
              <h3 className="text-base font-bold text-primary m-0 leading-snug">
                {intervention.title}
              </h3>
              <div className="flex items-center gap-2 mt-1.5 text-xs font-mono">
                <span
                  className="px-2 py-0.5 rounded-full font-bold uppercase text-[10px]"
                  style={{
                    backgroundColor: isHigh
                      ? 'rgba(251, 113, 133, 0.2)'
                      : 'rgba(251, 191, 36, 0.2)',
                    color: isHigh ? '#FB7185' : '#FBBF24'
                  }}
                >
                  {intervention.priority} Urgency
                </span>
                <span className="text-muted">
                  Status: {intervention.status}
                </span>
              </div>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg text-muted hover:text-primary hover:bg-[rgba(255,255,255,0.06)] transition-all cursor-pointer bg-transparent border-none"
            title="Close dialog"
          >
            <X style={{ width: '1.1rem', height: '1.1rem' }} />
          </button>
        </div>

        {/* Content Body */}
        <div className="p-5 overflow-y-auto space-y-4 text-xs">
          {/* Recommendation Message */}
          <div>
            <span className="text-[11px] font-mono uppercase tracking-wider text-muted block mb-1.5">
              Identified Divergence & Context
            </span>
            <div className="p-3.5 rounded-xl bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.06)] text-secondary leading-relaxed">
              {intervention.message}
            </div>
          </div>

          {/* Observed Evidence vs AI Recommendation Rationale */}
          <div>
            <span className="text-[11px] font-mono uppercase tracking-wider text-muted block mb-1.5">
              Why TESS Suggested This (Evidence Rationale)
            </span>
            <div className="p-3.5 rounded-xl bg-[rgba(169,154,217,0.06)] border border-[rgba(169,154,217,0.2)] text-secondary leading-relaxed space-y-2">
              <div className="flex items-start gap-2">
                <Sparkles style={{ width: '0.9rem', height: '0.9rem', color: '#A78BFA', flexShrink: 0, marginTop: '2px' }} />
                <span>
                  <strong className="text-primary font-semibold">Contributing Trigger: </strong>
                  Trajectory simulation detected potential delay cascading into dependent work packages.
                </span>
              </div>
              <div className="flex items-start gap-2">
                <CheckCircle2 style={{ width: '0.9rem', height: '0.9rem', color: '#35B9A5', flexShrink: 0, marginTop: '2px' }} />
                <span>
                  <strong className="text-primary font-semibold">Expected Impact: </strong>
                  Acting restores normal milestone probability and prevents unlogged hour discrepancies.
                </span>
              </div>
            </div>
          </div>

          {/* Suggested Fix */}
          {intervention.suggested_action && (
            <div>
              <span className="text-[11px] font-mono uppercase tracking-wider text-muted block mb-1.5">
                Recommended Autonomous Action
              </span>
              <div className="p-3.5 rounded-xl bg-[rgba(34,211,238,0.08)] border border-[rgba(34,211,238,0.25)] flex items-start gap-2.5">
                <Wrench style={{ width: '1rem', height: '1rem', color: '#22D3EE', flexShrink: 0, marginTop: '2px' }} />
                <div className="text-xs text-primary leading-relaxed">
                  <span className="font-semibold text-[#22D3EE]">TESS Agent Workflow: </span>
                  {intervention.suggested_action}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <div className="p-4 border-t border-[rgba(255,255,255,0.08)] flex items-center justify-between gap-3 bg-[rgba(255,255,255,0.01)]">
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => {
                onRespond(intervention.id, 'LATER');
                onClose();
              }}
              disabled={isActing}
              className="btn-secondary text-xs py-2 px-3 flex items-center gap-1.5"
            >
              <Clock style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Later</span>
            </button>

            <button
              type="button"
              onClick={() => {
                onRespond(intervention.id, 'DISMISS');
                onClose();
              }}
              disabled={isActing}
              className="btn-secondary text-xs py-2 px-3 flex items-center gap-1.5"
              style={{ color: 'var(--text-muted)' }}
            >
              <XCircle style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Dismiss</span>
            </button>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => {
                onFixIt(intervention);
                onClose();
              }}
              disabled={isActing}
              className="btn-primary text-xs py-2 px-3.5 flex items-center gap-1.5"
            >
              <Wrench style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>{isActing ? 'Executing...' : 'FIX IT WITH AGENT'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
