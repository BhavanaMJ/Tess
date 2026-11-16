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
  AlertCircle
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
        // Refresh selected plan
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
      const res = await apiService.executeAgentPlan(planId);
      setStatusMessage({ text: 'Plan executed successfully on external system!' });
      setMascotState('SUCCESS');
      await loadPlans();
    } catch (e: any) {
      setStatusMessage({ text: e.message || 'Action execution failed', error: true });
      setMascotState('ERROR');
    } finally {
      setExecuting(false);
    }
  };

  return (
    <div className="flex h-full" style={{ height: 'calc(100vh - 64px)' }}>
      {/* Plans Master List */}
      <div
        className="flex flex-col border-r"
        style={{
          width: '320px',
          backgroundColor: 'var(--bg-secondary)',
          borderColor: 'var(--border)'
        }}
      >
        {/* Create Objective Input */}
        <form onSubmit={handleCreateObjective} className="p-3 border-b" style={{ borderColor: 'var(--border)' }}>
          <div className="flex gap-2">
            <input
              type="text"
              className="tess-input py-1.5 text-xs"
              placeholder="e.g. Update worklog with 2 hours"
              value={newObjective}
              onChange={(e) => setNewObjective(e.target.value)}
              disabled={creating}
            />
            <button type="submit" className="btn-primary text-xs px-2.5" disabled={!newObjective.trim() || creating}>
              <Plus style={{ width: '0.9rem', height: '0.9rem' }} />
            </button>
          </div>
        </form>

        <div className="flex-1 overflow-y-auto p-2 flex flex-col gap-2">
          {plans.length === 0 && !loading && (
            <div className="text-center text-xs text-muted py-8">
              No agent plans found. Enter an objective above.
            </div>
          )}

          {plans.map((p) => {
            const isSelected = selectedPlan?.id === p.id;
            const isSuccess = p.status === 'SUCCESS';
            const isFailed = p.status === 'FAILED';
            return (
              <div
                key={p.id}
                onClick={() => setSelectedPlan(p)}
                className="tess-card p-3 cursor-pointer text-xs"
                style={{
                  backgroundColor: isSelected ? 'var(--bg-card)' : 'transparent',
                  borderColor: isSelected ? 'var(--accent)' : 'var(--border)'
                }}
              >
                <div className="flex items-center justify-between mb-1.5">
                  <span
                    className="font-bold px-2 py-0.5 rounded text-[10px]"
                    style={{
                      backgroundColor: isSuccess ? '#10B98125' : isFailed ? '#EF444425' : '#F59E0B25',
                      color: isSuccess ? 'var(--success)' : isFailed ? 'var(--danger)' : 'var(--warning)'
                    }}
                  >
                    {p.status}
                  </span>
                  <span className="text-[10px] text-muted">
                    {p.steps?.length || 0} step(s)
                  </span>
                </div>
                <div className="font-medium text-primary line-clamp-2">{p.objective}</div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Plan Details & Execution Area */}
      <div className="flex-1 overflow-y-auto p-6 bg-primary">
        {statusMessage && (
          <div
            className="p-3 mb-6 rounded-lg text-xs flex items-center gap-2"
            style={{
              backgroundColor: statusMessage.error ? 'rgba(239, 68, 68, 0.1)' : 'rgba(16, 185, 129, 0.1)',
              color: statusMessage.error ? 'var(--danger)' : 'var(--success)',
              border: '1px solid var(--border)'
            }}
          >
            {statusMessage.error ? (
              <AlertCircle style={{ width: '1rem', height: '1rem' }} />
            ) : (
              <CheckCircle style={{ width: '1rem', height: '1rem' }} />
            )}
            <span>{statusMessage.text}</span>
          </div>
        )}

        {!selectedPlan ? (
          <div className="text-center text-muted py-16 text-sm">
            <Bot style={{ width: '2.5rem', height: '2.5rem', margin: '0 auto 0.75rem', color: 'var(--accent)' }} />
            Select an agent plan or create a new objective to review proposed actions.
          </div>
        ) : (
          <div>
            <div className="flex items-center justify-between pb-4 border-b mb-6" style={{ borderColor: 'var(--border)' }}>
              <div>
                <span className="text-[11px] font-mono font-bold text-accent">
                  PLAN ID: {selectedPlan.id}
                </span>
                <h2 className="text-lg font-bold text-primary mt-1 m-0">
                  {selectedPlan.objective}
                </h2>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-2">
                {selectedPlan.status === 'READY' && (
                  <>
                    <button
                      onClick={() => handleConfirmPlan(selectedPlan.id)}
                      className="btn-primary text-xs"
                    >
                      <CheckCircle style={{ width: '0.9rem', height: '0.9rem' }} />
                      <span>Confirm Plan</span>
                    </button>
                    <button
                      onClick={() => handleCancelPlan(selectedPlan.id)}
                      className="btn-secondary text-xs"
                    >
                      <XCircle style={{ width: '0.9rem', height: '0.9rem' }} />
                      <span>Cancel</span>
                    </button>
                  </>
                )}

                {(selectedPlan.status === 'READY' || selectedPlan.status === 'PLANNING') && (
                  <button
                    onClick={() => handleExecutePlan(selectedPlan.id)}
                    disabled={executing}
                    className="btn-primary text-xs"
                    style={{ backgroundColor: 'var(--accent)' }}
                  >
                    <Play style={{ width: '0.9rem', height: '0.9rem' }} />
                    <span>{executing ? 'Executing...' : 'Execute Confirmed'}</span>
                  </button>
                )}
              </div>
            </div>

            {/* Steps & Tools List */}
            <h4 className="text-sm font-bold text-primary mb-3">Planned Tool Operations:</h4>
            <div className="flex flex-col gap-4">
              {selectedPlan.steps?.map((step) => {
                const isMediumOrHigh = step.risk_level === 'MEDIUM' || step.risk_level === 'HIGH';
                const confStatus = step.confirmation?.status || 'PENDING';
                return (
                  <div key={step.id || step.step_order} className="tess-card p-4">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-bold text-accent">
                          Step {step.step_order}:
                        </span>
                        <span className="text-sm font-bold text-primary">{step.tool_name}</span>
                      </div>

                      <div className="flex items-center gap-2">
                        {isMediumOrHigh && (
                          <span
                            className="text-[10px] font-bold px-2 py-0.5 rounded flex items-center gap-1"
                            style={{
                              backgroundColor: step.risk_level === 'HIGH' ? '#EF444425' : '#F59E0B25',
                              color: step.risk_level === 'HIGH' ? 'var(--danger)' : 'var(--warning)'
                            }}
                          >
                            <ShieldAlert style={{ width: '0.75rem', height: '0.75rem' }} />
                            {step.risk_level} RISK
                          </span>
                        )}
                        <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-secondary text-muted">
                          CONFIRMATION: {confStatus}
                        </span>
                      </div>
                    </div>

                    <div className="mt-2 text-xs text-muted">Parameters:</div>
                    <pre
                      className="font-mono text-xs p-3 rounded-lg mt-1 overflow-x-auto text-primary"
                      style={{ backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border)' }}
                    >
                      {JSON.stringify(step.parameters, null, 2)}
                    </pre>

                    {step.result && (
                      <div className="mt-3">
                        <div className="text-xs font-semibold text-success mb-1">Execution Result:</div>
                        <pre
                          className="font-mono text-xs p-3 rounded-lg overflow-x-auto text-primary"
                          style={{ backgroundColor: 'rgba(16, 185, 129, 0.05)', border: '1px solid var(--border)' }}
                        >
                          {JSON.stringify(step.result, null, 2)}
                        </pre>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

