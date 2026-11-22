import React, { useEffect } from 'react';
import { AgentPlan, AgentStep } from '../../types';
import {
  X,
  Bot,
  Play,
  Check,
  XCircle,
  Clock,
  ShieldAlert,
  Terminal,
  Calendar,
  Mail,
  Globe,
  FileText,
  AlertCircle,
  CheckCircle2,
  Lock,
  ExternalLink
} from 'lucide-react';

interface AgentPlanDetailModalProps {
  plan: AgentPlan | null;
  isOpen: boolean;
  onClose: () => void;
  onConfirmPlan?: (planId: string) => Promise<void>;
  onExecutePlan?: (planId: string) => Promise<void>;
  onCancelPlan?: (planId: string) => Promise<void>;
  executing?: boolean;
}

export const AgentPlanDetailModal: React.FC<AgentPlanDetailModalProps> = ({
  plan,
  isOpen,
  onClose,
  onConfirmPlan,
  onExecutePlan,
  onCancelPlan,
  executing
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen || !plan) return null;

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
      className="fixed inset-0 flex items-center justify-center p-4 z-50 animate-fadeIn"
      style={{ backgroundColor: 'rgba(0, 0, 0, 0.75)', backdropFilter: 'blur(6px)' }}
      onClick={onClose}
    >
      <div
        className="tess-card w-full max-w-3xl max-h-[85vh] flex flex-col overflow-hidden shadow-2xl animate-scaleUp"
        style={{
          backgroundColor: 'var(--bg-primary)',
          borderColor: 'rgba(139, 92, 246, 0.4)'
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Header */}
        <div className="p-5 border-b border-[rgba(255,255,255,0.08)] flex items-start justify-between gap-4">
          <div className="flex items-start gap-3 flex-1 min-w-0">
            <div
              className="p-2.5 rounded-xl shrink-0 mt-0.5"
              style={{
                backgroundColor: 'rgba(139, 92, 246, 0.15)',
                color: '#A78BFA',
                border: '1px solid rgba(139, 92, 246, 0.3)'
              }}
            >
              <Bot style={{ width: '1.25rem', height: '1.25rem' }} />
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1 flex-wrap">
                <span className="font-mono text-[10px] text-muted uppercase tracking-wider">
                  Plan Objective #{plan.id.slice(0, 8)}
                </span>
                <span
                  className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full uppercase"
                  style={{
                    backgroundColor:
                      plan.status === 'SUCCESS'
                        ? 'rgba(52, 211, 153, 0.15)'
                        : plan.status === 'READY'
                        ? 'rgba(34, 211, 238, 0.15)'
                        : plan.status === 'EXECUTING'
                        ? 'rgba(251, 191, 36, 0.15)'
                        : 'rgba(251, 113, 133, 0.15)',
                    color:
                      plan.status === 'SUCCESS'
                        ? '#34D399'
                        : plan.status === 'READY'
                        ? '#22D3EE'
                        : plan.status === 'EXECUTING'
                        ? '#FBBF24'
                        : '#FB7185',
                    border: '1px solid var(--border)'
                  }}
                >
                  {plan.status}
                </span>
              </div>

              <h3 className="text-base font-bold text-primary tracking-tight leading-snug m-0">
                {plan.objective}
              </h3>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg text-muted hover:text-primary transition-colors cursor-pointer"
            style={{ background: 'none', border: 'none' }}
          >
            <X style={{ width: '1.2rem', height: '1.2rem' }} />
          </button>
        </div>

        {/* Modal Scrollable Body: Steps & Safeguards */}
        <div className="p-5 overflow-y-auto flex-1 flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <h4 className="text-xs font-bold text-primary font-mono uppercase tracking-wider m-0">
              Execution Plan Steps ({plan.steps?.length || 0})
            </h4>
            <span className="text-[11px] font-mono text-muted">
              Audited by TESS Safety Layer
            </span>
          </div>

          {/* Steps Timeline */}
          <div className="flex flex-col gap-3">
            {plan.steps?.map((step: AgentStep, idx: number) => {
              const ToolIcon = getToolIcon(step.tool_name);
              const isHigh = step.risk_level?.toUpperCase() === 'HIGH';
              const isMedium = step.risk_level?.toUpperCase() === 'MEDIUM';

              return (
                <div
                  key={step.id || idx}
                  className="p-4 rounded-xl flex flex-col gap-2.5 transition-all"
                  style={{
                    backgroundColor: 'var(--bg-secondary)',
                    border: '1px solid var(--border)'
                  }}
                >
                  {/* Step Header */}
                  <div className="flex items-center justify-between gap-2 flex-wrap">
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-xs text-muted font-bold">
                        #{step.step_order || idx + 1}
                      </span>
                      <div className="flex items-center gap-1.5 font-mono text-xs font-semibold text-[#22D3EE]">
                        <ToolIcon style={{ width: '0.85rem', height: '0.85rem' }} />
                        <span>{step.tool_name}</span>
                      </div>
                      {step.action_type && (
                        <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-[rgba(255,255,255,0.04)] text-muted">
                          {step.action_type}
                        </span>
                      )}
                    </div>

                    <div className="flex items-center gap-2">
                      {step.risk_level && (
                        <span
                          className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full uppercase"
                          style={{
                            backgroundColor: isHigh
                              ? 'rgba(251, 113, 133, 0.15)'
                              : isMedium
                              ? 'rgba(251, 191, 36, 0.15)'
                              : 'rgba(52, 211, 153, 0.15)',
                            color: isHigh ? '#FB7185' : isMedium ? '#FBBF24' : '#34D399',
                            border: `1px solid ${
                              isHigh
                                ? 'rgba(251, 113, 133, 0.3)'
                                : isMedium
                                ? 'rgba(251, 191, 36, 0.3)'
                                : 'rgba(52, 211, 153, 0.3)'
                            }`
                          }}
                        >
                          {step.risk_level.toUpperCase()} RISK
                        </span>
                      )}

                      <span
                        className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full uppercase"
                        style={{
                          backgroundColor:
                            step.status === 'SUCCESS'
                              ? 'rgba(52, 211, 153, 0.12)'
                              : step.status === 'RUNNING'
                              ? 'rgba(251, 191, 36, 0.12)'
                              : 'rgba(255, 255, 255, 0.05)',
                          color:
                            step.status === 'SUCCESS'
                              ? '#34D399'
                              : step.status === 'RUNNING'
                              ? '#FBBF24'
                              : 'var(--text-muted)'
                        }}
                      >
                        {step.status || 'PENDING'}
                      </span>
                    </div>
                  </div>

                  {/* Step Confirmation Alert Box */}
                  {step.confirmation && (
                    <div
                      className="p-3 rounded-lg text-xs flex items-start gap-2.5"
                      style={{
                        backgroundColor:
                          step.confirmation.status === 'CONFIRMED'
                            ? 'rgba(52, 211, 153, 0.1)'
                            : step.confirmation.status === 'PENDING'
                            ? 'rgba(34, 211, 238, 0.1)'
                            : 'rgba(251, 113, 133, 0.1)',
                        border: `1px solid ${
                          step.confirmation.status === 'CONFIRMED'
                            ? 'rgba(52, 211, 153, 0.25)'
                            : step.confirmation.status === 'PENDING'
                            ? 'rgba(34, 211, 238, 0.25)'
                            : 'rgba(251, 113, 133, 0.25)'
                        }`
                      }}
                    >
                      <Lock
                        style={{
                          width: '0.9rem',
                          height: '0.9rem',
                          color:
                            step.confirmation.status === 'CONFIRMED'
                              ? '#34D399'
                              : step.confirmation.status === 'PENDING'
                              ? '#22D3EE'
                              : '#FB7185',
                          marginTop: '2px'
                        }}
                      />
                      <div className="flex-1">
                        <div className="font-semibold text-primary">
                          Human Safeguard: Confirmation {step.confirmation.status}
                        </div>
                        {step.confirmation.summary && (
                          <div className="text-[11px] text-secondary mt-0.5">
                            {step.confirmation.summary}
                          </div>
                        )}
                        {step.confirmation.expires_at && step.confirmation.status === 'PENDING' && (
                          <div className="text-[10px] font-mono text-muted mt-1">
                            Expires at: {new Date(step.confirmation.expires_at).toLocaleTimeString()}
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                  {/* Step Parameters Display */}
                  {step.parameters && Object.keys(step.parameters).length > 0 && (
                    <div>
                      <div className="text-[10px] font-mono text-muted mb-1 uppercase tracking-wider">
                        Tool Parameters:
                      </div>
                      <pre className="font-mono text-[11px] p-2.5 rounded-lg bg-[rgba(0,0,0,0.45)] text-secondary overflow-x-auto m-0 border border-[rgba(255,255,255,0.04)] leading-relaxed">
                        {JSON.stringify(step.parameters, null, 2)}
                      </pre>
                    </div>
                  )}

                  {/* Step Execution Output / Result */}
                  {step.result && (
                    <div>
                      <div className="text-[10px] font-mono text-[#34D399] mb-1 uppercase tracking-wider flex items-center gap-1">
                        <CheckCircle2 style={{ width: '0.75rem', height: '0.75rem' }} />
                        Execution Output:
                      </div>
                      <pre className="font-mono text-[11px] p-2.5 rounded-lg bg-[rgba(52,211,153,0.05)] text-[#34D399] overflow-x-auto m-0 border border-[rgba(52,211,153,0.2)] leading-relaxed">
                        {JSON.stringify(step.result, null, 2)}
                      </pre>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Modal Footer Controls */}
        <div className="p-4 border-t border-[rgba(255,255,255,0.08)] bg-[rgba(0,0,0,0.2)] flex items-center justify-between gap-3">
          <div className="text-xs text-muted font-mono">
            Status: <span className="text-primary font-bold">{plan.status}</span>
          </div>

          <div className="flex items-center gap-2.5">
            {plan.status === 'READY' && hasPendingConfirmation && onConfirmPlan && (
              <button
                type="button"
                onClick={() => onConfirmPlan(plan.id)}
                className="btn-cyan text-xs"
              >
                <Check style={{ width: '0.85rem', height: '0.85rem' }} />
                <span>Confirm Action Safeguards</span>
              </button>
            )}

            {plan.status === 'READY' && onExecutePlan && (
              <button
                type="button"
                onClick={() => onExecutePlan(plan.id)}
                disabled={executing}
                className="btn-primary text-xs"
              >
                <Play style={{ width: '0.85rem', height: '0.85rem' }} />
                <span>{executing ? 'Executing Steps...' : 'Execute Autonomous Plan'}</span>
              </button>
            )}

            {plan.status !== 'SUCCESS' && plan.status !== 'CANCELLED' && onCancelPlan && (
              <button
                type="button"
                onClick={() => onCancelPlan(plan.id)}
                className="btn-secondary text-xs"
                style={{ color: 'var(--text-muted)' }}
              >
                <XCircle style={{ width: '0.85rem', height: '0.85rem' }} />
                <span>Cancel Plan</span>
              </button>
            )}

            <button
              type="button"
              onClick={onClose}
              className="btn-secondary text-xs"
            >
              <span>Close</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

