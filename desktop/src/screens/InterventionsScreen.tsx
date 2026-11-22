import React, { useEffect, useState, useMemo, useCallback } from 'react';
import { apiService } from '../services/api';
import { InterventionResponse } from '../types';
import { useMascot } from '../contexts/MascotContext';
import { ScreenTab } from '../components/Sidebar';
import { InterventionCard } from '../components/interventions/InterventionCard';
import { InterventionDetailModal } from '../components/interventions/InterventionDetailModal';
import {
  ShieldAlert,
  CheckCircle,
  Clock,
  Sparkles,
  RefreshCw,
  AlertCircle,
  X,
  History,
  Archive,
  CheckCircle2
} from 'lucide-react';

interface InterventionsScreenProps {
  onNavigate: (tab: ScreenTab) => void;
  onTriggerAgentObjective?: (objective: string) => void;
}

export const InterventionsScreen: React.FC<InterventionsScreenProps> = ({
  onNavigate,
  onTriggerAgentObjective
}) => {
  const [interventions, setInterventions] = useState<InterventionResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [actingId, setActingId] = useState<string | null>(null);
  const [selectedIntervention, setSelectedIntervention] = useState<InterventionResponse | null>(null);
  const [statusFilter, setStatusFilter] = useState<'ACTIVE' | 'ACTED' | 'ALL'>('ACTIVE');
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const { setState: setMascotState, triggerEmotion } = useMascot();

  const loadInterventions = useCallback(async () => {
    setLoading(true);
    try {
      const data = await apiService.getInterventions();
      setInterventions(data || []);
      const active = (data || []).filter((i) => i.status === 'SENT');
      if (active.length > 0) {
        setMascotState('INTERVENING');
      } else {
        setMascotState('IDLE');
      }
    } catch (e: any) {
      setNotification({
        type: 'error',
        text: e.message || 'Failed to load proactive interventions'
      });
    } finally {
      setLoading(false);
    }
  }, [setMascotState]);

  useEffect(() => {
    loadInterventions();
  }, [loadInterventions]);

  const handleRespond = async (id: string, action: 'ACTED' | 'LATER' | 'DISMISS') => {
    setActingId(id);
    setNotification(null);
    try {
      await apiService.respondIntervention(id, action);
      const actionText =
        action === 'ACTED'
          ? 'Intervention marked as resolved.'
          : action === 'LATER'
          ? 'Intervention deferred for later review.'
          : 'Intervention dismissed.';
      setNotification({ type: 'success', text: actionText });
      triggerEmotion('HAPPY', 3000);
      await loadInterventions();
    } catch (e: any) {
      setNotification({
        type: 'error',
        text: `Failed to update intervention: ${e.message || String(e)}`
      });
      triggerEmotion('ERROR', 4000);
    } finally {
      setActingId(null);
    }
  };

  const handleFixIt = async (inv: InterventionResponse) => {
    const objective = `Fix ${inv.title}: ${inv.suggested_action}`;
    setActingId(inv.id);
    setMascotState('ACTING');

    if (onTriggerAgentObjective) {
      onTriggerAgentObjective(objective);
      setActingId(null);
    } else {
      try {
        await apiService.createAgentObjective(objective);
        await apiService.respondIntervention(inv.id, 'ACTED');
        triggerEmotion('SUCCESS', 3500);
        setNotification({
          type: 'success',
          text: `Autonomous agent dispatched for: "${inv.title}". Transferring to Agent Activity...`
        });
        setTimeout(() => onNavigate('agent'), 1200);
      } catch (e: any) {
        setNotification({
          type: 'error',
          text: `Agent objective creation failed: ${e.message || String(e)}`
        });
        triggerEmotion('ERROR', 5000);
      } finally {
        setActingId(null);
      }
    }
  };

  const activeInvs = useMemo(
    () => interventions.filter((i) => i.status === 'SENT'),
    [interventions]
  );

  const actedInvs = useMemo(
    () => interventions.filter((i) => i.status === 'ACTED'),
    [interventions]
  );

  const pastInvs = useMemo(
    () => interventions.filter((i) => i.status !== 'SENT'),
    [interventions]
  );

  const displayedInvs = useMemo(() => {
    if (statusFilter === 'ACTIVE') return activeInvs;
    if (statusFilter === 'ACTED') return actedInvs;
    return interventions;
  }, [statusFilter, activeInvs, actedInvs, interventions]);

  return (
    <div
      className="flex-1 overflow-y-auto p-4 sm:p-6 w-full h-full relative"
      style={{ zIndex: 1 }}
      data-testid="interventions-screen-container"
    >
      {/* 1. TOP METRICS OVERVIEW */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-6 select-none">
        <button
          type="button"
          onClick={() => setStatusFilter('ACTIVE')}
          className={`tess-card p-3.5 rounded-xl flex items-center justify-between text-left transition-all cursor-pointer border ${
            statusFilter === 'ACTIVE'
              ? 'border-[rgba(251,113,133,0.5)] bg-[rgba(251,113,133,0.08)]'
              : 'border-[rgba(255,255,255,0.08)]'
          }`}
        >
          <div>
            <span className="text-[11px] font-mono uppercase text-muted">Active Alerts</span>
            <div className="text-xl font-bold font-mono mt-1 text-[#FB7185]">
              {activeInvs.length}
            </div>
          </div>
          <div className="p-2 rounded-lg bg-[rgba(251,113,133,0.12)] text-[#FB7185]">
            <ShieldAlert style={{ width: '1.1rem', height: '1.1rem' }} />
          </div>
        </button>

        <button
          type="button"
          onClick={() => setStatusFilter('ACTED')}
          className={`tess-card p-3.5 rounded-xl flex items-center justify-between text-left transition-all cursor-pointer border ${
            statusFilter === 'ACTED'
              ? 'border-[rgba(52,211,153,0.5)] bg-[rgba(52,211,153,0.08)]'
              : 'border-[rgba(255,255,255,0.08)]'
          }`}
        >
          <div>
            <span className="text-[11px] font-mono uppercase text-muted">Resolved Fixes</span>
            <div className="text-xl font-bold font-mono mt-1 text-[#34D399]">
              {actedInvs.length}
            </div>
          </div>
          <div className="p-2 rounded-lg bg-[rgba(52,211,153,0.12)] text-[#34D399]">
            <CheckCircle2 style={{ width: '1.1rem', height: '1.1rem' }} />
          </div>
        </button>

        <button
          type="button"
          onClick={() => setStatusFilter('ALL')}
          className={`tess-card p-3.5 rounded-xl flex items-center justify-between text-left transition-all cursor-pointer border ${
            statusFilter === 'ALL'
              ? 'border-[rgba(167,139,250,0.5)] bg-[rgba(167,139,250,0.08)]'
              : 'border-[rgba(255,255,255,0.08)]'
          }`}
        >
          <div>
            <span className="text-[11px] font-mono uppercase text-muted">Total History</span>
            <div className="text-xl font-bold font-mono mt-1 text-[#A78BFA]">
              {interventions.length}
            </div>
          </div>
          <div className="p-2 rounded-lg bg-[rgba(167,139,250,0.12)] text-[#A78BFA]">
            <History style={{ width: '1.1rem', height: '1.1rem' }} />
          </div>
        </button>

        <div className="tess-card p-3.5 rounded-xl flex items-center justify-between text-left border border-[rgba(255,255,255,0.08)]">
          <div>
            <span className="text-[11px] font-mono uppercase text-muted">Safeguard Mode</span>
            <div className="text-xs font-bold font-mono mt-1.5 text-[#35B9A5]">
              Autonomous Proactive
            </div>
          </div>
          <div className="p-2 rounded-lg bg-[rgba(53,185,165,0.12)] text-[#35B9A5]">
            <Sparkles style={{ width: '1.1rem', height: '1.1rem' }} />
          </div>
        </div>
      </div>

      {/* FEEDBACK NOTIFICATION BANNER */}
      {notification && (
        <div
          className="p-3 mb-4 rounded-xl text-xs flex items-center justify-between border animate-in fade-in select-none"
          style={{
            backgroundColor:
              notification.type === 'error'
                ? 'rgba(251, 113, 133, 0.12)'
                : 'rgba(52, 211, 153, 0.12)',
            color: notification.type === 'error' ? '#FB7185' : '#34D399',
            borderColor:
              notification.type === 'error'
                ? 'rgba(251, 113, 133, 0.35)'
                : 'rgba(52, 211, 153, 0.35)'
          }}
        >
          <div className="flex items-center gap-2">
            <AlertCircle style={{ width: '1rem', height: '1rem' }} />
            <span>{notification.text}</span>
          </div>
          <button
            type="button"
            onClick={() => setNotification(null)}
            className="text-muted hover:text-primary cursor-pointer p-0.5 bg-transparent border-none"
          >
            <X style={{ width: '0.9rem', height: '0.9rem' }} />
          </button>
        </div>
      )}

      {/* 2. SECTION HEADER & FILTER TOGGLE */}
      <div className="flex items-center justify-between mb-4 select-none">
        <div className="flex items-center gap-2">
          <ShieldAlert style={{ width: '1.15rem', height: '1.15rem', color: '#FB7185' }} />
          <h3 className="text-sm font-bold text-primary tracking-wide font-mono uppercase m-0">
            {statusFilter === 'ACTIVE'
              ? `Active Interventions Requiring Focus (${activeInvs.length})`
              : statusFilter === 'ACTED'
              ? `Resolved Fixes Log (${actedInvs.length})`
              : `All Interventions Log (${interventions.length})`}
          </h3>
        </div>

        <div className="flex items-center gap-1.5 bg-[rgba(255,255,255,0.03)] p-1 rounded-xl border border-[rgba(255,255,255,0.06)] text-xs">
          <button
            type="button"
            onClick={() => setStatusFilter('ACTIVE')}
            className={`px-3 py-1 rounded-lg font-mono transition-all cursor-pointer border-none ${
              statusFilter === 'ACTIVE'
                ? 'bg-[rgba(251,113,133,0.2)] text-[#FB7185] font-bold'
                : 'text-muted hover:text-primary bg-transparent'
            }`}
          >
            Active ({activeInvs.length})
          </button>
          <button
            type="button"
            onClick={() => setStatusFilter('ACTED')}
            className={`px-3 py-1 rounded-lg font-mono transition-all cursor-pointer border-none ${
              statusFilter === 'ACTED'
                ? 'bg-[rgba(52,211,153,0.2)] text-[#34D399] font-bold'
                : 'text-muted hover:text-primary bg-transparent'
            }`}
          >
            Resolved ({actedInvs.length})
          </button>
          <button
            type="button"
            onClick={() => setStatusFilter('ALL')}
            className={`px-3 py-1 rounded-lg font-mono transition-all cursor-pointer border-none ${
              statusFilter === 'ALL'
                ? 'bg-[rgba(167,139,250,0.2)] text-[#A78BFA] font-bold'
                : 'text-muted hover:text-primary bg-transparent'
            }`}
          >
            All History
          </button>
        </div>
      </div>

      {/* 3. INTERVENTIONS LIST / EMPTY STATE */}
      {loading ? (
        <div className="space-y-3 py-6">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="tess-card p-5 rounded-2xl flex flex-col gap-3 animate-pulse"
            >
              <div className="flex items-center justify-between">
                <div className="w-1/3 h-5 rounded bg-[rgba(255,255,255,0.06)]" />
                <div className="w-20 h-5 rounded bg-[rgba(255,255,255,0.06)]" />
              </div>
              <div className="w-2/3 h-4 rounded bg-[rgba(255,255,255,0.04)]" />
              <div className="w-full h-10 rounded bg-[rgba(255,255,255,0.04)]" />
            </div>
          ))}
        </div>
      ) : displayedInvs.length === 0 ? (
        <div className="tess-card p-12 text-center rounded-2xl bg-[rgba(52,211,153,0.02)] border-[rgba(52,211,153,0.2)] select-none">
          <div className="w-12 h-12 rounded-full bg-[rgba(52,211,153,0.1)] border border-[rgba(52,211,153,0.3)] flex items-center justify-center mx-auto mb-3">
            <CheckCircle style={{ width: '1.5rem', height: '1.5rem', color: '#34D399' }} />
          </div>
          <div className="text-sm font-semibold text-primary">No Active Divergences</div>
          <p className="text-xs text-muted max-w-sm mx-auto mt-1 leading-relaxed">
            TESS has not detected any critical risks to your milestones or trajectory patterns.
          </p>
        </div>
      ) : (
        <div className="flex flex-col gap-4 mb-8">
          {displayedInvs.map((inv) => (
            <InterventionCard
              key={inv.id}
              intervention={inv}
              actingId={actingId}
              onFixIt={handleFixIt}
              onRespond={handleRespond}
              onViewDetails={(i) => {
                setSelectedIntervention(i);
                setMascotState('CONFIRMING');
              }}
            />
          ))}
        </div>
      )}

      {/* 4. HISTORICAL INTERVENTIONS LOG (WHEN IN ACTIVE FILTER MODE) */}
      {statusFilter === 'ACTIVE' && pastInvs.length > 0 && (
        <div className="mt-8 pt-6 border-t border-[rgba(255,255,255,0.06)]">
          <div className="flex items-center gap-2 mb-3 select-none">
            <Clock style={{ width: '1.05rem', height: '1.05rem', color: 'var(--text-muted)' }} />
            <h3 className="text-xs font-bold text-muted font-mono uppercase tracking-wider m-0">
              Historical Interventions Log ({pastInvs.length})
            </h3>
          </div>

          <div className="flex flex-col gap-2">
            {pastInvs.map((inv) => (
              <div
                key={inv.id}
                className="tess-card p-3 flex items-center justify-between text-xs rounded-xl"
                style={{ backgroundColor: 'var(--bg-secondary, #0B0D18)' }}
              >
                <div className="truncate pr-4" style={{ maxWidth: '600px' }}>
                  <span className="font-semibold text-primary">{inv.title}</span>
                  <span className="text-muted text-[11px] block truncate mt-0.5">
                    {inv.message}
                  </span>
                </div>
                <span
                  className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full shrink-0"
                  style={{
                    backgroundColor:
                      inv.status === 'ACTED'
                        ? 'rgba(52,211,153,0.15)'
                        : 'rgba(255,255,255,0.05)',
                    color:
                      inv.status === 'ACTED'
                        ? '#34D399'
                        : 'var(--text-muted)',
                    border: '1px solid var(--border)'
                  }}
                >
                  {inv.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 5. INTERVENTION DETAIL & RATIONALE MODAL */}
      <InterventionDetailModal
        intervention={selectedIntervention}
        actingId={actingId}
        onClose={() => {
          setSelectedIntervention(null);
          setMascotState('IDLE');
        }}
        onFixIt={handleFixIt}
        onRespond={handleRespond}
      />
    </div>
  );
};
