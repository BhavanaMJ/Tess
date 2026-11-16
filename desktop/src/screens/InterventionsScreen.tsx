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
  ArrowRight
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
      // Create agent objective and navigate to Agent Activity
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
    <div className="flex-1 overflow-y-auto p-6" style={{ height: 'calc(100vh - 64px)' }}>
      {error && (
        <div
          className="p-3 mb-4 rounded-lg text-xs"
          style={{ backgroundColor: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', border: '1px solid var(--border)' }}
        >
          {error}
        </div>
      )}

      {/* Active Interventions Section */}
      <div className="mb-8">
        <h3 className="text-base font-bold text-primary mb-3 flex items-center gap-2">
          <AlertTriangle style={{ width: '1.1rem', height: '1.1rem', color: 'var(--warning)' }} />
          Interventions Requiring Attention ({activeInvs.length})
        </h3>

        {activeInvs.length === 0 && !loading ? (
          <div className="tess-card text-center py-8 text-xs text-muted">
            <CheckCircle style={{ width: '1.5rem', height: '1.5rem', color: 'var(--success)', margin: '0 auto 0.5rem' }} />
            No active interventions at the moment. You are in good flow!
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {activeInvs.map((inv) => (
              <div
                key={inv.id}
                className="tess-card p-5"
                style={{
                  borderColor: 'var(--warning)',
                  backgroundColor: 'rgba(245, 158, 11, 0.05)'
                }}
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-bold text-primary">{inv.title}</span>
                  <span
                    className="text-[10px] font-bold px-2 py-0.5 rounded uppercase"
                    style={{ backgroundColor: '#F59E0B25', color: 'var(--warning)' }}
                  >
                    {inv.priority} PRIORITY
                  </span>
                </div>

                <p className="text-xs text-secondary mb-3 leading-relaxed">{inv.message}</p>

                <div className="p-2.5 rounded-lg bg-secondary text-xs font-medium text-primary mb-4 flex items-center gap-2">
                  <Wrench style={{ width: '0.9rem', height: '0.9rem', color: 'var(--accent)' }} />
                  <span>Suggested Action: {inv.suggested_action}</span>
                </div>

                {/* Actions: FIX IT (Agent), LATER, DISMISS */}
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
            ))}
          </div>
        )}
      </div>

      {/* Intervention History */}
      <div>
        <h4 className="text-sm font-bold text-primary mb-3">Past Interventions History</h4>
        {pastInvs.length === 0 ? (
          <div className="tess-card text-center py-6 text-xs text-muted">No past interventions yet.</div>
        ) : (
          <div className="flex flex-col gap-2">
            {pastInvs.map((inv) => (
              <div
                key={inv.id}
                className="tess-card p-3 flex items-center justify-between text-xs opacity-75"
              >
                <div>
                  <div className="font-semibold text-primary">{inv.title}</div>
                  <div className="text-[11px] text-muted">{inv.message}</div>
                </div>
                <span className="font-mono text-[10px] px-2 py-0.5 rounded bg-secondary text-muted uppercase">
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

