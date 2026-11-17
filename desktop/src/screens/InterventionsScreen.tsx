import React, { useEffect, useState } from 'react';
import { apiService } from '../services/api';
import { InterventionResponse } from '../types';
import { useMascot } from '../contexts/MascotContext';
import { ScreenTab } from '../components/Sidebar';
import {
  AlertTriangle,
  CheckCircle,
  Clock,
  XCircle,
  Wrench,
  ArrowRight,
  ShieldAlert,
  Sparkles,
  Zap
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
  const [error, setError] = useState<string | null>(null);

  const { setState: setMascotState } = useMascot();

  const loadInterventions = async () => {
    setLoading(true);
    try {
      const data = await apiService.getInterventions();
      setInterventions(data);
      const active = data.filter((i) => i.status === 'SENT');
      if (active.length > 0) {
        setMascotState('INTERVENING');
      }
    } catch (e: any) {
      setError(e.message || 'Failed to load interventions');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadInterventions();
  }, []);

  const handleRespond = async (id: string, action: 'ACTED' | 'LATER' | 'DISMISS') => {
    setActingId(id);
    setError(null);
    try {
      await apiService.respondIntervention(id, action);
      await loadInterventions();
    } catch (e: any) {
      setError(e.message || 'Failed to update intervention response');
    } finally {
      setActingId(null);
    }
  };

  const handleFixIt = async (inv: InterventionResponse) => {
    const objective = `Fix ${inv.title}: ${inv.suggested_action}`;
    if (onTriggerAgentObjective) {
      onTriggerAgentObjective(objective);
    } else {
      try {
        await apiService.createAgentObjective(objective);
        await apiService.respondIntervention(inv.id, 'ACTED');
      } catch (_) {}
      onNavigate('agent');
    }
  };

  const activeInvs = interventions.filter((i) => i.status === 'SENT');
  const pastInvs = interventions.filter((i) => i.status !== 'SENT');

  return (
    <div
      className="flex-1 overflow-y-auto p-6"
      style={{ height: 'calc(100vh - 68px)', position: 'relative', zIndex: 1 }}
    >
      {error && (
        <div
          className="p-3 mb-4 rounded-xl text-xs flex items-center justify-between"
          style={{
            backgroundColor: 'rgba(251, 113, 133, 0.12)',
            color: '#FB7185',
            border: '1px solid rgba(251, 113, 133, 0.3)'
          }}
        >
          <span>{error}</span>
          <button
            onClick={() => setError(null)}
            className="text-muted hover:text-primary cursor-pointer font-bold"
            style={{ background: 'none', border: 'none' }}
          >
            ×
          </button>
        </div>
      )}

      {/* ACTIVE INTERVENTIONS SECTION */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <ShieldAlert style={{ width: '1.15rem', height: '1.15rem', color: '#FB7185' }} />
            <h3 className="text-sm font-bold text-primary tracking-wide font-mono uppercase m-0">
              Active Interventions Requiring Focus ({activeInvs.length})
            </h3>
          </div>
          <span className="text-[11px] font-mono text-muted">
            Proactive Safeguards Active
          </span>
        </div>

        {activeInvs.length === 0 && !loading ? (
          <div className="tess-card p-8 text-center bg-[rgba(52,211,153,0.02)] border-[rgba(52,211,153,0.2)]">
            <div className="w-12 h-12 rounded-full bg-[rgba(52,211,153,0.1)] border border-[rgba(52,211,153,0.3)] flex items-center justify-center mx-auto mb-3">
              <CheckCircle style={{ width: '1.5rem', height: '1.5rem', color: '#34D399' }} />
            </div>
            <div className="text-sm font-semibold text-primary">No Active Divergences</div>
            <p className="text-xs text-muted max-w-sm mx-auto mt-1 leading-relaxed">
              TESS has not detected any critical risks to your milestones or trajectory patterns.
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            {activeInvs.map((inv) => {
              const isHigh = inv.priority === 'HIGH' || inv.priority === 'CRITICAL';
              return (
                <div
                  key={inv.id}
                  className="tess-card p-5 relative overflow-hidden"
                  style={{
                    borderColor: isHigh ? 'rgba(251, 113, 133, 0.45)' : 'rgba(251, 191, 36, 0.45)',
                    background: isHigh
                      ? 'linear-gradient(135deg, rgba(251, 113, 133, 0.08) 0%, rgba(17, 20, 38, 0.85) 100%)'
                      : 'linear-gradient(135deg, rgba(251, 191, 36, 0.08) 0%, rgba(17, 20, 38, 0.85) 100%)',
                    boxShadow: isHigh ? '0 0 25px rgba(251, 113, 133, 0.15)' : '0 0 25px rgba(251, 191, 36, 0.15)'
                  }}
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <span
                        className="w-2 h-2 rounded-full animate-ping"
                        style={{ backgroundColor: isHigh ? '#FB7185' : '#FBBF24' }}
                      />
                      <h4 className="text-sm font-bold text-primary m-0 tracking-tight">
                        {inv.title}
                      </h4>
                    </div>

                    <span
                      className="text-[10px] font-mono font-bold px-2 py-0.5 rounded-full uppercase tracking-wider"
                      style={{
                        backgroundColor: isHigh ? 'rgba(251, 113, 133, 0.2)' : 'rgba(251, 191, 36, 0.2)',
                        color: isHigh ? '#FB7185' : '#FBBF24',
                        border: `1px solid ${isHigh ? 'rgba(251, 113, 133, 0.4)' : 'rgba(251, 191, 36, 0.4)'}`
                      }}
                    >
                      {inv.priority} PRIORITY
                    </span>
                  </div>

                  <p className="text-xs text-secondary mt-1.5 mb-3 leading-relaxed">
                    {inv.message}
                  </p>

                  <div className="p-3 rounded-lg bg-[rgba(0,0,0,0.35)] border border-[rgba(255,255,255,0.06)] text-xs font-medium text-primary mb-4 flex items-center gap-2.5">
                    <Wrench style={{ width: '0.95rem', height: '0.95rem', color: '#22D3EE', flexShrink: 0 }} />
                    <span>
                      <strong className="text-[#22D3EE] font-mono uppercase text-[11px] mr-1.5">
                        Autonomous Fix:
                      </strong>
                      {inv.suggested_action}
                    </span>
                  </div>

                  {/* Actions: FIX IT WITH AGENT, LATER, DISMISS */}
                  <div className="flex items-center gap-3">
                    <button
                      onClick={() => handleFixIt(inv)}
                      disabled={actingId === inv.id}
                      className="btn-primary text-xs"
                    >
                      <Wrench style={{ width: '0.85rem', height: '0.85rem' }} />
                      <span>FIX IT WITH AGENT</span>
                    </button>

                    <button
                      onClick={() => handleRespond(inv.id, 'LATER')}
                      disabled={actingId === inv.id}
                      className="btn-secondary text-xs"
                    >
                      <Clock style={{ width: '0.85rem', height: '0.85rem' }} />
                      <span>Later</span>
                    </button>

                    <button
                      onClick={() => handleRespond(inv.id, 'DISMISS')}
                      disabled={actingId === inv.id}
                      className="btn-secondary text-xs"
                      style={{ color: 'var(--text-muted)' }}
                    >
                      <XCircle style={{ width: '0.85rem', height: '0.85rem' }} />
                      <span>Dismiss</span>
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* RESOLVED & ARCHIVED INTERVENTIONS */}
      <div>
        <div className="flex items-center gap-2 mb-3">
          <Clock style={{ width: '1.05rem', height: '1.05rem', color: 'var(--text-muted)' }} />
          <h3 className="text-xs font-bold text-muted font-mono uppercase tracking-wider m-0">
            Historical Interventions Log ({pastInvs.length})
          </h3>
        </div>

        {pastInvs.length === 0 ? (
          <div className="text-xs text-muted py-4">No past intervention history.</div>
        ) : (
          <div className="flex flex-col gap-2">
            {pastInvs.map((inv) => (
              <div
                key={inv.id}
                className="tess-card p-3 flex items-center justify-between text-xs"
                style={{ backgroundColor: 'var(--bg-secondary)' }}
              >
                <div className="truncate pr-4" style={{ maxWidth: '600px' }}>
                  <span className="font-semibold text-primary">{inv.title}</span>
                  <span className="text-muted text-[11px] block truncate mt-0.5">{inv.message}</span>
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
        )}
      </div>
    </div>
  );
};
