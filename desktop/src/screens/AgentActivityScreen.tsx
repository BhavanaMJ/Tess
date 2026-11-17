import React, { useEffect, useState } from 'react';
import { apiService } from '../services/api';
import { AgentPlan } from '../types';
import { useMascot } from '../contexts/MascotContext';
import {
  Bot,
  Plus,
  CheckCircle,
  XCircle,
  Play,
  Clock,
  ShieldAlert,
  AlertCircle,
  ArrowRight,
  Terminal,
  Zap,
  Check
} from 'lucide-react';

export const AgentActivityScreen: React.FC = () => {
  const [plans, setPlans] = useState<AgentPlan[]>([]);
  const [selectedPlan, setSelectedPlan] = useState<AgentPlan | null>(null);
  const [newObjective, setNewObjective] = useState('');
  const [creating, setCreating] = useState(false);
  const [executing, setExecuting] = useState(false);
  const [loading, setLoading] = useState(true);
  const [statusMessage, setStatusMessage] = useState<{ text: string; error?: boolean } | null>(null);

  const { setState: setMascotState } = useMascot();

  const loadPlans = async () => {
    setLoading(true);
    try {
      const data = await apiService.getAgentPlans();
      setPlans(data);
      if (data.length > 0 && !selectedPlan) {
        setSelectedPlan(data[0]);
      } else if (selectedPlan) {
        const updated = data.find((p) => p.id === selectedPlan.id);
        if (updated) setSelectedPlan(updated);
      }
    } catch (e: any) {
      setStatusMessage({ text: e.message || 'Failed to load agent plans', error: true });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPlans();
  }, []);

  const handleCreateObjective = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newObjective.trim() || creating) return;

    setCreating(true);
    setStatusMessage(null);
    setMascotState('PLANNING');

    try {
      const plan = await apiService.createAgentObjective(newObjective.trim());
      setNewObjective('');
      setPlans((prev) => [plan, ...prev]);
      setSelectedPlan(plan);
      setMascotState('CONFIRMING');
      setStatusMessage({ text: `Plan created: Ready for confirmation.` });
    } catch (e: any) {
      setStatusMessage({ text: e.message || 'Plan generation failed', error: true });
      setMascotState('ERROR');
    } finally {
      setCreating(false);
    }
  };

  const handleConfirmPlan = async (planId: string) => {
    setStatusMessage(null);
    try {
      await apiService.confirmAgentPlan(planId);
      setStatusMessage({ text: 'Action confirmed. You can now execute the plan.' });
      await loadPlans();
    } catch (e: any) {
      setStatusMessage({ text: e.message || 'Confirmation failed', error: true });
    }
  };

  const handleCancelPlan = async (planId: string) => {
    setStatusMessage(null);
    try {
      await apiService.cancelAgentPlan(planId);
      setStatusMessage({ text: 'Plan cancelled.' });
      await loadPlans();
    } catch (e: any) {
      setStatusMessage({ text: e.message || 'Cancel failed', error: true });
    }
  };

  const handleExecutePlan = async (planId: string) => {
    setExecuting(true);
    setStatusMessage(null);
    setMascotState('ACTING');

    try {
      const updated = await apiService.executeAgentPlan(planId);
      setStatusMessage({ text: `Execution finished with status: ${updated.status}` });
      if (selectedPlan) {
        setSelectedPlan({ ...selectedPlan, status: updated.status as any });
      }
      await loadPlans();
      setMascotState(updated.status === 'SUCCESS' ? 'SUCCESS' : 'ERROR');
    } catch (e: any) {
      setStatusMessage({ text: e.message || 'Execution failed', error: true });
      setMascotState('ERROR');
    } finally {
      setExecuting(false);
    }
  };

  return (
    <div
      className="flex h-full"
      style={{ height: 'calc(100vh - 68px)', position: 'relative', zIndex: 1 }}
    >
      {/* LEFT COLUMN: Objectives List */}
      <div
        className="flex flex-col border-r select-none"
        style={{
          width: '320px',
          backgroundColor: 'var(--bg-secondary)',
          borderColor: 'var(--border)'
        }}
      >
        <div className="p-3 border-b border-[rgba(255,255,255,0.06)]">
          <form onSubmit={handleCreateObjective} className="flex flex-col gap-2">
            <span className="text-[11px] font-mono text-muted uppercase tracking-wider">
              Autonomous Objective:
            </span>
            <input
              type="text"
              className="tess-input text-xs"
              placeholder="e.g. Log 1.5h on task #101"
              value={newObjective}
              onChange={(e) => setNewObjective(e.target.value)}
              disabled={creating}
            />
            <button
              type="submit"
              disabled={!newObjective.trim() || creating}
              className="btn-primary text-xs justify-center"
            >
              <Plus style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>{creating ? 'Formulating Plan...' : 'Generate Agent Plan'}</span>
            </button>
          </form>
        </div>

        <div className="flex-1 overflow-y-auto p-2 flex flex-col gap-1.5">
          {plans.map((p) => {
            const isSelected = selectedPlan?.id === p.id;
            return (
              <div
                key={p.id}
                onClick={() => setSelectedPlan(p)}
                className="p-3 rounded-xl cursor-pointer transition-all"
                style={{
                  backgroundColor: isSelected ? 'rgba(139, 92, 246, 0.12)' : 'transparent',
                  border: isSelected ? '1px solid rgba(139, 92, 246, 0.35)' : '1px solid transparent'
                }}
              >
                <div className="flex items-center justify-between mb-1">
                  <span
                    className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full uppercase"
                    style={{
                      backgroundColor:
                        p.status === 'SUCCESS'
                          ? 'rgba(52,211,153,0.15)'
                          : p.status === 'READY'
                          ? 'rgba(34,211,238,0.15)'
                          : 'rgba(251,191,36,0.15)',
                      color:
                        p.status === 'SUCCESS'
                          ? '#34D399'
                          : p.status === 'READY'
                          ? '#22D3EE'
                          : '#FBBF24',
                      border: '1px solid var(--border)'
                    }}
                  >
                    {p.status}
                  </span>
                  <span className="text-[10px] font-mono text-muted">
                    {p.steps?.length || 0} step(s)
                  </span>
                </div>
                <div className="text-xs font-semibold text-primary truncate tracking-tight">
                  {p.objective}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* RIGHT COLUMN: Plan Details, Safeguards, & Execution */}
      <div className="flex-1 overflow-y-auto p-6 flex flex-col gap-4 bg-primary">
        {statusMessage && (
          <div
            className="p-3 rounded-xl text-xs flex items-center justify-between"
            style={{
              backgroundColor: statusMessage.error
                ? 'rgba(251, 113, 133, 0.12)'
                : 'rgba(52, 211, 153, 0.12)',
              color: statusMessage.error ? '#FB7185' : '#34D399',
              border: `1px solid ${statusMessage.error ? 'rgba(251, 113, 133, 0.3)' : 'rgba(52, 211, 153, 0.3)'}`
            }}
          >
            <span>{statusMessage.text}</span>
            <button
              onClick={() => setStatusMessage(null)}
              className="text-muted hover:text-primary cursor-pointer font-bold"
              style={{ background: 'none', border: 'none' }}
            >
              ×
            </button>
          </div>
        )}

        {selectedPlan ? (
          <div className="flex flex-col gap-4">
            {/* Header Card */}
            <div className="tess-card p-5">
              <div className="flex items-center justify-between mb-2">
                <span className="font-mono text-xs text-muted uppercase tracking-wider">
                  Plan Objective ID: {selectedPlan.id}
                </span>
                <span
                  className="font-mono text-xs font-bold px-2.5 py-0.5 rounded-full uppercase"
                  style={{
                    backgroundColor: 'rgba(139, 92, 246, 0.15)',
                    color: '#A78BFA',
                    border: '1px solid rgba(139, 92, 246, 0.35)'
                  }}
                >
                  Status: {selectedPlan.status}
                </span>
              </div>
              <h3 className="text-base font-bold text-primary m-0 tracking-tight">
                {selectedPlan.objective}
              </h3>

              {/* Action Safeguard Buttons */}
              <div className="flex items-center gap-3 mt-4 pt-3 border-t border-[rgba(255,255,255,0.06)]">
                {selectedPlan.status === 'READY' && (
                  <button
                    onClick={() => handleConfirmPlan(selectedPlan.id)}
                    className="btn-cyan text-xs"
                  >
                    <Check style={{ width: '0.85rem', height: '0.85rem' }} />
                    <span>Confirm Action</span>
                  </button>
                )}

                {selectedPlan.status === 'READY' && (
                  <button
                    onClick={() => handleExecutePlan(selectedPlan.id)}
                    disabled={executing}
                    className="btn-primary text-xs"
                  >
                    <Play style={{ width: '0.85rem', height: '0.85rem' }} />
                    <span>{executing ? 'Executing Steps...' : 'Execute Plan'}</span>
                  </button>
                )}

                {selectedPlan.status !== 'SUCCESS' && selectedPlan.status !== 'CANCELLED' && (
                  <button
                    onClick={() => handleCancelPlan(selectedPlan.id)}
                    className="btn-secondary text-xs"
                    style={{ color: 'var(--text-muted)' }}
                  >
                    <XCircle style={{ width: '0.85rem', height: '0.85rem' }} />
                    <span>Cancel Plan</span>
                  </button>
                )}
              </div>
            </div>

            {/* Plan Steps Detailed List */}
            <div className="tess-card p-5">
              <h4 className="text-xs font-bold text-primary uppercase font-mono tracking-wider mb-3">
                Execution Steps ({selectedPlan.steps?.length || 0})
              </h4>

              <div className="flex flex-col gap-2.5">
                {selectedPlan.steps?.map((step: any, index: number) => {
                  const isMediumOrHighRisk =
                    step.risk_level?.toUpperCase() === 'HIGH' ||
                    step.risk_level?.toUpperCase() === 'MEDIUM';
                  return (
                    <div
                      key={index}
                      className="p-3.5 rounded-xl flex flex-col gap-1.5 transition-colors"
                      style={{
                        backgroundColor: 'var(--bg-secondary)',
                        border: '1px solid var(--border)'
                      }}
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <span className="font-mono text-xs text-muted font-bold">
                            #{index + 1}
                          </span>
                          <span className="font-mono text-xs font-semibold text-[#22D3EE]">
                            {step.tool_name}
                          </span>
                        </div>

                        {step.risk_level && (
                          <span
                            className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full uppercase"
                            style={{
                              backgroundColor: isMediumOrHighRisk
                                ? 'rgba(251, 113, 133, 0.15)'
                                : 'rgba(52, 211, 153, 0.15)',
                              color: isMediumOrHighRisk ? '#FB7185' : '#34D399',
                              border: `1px solid ${isMediumOrHighRisk ? 'rgba(251, 113, 133, 0.3)' : 'rgba(52, 211, 153, 0.3)'}`
                            }}
                          >
                            {step.risk_level.toUpperCase()} RISK
                          </span>
                        )}
                      </div>

                      <div className="text-xs text-secondary leading-relaxed">
                        {step.description || 'Executes external system interaction.'}
                      </div>

                      {step.arguments && (
                        <pre className="font-mono text-[10px] p-2 rounded-lg bg-[rgba(0,0,0,0.4)] text-muted overflow-x-auto m-0 border border-[rgba(255,255,255,0.04)]">
                          {JSON.stringify(step.arguments, null, 2)}
                        </pre>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        ) : (
          <div className="tess-card text-center py-16">
            <Bot style={{ width: '2.5rem', height: '2.5rem', color: 'var(--text-muted)', margin: '0 auto 0.5rem', opacity: 0.5 }} />
            <div className="text-sm font-semibold text-primary">No Plan Selected</div>
            <p className="text-xs text-muted mt-1 max-w-sm mx-auto">
              Select an objective from the rail or generate a new agent plan.
            </p>
          </div>
        )}
      </div>
    </div>
  );
};
