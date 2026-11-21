import React, { useEffect, useRef, useState } from 'react';
import {
  X,
  MessageSquare,
  ShieldAlert,
  Bot,
  Compass,
  CheckSquare,
  ArrowRight,
  Sparkles,
  ExternalLink
} from 'lucide-react';
import { Mascot } from '../Mascot';
import { useMascot } from '../../contexts/MascotContext';
import { ScreenTab } from '../Sidebar';
import { apiService } from '../../services/api';
import { InterventionResponse, AgentPlan } from '../../types';

interface CompanionPanelProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigate: (tab: ScreenTab) => void;
}

export const CompanionPanel: React.FC<CompanionPanelProps> = ({
  isOpen,
  onClose,
  onNavigate
}) => {
  const { state: mascotState, message: mascotMessage } = useMascot();
  const panelRef = useRef<HTMLDivElement>(null);

  const [activeInterventions, setActiveInterventions] = useState<InterventionResponse[]>([]);
  const [pendingPlans, setPendingPlans] = useState<AgentPlan[]>([]);
  const [loading, setLoading] = useState(false);

  // Close on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        e.preventDefault();
        onClose();
      }
    };
    if (isOpen) {
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  // Close on click outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (panelRef.current && !panelRef.current.contains(e.target as Node) && isOpen) {
        onClose();
      }
    };
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen, onClose]);

  // Fetch real contextual intelligence for the popover
  useEffect(() => {
    if (!isOpen) return;

    let isMounted = true;
    setLoading(true);

    Promise.allSettled([
      apiService.getInterventions(),
      apiService.getAgentPlans()
    ])
      .then(([invRes, planRes]) => {
        if (!isMounted) return;
        if (invRes.status === 'fulfilled') {
          setActiveInterventions((invRes.value || []).filter((i) => i.status === 'SENT'));
        }
        if (planRes.status === 'fulfilled') {
          setPendingPlans((planRes.value || []).filter((p) => p.status === 'READY'));
        }
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [isOpen]);

  if (!isOpen) return null;

  const getCompanionExpressionHeadline = () => {
    switch (mascotState) {
      case 'THINKING':
        return 'TESS is analyzing context...';
      case 'ATTENTION':
        return 'Attention advised on upcoming commitments.';
      case 'INTERVENING':
        return 'Proactive guidance ready for your review.';
      case 'CONFIRMING':
        return 'Agent is awaiting your approval.';
      case 'PLANNING':
        return 'Synthesizing trajectory simulations...';
      case 'ACTING':
        return 'Executing approved autonomous actions.';
      case 'SUCCESS':
        return 'Action successfully completed!';
      case 'HAPPY':
        return 'Good progress! Velocity is healthy.';
      case 'ERROR':
        return 'Attention needed: An operation encountered friction.';
      case 'IDLE':
      default:
        return 'TESS is observing context and standing by.';
    }
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="TESS Interactive Companion Panel"
      className="fixed inset-0 z-50 pointer-events-none flex items-end justify-end p-4 md:p-6"
    >
      <div
        ref={panelRef}
        className="pointer-events-auto w-full max-w-sm rounded-2xl shadow-2xl border flex flex-col overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-200"
        style={{
          backgroundColor: 'var(--bg-secondary)',
          borderColor: 'rgba(53, 185, 165, 0.35)',
          backdropFilter: 'blur(24px)',
          WebkitBackdropFilter: 'blur(24px)'
        }}
      >
        {/* Header Bar */}
        <div
          className="flex items-center justify-between p-3.5 border-b border-[rgba(255,255,255,0.06)]"
          style={{
            background: 'linear-gradient(135deg, rgba(22, 143, 131, 0.12) 0%, rgba(17, 20, 38, 0.4) 100%)'
          }}
        >
          <div className="flex items-center gap-2.5">
            <Mascot state={mascotState} size="sm" />
            <div>
              <div className="flex items-center gap-1.5">
                <span className="font-bold text-xs tracking-wider text-primary font-mono">
                  TESS COMPANION
                </span>
                <span className="text-[9px] font-mono font-bold px-1.5 py-0.2 rounded bg-[rgba(53,185,165,0.15)] text-[#35B9A5] border border-[rgba(53,185,165,0.3)]">
                  {mascotState}
                </span>
              </div>
              <div className="text-[10px] text-muted font-mono mt-0.5">
                AI Companion • v2.0
              </div>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-muted hover:text-primary hover:bg-[rgba(255,255,255,0.06)] transition-colors cursor-pointer"
            title="Close Panel (Esc)"
            style={{ background: 'none', border: 'none' }}
          >
            <X style={{ width: '1rem', height: '1rem' }} />
          </button>
        </div>

        {/* Content Body */}
        <div className="p-4 space-y-3.5 max-h-[75vh] overflow-y-auto">
          {/* Real-time Contextual State Message */}
          <div className="p-3 rounded-xl bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.05)]">
            <div className="flex items-center gap-1.5 text-xs font-semibold text-primary mb-1">
              <Sparkles style={{ width: '0.85rem', height: '0.85rem', color: '#35B9A5' }} />
              <span>{getCompanionExpressionHeadline()}</span>
            </div>
            <p className="text-[11px] text-secondary leading-relaxed m-0">
              {mascotMessage ||
                (activeInterventions.length > 0
                  ? `TESS has ${activeInterventions.length} pending proactive recommendation(s) to optimize your trajectory.`
                  : pendingPlans.length > 0
                  ? `An autonomous agent workflow is ready and requires your confirmation.`
                  : `All systems nominal. Ask TESS questions, simulate future paths, or review task commitments.`)}
            </p>
          </div>

          {/* Urgent Pending Interventions (if any) */}
          {activeInterventions.length > 0 && (
            <div className="p-3 rounded-xl border border-[rgba(251,113,133,0.35)] bg-[rgba(251,113,133,0.08)]">
              <div className="flex items-center justify-between text-xs font-semibold text-[#FB7185] mb-1">
                <span className="flex items-center gap-1.5">
                  <ShieldAlert style={{ width: '0.85rem', height: '0.85rem' }} />
                  <span>Pending Intervention</span>
                </span>
                <span className="text-[9px] font-mono font-bold uppercase">URGENT</span>
              </div>
              <p className="text-[11px] text-primary truncate mb-2">
                {activeInterventions[0].title}
              </p>
              <button
                onClick={() => {
                  onNavigate('interventions');
                  onClose();
                }}
                className="w-full py-1.5 rounded-lg text-xs font-mono font-semibold bg-[#FB7185] text-white hover:bg-[#F43F5E] transition-colors cursor-pointer flex items-center justify-center gap-1"
                style={{ border: 'none' }}
              >
                <span>Review in Interventions</span>
                <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
              </button>
            </div>
          )}

          {/* Pending Agent Approvals (if any) */}
          {pendingPlans.length > 0 && (
            <div className="p-3 rounded-xl border border-[rgba(167,139,250,0.35)] bg-[rgba(167,139,250,0.08)]">
              <div className="flex items-center justify-between text-xs font-semibold text-[#A78BFA] mb-1">
                <span className="flex items-center gap-1.5">
                  <Bot style={{ width: '0.85rem', height: '0.85rem' }} />
                  <span>Agent Awaiting Confirmation</span>
                </span>
                <span className="text-[9px] font-mono font-bold uppercase">READY</span>
              </div>
              <p className="text-[11px] text-primary truncate mb-2">
                {pendingPlans[0].objective}
              </p>
              <button
                onClick={() => {
                  onNavigate('agent');
                  onClose();
                }}
                className="w-full py-1.5 rounded-lg text-xs font-mono font-semibold bg-[#A78BFA] text-white hover:bg-[#8B5CF6] transition-colors cursor-pointer flex items-center justify-center gap-1"
                style={{ border: 'none' }}
              >
                <span>Inspect Agent Plan</span>
                <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
              </button>
            </div>
          )}

          {/* Navigation Action Grid */}
          <div>
            <div className="text-[10px] font-mono font-semibold text-muted uppercase tracking-wider mb-2">
              Companion Shortcuts
            </div>
            <div className="grid grid-cols-2 gap-2">
              <button
                onClick={() => {
                  onNavigate('chat');
                  onClose();
                }}
                className="p-2.5 rounded-xl border border-[rgba(255,255,255,0.06)] bg-[rgba(255,255,255,0.02)] hover:bg-[rgba(53,185,165,0.1)] hover:border-[rgba(53,185,165,0.3)] transition-all cursor-pointer text-left flex items-center gap-2 group"
              >
                <MessageSquare style={{ width: '0.9rem', height: '0.9rem', color: '#35B9A5' }} />
                <span className="text-xs font-medium text-secondary group-hover:text-primary">Chat Stream</span>
              </button>

              <button
                onClick={() => {
                  onNavigate('futures');
                  onClose();
                }}
                className="p-2.5 rounded-xl border border-[rgba(255,255,255,0.06)] bg-[rgba(255,255,255,0.02)] hover:bg-[rgba(169,154,217,0.1)] hover:border-[rgba(169,154,217,0.3)] transition-all cursor-pointer text-left flex items-center gap-2 group"
              >
                <Compass style={{ width: '0.9rem', height: '0.9rem', color: '#A99AD9' }} />
                <span className="text-xs font-medium text-secondary group-hover:text-primary">Simulate Future</span>
              </button>

              <button
                onClick={() => {
                  onNavigate('tasks');
                  onClose();
                }}
                className="p-2.5 rounded-xl border border-[rgba(255,255,255,0.06)] bg-[rgba(255,255,255,0.02)] hover:bg-[rgba(34,211,238,0.1)] hover:border-[rgba(34,211,238,0.3)] transition-all cursor-pointer text-left flex items-center gap-2 group"
              >
                <CheckSquare style={{ width: '0.9rem', height: '0.9rem', color: '#22D3EE' }} />
                <span className="text-xs font-medium text-secondary group-hover:text-primary">Tasks & Deadlines</span>
              </button>

              <button
                onClick={() => {
                  onNavigate('agent');
                  onClose();
                }}
                className="p-2.5 rounded-xl border border-[rgba(255,255,255,0.06)] bg-[rgba(255,255,255,0.02)] hover:bg-[rgba(167,139,250,0.1)] hover:border-[rgba(167,139,250,0.3)] transition-all cursor-pointer text-left flex items-center gap-2 group"
              >
                <Bot style={{ width: '0.9rem', height: '0.9rem', color: '#A78BFA' }} />
                <span className="text-xs font-medium text-secondary group-hover:text-primary">Agent Console</span>
              </button>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-3 border-t border-[rgba(255,255,255,0.06)] flex items-center justify-between text-[10px] font-mono text-muted bg-[rgba(0,0,0,0.15)]">
          <span>Press ESC or click outside to dismiss</span>
          <button
            onClick={() => {
              onNavigate('chat');
              onClose();
            }}
            className="text-[#35B9A5] hover:underline cursor-pointer flex items-center gap-0.5"
            style={{ background: 'none', border: 'none' }}
          >
            <span>Open Chat</span>
            <ExternalLink style={{ width: '0.7rem', height: '0.7rem' }} />
          </button>
        </div>
      </div>
    </div>
  );
};
