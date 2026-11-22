import React from 'react';
import { InterventionResponse } from '../../types';
import {
  Wrench,
  Clock,
  XCircle,
  Info,
  ShieldAlert,
  Sparkles
} from 'lucide-react';

interface InterventionCardProps {
  intervention: InterventionResponse;
  actingId: string | null;
  onFixIt: (inv: InterventionResponse) => void;
  onRespond: (id: string, action: 'ACTED' | 'LATER' | 'DISMISS') => void;
  onViewDetails: (inv: InterventionResponse) => void;
}

export const InterventionCard: React.FC<InterventionCardProps> = ({
  intervention,
  actingId,
  onFixIt,
  onRespond,
  onViewDetails
}) => {
  const isHigh =
    intervention.priority === 'HIGH' || intervention.priority === 'CRITICAL';
  const isActing = actingId === intervention.id;

  return (
    <div
      className="tess-card p-5 relative overflow-hidden rounded-2xl transition-all"
      style={{
        borderColor: isHigh
          ? 'rgba(251, 113, 133, 0.45)'
          : 'rgba(251, 191, 36, 0.45)',
        background: isHigh
          ? 'linear-gradient(135deg, rgba(251, 113, 133, 0.08) 0%, rgba(17, 20, 38, 0.85) 100%)'
          : 'linear-gradient(135deg, rgba(251, 191, 36, 0.08) 0%, rgba(17, 20, 38, 0.85) 100%)',
        boxShadow: isHigh
          ? '0 0 25px rgba(251, 113, 133, 0.15)'
          : '0 0 25px rgba(251, 191, 36, 0.15)'
      }}
      data-testid={`intervention-card-${intervention.id}`}
    >
      {/* Top Header */}
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2.5">
          <span
            className="w-2.5 h-2.5 rounded-full animate-ping"
            style={{ backgroundColor: isHigh ? '#FB7185' : '#FBBF24' }}
          />
          <h4 className="text-sm font-bold text-primary m-0 tracking-tight">
            {intervention.title}
          </h4>
        </div>

        <span
          className="text-[10px] font-mono font-bold px-2.5 py-0.5 rounded-full uppercase tracking-wider"
          style={{
            backgroundColor: isHigh
              ? 'rgba(251, 113, 133, 0.2)'
              : 'rgba(251, 191, 36, 0.2)',
            color: isHigh ? '#FB7185' : '#FBBF24',
            border: `1px solid ${
              isHigh ? 'rgba(251, 113, 133, 0.4)' : 'rgba(251, 191, 36, 0.4)'
            }`
          }}
        >
          {intervention.priority} PRIORITY
        </span>
      </div>

      {/* Description / Message */}
      <p className="text-xs text-secondary mt-1.5 mb-3 leading-relaxed">
        {intervention.message}
      </p>

      {/* Suggested Autonomous Fix Box */}
      {intervention.suggested_action && (
        <div className="p-3 rounded-xl bg-[rgba(0,0,0,0.35)] border border-[rgba(255,255,255,0.06)] text-xs font-medium text-primary mb-4 flex items-center gap-2.5">
          <Wrench
            style={{
              width: '0.95rem',
              height: '0.95rem',
              color: '#22D3EE',
              flexShrink: 0
            }}
          />
          <span className="flex-1">
            <strong className="text-[#22D3EE] font-mono uppercase text-[11px] mr-1.5">
              Autonomous Fix:
            </strong>
            {intervention.suggested_action}
          </span>
        </div>
      )}

      {/* Action Buttons: FIX IT WITH AGENT, Later, Dismiss, Details */}
      <div className="flex flex-wrap items-center gap-2.5 pt-1">
        <button
          type="button"
          onClick={() => onFixIt(intervention)}
          disabled={isActing}
          className="btn-primary text-xs py-2 px-3.5 flex items-center gap-1.5"
          title="Approve and execute fix with TESS Agent"
        >
          <Wrench style={{ width: '0.85rem', height: '0.85rem' }} />
          <span>{isActing ? 'Executing...' : 'FIX IT WITH AGENT'}</span>
        </button>

        <button
          type="button"
          onClick={() => onRespond(intervention.id, 'LATER')}
          disabled={isActing}
          className="btn-secondary text-xs py-2 px-3 flex items-center gap-1.5"
          title="Postpone intervention for later review"
        >
          <Clock style={{ width: '0.85rem', height: '0.85rem' }} />
          <span>Later</span>
        </button>

        <button
          type="button"
          onClick={() => onRespond(intervention.id, 'DISMISS')}
          disabled={isActing}
          className="btn-secondary text-xs py-2 px-3 flex items-center gap-1.5"
          style={{ color: 'var(--text-muted)' }}
          title="Dismiss this recommendation"
        >
          <XCircle style={{ width: '0.85rem', height: '0.85rem' }} />
          <span>Dismiss</span>
        </button>

        <button
          type="button"
          onClick={() => onViewDetails(intervention)}
          className="text-xs text-muted hover:text-primary transition-colors py-2 px-2 flex items-center gap-1 ml-auto cursor-pointer bg-transparent border-none"
          title="Inspect why TESS suggested this intervention"
        >
          <Info style={{ width: '0.85rem', height: '0.85rem' }} />
          <span>Rationale Details</span>
        </button>
      </div>
    </div>
  );
};
