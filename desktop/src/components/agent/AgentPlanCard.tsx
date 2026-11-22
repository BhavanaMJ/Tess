import React from 'react';
import { AgentPlan } from '../../types';
import {
  CheckCircle,
  XCircle,
  Play,
  Clock,
  ShieldAlert,
  ArrowRight,
  Terminal,
  Calendar,
  Mail,
  Globe,
  FileText,
  AlertTriangle,
  Check
} from 'lucide-react';

interface AgentPlanCardProps {
  plan: AgentPlan;
  isSelected: boolean;
  onSelect: () => void;
  onOpenDetails: () => void;
  onConfirm?: (planId: string) => void;
  onExecute?: (planId: string) => void;
  onCancel?: (planId: string) => void;
  executing?: boolean;
}

export const AgentPlanCard: React.FC<AgentPlanCardProps> = ({
  plan,
  isSelected,
  onSelect,
  onOpenDetails,
  onConfirm,
  onExecute,
  onCancel,
  executing
}) => {
  // Determine maximum risk level among steps
  const maxRisk = plan.steps?.reduce<'LOW' | 'MEDIUM' | 'HIGH'>((acc, step) => {
    const r = step.risk_level?.toUpperCase();
    if (r === 'HIGH') return 'HIGH';
    if (r === 'MEDIUM' && acc !== 'HIGH') return 'MEDIUM';
    return acc;
  }, 'LOW') || 'LOW';

  // Distinct tools used
  const toolNames = Array.from(new Set(plan.steps?.map((s) => s.tool_name).filter(Boolean)));

  // Status visual attributes
  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'SUCCESS':
        return {
          label: 'Completed',
          bg: 'rgba(52, 211, 153, 0.15)',
          color: '#34D399',
          border: 'rgba(52, 211, 153, 0.35)',
          icon: CheckCircle
        };
      case 'READY':
        return {
          label: 'Ready / Action Required',
          bg: 'rgba(34, 211, 238, 0.15)',
          color: '#22D3EE',
          border: 'rgba(34, 211, 238, 0.35)',
          icon: Clock
        };
      case 'EXECUTING':
        return {
          label: 'Executing',
          bg: 'rgba(251, 191, 36, 0.15)',
          color: '#FBBF24',
          border: 'rgba(251, 191, 36, 0.35)',
          icon: Play
        };
      case 'FAILED':
        return {
          label: 'Failed',
          bg: 'rgba(251, 113, 133, 0.15)',
          color: '#FB7185',
          border: 'rgba(251, 113, 133, 0.35)',
          icon: XCircle
        };
      case 'CANCELLED':
        return {
          label: 'Cancelled',
          bg: 'rgba(148, 163, 184, 0.15)',
          color: '#94A3B8',
          border: 'rgba(148, 163, 184, 0.35)',
          icon: XCircle
        };
      default:
        return {
          label: status,
          bg: 'rgba(139, 92, 246, 0.15)',
          color: '#A78BFA',
          border: 'rgba(139, 92, 246, 0.35)',
          icon: Clock
        };
    }
  };

  const statusMeta = getStatusBadge(plan.status);
  const StatusIcon = statusMeta.icon;

  const hasPendingConfirmation = plan.steps?.some(
    (s) => s.confirmation && s.confirmation.status === 'PENDING'
  );

  const getToolIcon = (tool: string) => {
    if (tool.includes('calendar')) return Calendar;
    if (tool.includes('gmail') || tool.includes('email')) return Mail;
    if (tool.includes('browser')) return Globe;
    if (tool.includes('file')) return FileText;
    return Terminal;
  };

  return (
    <div
      onClick={onSelect}
      className="tess-card p-4 transition-all cursor-pointer flex flex-col gap-3 hover:border-[rgba(139,92,246,0.35)]"
      style={{
        backgroundColor: isSelected ? 'rgba(139, 92, 246, 0.08)' : 'var(--bg-secondary)',
        borderColor: isSelected ? 'rgba(139, 92, 246, 0.4)' : 'var(--border)'
      }}
    >
      {/* Top Row: Status Pill, Risk Badge, and Timestamp */}
      <div className="flex items-center justify-between gap-2 flex-wrap">
        <div className="flex items-center gap-2">
          <span
            className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full uppercase flex items-center gap-1"
            style={{
              backgroundColor: statusMeta.bg,
              color: statusMeta.color,
              border: `1px solid ${statusMeta.border}`
            }}
          >
            <StatusIcon style={{ width: '0.75rem', height: '0.75rem' }} />
            {plan.status}
          </span>

          <span
            className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full uppercase"
            style={{
              backgroundColor:
                maxRisk === 'HIGH'
                  ? 'rgba(251, 113, 133, 0.15)'
                  : maxRisk === 'MEDIUM'
                  ? 'rgba(251, 191, 36, 0.15)'
                  : 'rgba(52, 211, 153, 0.15)',
              color:
                maxRisk === 'HIGH'
                  ? '#FB7185'
                  : maxRisk === 'MEDIUM'
                  ? '#FBBF24'
                  : '#34D399',
              border: `1px solid ${
                maxRisk === 'HIGH'
                  ? 'rgba(251, 113, 133, 0.3)'
                  : maxRisk === 'MEDIUM'
                  ? 'rgba(251, 191, 36, 0.3)'
                  : 'rgba(52, 211, 153, 0.3)'
              }`
            }}
          >
            Level: {maxRisk}
          </span>
        </div>

        <div className="text-[10px] font-mono text-muted">
          {plan.created_at ? new Date(plan.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Recent'}
        </div>
      </div>

      {/* Objective Text */}
      <div>
        <h4 className="text-sm font-semibold text-primary tracking-tight leading-snug m-0">
          {plan.objective}
        </h4>
        <div className="text-[10px] font-mono text-muted mt-1">
          Plan ID: {plan.id.slice(0, 8)}...{plan.id.slice(-4)}
        </div>
      </div>

      {/* Tools Used preview */}
      {toolNames.length > 0 && (
        <div className="flex items-center gap-1.5 flex-wrap">
          {toolNames.map((tool) => {
            const Icon = getToolIcon(tool);
            const toolLabel = tool.includes('openproject')
              ? 'OpenProject'
              : tool.includes('gmail')
              ? 'Gmail'
              : tool.includes('calendar')
              ? 'Calendar'
              : tool.includes('browser')
              ? 'Browser'
              : tool.includes('file')
              ? 'File System'
              : tool.replace(/_/g, ' ');
            return (
              <span
                key={tool}
                className="font-mono text-[10px] px-2 py-0.5 rounded-md flex items-center gap-1"
                style={{
                  backgroundColor: 'rgba(255, 255, 255, 0.04)',
                  color: 'var(--text-secondary)',
                  border: '1px solid rgba(255, 255, 255, 0.06)'
                }}
              >
                <Icon style={{ width: '0.7rem', height: '0.7rem', color: '#22D3EE' }} />
                <span>{toolLabel}</span>
              </span>
            );
          })}
        </div>
      )}

      {/* Footer Row: Step Count & Quick Actions */}
      <div className="flex items-center justify-between pt-2 border-t border-[rgba(255,255,255,0.06)] text-xs">
        <span className="text-[11px] font-mono text-muted">
          {plan.steps?.length || 0} step(s)
        </span>

        <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
          {plan.status === 'READY' && hasPendingConfirmation && onConfirm && (
            <button
              type="button"
              onClick={() => onConfirm(plan.id)}
              className="btn-cyan text-[11px] py-1 px-2.5"
            >
              <Check style={{ width: '0.75rem', height: '0.75rem' }} />
              <span>Confirm</span>
            </button>
          )}

          {plan.status === 'READY' && onExecute && (
            <button
              type="button"
              onClick={() => onExecute(plan.id)}
              disabled={executing}
              className="btn-primary text-[11px] py-1 px-2.5"
            >
              <Play style={{ width: '0.75rem', height: '0.75rem' }} />
              <span>{executing ? 'Running...' : 'Execute'}</span>
            </button>
          )}

          <button
            type="button"
            onClick={onOpenDetails}
            className="text-[11px] font-mono text-accent hover:underline flex items-center gap-0.5 p-1"
            style={{ background: 'none', border: 'none', cursor: 'pointer' }}
          >
            <span>Timeline</span>
            <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
          </button>
        </div>
      </div>
    </div>
  );
};
