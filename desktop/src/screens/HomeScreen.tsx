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
  Sparkles
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

      // Contextual mascot behavior based on data
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

  const dueSoonTasks = tasks.filter(t => {
    if (!t.due_date) return false;
    const diff = new Date(t.due_date).getTime() - Date.now();
    return diff > 0 && diff <= 3 * 24 * 60 * 60 * 1000;
  });

  const activeInterventions = interventions.filter(i => i.status === 'SENT');

  return (
    <div className="flex-1 overflow-y-auto p-6" style={{ height: 'calc(100vh - 64px)' }}>
      {/* Welcome & Mascot Banner */}
      <div
        className="tess-card flex items-center justify-between p-6"
        style={{
          background: 'linear-gradient(135deg, rgba(139, 92, 246, 0.12) 0%, rgba(21, 21, 34, 0.8) 100%)',
          borderColor: 'rgba(139, 92, 246, 0.3)'
        }}
      >
        <div>
          <div className="flex items-center gap-2 mb-2">
            <Sparkles style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
            <span className="text-xs font-semibold text-accent uppercase tracking-wider">
              Cross-Device Companion
            </span>
          </div>
          <h2 className="text-2xl font-bold" style={{ margin: 0, color: 'var(--text-primary)' }}>
            Welcome back{user?.email ? `, ${user.email.split('@')[0]}` : ''}
          </h2>
          <p className="text-sm mt-1" style={{ color: 'var(--text-secondary)' }}>
            TESS is actively monitoring your productivity, simulated futures, and agent workflows.
          </p>

          <div className="flex items-center gap-3 mt-4">
            <button onClick={() => onNavigate('chat')} className="btn-primary text-xs">
              Chat with TESS
            </button>
            <button onClick={() => onNavigate('tasks')} className="btn-secondary text-xs">
              View Tasks ({tasks.length})
            </button>
          </div>
        </div>

        <div className="flex flex-col items-center">
          <Mascot state={mascotState} size="lg" showLabel={true} />
        </div>
      </div>

      <div style={{ height: '1.5rem' }} />

      {/* Productivity Summary 4-Grid */}
      <div className="grid gap-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)' }}>
        <div className="tess-card">
          <div className="text-xs text-muted font-medium">TOTAL ACTIVE</div>
          <div className="text-2xl font-bold mt-1 text-primary">{summary?.total_active ?? 0}</div>
          <div className="text-xs text-secondary mt-1">Work packages</div>
        </div>
        <div className="tess-card">
          <div className="text-xs font-medium" style={{ color: 'var(--danger)' }}>OVERDUE</div>
          <div className="text-2xl font-bold mt-1" style={{ color: 'var(--danger)' }}>
            {summary?.overdue ?? overdueTasks.length}
          </div>
          <div className="text-xs text-secondary mt-1">Needs attention</div>
        </div>
        <div className="tess-card">
          <div className="text-xs font-medium" style={{ color: 'var(--warning)' }}>DUE TODAY</div>
          <div className="text-2xl font-bold mt-1" style={{ color: 'var(--warning)' }}>
            {summary?.due_today ?? 0}
          </div>
          <div className="text-xs text-secondary mt-1">Today's priority</div>
        </div>
        <div className="tess-card">
          <div className="text-xs font-medium" style={{ color: 'var(--success)' }}>RECENTLY COMPLETED</div>
          <div className="text-2xl font-bold mt-1" style={{ color: 'var(--success)' }}>
            {summary?.completed_recently ?? 0}
          </div>
          <div className="text-xs text-secondary mt-1">Last 7 days</div>
        </div>
      </div>

      <div style={{ height: '1.5rem' }} />

      {/* Main 2-Column Section */}
      <div style={{ display: 'grid', gridTemplateColumns: '1.1fr 0.9fr', gap: '1.5rem' }}>
        {/* Left Column: Tasks & Predictions */}
        <div className="flex flex-col gap-4">
          {/* Active Interventions Alert */}
          {activeInterventions.length > 0 && (
            <div
              className="tess-card"
              style={{
                borderColor: 'var(--warning)',
                backgroundColor: 'rgba(245, 158, 11, 0.08)'
              }}
            >
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <AlertTriangle style={{ width: '1.1rem', height: '1.1rem', color: 'var(--warning)' }} />
                  <span className="text-sm font-bold" style={{ color: 'var(--warning)' }}>
                    Proactive Intervention Required
                  </span>
                </div>
                <button
                  onClick={() => onNavigate('interventions')}
                  className="text-xs font-semibold flex items-center gap-1 cursor-pointer"
                  style={{ color: 'var(--warning)', background: 'none', border: 'none' }}
                >
                  Review <ArrowRight style={{ width: '0.8rem', height: '0.8rem' }} />
                </button>
              </div>
              <p className="text-xs text-secondary mb-2">{activeInterventions[0].message}</p>
              <div className="text-xs font-medium text-primary">
                Suggested action: {activeInterventions[0].suggested_action}
              </div>
            </div>
          )}

          {/* Important Tasks */}
          <div className="tess-card">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <CheckSquare style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
                <span className="text-sm font-bold text-primary">Important Tasks</span>
              </div>
              <button
                onClick={() => onNavigate('tasks')}
                className="text-xs text-accent flex items-center gap-1 cursor-pointer"
                style={{ background: 'none', border: 'none' }}
              >
                View all <ArrowRight style={{ width: '0.8rem', height: '0.8rem' }} />
              </button>
            </div>

            {tasks.length === 0 ? (
              <div className="text-xs text-muted py-4 text-center">
                No active tasks found. Sync OpenProject in Tasks tab.
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                {tasks.slice(0, 4).map((task) => (
                  <div
                    key={task.id}
                    className="flex items-center justify-between p-2 rounded-lg"
                    style={{ backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border)' }}
                  >
                    <div className="truncate" style={{ maxWidth: '280px' }}>
                      <div className="text-xs font-medium text-primary truncate">{task.title}</div>
                      <div className="text-[11px] text-muted">
                        {task.project || 'OpenProject'} • {task.status || 'Active'}
                      </div>
                    </div>
                    {task.due_date && (
                      <span className="text-[11px] text-muted flex items-center gap-1">
                        <Clock style={{ width: '0.75rem', height: '0.75rem' }} />
                        {task.due_date}
                      </span>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right Column: Future Predictions & Agent Workflows */}
        <div className="flex flex-col gap-4">
          {/* Future Trajectory */}
          <div className="tess-card">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <Compass style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
                <span className="text-sm font-bold text-primary">Future Engine Trajectory</span>
              </div>
              <button
                onClick={() => onNavigate('futures')}
                className="text-xs text-accent flex items-center gap-1 cursor-pointer"
                style={{ background: 'none', border: 'none' }}
              >
                Simulate <ArrowRight style={{ width: '0.8rem', height: '0.8rem' }} />
              </button>
            </div>

            {predictions.length === 0 ? (
              <div className="text-xs text-muted py-4 text-center">
                No future predictions yet. Run a simulation in Futures.
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                {predictions.slice(0, 3).map((pred) => (
                  <div
                    key={pred.id}
                    className="p-2.5 rounded-lg text-xs"
                    style={{
                      backgroundColor: 'var(--bg-secondary)',
                      border: '1px solid var(--border)'
                    }}
                  >
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-semibold text-primary">{pred.title}</span>
                      <span
                        className="text-[10px] font-bold px-1.5 py-0.5 rounded"
                        style={{
                          backgroundColor: pred.probability >= 0.7 ? '#EF444420' : '#10B98120',
                          color: pred.probability >= 0.7 ? '#EF4444' : '#10B981'
                        }}
                      >
                        {Math.round(pred.probability * 100)}% prob
                      </span>
                    </div>
                    <p className="text-muted text-[11px] m-0 line-clamp-2">{pred.description}</p>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Recent Agent Activity */}
          <div className="tess-card">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <Bot style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
                <span className="text-sm font-bold text-primary">Recent Agent Activity</span>
              </div>
              <button
                onClick={() => onNavigate('agent')}
                className="text-xs text-accent flex items-center gap-1 cursor-pointer"
                style={{ background: 'none', border: 'none' }}
              >
                View <ArrowRight style={{ width: '0.8rem', height: '0.8rem' }} />
              </button>
            </div>

            {plans.length === 0 ? (
              <div className="text-xs text-muted py-4 text-center">
                No agent plans created yet. Trigger an action from Interventions or Agent Activity.
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                {plans.slice(0, 2).map((p) => (
                  <div
                    key={p.id}
                    className="p-2 rounded-lg text-xs flex items-center justify-between"
                    style={{ backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border)' }}
                  >
                    <div className="truncate" style={{ maxWidth: '240px' }}>
                      <span className="font-medium text-primary block truncate">{p.objective}</span>
                      <span className="text-[10px] text-muted">{p.steps?.length || 0} step(s)</span>
                    </div>
                    <span
                      className="text-[10px] font-bold px-2 py-0.5 rounded-full"
                      style={{
                        backgroundColor: p.status === 'SUCCESS' ? '#10B98120' : '#F59E0B20',
                        color: p.status === 'SUCCESS' ? '#10B981' : '#F59E0B'
                      }}
                    >
                      {p.status}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

