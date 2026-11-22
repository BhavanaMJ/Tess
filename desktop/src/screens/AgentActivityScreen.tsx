import React, { useEffect, useState, useMemo } from 'react';
import { apiService } from '../services/api';
import { AgentPlan } from '../types';
import { useMascot } from '../contexts/MascotContext';
import { AgentMetricsOverview } from '../components/agent/AgentMetricsOverview';
import { AgentFilterBar } from '../components/agent/AgentFilterBar';
import { AgentPlanCard } from '../components/agent/AgentPlanCard';
import { AgentPlanDetailModal } from '../components/agent/AgentPlanDetailModal';
import { AgentObjectiveForm } from '../components/agent/AgentObjectiveForm';
import {
  Bot,
  Play,
  Clock,
  CheckCircle,
  XCircle,
  ShieldAlert,
  AlertCircle,
  Check,
  Terminal,
  Calendar,
  Mail,
  Globe,
  FileText,
  Lock,
  ChevronRight,
  Maximize2
} from 'lucide-react';

export const AgentActivityScreen: React.FC = () => {
  const [plans, setPlans] = useState<AgentPlan[]>([]);
  const [selectedPlan, setSelectedPlan] = useState<AgentPlan | null>(null);
  const [newObjective, setNewObjective] = useState('');
  const [creating, setCreating] = useState(false);
  const [executing, setExecuting] = useState(false);
  const [loading, setLoading] = useState(true);
  const [statusMessage, setStatusMessage] = useState<{ text: string; error?: boolean } | null>(null);

  // Filters & Modal
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);

  const { setState: setMascotState } = useMascot();

  const loadPlans = async () => {
    setLoading(true);
    try {
      const data = await apiService.getAgentPlans();
      setPlans(data);
      if (data.length > 0) {
        if (!selectedPlan) {
          setSelectedPlan(data[0]);
        } else {
          const updated = data.find((p) => p.id === selectedPlan.id);
          setSelectedPlan(updated || data[0]);
        }
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
      setStatusMessage({ text: `Plan created successfully: Ready for review and confirmation.` });
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
      if (selectedPlan && selectedPlan.id === planId) {
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

  // Filter & Search Logic
  const filteredPlans = useMemo(() => {
    return plans.filter((p) => {
      // Status filter
      if (statusFilter !== 'ALL') {
        if (statusFilter === 'READY' && p.status !== 'READY') return false;
        if (statusFilter === 'EXECUTING' && p.status !== 'EXECUTING') return false;
        if (statusFilter === 'SUCCESS' && p.status !== 'SUCCESS') return false;
        if (statusFilter === 'FAILED' && p.status !== 'FAILED') return false;
        if (statusFilter === 'CANCELLED' && p.status !== 'CANCELLED') return false;
      }

      // Search Query
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchesObjective = p.objective.toLowerCase().includes(q);
        const matchesId = p.id.toLowerCase().includes(q);
        const matchesTool = p.steps?.some((s) => s.tool_name.toLowerCase().includes(q));
        if (!matchesObjective && !matchesId && !matchesTool) return false;
      }

      return true;
    });
  }, [plans, statusFilter, searchQuery]);

  const countsByStatus = useMemo(() => {
    return {
      ALL: plans.length,
      READY: plans.filter((p) => p.status === 'READY').length,
      EXECUTING: plans.filter((p) => p.status === 'EXECUTING').length,
      SUCCESS: plans.filter((p) => p.status === 'SUCCESS').length,
      FAILED: plans.filter((p) => p.status === 'FAILED').length,
      CANCELLED: plans.filter((p) => p.status === 'CANCELLED').length
    };
  }, [plans]);

  const getToolIcon = (tool: string) => {
    if (tool.includes('calendar')) return Calendar;
    if (tool.includes('gmail') || tool.includes('email')) return Mail;
    if (tool.includes('browser')) return Globe;
    if (tool.includes('file')) return FileText;
    return Terminal;
  };

  return (
    <div
      className="flex-1 overflow-y-auto p-6"
      style={{ height: 'calc(100vh - 68px)', position: 'relative', zIndex: 1 }}
    >
      {/* Status / Alert Banner */}
      {statusMessage && (
        <div
          className="p-3 mb-4 rounded-xl text-xs flex items-center justify-between animate-fadeIn"
          style={{
            backgroundColor: statusMessage.error
              ? 'rgba(251, 113, 133, 0.12)'
              : 'rgba(52, 211, 153, 0.12)',
            color: statusMessage.error ? '#FB7185' : '#34D399',
            border: `1px solid ${statusMessage.error ? 'rgba(251, 113, 133, 0.3)' : 'rgba(52, 211, 153, 0.3)'}`
          }}
        >
          <span className="flex items-center gap-2">
            {statusMessage.error ? (
              <AlertCircle style={{ width: '0.9rem', height: '0.9rem' }} />
            ) : (
              <CheckCircle style={{ width: '0.9rem', height: '0.9rem' }} />
            )}
            {statusMessage.text}
          </span>
          <button
            type="button"
            onClick={() => setStatusMessage(null)}
            className="text-muted hover:text-primary cursor-pointer font-bold"
            style={{ background: 'none', border: 'none' }}
          >
            ×
          </button>
        </div>
      )}

      {/* Top Section: Metrics Overview */}
      <AgentMetricsOverview
        plans={plans}
        selectedFilter={statusFilter}
        onSelectFilter={setStatusFilter}
      />

      {/* Objective Creation Form with Domain Starters */}
      <AgentObjectiveForm
        objective={newObjective}
        onObjectiveChange={setNewObjective}
        onSubmit={handleCreateObjective}
        creating={creating}
      />

      {/* Filter and Search Bar */}
      <AgentFilterBar
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        selectedStatus={statusFilter}
        onStatusChange={setStatusFilter}
        onRefresh={loadPlans}
        loading={loading}
        counts={countsByStatus}
      />

      {/* Main Two-Column Console Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Left Column: Plan Cards List */}
        <div className="lg:col-span-5 flex flex-col gap-3">
          <div className="flex items-center justify-between text-xs text-muted font-mono mb-1">
            <span>Plans ({filteredPlans.length})</span>
            {searchQuery && (
              <button
                type="button"
                onClick={() => setSearchQuery('')}
                className="text-accent hover:underline cursor-pointer"
                style={{ background: 'none', border: 'none' }}
              >
                Clear Search
              </button>
            )}
          </div>

          {loading && plans.length === 0 ? (
            <div className="tess-card text-center py-12 text-muted text-xs font-mono">
              Loading autonomous plans...
            </div>
          ) : filteredPlans.length === 0 ? (
            <div className="tess-card text-center py-12">
              <Bot
                style={{
                  width: '2rem',
                  height: '2rem',
                  color: 'var(--text-muted)',
                  margin: '0 auto 0.5rem',
                  opacity: 0.5
                }}
              />
              <div className="text-sm font-semibold text-primary">No Matching Plans</div>
              <p className="text-xs text-muted mt-1 max-w-xs mx-auto">
                {plans.length === 0
                  ? 'Dispatch your first autonomous objective above to generate an execution plan.'
                  : 'Try selecting another status tab or adjusting your search query.'}
              </p>
            </div>
          ) : (
            <div className="flex flex-col gap-2.5">
              {filteredPlans.map((p) => (
                <AgentPlanCard
                  key={p.id}
                  plan={p}
                  isSelected={selectedPlan?.id === p.id}
                  onSelect={() => setSelectedPlan(p)}
                  onOpenDetails={() => {
                    setSelectedPlan(p);
                    setIsDetailModalOpen(true);
                  }}
                  onConfirm={handleConfirmPlan}
                  onExecute={handleExecutePlan}
                  onCancel={handleCancelPlan}
                  executing={executing && selectedPlan?.id === p.id}
                />
              ))}
            </div>
          )}
        </div>

        {/* Right Column: Active Plan Deep-Dive Inspector */}
        <div className="lg:col-span-7 flex flex-col gap-4">
          {selectedPlan ? (
            <div className="flex flex-col gap-4">
              {/* Header Inspector Card */}
              <div className="tess-card p-5">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-mono text-xs text-muted uppercase tracking-wider">
                    Plan Objective ID: {selectedPlan.id}
                  </span>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => setIsDetailModalOpen(true)}
                      className="p-1.5 rounded-lg text-muted hover:text-primary transition-colors cursor-pointer border border-[var(--border)]"
                      style={{ backgroundColor: 'var(--bg-secondary)' }}
                      title="Open full-screen timeline modal"
                    >
                      <Maximize2 style={{ width: '0.85rem', height: '0.85rem' }} />
                    </button>
                    <span
                      className="font-mono text-xs font-bold px-2.5 py-0.5 rounded-full uppercase"
                      style={{
                        backgroundColor:
                          selectedPlan.status === 'SUCCESS'
                            ? 'rgba(52,211,153,0.15)'
                            : selectedPlan.status === 'READY'
                            ? 'rgba(34,211,238,0.15)'
                            : selectedPlan.status === 'EXECUTING'
                            ? 'rgba(251,191,36,0.15)'
                            : 'rgba(251,113,133,0.15)',
                        color:
                          selectedPlan.status === 'SUCCESS'
                            ? '#34D399'
                            : selectedPlan.status === 'READY'
                            ? '#22D3EE'
                            : selectedPlan.status === 'EXECUTING'
                            ? '#FBBF24'
                            : '#FB7185',
                        border: '1px solid var(--border)'
                      }}
                    >
                      Status: {selectedPlan.status}
                    </span>
                  </div>
                </div>

                <h3 className="text-base font-bold text-primary m-0 tracking-tight leading-snug">
                  {selectedPlan.objective}
                </h3>

                {/* Safeguard & Execution Buttons */}
                <div className="flex items-center gap-3 mt-4 pt-3 border-t border-[rgba(255,255,255,0.06)] flex-wrap">
                  {selectedPlan.status === 'READY' && (
                    <button
                      type="button"
                      onClick={() => handleConfirmPlan(selectedPlan.id)}
                      className="btn-cyan text-xs"
                    >
                      <Check style={{ width: '0.85rem', height: '0.85rem' }} />
                      <span>Confirm Action</span>
                    </button>
                  )}

                  {selectedPlan.status === 'READY' && (
                    <button
                      type="button"
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
                      type="button"
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

              {/* Execution Steps Timeline */}
              <div className="tess-card p-5">
                <div className="flex items-center justify-between mb-3.5">
                  <h4 className="text-xs font-bold text-primary uppercase font-mono tracking-wider m-0">
                    Execution Steps ({selectedPlan.steps?.length || 0})
                  </h4>
                  <span className="text-[11px] font-mono text-muted">
                    Automated Tool Sequence
                  </span>
                </div>

                <div className="flex flex-col gap-3">
                  {selectedPlan.steps?.map((step: any, index: number) => {
                    const ToolIcon = getToolIcon(step.tool_name);
                    const isHigh = step.risk_level?.toUpperCase() === 'HIGH';
                    const isMedium = step.risk_level?.toUpperCase() === 'MEDIUM';

                    return (
                      <div
                        key={step.id || index}
                        className="p-3.5 rounded-xl flex flex-col gap-2 transition-colors"
                        style={{
                          backgroundColor: 'var(--bg-secondary)',
                          border: '1px solid var(--border)'
                        }}
                      >
                        <div className="flex items-center justify-between flex-wrap gap-2">
                          <div className="flex items-center gap-2">
                            <span className="font-mono text-xs text-muted font-bold">
                              #{index + 1}
                            </span>
                            <div className="flex items-center gap-1.5 font-mono text-xs font-semibold text-[#22D3EE]">
                              <ToolIcon style={{ width: '0.85rem', height: '0.85rem' }} />
                              <span>{step.tool_name}</span>
                            </div>
                          </div>

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
                        </div>

                        {/* Confirmation Box if present */}
                        {step.confirmation && (
                          <div
                            className="p-2.5 rounded-lg text-xs flex items-start gap-2"
                            style={{
                              backgroundColor:
                                step.confirmation.status === 'CONFIRMED'
                                  ? 'rgba(52, 211, 153, 0.08)'
                                  : 'rgba(34, 211, 238, 0.08)',
                              border: `1px solid ${
                                step.confirmation.status === 'CONFIRMED'
                                  ? 'rgba(52, 211, 153, 0.2)'
                                  : 'rgba(34, 211, 238, 0.2)'
                              }`
                            }}
                          >
                            <Lock
                              style={{
                                width: '0.85rem',
                                height: '0.85rem',
                                color: step.confirmation.status === 'CONFIRMED' ? '#34D399' : '#22D3EE',
                                marginTop: '2px'
                              }}
                            />
                            <div className="text-[11px] text-secondary">
                              <span className="font-semibold text-primary">
                                Safeguard {step.confirmation.status}:
                              </span>{' '}
                              {step.confirmation.summary || 'Requires user approval before execution.'}
                            </div>
                          </div>
                        )}

                        <div className="text-xs text-secondary leading-relaxed">
                          {step.description ||
                            `Executes ${step.action_type || 'tool action'} safely within sandbox.`}
                        </div>

                        {/* Parameters */}
                        {(step.parameters || step.arguments) && (
                          <pre className="font-mono text-[10px] p-2 rounded-lg bg-[rgba(0,0,0,0.4)] text-muted overflow-x-auto m-0 border border-[rgba(255,255,255,0.04)]">
                            {JSON.stringify(step.parameters || step.arguments, null, 2)}
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
              <Bot
                style={{
                  width: '2.5rem',
                  height: '2.5rem',
                  color: 'var(--text-muted)',
                  margin: '0 auto 0.5rem',
                  opacity: 0.5
                }}
              />
              <div className="text-sm font-semibold text-primary">No Plan Selected</div>
              <p className="text-xs text-muted mt-1 max-w-sm mx-auto">
                Select an objective from the left list or dispatch a new agent plan.
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Deep-Dive Inspection Modal */}
      <AgentPlanDetailModal
        plan={selectedPlan}
        isOpen={isDetailModalOpen}
        onClose={() => setIsDetailModalOpen(false)}
        onConfirmPlan={handleConfirmPlan}
        onExecutePlan={handleExecutePlan}
        onCancelPlan={handleCancelPlan}
        executing={executing}
      />
    </div>
  );
};
