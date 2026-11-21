import React, { useEffect, useState, useCallback, useRef } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useMascot } from '../contexts/MascotContext';
import { apiService } from '../services/api';
import {
  ProductivitySummary,
  ProductivityTask,
  FuturePrediction,
  InterventionResponse,
  AgentPlan
} from '../types';
import { ScreenTab } from '../components/Sidebar';
import { DashboardWelcome } from '../components/dashboard/DashboardWelcome';
import { ProductivityOverview } from '../components/dashboard/ProductivityOverview';
import { PriorityWorkspace } from '../components/dashboard/PriorityWorkspace';
import { ProductivityTrends } from '../components/dashboard/ProductivityTrends';
import { FutureTrajectoryPreview } from '../components/dashboard/FutureTrajectoryPreview';
import { InterventionPreview } from '../components/dashboard/InterventionPreview';
import { AgentActivityPreview } from '../components/dashboard/AgentActivityPreview';
import { DashboardQuickActions } from '../components/dashboard/DashboardQuickActions';
import { DashboardSkeleton } from '../components/dashboard/DashboardSkeleton';
import { DashboardErrorState } from '../components/dashboard/DashboardErrorState';

interface HomeScreenProps {
  onNavigate: (tab: ScreenTab) => void;
  onOpenCommandPalette?: () => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({
  onNavigate,
  onOpenCommandPalette
}) => {
  const { user } = useAuth();
  const { state: mascotState, setState: setMascotState } = useMascot();

  const [summary, setSummary] = useState<ProductivitySummary | null>(null);
  const [tasks, setTasks] = useState<ProductivityTask[]>([]);
  const [predictions, setPredictions] = useState<FuturePrediction[]>([]);
  const [interventions, setInterventions] = useState<InterventionResponse[]>([]);
  const [plans, setPlans] = useState<AgentPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastRefreshedAt, setLastRefreshedAt] = useState<string | null>(null);

  const isMountedRef = useRef(true);

  const loadHomeData = useCallback(async (isInitial: boolean = false) => {
    if (isInitial) {
      setLoading(true);
    }
    setError(null);
    setMascotState('THINKING');

    try {
      const [sumRes, taskRes, predRes, invRes, planRes] = await Promise.allSettled([
        apiService.getProductivitySummary(),
        apiService.getProductivityTasks(),
        apiService.getFuturePredictions(),
        apiService.getInterventions(),
        apiService.getAgentPlans()
      ]);

      if (!isMountedRef.current) return;

      let allFailed = true;

      if (sumRes.status === 'fulfilled') {
        setSummary(sumRes.value);
        allFailed = false;
      }
      if (taskRes.status === 'fulfilled') {
        setTasks(taskRes.value || []);
        allFailed = false;
      }
      if (predRes.status === 'fulfilled') {
        setPredictions(predRes.value || []);
        allFailed = false;
      }
      if (invRes.status === 'fulfilled') {
        setInterventions(invRes.value || []);
        allFailed = false;
      }
      if (planRes.status === 'fulfilled') {
        setPlans(planRes.value || []);
        allFailed = false;
      }

      if (allFailed) {
        setError('Unable to fetch telemetry from TESS AI backend. Verify service connectivity.');
        setMascotState('ERROR');
        return;
      }

      setLastRefreshedAt(new Date().toLocaleTimeString());

      // Contextual Companion behavior based on genuine system state
      const currentTasks = taskRes.status === 'fulfilled' ? taskRes.value || [] : [];
      const currentInvs = invRes.status === 'fulfilled' ? invRes.value || [] : [];
      const currentPreds = predRes.status === 'fulfilled' ? predRes.value || [] : [];

      const activeInvs = currentInvs.filter((i) => i.status === 'SENT');
      const overdueTasks = currentTasks.filter((t) => {
        if (!t.due_date || t.status === 'CLOSED') return false;
        return new Date(t.due_date) < new Date();
      });
      const highRiskPreds = currentPreds.filter(
        (p) => p.prediction_type === 'RISK' && p.probability >= 0.7
      );

      if (activeInvs.length > 0) {
        setMascotState('INTERVENING');
      } else if (overdueTasks.length > 0 || highRiskPreds.length > 0) {
        setMascotState('ATTENTION');
      } else {
        setMascotState('IDLE');
      }
    } catch (err: any) {
      if (isMountedRef.current) {
        setError(err?.message || 'Error communicating with TESS services.');
        setMascotState('ERROR');
      }
    } finally {
      if (isMountedRef.current) {
        setLoading(false);
      }
    }
  }, [setMascotState]);

