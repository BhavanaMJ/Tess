import React, { useEffect, useState } from 'react';
import { apiService } from '../services/api';
import {
  FuturePrediction,
  SimulationResponse,
  BehavioralAnalysisResponse,
  LongTermForecastResponse,
  MultipleFuturesResponse,
  AccuracyMetricsResponse,
  InterventionEffectivenessResponse
} from '../types';
import { useMascot } from '../contexts/MascotContext';
import {
  Compass,
  TrendingUp,
  AlertTriangle,
  GitBranch,
  Calendar,
  Brain,
  Target,
  Sparkles,
  BarChart3,
  RefreshCw,
  Clock,
  ShieldAlert,
  ArrowRight,
  Bot,
  CheckCircle2,
  HelpCircle
} from 'lucide-react';

interface FuturesScreenProps {
  onNavigate?: (tab: any) => void;
}

type TabType = 'overview' | 'longterm' | 'multiple_futures' | 'behavioral' | 'accuracy';

export const FuturesScreen: React.FC<FuturesScreenProps> = ({ onNavigate }) => {
  const [activeTab, setActiveTab] = useState<TabType>('overview');

  // Overview / Short-Term State
  const [predictions, setPredictions] = useState<FuturePrediction[]>([]);
  const [simulation, setSimulation] = useState<SimulationResponse | null>(null);
  const [selectedHorizon, setSelectedHorizon] = useState<'24h' | '3d' | '7d'>('24h');
  const [loading, setLoading] = useState(false);
  const [simulating, setSimulating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Long-Term Forecast State
  const [longTermHorizon, setLongTermHorizon] = useState<'30d' | '90d' | '365d'>('30d');
  const [longTermForecast, setLongTermForecast] = useState<LongTermForecastResponse | null>(null);
  const [loadingLongTerm, setLoadingLongTerm] = useState(false);

  // Multiple Futures State
  const [futuresHorizon, setFuturesHorizon] = useState<'30d' | '90d' | '365d'>('30d');
  const [userGoal, setUserGoal] = useState('');
  const [multipleFutures, setMultipleFutures] = useState<MultipleFuturesResponse | null>(null);
  const [loadingFutures, setLoadingFutures] = useState(false);
  const [agentActionSuccess, setAgentActionSuccess] = useState<string | null>(null);

  // Behavioral Intelligence State
  const [behavioralWindow, setBehavioralWindow] = useState<number>(30);
  const [behavioralProfile, setBehavioralProfile] = useState<BehavioralAnalysisResponse | null>(null);
  const [loadingBehavioral, setLoadingBehavioral] = useState(false);

  // Accuracy & Effectiveness State
  const [accuracyMetrics, setAccuracyMetrics] = useState<AccuracyMetricsResponse | null>(null);
  const [effectivenessMetrics, setEffectivenessMetrics] = useState<InterventionEffectivenessResponse | null>(null);
  const [loadingAccuracy, setLoadingAccuracy] = useState(false);
  const [evaluating, setEvaluating] = useState(false);

  const { setState: setMascotState } = useMascot();

  // Load Short-term predictions and initial simulation
  const loadPredictions = async () => {
    try {
      setLoading(true);
      const preds = await apiService.getFuturePredictions();
      setPredictions(preds);
    } catch (e: any) {
      setError(e.message || 'Failed to load predictions');
    } finally {
      setLoading(false);
    }
  };

  const handleRunSimulation = async (horizon: '24h' | '3d' | '7d') => {
    setSelectedHorizon(horizon);
    setSimulating(true);
    setMascotState('PLANNING');
    setError(null);
    try {
      const sim = await apiService.simulateFuture(horizon);
      setSimulation(sim);
      setMascotState('IDLE');
    } catch (e: any) {
      setError(e.message || 'Simulation failed');
      setMascotState('ERROR');
    } finally {
      setSimulating(false);
    }
  };

  // Load Long-Term Forecast
  const handleLoadLongTermForecast = async (horizon: '30d' | '90d' | '365d') => {
    setLongTermHorizon(horizon);
    setLoadingLongTerm(true);
    setError(null);
    try {
      const forecast = await apiService.generateLongTermForecast(horizon);
      setLongTermForecast(forecast);
    } catch (e: any) {
      setError(e.message || 'Failed to generate long-term forecast');
    } finally {
      setLoadingLongTerm(false);
    }
  };

  // Load Multiple Futures
  const handleLoadMultipleFutures = async (horizon: '30d' | '90d' | '365d') => {
    setFuturesHorizon(horizon);
    setLoadingFutures(true);
    setError(null);
    try {
      const res = await apiService.generateMultipleFutures(horizon, userGoal.trim() || undefined);
      setMultipleFutures(res);
    } catch (e: any) {
      setError(e.message || 'Failed to generate multiple future scenarios');
    } finally {
      setLoadingFutures(false);
    }
  };

  // Load Behavioral Profile
  const handleLoadBehavioral = async (windowDays: number) => {
    setBehavioralWindow(windowDays);
    setLoadingBehavioral(true);
    setError(null);
    try {
      const profile = await apiService.getBehavioralProfile(windowDays);
      setBehavioralProfile(profile);
    } catch (e: any) {
      setError(e.message || 'Failed to fetch behavioral profile');
    } finally {
      setLoadingBehavioral(false);
    }
  };

  // Load Accuracy & Effectiveness
  const handleLoadAccuracy = async () => {
    setLoadingAccuracy(true);
    setError(null);
    try {
      const [acc, eff] = await Promise.allSettled([
        apiService.getPredictionAccuracy(),
        apiService.getInterventionEffectiveness()
      ]);
      if (acc.status === 'fulfilled') setAccuracyMetrics(acc.value);
      if (eff.status === 'fulfilled') setEffectivenessMetrics(eff.value);
    } catch (e: any) {
      setError(e.message || 'Failed to load accuracy metrics');
    } finally {
      setLoadingAccuracy(false);
    }
  };

  // Trigger Prediction Evaluation
  const handleEvaluatePredictions = async () => {
    setEvaluating(true);
    setError(null);
    try {
      const evaluations = await apiService.evaluatePredictions();
      await handleLoadAccuracy();
      setAgentActionSuccess(`Evaluated ${evaluations.length} mature predictions against observed task outcomes.`);
    } catch (e: any) {
      setError(e.message || 'Failed to evaluate predictions');
    } finally {
      setEvaluating(false);
    }
  };

  // Bridge Future Scenario to Phase 6 Agent Action
  const handleApplyTrajectoryWithAgent = async (scenario: any) => {
    setError(null);
    setAgentActionSuccess(null);
    try {
      setMascotState('PLANNING');
      const objective = `Execute strategic alignment plan: ${scenario.title}. Address: ${scenario.summary}`;
      const plan = await apiService.createAgentObjective(objective);
      setAgentActionSuccess(`Agent objective created: "${objective}". Plan ID: ${plan.id}`);
      setMascotState('SUCCESS');
      if (onNavigate) {
        setTimeout(() => onNavigate('agent'), 1200);
      }
    } catch (e: any) {
      setError(e.message || 'Failed to create agent objective');
      setMascotState('ERROR');
    }
  };

  useEffect(() => {
    loadPredictions();
    handleRunSimulation('24h');
  }, []);

  useEffect(() => {
    if (activeTab === 'longterm' && !longTermForecast) {
      handleLoadLongTermForecast(longTermHorizon);
    } else if (activeTab === 'multiple_futures' && !multipleFutures) {
      handleLoadMultipleFutures(futuresHorizon);
    } else if (activeTab === 'behavioral' && !behavioralProfile) {
      handleLoadBehavioral(behavioralWindow);
    } else if (activeTab === 'accuracy' && !accuracyMetrics) {
      handleLoadAccuracy();
    }
  }, [activeTab]);

  return (
    <div className="flex-1 overflow-y-auto p-6" style={{ height: 'calc(100vh - 64px)' }}>
      {/* Top Header & Tab Navigation Bar */}
      <div className="flex flex-col gap-4 mb-6">
        <div
          className="tess-card flex items-center justify-between p-4"
          style={{
            background: 'linear-gradient(135deg, rgba(139, 92, 246, 0.1) 0%, rgba(21, 21, 34, 0.95) 100%)',
            borderColor: 'rgba(139, 92, 246, 0.35)'
          }}
        >
          <div>
            <div className="flex items-center gap-2 mb-1">
              <Compass style={{ width: '1.2rem', height: '1.2rem', color: 'var(--accent)' }} />
              <span className="text-sm font-bold text-primary">TESS Future Intelligence System</span>
              <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-purple-900/40 text-purple-300 border border-purple-700/50">
                Phase 9
              </span>
            </div>
            <p className="text-xs text-secondary m-0">
              "Show me the most likely version of myself that I am currently creating."
            </p>
          </div>

          <div className="flex items-center gap-1.5 bg-[#12121A] p-1 rounded-xl border border-border">
            <button
              onClick={() => setActiveTab('overview')}
              className={`text-xs px-3 py-1.5 rounded-lg font-semibold flex items-center gap-1.5 transition-all ${
                activeTab === 'overview' ? 'btn-primary' : 'text-secondary hover:text-primary'
              }`}
            >
              <Calendar style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Short-Term</span>
            </button>
            <button
              onClick={() => setActiveTab('longterm')}
              className={`text-xs px-3 py-1.5 rounded-lg font-semibold flex items-center gap-1.5 transition-all ${
                activeTab === 'longterm' ? 'btn-primary' : 'text-secondary hover:text-primary'
              }`}
            >
              <Target style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Long-Term Forecast</span>
            </button>
            <button
              onClick={() => setActiveTab('multiple_futures')}
              className={`text-xs px-3 py-1.5 rounded-lg font-semibold flex items-center gap-1.5 transition-all ${
                activeTab === 'multiple_futures' ? 'btn-primary' : 'text-secondary hover:text-primary'
              }`}
            >
              <GitBranch style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Multiple Selves</span>
            </button>
            <button
              onClick={() => setActiveTab('behavioral')}
              className={`text-xs px-3 py-1.5 rounded-lg font-semibold flex items-center gap-1.5 transition-all ${
                activeTab === 'behavioral' ? 'btn-primary' : 'text-secondary hover:text-primary'
              }`}
            >
              <Brain style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Behavioral Intel</span>
            </button>
            <button
              onClick={() => setActiveTab('accuracy')}
              className={`text-xs px-3 py-1.5 rounded-lg font-semibold flex items-center gap-1.5 transition-all ${
                activeTab === 'accuracy' ? 'btn-primary' : 'text-secondary hover:text-primary'
              }`}
            >
              <BarChart3 style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Accuracy & Learning</span>
            </button>
          </div>
        </div>

        {/* Transparency & Probabilistic Guidance Banner */}
        <div className="p-3.5 rounded-xl bg-[rgba(169,154,217,0.08)] border border-[rgba(169,154,217,0.22)] flex items-start gap-3 text-xs text-secondary select-none">
          <Brain style={{ width: '1.15rem', height: '1.15rem', color: '#A78BFA', flexShrink: 0, marginTop: '2px' }} />
          <div className="leading-relaxed">
            <span className="font-semibold text-primary">Probabilistic Trajectory Engine: </span>
            <span>
              Simulations represent mathematical projections of your current velocity and task commitments, not certainties. Each scenario estimates likelihood and isolates key counterfactual levers to help you steer your trajectory.
            </span>
          </div>
        </div>

        {error && (
          <div
            className="p-3 rounded-lg text-xs flex items-center justify-between"
            style={{ backgroundColor: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', border: '1px solid var(--border)' }}
          >
            <span>{error}</span>
            <button onClick={() => setError(null)} className="text-secondary hover:text-primary font-bold">×</button>
          </div>
        )}

        {agentActionSuccess && (
          <div
            className="p-3 rounded-lg text-xs flex items-center justify-between"
            style={{ backgroundColor: 'rgba(16, 185, 129, 0.1)', color: 'var(--success)', border: '1px solid rgba(16, 185, 129, 0.3)' }}
          >
            <span className="flex items-center gap-2">
              <CheckCircle2 style={{ width: '1rem', height: '1rem' }} />
              {agentActionSuccess}
            </span>
            <button onClick={() => setAgentActionSuccess(null)} className="text-secondary hover:text-primary font-bold">×</button>
          </div>
        )}
      </div>

      {/* ========================================================================= */}
      {/* TAB 1: OVERVIEW & SHORT-TERM SIMULATION (24h / 3d / 7d)                    */}
      {/* ========================================================================= */}
      {activeTab === 'overview' && (
        <div className="flex flex-col gap-6">
          <div className="flex items-center justify-between mb-1">
            <span className="text-xs text-secondary font-medium">
              Immediate horizons based on recent work velocity and open tasks:
            </span>
            <div className="flex items-center gap-2">
              {(['24h', '3d', '7d'] as const).map((hz) => (
                <button
                  key={hz}
                  onClick={() => handleRunSimulation(hz)}
                  disabled={simulating}
                  className={`text-xs px-3 py-1 rounded-lg font-semibold flex items-center gap-1 cursor-pointer transition-all ${
                    selectedHorizon === hz ? 'btn-primary' : 'btn-secondary'
                  }`}
                >
                  <Calendar style={{ width: '0.75rem', height: '0.75rem' }} />
                  <span>{hz === '24h' ? 'Next 24h' : hz === '3d' ? '3 Days' : '7 Days'}</span>
                </button>
              ))}
            </div>
          </div>

          {simulating ? (
            <div className="tess-card text-center py-12 text-sm text-muted">
              <Compass style={{ width: '2rem', height: '2rem', margin: '0 auto 0.5rem', color: 'var(--accent)' }} />
              Simulating probable trajectory for horizon {selectedHorizon}...
            </div>
          ) : simulation ? (
            <div className="flex flex-col gap-6">
              {/* Main Scenario */}
              <div className="tess-card p-5" style={{ borderColor: 'var(--accent)' }}>
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <span className="text-[11px] font-bold text-accent uppercase tracking-wider">
                      Probable Trajectory ({simulation.horizon})
                    </span>
                    <h3 className="text-lg font-bold text-primary mt-1 mb-0">
                      {simulation.scenario.title}
                    </h3>
                  </div>
                </div>

                <p className="text-xs text-secondary mb-4 leading-relaxed">
                  {simulation.scenario.summary}
                </p>

                {/* Timeline Events */}
                <div className="flex flex-col gap-2 mt-4 pt-4 border-t" style={{ borderColor: 'var(--border)' }}>
                  <div className="text-xs font-semibold text-muted mb-1">PROJECTED TIMELINE:</div>
                  {simulation.scenario.events?.map((ev, i) => (
                    <div
                      key={i}
                      className="flex items-start gap-3 p-2.5 rounded-lg"
                      style={{ backgroundColor: 'var(--bg-secondary)' }}
                    >
                      <span className="font-mono text-[11px] font-bold text-accent min-w-[70px]">
                        {ev.relative_time}
                      </span>
                      <div>
                        <div className="text-xs font-semibold text-primary">{ev.title}</div>
                        <div className="text-[11px] text-muted mt-0.5">{ev.description}</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Alternative Scenario / Counterfactual */}
              {simulation.alternative && (
                <div
                  className="tess-card p-5"
                  style={{
                    borderColor: 'var(--success)',
                    backgroundColor: 'rgba(16, 185, 129, 0.04)'
                  }}
                >
                  <div className="flex items-center gap-2 mb-2">
                    <GitBranch style={{ width: '1.1rem', height: '1.1rem', color: 'var(--success)' }} />
                    <span className="text-xs font-bold" style={{ color: 'var(--success)' }}>
                      Alternative Scenario (One Recommended Change)
                    </span>
                  </div>
                  <div className="text-sm font-semibold text-primary mb-1">
                    Action: {simulation.alternative.action}
                  </div>
                  <p className="text-xs text-secondary m-0">
                    Expected outcome: {simulation.alternative.expected_effect}
                  </p>
                  <div className="mt-3 pt-3 border-t border-[rgba(255,255,255,0.06)] flex items-center justify-between">
                    <span className="text-[11px] font-mono text-muted">Counterfactual Delta: High-leverage behavioral adjustment</span>
                    {onNavigate && (
                      <button
                        type="button"
                        onClick={() => onNavigate('chat')}
                        className="btn-primary text-xs py-1.5 px-3 flex items-center gap-1.5"
                        title="Discuss trajectory in Companion Chat"
                      >
                        <Bot style={{ width: '0.85rem', height: '0.85rem' }} />
                        <span>Discuss with TESS</span>
                      </button>
                    )}
                  </div>
                </div>
              )}
            </div>
          ) : null}

          {/* Active Model Predictions */}
          <div>
            <h4 className="text-sm font-bold text-primary mb-3 flex items-center gap-2">
              <TrendingUp style={{ width: '1rem', height: '1rem', color: 'var(--accent)' }} />
              Active Model Predictions
            </h4>

            {predictions.length === 0 ? (
              <div className="tess-card text-center py-6 text-xs text-muted">
                No active individual signals or pattern predictions.
              </div>
            ) : (
              <div className="grid gap-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)' }}>
                {predictions.map((p) => {
                  const isRisk = p.prediction_type === 'RISK';
                  return (
                    <div key={p.id} className="tess-card p-4">
                      <div className="flex items-center justify-between mb-2">
                        <span
                          className="text-xs font-semibold flex items-center gap-1.5"
                          style={{ color: isRisk ? 'var(--danger)' : 'var(--success)' }}
                        >
                          {isRisk && <AlertTriangle style={{ width: '0.85rem', height: '0.85rem' }} />}
                          {p.title}
                        </span>
                        <span
                          className="text-[10px] font-bold px-2 py-0.5 rounded-full"
                          style={{
                            backgroundColor: isRisk ? '#EF444420' : '#10B98120',
                            color: isRisk ? 'var(--danger)' : 'var(--success)'
                          }}
                        >
                          {Math.round(p.probability * 100)}% ({p.confidence})
                        </span>
                      </div>
                      <p className="text-xs text-secondary mb-3 leading-relaxed">{p.description}</p>
                      {p.evidence && p.evidence.length > 0 && (
                        <div className="text-[11px] text-muted">
                          Evidence: {p.evidence.join(', ')}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 2: LONG-TERM FORECASTING (30d / 90d / 365d)                           */}
      {/* ========================================================================= */}
      {activeTab === 'longterm' && (
        <div className="flex flex-col gap-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-bold text-primary m-0 flex items-center gap-2">
                <Target style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
                Long-Term Asymptotic Projections
              </h3>
              <p className="text-xs text-secondary mt-1 mb-0">
                Non-linear modeling incorporating velocity saturation, inflow momentum, and burnout risk.
              </p>
            </div>
            <div className="flex items-center gap-2">
              {(['30d', '90d', '365d'] as const).map((hz) => (
                <button
                  key={hz}
                  onClick={() => handleLoadLongTermForecast(hz)}
                  disabled={loadingLongTerm}
                  className={`text-xs px-3 py-1.5 rounded-lg font-semibold transition-all ${
                    longTermHorizon === hz ? 'btn-primary' : 'btn-secondary'
                  }`}
                >
                  {hz === '30d' ? '30 Days' : hz === '90d' ? '90 Days' : '1 Year (365d)'}
                </button>
              ))}
            </div>
          </div>

          {loadingLongTerm ? (
            <div className="tess-card text-center py-16 text-sm text-muted">
              <RefreshCw className="animate-spin" style={{ width: '2rem', height: '2rem', margin: '0 auto 0.5rem', color: 'var(--accent)' }} />
              Synthesizing long-term asymptotic forecast for {longTermHorizon}...
            </div>
          ) : longTermForecast ? (
            <div className="flex flex-col gap-6">
              {/* Metric Highlights Grid */}
              <div className="grid grid-cols-4 gap-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)' }}>
                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Projected Active Backlog</span>
                  <div className="text-2xl font-bold text-primary mt-1">
                    {longTermForecast.projected_backlog}
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    Uncertainty: [{longTermForecast.uncertainty_range?.backlog_min ?? 0} – {longTermForecast.uncertainty_range?.backlog_max ?? 0}]
                  </div>
                </div>

                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Expected Completions</span>
                  <div className="text-2xl font-bold text-accent mt-1">
                    {longTermForecast.completion_forecast}
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    Range: [{longTermForecast.uncertainty_range?.completion_min ?? 0} – {longTermForecast.uncertainty_range?.completion_max ?? 0}]
                  </div>
                </div>

                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Burnout / Overload Risk</span>
                  <div
                    className="text-2xl font-bold mt-1"
                    style={{
                      color:
                        longTermForecast.burnout_risk_score > 0.6
                          ? 'var(--danger)'
                          : longTermForecast.burnout_risk_score > 0.35
                          ? '#F59E0B'
                          : 'var(--success)'
                    }}
                  >
                    {Math.round(longTermForecast.burnout_risk_score * 100)}%
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    {longTermForecast.burnout_risk_score > 0.6 ? 'High exhaustion risk' : 'Manageable workload'}
                  </div>
                </div>

                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Forecast Confidence</span>
                  <div className="text-2xl font-bold text-primary mt-1">
                    {Math.round(longTermForecast.probability * 100)}%
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    Confidence Tier: <span className="font-semibold text-primary">{longTermForecast.confidence}</span>
                  </div>
                </div>
              </div>

              {/* Explainable Narrative Card */}
              <div className="tess-card p-5" style={{ borderColor: 'rgba(139, 92, 246, 0.4)' }}>
                <h4 className="text-sm font-bold text-primary mb-2 flex items-center gap-2">
                  <Sparkles style={{ width: '1rem', height: '1rem', color: 'var(--accent)' }} />
                  Forecast Narrative & Strategic Trajectory
                </h4>
                <p className="text-xs text-secondary leading-relaxed m-0">
                  {longTermForecast.explanation}
                </p>
              </div>

              {/* Assumptions & Evidence Columns */}
              <div className="grid grid-cols-2 gap-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)' }}>
                <div className="tess-card p-4">
                  <span className="text-xs font-bold text-primary mb-2 block flex items-center gap-1.5">
                    <Clock style={{ width: '0.9rem', height: '0.9rem', color: 'var(--accent)' }} />
                    Model Assumptions ({longTermForecast.horizon})
                  </span>
                  <ul className="text-xs text-secondary space-y-1.5 pl-4 m-0 list-disc">
                    {longTermForecast.assumptions?.map((asm, i) => (
                      <li key={i}>{asm}</li>
                    ))}
                  </ul>
                </div>

                <div className="tess-card p-4">
                  <span className="text-xs font-bold text-primary mb-2 block flex items-center gap-1.5">
                    <ShieldAlert style={{ width: '0.9rem', height: '0.9rem', color: '#10B981' }} />
                    Observed Historical Evidence
                  </span>
                  <ul className="text-xs text-secondary space-y-1.5 pl-4 m-0 list-disc">
                    {longTermForecast.evidence?.map((ev, i) => (
                      <li key={i}>{ev}</li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>
          ) : (
            <div className="tess-card text-center py-8 text-xs text-muted">
              Select a horizon above to generate a long-term forecast.
            </div>
          )}
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 3: MULTIPLE FUTURE SELVES (Current vs Improved vs Alternative)        */}
      {/* ========================================================================= */}
      {activeTab === 'multiple_futures' && (
        <div className="flex flex-col gap-6">
          <div className="tess-card p-4 flex flex-col md:flex-row items-center justify-between gap-4">
            <div>
              <h3 className="text-sm font-bold text-primary m-0 flex items-center gap-2">
                <GitBranch style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
                Multiple Future Trajectories
              </h3>
              <p className="text-xs text-secondary mt-1 mb-0">
                Explore divergent paths: your autopilot projection vs high-leverage behavioral interventions.
              </p>
            </div>

            <div className="flex items-center gap-3 w-full md:w-auto">
              <input
                type="text"
                placeholder="Optional goal (e.g. Finish sprint without tech debt)..."
                value={userGoal}
                onChange={(e) => setUserGoal(e.target.value)}
                className="input-field text-xs py-1.5 px-3 min-w-[280px]"
              />
              <div className="flex items-center gap-1.5">
                {(['30d', '90d', '365d'] as const).map((hz) => (
                  <button
                    key={hz}
                    onClick={() => handleLoadMultipleFutures(hz)}
                    disabled={loadingFutures}
                    className={`text-xs px-2.5 py-1.5 rounded-lg font-semibold transition-all ${
                      futuresHorizon === hz ? 'btn-primary' : 'btn-secondary'
                    }`}
                  >
                    {hz}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {loadingFutures ? (
            <div className="tess-card text-center py-16 text-sm text-muted">
              <RefreshCw className="animate-spin" style={{ width: '2rem', height: '2rem', margin: '0 auto 0.5rem', color: 'var(--accent)' }} />
              Simulating multiple future selves across {futuresHorizon} horizon...
            </div>
          ) : multipleFutures ? (
            <div className="grid grid-cols-3 gap-5" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)' }}>
              {/* 1. CURRENT TRAJECTORY (AUTOPILOT) */}
              <div
                className="tess-card p-5 flex flex-col justify-between"
                style={{
                  borderColor: 'rgba(239, 68, 68, 0.4)',
                  backgroundColor: 'rgba(239, 68, 68, 0.02)'
                }}
              >
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-red-900/30 text-red-400 border border-red-700/40 uppercase">
                      Current Trajectory (Autopilot)
                    </span>
                    <span className="text-xs font-mono text-muted">{multipleFutures.horizon}</span>
                  </div>
                  <h4 className="text-sm font-bold text-primary mt-2 mb-1">
                    {multipleFutures.current_trajectory.title}
                  </h4>
                  <p className="text-xs text-secondary mb-4 leading-relaxed">
                    {multipleFutures.current_trajectory.summary}
                  </p>

                  <div className="border-t border-border pt-3">
                    <span className="text-[11px] font-semibold text-muted block mb-2">PROJECTED MILESTONES:</span>
                    <div className="space-y-2">
                      {multipleFutures.current_trajectory.events?.map((ev, i) => (
                        <div key={i} className="text-xs bg-bg-secondary p-2 rounded">
                          <span className="font-mono text-[10px] text-red-400 font-bold block">{ev.relative_time}</span>
                          <span className="font-semibold text-primary">{ev.title}</span>
                          <p className="text-[11px] text-muted m-0 mt-0.5">{ev.description}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="mt-4 pt-3 border-t border-border text-[11px] text-muted">
                  Status quo behavior without systemic workload intervention.
                </div>
              </div>

              {/* 2. IMPROVED TRAJECTORY (RECOMMENDED) */}
              <div
                className="tess-card p-5 flex flex-col justify-between"
                style={{
                  borderColor: 'var(--accent)',
                  backgroundColor: 'rgba(139, 92, 246, 0.04)',
                  boxShadow: '0 0 20px rgba(139, 92, 246, 0.15)'
                }}
              >
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-purple-900/40 text-purple-300 border border-purple-600/50 uppercase flex items-center gap-1">
                      <Sparkles style={{ width: '0.7rem', height: '0.7rem' }} /> Recommended Future
                    </span>
                    <span className="text-xs font-mono text-accent">{multipleFutures.horizon}</span>
                  </div>
                  <h4 className="text-sm font-bold text-primary mt-2 mb-1">
                    {multipleFutures.improved_trajectory.title}
                  </h4>
                  <p className="text-xs text-secondary mb-4 leading-relaxed">
                    {multipleFutures.improved_trajectory.summary}
                  </p>

                  <div className="border-t border-border pt-3">
                    <span className="text-[11px] font-semibold text-muted block mb-2">TARGET MILESTONES:</span>
                    <div className="space-y-2">
                      {multipleFutures.improved_trajectory.events?.map((ev, i) => (
                        <div key={i} className="text-xs bg-bg-secondary p-2 rounded border border-purple-900/20">
                          <span className="font-mono text-[10px] text-purple-400 font-bold block">{ev.relative_time}</span>
                          <span className="font-semibold text-primary">{ev.title}</span>
                          <p className="text-[11px] text-muted m-0 mt-0.5">{ev.description}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="mt-4 pt-4 border-t border-border">
                  <button
                    onClick={() => handleApplyTrajectoryWithAgent(multipleFutures.improved_trajectory)}
                    className="w-full btn-primary text-xs py-2 px-3 rounded-lg flex items-center justify-center gap-1.5 cursor-pointer font-bold"
                  >
                    <Bot style={{ width: '0.9rem', height: '0.9rem' }} />
                    Act on This Path with Agent
                    <ArrowRight style={{ width: '0.85rem', height: '0.85rem' }} />
                  </button>
                </div>
              </div>

              {/* 3. ALTERNATIVE TRAJECTORY (COUNTERFACTUAL) */}
              <div
                className="tess-card p-5 flex flex-col justify-between"
                style={{
                  borderColor: 'rgba(6, 182, 212, 0.4)',
                  backgroundColor: 'rgba(6, 182, 212, 0.02)'
                }}
              >
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-cyan-900/30 text-cyan-400 border border-cyan-700/40 uppercase">
                      Alternative Shift
                    </span>
                    <span className="text-xs font-mono text-muted">{multipleFutures.horizon}</span>
                  </div>
                  <h4 className="text-sm font-bold text-primary mt-2 mb-1">
                    {multipleFutures.alternative_trajectory.title}
                  </h4>
                  <p className="text-xs text-secondary mb-4 leading-relaxed">
                    {multipleFutures.alternative_trajectory.summary}
                  </p>

                  <div className="border-t border-border pt-3">
                    <span className="text-[11px] font-semibold text-muted block mb-2">CONDITIONAL MILESTONES:</span>
                    <div className="space-y-2">
                      {multipleFutures.alternative_trajectory.events?.map((ev, i) => (
                        <div key={i} className="text-xs bg-bg-secondary p-2 rounded">
                          <span className="font-mono text-[10px] text-cyan-400 font-bold block">{ev.relative_time}</span>
                          <span className="font-semibold text-primary">{ev.title}</span>
                          <p className="text-[11px] text-muted m-0 mt-0.5">{ev.description}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="mt-4 pt-3 border-t border-border text-[11px] text-muted">
                  Contingent model under altered task constraints or external resourcing.
                </div>
              </div>
            </div>
          ) : (
            <div className="tess-card text-center py-8 text-xs text-muted">
              Select horizon or enter a goal to generate multiple trajectories.
            </div>
          )}
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 4: BEHAVIORAL INTELLIGENCE & PATTERNS                                 */}
      {/* ========================================================================= */}
      {activeTab === 'behavioral' && (
        <div className="flex flex-col gap-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-bold text-primary m-0 flex items-center gap-2">
                <Brain style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
                Personal Behavioral Intelligence
              </h3>
              <p className="text-xs text-secondary mt-1 mb-0">
                Data-driven behavioral features extracted from historical task events and interactions.
              </p>
            </div>

            <div className="flex items-center gap-2">
              <span className="text-xs text-muted">Window:</span>
              {[7, 14, 30, 60, 90].map((days) => (
                <button
                  key={days}
                  onClick={() => handleLoadBehavioral(days)}
                  disabled={loadingBehavioral}
                  className={`text-xs px-2.5 py-1 rounded-lg font-semibold transition-all ${
                    behavioralWindow === days ? 'btn-primary' : 'btn-secondary'
                  }`}
                >
                  {days}d
                </button>
              ))}
            </div>
          </div>

          {loadingBehavioral ? (
            <div className="tess-card text-center py-16 text-sm text-muted">
              <RefreshCw className="animate-spin" style={{ width: '2rem', height: '2rem', margin: '0 auto 0.5rem', color: 'var(--accent)' }} />
              Extracting behavioral dimensions over {behavioralWindow}-day window...
            </div>
          ) : behavioralProfile ? (
            <div className="flex flex-col gap-6">
              {/* Quality & Metrics Header */}
              <div className="tess-card p-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="text-xs font-semibold text-secondary">Data Quality Tier:</span>
                  <span
                    className="text-xs font-bold px-2.5 py-0.5 rounded-full"
                    style={{
                      backgroundColor:
                        behavioralProfile.data_quality === 'GOOD'
                          ? 'rgba(16, 185, 129, 0.15)'
                          : behavioralProfile.data_quality === 'PRELIMINARY'
                          ? 'rgba(245, 158, 11, 0.15)'
                          : 'rgba(239, 68, 68, 0.15)',
                      color:
                        behavioralProfile.data_quality === 'GOOD'
                          ? 'var(--success)'
                          : behavioralProfile.data_quality === 'PRELIMINARY'
                          ? '#F59E0B'
                          : 'var(--danger)',
                      border: '1px solid var(--border)'
                    }}
                  >
                    {behavioralProfile.data_quality}
                  </span>
                  <span className="text-xs text-muted">
                    {behavioralProfile.data_quality === 'INSUFFICIENT'
                      ? '(Cold-start mode: generalizations applied until more activity is logged)'
                      : behavioralProfile.data_quality === 'PRELIMINARY'
                      ? '(Initial patterns observed; baseline tightening)'
                      : '(Robust dataset with high predictive validity)'}
                  </span>
                </div>

                <span className="text-xs text-muted font-mono">
                  {new Date(behavioralProfile.period_start).toLocaleDateString()} – {new Date(behavioralProfile.period_end).toLocaleDateString()}
                </span>
              </div>

              {/* Behavioral Dimensions Cards */}
              <div className="grid grid-cols-4 gap-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)' }}>
                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Task Completion Rate</span>
                  <div className="text-2xl font-bold text-primary mt-1">
                    {Math.round((behavioralProfile.metrics?.completion_rate ?? 0) * 100)}%
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    {behavioralProfile.metrics?.completed_tasks ?? 0} of {behavioralProfile.metrics?.total_tasks ?? 0} tasks finished
                  </div>
                </div>

                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Overdue Rate</span>
                  <div className="text-2xl font-bold text-accent mt-1">
                    {Math.round((behavioralProfile.metrics?.overdue_rate ?? 0) * 100)}%
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    {behavioralProfile.metrics?.overdue_tasks ?? 0} tasks past deadline
                  </div>
                </div>

                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Inflow Momentum</span>
                  <div className="text-2xl font-bold text-primary mt-1">
                    {((behavioralProfile.metrics?.inflow_rate_per_day ?? 0) as number).toFixed(2)}/d
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    vs Completion: {((behavioralProfile.metrics?.completion_velocity_per_day ?? 0) as number).toFixed(2)}/d
                  </div>
                </div>

                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Intervention Responsiveness</span>
                  <div className="text-2xl font-bold text-primary mt-1">
                    {Math.round((behavioralProfile.metrics?.intervention_acceptance_rate ?? 0) * 100)}%
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    {behavioralProfile.metrics?.total_interventions ?? 0} interventions evaluated
                  </div>
                </div>
              </div>

              {/* Detailed Insights List */}
              <div>
                <h4 className="text-sm font-bold text-primary mb-3">Evidence-Backed Behavioral Insights</h4>
                <div className="grid grid-cols-2 gap-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)' }}>
                  {behavioralProfile.insights?.map((ins, i) => (
                    <div key={i} className="tess-card p-4">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs font-bold text-primary">{ins.headline}</span>
                        <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-bg-secondary text-secondary">
                          {ins.category}
                        </span>
                      </div>
                      <p className="text-xs text-secondary mb-3 leading-relaxed">{ins.observation}</p>
                      {ins.evidence && ins.evidence.length > 0 && (
                        <div className="text-[11px] text-muted pt-2 border-t border-border">
                          <span className="font-semibold">Evidence:</span> {ins.evidence.join(' • ')}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            <div className="tess-card text-center py-8 text-xs text-muted">
              No behavioral snapshot found for selected window.
            </div>
          )}
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 5: PREDICTION ACCURACY & CONTINUOUS LEARNING                           */}
      {/* ========================================================================= */}
      {activeTab === 'accuracy' && (
        <div className="flex flex-col gap-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-bold text-primary m-0 flex items-center gap-2">
                <BarChart3 style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
                Prediction Accuracy & Evaluator
              </h3>
              <p className="text-xs text-secondary mt-1 mb-0">
                Empirical evaluation comparing forecasted outcomes against actual historical reality.
              </p>
            </div>

            <button
              onClick={handleEvaluatePredictions}
              disabled={evaluating}
              className="btn-primary text-xs py-1.5 px-3 rounded-lg flex items-center gap-1.5 font-bold cursor-pointer"
            >
              <RefreshCw className={evaluating ? 'animate-spin' : ''} style={{ width: '0.85rem', height: '0.85rem' }} />
              {evaluating ? 'Evaluating...' : 'Evaluate Due Predictions'}
            </button>
          </div>

          {loadingAccuracy ? (
            <div className="tess-card text-center py-16 text-sm text-muted">
              <RefreshCw className="animate-spin" style={{ width: '2rem', height: '2rem', margin: '0 auto 0.5rem', color: 'var(--accent)' }} />
              Loading calibration metrics and evaluation history...
            </div>
          ) : (
            <div className="flex flex-col gap-6">
              {/* Calibration & Accuracy Overview */}
              <div className="grid grid-cols-4 gap-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)' }}>
                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Brier Calibration Score</span>
                  <div className="text-2xl font-bold text-accent mt-1">
                    {(accuracyMetrics?.brier_calibration_score ?? 0).toFixed(3)}
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    Ideal: 0.00 (probabilistic calibration)
                  </div>
                </div>

                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Overall Accuracy</span>
                  <div className="text-2xl font-bold text-primary mt-1">
                    {Math.round((accuracyMetrics?.overall_accuracy ?? 0) * 100)}%
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    {accuracyMetrics?.total_evaluated ?? 0} mature predictions evaluated
                  </div>
                </div>

                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Intervention Acceptance</span>
                  <div className="text-2xl font-bold text-primary mt-1">
                    {Math.round((effectivenessMetrics?.acceptance_rate ?? 0) * 100)}%
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    {effectivenessMetrics?.accepted_count ?? 0} accepted / {effectivenessMetrics?.total_interventions ?? 0} total
                  </div>
                </div>

                <div className="tess-card p-4">
                  <span className="text-[11px] text-secondary font-medium">Action Conversion Rate</span>
                  <div className="text-2xl font-bold text-success mt-1">
                    {Math.round((effectivenessMetrics?.action_conversion_rate ?? 0) * 100)}%
                  </div>
                  <div className="text-[11px] text-muted mt-1">
                    {effectivenessMetrics?.actions_completed_count ?? 0} interventions triggered action
                  </div>
                </div>
              </div>

              {/* Accuracy By Horizon and Type */}
              <div className="grid grid-cols-2 gap-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)' }}>
                <div className="tess-card p-4">
                  <h4 className="text-xs font-bold text-primary mb-3">Accuracy by Time Horizon</h4>
                  <div className="space-y-2">
                    {Object.entries(accuracyMetrics?.accuracy_by_horizon || {}).map(([hz, acc]) => (
                      <div key={hz} className="flex items-center justify-between text-xs">
                        <span className="font-mono text-secondary">{hz}</span>
                        <div className="flex items-center gap-2">
                          <div className="w-24 bg-bg-secondary h-2 rounded-full overflow-hidden">
                            <div
                              className="h-full bg-accent"
                              style={{ width: `${Math.round(acc * 100)}%` }}
                            />
                          </div>
                          <span className="font-bold text-primary w-10 text-right">{Math.round(acc * 100)}%</span>
                        </div>
                      </div>
                    ))}
                    {Object.keys(accuracyMetrics?.accuracy_by_horizon || {}).length === 0 && (
                      <span className="text-xs text-muted">No horizon breakdown available yet.</span>
                    )}
                  </div>
                </div>

                <div className="tess-card p-4">
                  <h4 className="text-xs font-bold text-primary mb-3">Accuracy by Prediction Type</h4>
                  <div className="space-y-2">
                    {Object.entries(accuracyMetrics?.accuracy_by_type || {}).map(([tp, acc]) => (
                      <div key={tp} className="flex items-center justify-between text-xs">
                        <span className="text-secondary">{tp}</span>
                        <div className="flex items-center gap-2">
                          <div className="w-24 bg-bg-secondary h-2 rounded-full overflow-hidden">
                            <div
                              className="h-full bg-purple-500"
                              style={{ width: `${Math.round(acc * 100)}%` }}
                            />
                          </div>
                          <span className="font-bold text-primary w-10 text-right">{Math.round(acc * 100)}%</span>
                        </div>
                      </div>
                    ))}
                    {Object.keys(accuracyMetrics?.accuracy_by_type || {}).length === 0 && (
                      <span className="text-xs text-muted">No type breakdown available yet.</span>
                    )}
                  </div>
                </div>
              </div>

              {/* Recent Evaluated Predictions List */}
              <div className="tess-card p-4">
                <h4 className="text-xs font-bold text-primary mb-3">Recent Prediction Outcome Evaluations</h4>
                {(!accuracyMetrics?.recent_evaluations || accuracyMetrics.recent_evaluations.length === 0) ? (
                  <div className="text-xs text-muted py-4 text-center">
                    No evaluated predictions yet. Predictions are evaluated once their forecast horizon elapses.
                  </div>
                ) : (
                  <div className="space-y-2">
                    {accuracyMetrics.recent_evaluations.map((ev) => (
                      <div key={ev.id} className="p-3 bg-bg-secondary rounded-lg flex items-center justify-between text-xs">
                        <div>
                          <div className="flex items-center gap-2 mb-1">
                            <span
                              className="text-[10px] font-bold px-2 py-0.5 rounded-full"
                              style={{
                                backgroundColor:
                                  ev.status === 'CONFIRMED'
                                    ? 'rgba(16, 185, 129, 0.15)'
                                    : ev.status === 'NOT_CONFIRMED'
                                    ? 'rgba(239, 68, 68, 0.15)'
                                    : 'rgba(139, 92, 246, 0.15)',
                                color:
                                  ev.status === 'CONFIRMED'
                                    ? 'var(--success)'
                                    : ev.status === 'NOT_CONFIRMED'
                                    ? 'var(--danger)'
                                    : 'var(--accent)'
                              }}
                            >
                              {ev.status}
                            </span>
                            <span className="font-mono text-muted text-[11px]">{ev.horizon}</span>
                          </div>
                          <div className="text-secondary">
                            <span className="font-semibold text-primary">Predicted:</span> {ev.predicted_outcome}
                          </div>
                          <div className="text-muted text-[11px] mt-0.5">
                            <span className="font-semibold text-secondary">Observed:</span> {ev.actual_outcome}
                          </div>
                        </div>

                        {ev.brier_score !== null && ev.brier_score !== undefined && (
                          <div className="text-right">
                            <span className="text-[10px] text-muted block">Brier Error</span>
                            <span className="font-mono text-xs font-bold text-accent">
                              {ev.brier_score.toFixed(3)}
                            </span>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
