import React, { useEffect, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useMascot } from '../contexts/MascotContext';
import { Mascot } from '../components/Mascot';
import { apiService } from '../services/api';
import {
  ProductivitySummary,
  ProductivityTask,
  FuturePrediction,
  InterventionResponse,
  AgentPlan
} from '../types';
import { ScreenTab } from '../components/Sidebar';
import {
  CheckSquare,
  AlertTriangle,
  Compass,
  Bot,
  ArrowRight,
  Clock,
  Sparkles,
  Zap,
  TrendingUp,
  ShieldAlert,
  Terminal,
  Activity
} from 'lucide-react';

interface HomeScreenProps {
  onNavigate: (tab: ScreenTab) => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ onNavigate }) => {
  const { user } = useAuth();
  const { state: mascotState, setState: setMascotState } = useMascot();

  const [summary, setSummary] = useState<ProductivitySummary | null>(null);
  const [tasks, setTasks] = useState<ProductivityTask[]>([]);
  const [predictions, setPredictions] = useState<FuturePrediction[]>([]);
  const [interventions, setInterventions] = useState<InterventionResponse[]>([]);
  const [plans, setPlans] = useState<AgentPlan[]>([]);
  const [loading, setLoading] = useState(true);

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  };

  const loadHomeData = async () => {
    setLoading(true);
    try {
      const [sumRes, taskRes, predRes, invRes, planRes] = await Promise.allSettled([
        apiService.getProductivitySummary(),
        apiService.getProductivityTasks(),
        apiService.getFuturePredictions(),
        apiService.getInterventions(),
        apiService.getAgentPlans()
      ]);

      if (sumRes.status === 'fulfilled') setSummary(sumRes.value);
      if (taskRes.status === 'fulfilled') setTasks(taskRes.value);
      if (predRes.status === 'fulfilled') setPredictions(predRes.value);
      if (invRes.status === 'fulfilled') setInterventions(invRes.value);
      if (planRes.status === 'fulfilled') setPlans(planRes.value);

      // Contextual mascot behavior based on real system state
      const activeInvs = invRes.status === 'fulfilled' ? invRes.value.filter(i => i.status === 'SENT') : [];
      const hasRisks = predRes.status === 'fulfilled' && predRes.value.some(p => p.prediction_type === 'RISK' && p.probability >= 0.7);

      if (activeInvs.length > 0) {
        setMascotState('INTERVENING');
      } else if (hasRisks) {
        setMascotState('ATTENTION');
      } else {
        setMascotState('IDLE');
      }
    } catch (_) {
      setMascotState('ERROR');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadHomeData();
  }, []);

  const overdueTasks = tasks.filter(t => {
    if (!t.due_date) return false;
    return new Date(t.due_date) < new Date();
  });

  const activeInterventions = interventions.filter(i => i.status === 'SENT');
  const criticalPredictions = predictions.filter(p => p.prediction_type === 'RISK' || p.probability >= 0.65);

  return (
    <div
      className="flex-1 overflow-y-auto p-6"
      style={{ height: 'calc(100vh - 68px)', position: 'relative', zIndex: 1 }}
    >
      {/* SECTION A: HERO COMMAND CENTRE — MEET TESS */}
      <div
        className="tess-card p-6 relative overflow-hidden"
        style={{
          background: 'linear-gradient(135deg, rgba(23, 26, 45, 0.85) 0%, rgba(11, 13, 24, 0.95) 100%)',
          borderColor: 'rgba(139, 92, 246, 0.3)',
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.5), inset 0 0 24px rgba(139, 92, 246, 0.05)'
        }}
      >
        {/* Subtle Ambient Cosmic Lighting Accent */}
        <div
          className="absolute -top-16 -right-16 w-64 h-64 rounded-full pointer-events-none"
          style={{
            background: 'radial-gradient(circle, rgba(139, 92, 246, 0.18) 0%, transparent 70%)',
            filter: 'blur(30px)'
          }}
        />

        <div className="flex flex-col md:flex-row items-center justify-between gap-6 relative z-10">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <div className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-[rgba(139,92,246,0.15)] border border-[rgba(139,92,246,0.35)]">
                <Sparkles style={{ width: '0.85rem', height: '0.85rem', color: '#A78BFA' }} />
                <span className="text-[11px] font-mono font-bold text-[#A78BFA] tracking-wider uppercase">
                  Autonomous Operating System
                </span>
              </div>
              <span className="text-[11px] font-mono text-muted">
                v2.0 • Active
              </span>
            </div>

            <h2 className="text-2xl font-bold tracking-tight text-primary m-0">
              {getGreeting()}{user?.email ? `, ${user.email.split('@')[0]}` : ''}
            </h2>

            <p className="text-xs text-secondary mt-1.5 max-w-xl leading-relaxed m-0">
              {activeInterventions.length > 0
                ? `TESS detected an active divergence in your trajectory. An urgent intervention is ready for review.`
                : overdueTasks.length > 0
                ? `You have ${overdueTasks.length} overdue task(s) requiring focus to protect your upcoming milestones.`
                : `Your trajectory is balanced. TESS is observing context, predicting potential outcomes, and standing by.`}
            </p>

            <div className="flex items-center gap-3 mt-4">
              <button
                onClick={() => onNavigate('chat')}
                className="btn-primary text-xs"
              >
                <span>Talk to TESS</span>
                <ArrowRight style={{ width: '0.85rem', height: '0.85rem' }} />
              </button>
              <button
                onClick={() => onNavigate('futures')}
                className="btn-cyan text-xs"
              >
                <Compass style={{ width: '0.85rem', height: '0.85rem' }} />
                <span>Simulate Future</span>
              </button>
              <button
                onClick={() => onNavigate('tasks')}
                className="btn-secondary text-xs"
              >
                <span>Tasks ({tasks.length})</span>
              </button>
            </div>
          </div>

          {/* Living Holographic Mascot Orb */}
          <div className="flex flex-col items-center justify-center p-3">
            <Mascot state={mascotState} size="lg" showLabel={true} />
          </div>
        </div>
      </div>

      <div style={{ height: '1.25rem' }} />

      {/* SECTION B & C: TELEMETRY METRIC STRIP */}
      <div className="grid gap-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)' }}>
        <div
          onClick={() => onNavigate('tasks')}
          className="tess-card p-4 cursor-pointer hover:border-[rgba(139,92,246,0.4)] transition-all"
        >
          <div className="flex items-center justify-between text-muted text-[11px] font-mono tracking-wider font-semibold">
            <span>ACTIVE TASKS</span>
            <Activity style={{ width: '0.9rem', height: '0.9rem', color: '#22D3EE' }} />
          </div>
          <div className="text-2xl font-bold mt-1 text-primary font-mono">{summary?.total_active ?? tasks.length}</div>
          <div className="text-[11px] text-muted mt-1">Open work packages</div>
        </div>

        <div
          onClick={() => onNavigate('tasks')}
          className="tess-card p-4 cursor-pointer hover:border-[rgba(251,113,133,0.4)] transition-all"
          style={{ borderColor: overdueTasks.length > 0 ? 'rgba(251, 113, 133, 0.35)' : 'var(--border)' }}
        >
          <div className="flex items-center justify-between text-[11px] font-mono tracking-wider font-semibold" style={{ color: '#FB7185' }}>
            <span>OVERDUE</span>
            <ShieldAlert style={{ width: '0.9rem', height: '0.9rem', color: '#FB7185' }} />
          </div>
          <div className="text-2xl font-bold mt-1 font-mono" style={{ color: '#FB7185' }}>
            {summary?.overdue ?? overdueTasks.length}
          </div>
          <div className="text-[11px] text-muted mt-1">Requires intervention</div>
        </div>

        <div
          onClick={() => onNavigate('tasks')}
          className="tess-card p-4 cursor-pointer hover:border-[rgba(251,191,36,0.4)] transition-all"
        >
          <div className="flex items-center justify-between text-[11px] font-mono tracking-wider font-semibold" style={{ color: '#FBBF24' }}>
            <span>DUE TODAY</span>
            <Clock style={{ width: '0.9rem', height: '0.9rem', color: '#FBBF24' }} />
          </div>
          <div className="text-2xl font-bold mt-1 font-mono" style={{ color: '#FBBF24' }}>
            {summary?.due_today ?? 0}
          </div>
          <div className="text-[11px] text-muted mt-1">High priority focus</div>
        </div>

        <div
          onClick={() => onNavigate('tasks')}
          className="tess-card p-4 cursor-pointer hover:border-[rgba(52,211,153,0.4)] transition-all"
        >
          <div className="flex items-center justify-between text-[11px] font-mono tracking-wider font-semibold" style={{ color: '#34D399' }}>
            <span>COMPLETED</span>
            <TrendingUp style={{ width: '0.9rem', height: '0.9rem', color: '#34D399' }} />
          </div>
          <div className="text-2xl font-bold mt-1 font-mono" style={{ color: '#34D399' }}>
            {summary?.completed_recently ?? 0}
          </div>
          <div className="text-[11px] text-muted mt-1">Last 7 days momentum</div>
        </div>
      </div>

      <div style={{ height: '1.25rem' }} />

      {/* 2-COLUMN MAIN SPATIAL GRID */}
      <div style={{ display: 'grid', gridTemplateColumns: '1.15fr 0.85fr', gap: '1.25rem' }}>
        
        {/* LEFT COLUMN: Proactive Interventions & Tasks */}
        <div className="flex flex-col gap-4">
          
          {/* SECTION E: PROACTIVE TESS INTERVENTION */}
          {activeInterventions.length > 0 ? (
            <div
              className="tess-card p-5 relative overflow-hidden"
              style={{
                borderColor: 'rgba(251, 113, 133, 0.45)',
                background: 'linear-gradient(135deg, rgba(251, 113, 133, 0.08) 0%, rgba(17, 20, 38, 0.8) 100%)',
                boxShadow: '0 0 25px rgba(251, 113, 133, 0.15)'
              }}
            >
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-[#FB7185] animate-ping" />
                  <span className="text-xs font-mono font-bold tracking-wider uppercase text-[#FB7185]">
                    Proactive Intervention Required
                  </span>
                </div>
                <button
                  onClick={() => onNavigate('interventions')}
                  className="text-xs font-mono font-semibold flex items-center gap-1 cursor-pointer text-[#FB7185]"
                  style={{ background: 'none', border: 'none' }}
                >
                  Inspect <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
                </button>
              </div>

              <h4 className="text-sm font-semibold text-primary m-0 mt-1">
                {activeInterventions[0].title || 'Trajectory Risk Detected'}
              </h4>
              <p className="text-xs text-secondary mt-1.5 leading-relaxed m-0">
                {activeInterventions[0].message}
              </p>

              <div className="mt-3 p-2.5 rounded-lg bg-[rgba(0,0,0,0.3)] border border-[rgba(255,255,255,0.06)] flex items-center justify-between">
                <div className="text-[11px] text-muted">
                  <span className="text-secondary font-medium">Recommended Fix:</span>{' '}
                  {activeInterventions[0].suggested_action}
                </div>
                <button
                  onClick={() => onNavigate('interventions')}
                  className="px-3 py-1 rounded-md text-[11px] font-semibold font-mono bg-[#FB7185] text-white cursor-pointer hover:bg-[#F43F5E] transition-all"
                  style={{ border: 'none' }}
                >
                  FIX MY FUTURE
                </button>
              </div>
            </div>
          ) : (
            <div className="tess-card p-4 flex items-center justify-between bg-[rgba(52,211,153,0.03)] border-[rgba(52,211,153,0.2)]">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-[rgba(52,211,153,0.12)] border border-[rgba(52,211,153,0.3)] flex items-center justify-center">
                  <Zap style={{ width: '1rem', height: '1rem', color: '#34D399' }} />
                </div>
                <div>
                  <div className="text-xs font-semibold text-primary">No Active Interventions</div>
                  <div className="text-[11px] text-muted">Your current behavioral velocity aligns with expected milestones.</div>
                </div>
              </div>
              <button
                onClick={() => onNavigate('interventions')}
                className="text-xs font-mono text-muted hover:text-primary cursor-pointer"
                style={{ background: 'none', border: 'none' }}
              >
                History →
              </button>
            </div>
          )}

          {/* SECTION B: DAILY INTELLIGENCE & TASKS */}
          <div className="tess-card p-5">
            <div className="flex items-center justify-between mb-3.5 pb-2.5 border-b border-[rgba(255,255,255,0.06)]">
              <div className="flex items-center gap-2">
                <CheckSquare style={{ width: '1rem', height: '1rem', color: '#22D3EE' }} />
                <span className="text-xs font-bold text-primary uppercase font-mono tracking-wider">
                  Important Tasks & Deadlines
                </span>
              </div>
              <button
                onClick={() => onNavigate('tasks')}
                className="text-xs font-mono text-[#22D3EE] flex items-center gap-1 cursor-pointer hover:underline"
                style={{ background: 'none', border: 'none' }}
              >
                View all ({tasks.length}) <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
              </button>
            </div>

            {tasks.length === 0 ? (
              <div className="text-center py-6">
                <Clock style={{ width: '1.5rem', height: '1.5rem', color: 'var(--text-muted)', margin: '0 auto' }} />
                <div className="text-xs text-secondary font-medium mt-2">No Active Tasks Synchronized</div>
                <p className="text-[11px] text-muted mt-1 max-w-xs mx-auto">
                  Sync your tasks with OpenProject or add personal action items in the Tasks tab.
                </p>
                <button
                  onClick={() => onNavigate('tasks')}
                  className="btn-secondary text-[11px] mt-3 py-1.5 px-3"
                >
                  Manage Tasks
                </button>
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                {tasks.slice(0, 4).map((task) => {
                  const isOverdue = task.due_date && new Date(task.due_date) < new Date();
                  return (
                    <div
                      key={task.id}
                      className="flex items-center justify-between p-2.5 rounded-lg transition-colors hover:bg-[rgba(255,255,255,0.03)]"
                      style={{
                        backgroundColor: 'var(--bg-secondary)',
                        border: isOverdue ? '1px solid rgba(251,113,133,0.3)' : '1px solid var(--border)'
                      }}
                    >
                      <div className="truncate pr-3" style={{ maxWidth: '320px' }}>
                        <div className="text-xs font-semibold text-primary truncate">{task.title}</div>
                        <div className="text-[10px] font-mono text-muted mt-0.5">
                          {task.project || 'OpenProject'} • {task.status || 'Active'}
                        </div>
                      </div>

                      {task.due_date && (
                        <div
                          className="text-[11px] font-mono px-2 py-0.5 rounded flex items-center gap-1 shrink-0"
                          style={{
                            color: isOverdue ? '#FB7185' : 'var(--text-muted)',
                            backgroundColor: isOverdue ? 'rgba(251,113,133,0.1)' : 'rgba(255,255,255,0.03)'
                          }}
                        >
                          <Clock style={{ width: '0.7rem', height: '0.7rem' }} />
                          <span>{task.due_date}</span>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* RIGHT COLUMN: Future Engine & Autonomous Agent Workflows */}
        <div className="flex flex-col gap-4">
          
          {/* SECTION D: FUTURE ENGINE TRAJECTORY */}
          <div
            className="tess-card p-5"
            style={{
              borderColor: 'rgba(34, 211, 238, 0.25)',
              background: 'linear-gradient(135deg, rgba(34, 211, 238, 0.04) 0%, rgba(17, 20, 38, 0.8) 100%)'
            }}
          >
            <div className="flex items-center justify-between mb-3.5 pb-2.5 border-b border-[rgba(255,255,255,0.06)]">
              <div className="flex items-center gap-2">
                <Compass style={{ width: '1rem', height: '1rem', color: '#22D3EE' }} />
                <span className="text-xs font-bold text-primary uppercase font-mono tracking-wider">
                  Future Engine Trajectory
                </span>
              </div>
              <button
                onClick={() => onNavigate('futures')}
                className="text-xs font-mono text-[#22D3EE] flex items-center gap-1 cursor-pointer hover:underline"
                style={{ background: 'none', border: 'none' }}
              >
                Simulate <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
              </button>
            </div>

            {predictions.length === 0 ? (
              <div className="text-center py-6">
                <Compass style={{ width: '1.5rem', height: '1.5rem', color: '#22D3EE', margin: '0 auto', opacity: 0.6 }} />
                <div className="text-xs text-secondary font-medium mt-2">No Active Trajectories Simulated</div>
                <p className="text-[11px] text-muted mt-1 max-w-xs mx-auto">
                  Run your first future simulation to map 24h, 3-day, and 7-day probabilistic outcomes.
                </p>
                <button
                  onClick={() => onNavigate('futures')}
                  className="btn-cyan text-[11px] mt-3 py-1.5 px-3"
                >
                  Run Simulation
                </button>
              </div>
            ) : (
              <div className="flex flex-col gap-2.5">
                {predictions.slice(0, 3).map((pred) => {
                  const isRisk = pred.prediction_type === 'RISK' || pred.probability >= 0.7;
                  const probPercent = Math.round(pred.probability * 100);
                  return (
                    <div
                      key={pred.id}
                      className="p-3 rounded-lg text-xs transition-colors"
                      style={{
                        backgroundColor: 'var(--bg-secondary)',
                        border: isRisk ? '1px solid rgba(251,113,133,0.3)' : '1px solid rgba(34,211,238,0.2)'
                      }}
                    >
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="font-semibold text-primary truncate pr-2">{pred.title}</span>
                        <span
                          className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full shrink-0"
                          style={{
                            backgroundColor: isRisk ? 'rgba(251,113,133,0.15)' : 'rgba(34,211,238,0.15)',
                            color: isRisk ? '#FB7185' : '#22D3EE',
                            border: `1px solid ${isRisk ? 'rgba(251,113,133,0.3)' : 'rgba(34,211,238,0.3)'}`
                          }}
                        >
                          {probPercent}% prob
                        </span>
                      </div>
                      <p className="text-muted text-[11px] m-0 line-clamp-2 leading-relaxed">
                        {pred.description}
                      </p>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* SECTION F: AUTONOMOUS AGENT ACTIVITY */}
          <div className="tess-card p-5">
            <div className="flex items-center justify-between mb-3.5 pb-2.5 border-b border-[rgba(255,255,255,0.06)]">
              <div className="flex items-center gap-2">
                <Bot style={{ width: '1rem', height: '1rem', color: '#A78BFA' }} />
                <span className="text-xs font-bold text-primary uppercase font-mono tracking-wider">
                  Agent Workflows & Safeguards
                </span>
              </div>
              <button
                onClick={() => onNavigate('agent')}
                className="text-xs font-mono text-[#A78BFA] flex items-center gap-1 cursor-pointer hover:underline"
                style={{ background: 'none', border: 'none' }}
              >
                Inspect <ArrowRight style={{ width: '0.75rem', height: '0.75rem' }} />
              </button>
            </div>

            {plans.length === 0 ? (
              <div className="text-center py-6">
                <Terminal style={{ width: '1.5rem', height: '1.5rem', color: 'var(--text-muted)', margin: '0 auto' }} />
                <div className="text-xs text-secondary font-medium mt-2">No Active Agent Plans</div>
                <p className="text-[11px] text-muted mt-1 max-w-xs mx-auto">
                  Trigger autonomous actions from Interventions or plan multi-step workflows with human confirmation safeguards.
                </p>
                <button
                  onClick={() => onNavigate('agent')}
                  className="btn-secondary text-[11px] mt-3 py-1.5 px-3"
                >
                  Create Plan
                </button>
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                {plans.slice(0, 2).map((p) => {
                  const isSuccess = p.status === 'SUCCESS';
                  return (
                    <div
                      key={p.id}
                      className="p-2.5 rounded-lg text-xs flex items-center justify-between"
                      style={{ backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border)' }}
                    >
                      <div className="truncate pr-2" style={{ maxWidth: '240px' }}>
                        <span className="font-semibold text-primary block truncate">{p.objective}</span>
                        <span className="text-[10px] font-mono text-muted">{p.steps?.length || 0} planned step(s)</span>
                      </div>
                      <span
                        className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-full"
                        style={{
                          backgroundColor: isSuccess ? 'rgba(52,211,153,0.15)' : 'rgba(251,191,36,0.15)',
                          color: isSuccess ? '#34D399' : '#FBBF24',
                          border: `1px solid ${isSuccess ? 'rgba(52,211,153,0.3)' : 'rgba(251,191,36,0.3)'}`
                        }}
                      >
                        {p.status}
                      </span>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