  useEffect(() => {
    isMountedRef.current = true;
    loadHomeData(true);

    return () => {
      isMountedRef.current = false;
    };
  }, [loadHomeData]);

  if (loading) {
    return <DashboardSkeleton />;
  }

  if (error && !summary && tasks.length === 0 && predictions.length === 0) {
    return <DashboardErrorState onRetry={() => loadHomeData(true)} errorMessage={error} />;
  }

  const overdueCount = summary?.overdue ?? tasks.filter((t) => {
    if (!t.due_date || t.status === 'CLOSED') return false;
    return new Date(t.due_date) < new Date();
  }).length;

  const activeInvsCount = interventions.filter((i) => i.status === 'SENT').length;
  const hasRiskPreds = predictions.some((p) => p.prediction_type === 'RISK' && p.probability >= 0.65);

  return (
    <div
      className="flex-1 overflow-y-auto p-5 md:p-6 space-y-5"
      style={{ height: 'calc(100vh - 68px)', position: 'relative', zIndex: 1 }}
    >
      {/* SECTION A: WELCOME AND TESS CONTEXT */}
      <DashboardWelcome
        user={user}
        mascotState={mascotState}
        overdueCount={overdueCount}
        activeInterventionsCount={activeInvsCount}
        hasRiskPredictions={hasRiskPreds}
        onNavigate={onNavigate}
        onOpenCommandPalette={onOpenCommandPalette}
      />

      {/* SECTION B: PRODUCTIVITY OVERVIEW METRICS */}
      <ProductivityOverview
        summary={summary}
        tasks={tasks}
        onNavigate={onNavigate}
      />

      {/* SECTION H: QUICK ACTIONS BAR */}
      <DashboardQuickActions
        onNavigate={onNavigate}
        onRefreshData={() => loadHomeData(false)}
      />

      {/* MAIN INTELLIGENCE GRID: Balanced Multi-Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Left Column: Work & Velocity (7/12) */}
        <div className="lg:col-span-7 space-y-5 flex flex-col">
          {/* SECTION C: MY DAY / PRIORITY WORKSPACE */}
          <div className="flex-1">
            <PriorityWorkspace
              tasks={tasks}
              interventions={interventions}
              plans={plans}
              onNavigate={onNavigate}
            />
          </div>

          {/* SECTION D: PRODUCTIVITY TRENDS */}
          <div>
            <ProductivityTrends
              summary={summary}
              tasks={tasks}
            />
          </div>
        </div>

        {/* Right Column: Foresight, Proactivity & Agents (5/12) */}
        <div className="lg:col-span-5 space-y-5 flex flex-col">
          {/* SECTION E: FUTURE TRAJECTORY PREVIEW */}
          <div>
            <FutureTrajectoryPreview
              predictions={predictions}
              onNavigate={onNavigate}
            />
          </div>

          {/* SECTION F: PROACTIVE INTERVENTIONS PREVIEW */}
          <div>
            <InterventionPreview
              interventions={interventions}
              onNavigate={onNavigate}
            />
          </div>

          {/* SECTION G: AGENT ACTIVITY PREVIEW */}
          <div>
            <AgentActivityPreview
              plans={plans}
              onNavigate={onNavigate}
            />
          </div>
        </div>
      </div>

      {/* Footer System Telemetry Status */}
      {lastRefreshedAt && (
        <div className="pt-2 text-center text-[10px] font-mono text-muted/60">
          Command Centre synchronized with TESS AI Core • Last refreshed at {lastRefreshedAt}
        </div>
      )}
    </div>
  );
};
