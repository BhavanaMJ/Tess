import React, { useEffect, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useMascot, THEME_COLORS } from '../contexts/MascotContext';
import {
  getNotificationSettings,
  saveNotificationSettings
} from '../services/notifications';
import { apiService } from '../services/api';
import {
  NotificationSettings,
  UserDevice,
  CompanionPreferences,
  CompanionRoutine,
  CompanionMilestone,
  CompanionActivity
} from '../types';
import {
  Settings,
  Bell,
  Eye,
  Smartphone,
  Info,
  LogOut,
  Laptop,
  Sparkles,
  Heart,
  Clock,
  Volume2,
  VolumeX,
  Plus,
  Trash2,
  CheckCircle2,
  Award,
  Activity,
  Calendar
} from 'lucide-react';

export const SettingsScreen: React.FC = () => {
  const { user, signOut } = useAuth();
  const { floatingVisible, setFloatingVisible, setCompanionPreferences } = useMascot();

  // Notification & devices state
  const [notifSettings, setNotifSettings] = useState<NotificationSettings>(getNotificationSettings());
  const [devices, setDevices] = useState<UserDevice[]>([]);
  const [savedMessage, setSavedMessage] = useState<string | null>(null);

  // Phase 10 Companion states
  const [preferences, setPreferences] = useState<CompanionPreferences | null>(null);
  const [routines, setRoutines] = useState<CompanionRoutine[]>([]);
  const [milestones, setMilestones] = useState<CompanionMilestone[]>([]);
  const [activities, setActivities] = useState<CompanionActivity[]>([]);

  // New Routine Form State
  const [newRoutineName, setNewRoutineName] = useState('');
  const [newRoutineType, setNewRoutineType] = useState('MORNING_BRIEFING');
  const [newRoutineTime, setNewRoutineTime] = useState('08:30');

  const loadAllCompanionData = async () => {
    try {
      const [prefData, routineData, milestoneData, activityData] = await Promise.allSettled([
        apiService.getCompanionPreferences(),
        apiService.getCompanionRoutines(),
        apiService.getCompanionMilestones(),
        apiService.getCompanionActivity(15)
      ]);

      if (prefData.status === 'fulfilled') {
        setPreferences(prefData.value);
        setCompanionPreferences(prefData.value);
      }
      if (routineData.status === 'fulfilled') setRoutines(routineData.value);
      if (milestoneData.status === 'fulfilled') setMilestones(milestoneData.value);
      if (activityData.status === 'fulfilled') setActivities(activityData.value);
    } catch (_) {}
  };

  useEffect(() => {
    apiService.getUserDevices().then(setDevices).catch(() => {});
    loadAllCompanionData();
  }, []);

  const handleToggleNotif = (key: keyof NotificationSettings) => {
    const updated = { ...notifSettings, [key]: !notifSettings[key] };
    setNotifSettings(updated);
    saveNotificationSettings(updated);
    setSavedMessage('Notification preferences saved');
    setTimeout(() => setSavedMessage(null), 3000);
  };

  const handleUpdatePreferences = async (updates: Partial<CompanionPreferences>) => {
    try {
      const updated = await apiService.updateCompanionPreferences(updates);
      setPreferences(updated);
      setCompanionPreferences(updated);
      setSavedMessage('Companion preferences updated & synced across devices');
      setTimeout(() => setSavedMessage(null), 3000);
    } catch (e: any) {
      setSavedMessage(e.message || 'Failed to update preferences');
      setTimeout(() => setSavedMessage(null), 3000);
    }
  };

  const handleCreateRoutine = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newRoutineName.trim()) return;

    try {
      const created = await apiService.createCompanionRoutine({
        routine_name: newRoutineName.trim(),
        routine_type: newRoutineType,
        preferred_time: newRoutineTime,
        days_of_week: ['MON', 'TUE', 'WED', 'THU', 'FRI'],
        timezone: 'UTC'
      });
      setRoutines((prev) => [...prev, created]);
      setNewRoutineName('');
      setSavedMessage(`Routine "${created.routine_name}" scheduled`);
      setTimeout(() => setSavedMessage(null), 3000);
    } catch (e: any) {
      setSavedMessage(e.message || 'Failed to create routine');
      setTimeout(() => setSavedMessage(null), 3000);
    }
  };

  const handleToggleRoutine = async (routine: CompanionRoutine) => {
    try {
      const updated = await apiService.updateCompanionRoutine(routine.id, { enabled: !routine.enabled });
      setRoutines((prev) => prev.map((r) => (r.id === routine.id ? updated : r)));
    } catch (_) {}
  };

  const handleDeleteRoutine = async (id: string) => {
    try {
      await apiService.deleteCompanionRoutine(id);
      setRoutines((prev) => prev.filter((r) => r.id !== id));
    } catch (_) {}
  };

  return (
    <div className="flex-1 overflow-y-auto p-6" style={{ height: 'calc(100vh - 64px)' }}>
      {savedMessage && (
        <div
          className="p-3 mb-4 rounded-lg text-xs flex items-center justify-between"
          style={{ backgroundColor: 'rgba(16, 185, 129, 0.1)', color: 'var(--success)', border: '1px solid var(--border)' }}
        >
          <span className="flex items-center gap-2">
            <CheckCircle2 style={{ width: '0.9rem', height: '0.9rem' }} />
            {savedMessage}
          </span>
          <button onClick={() => setSavedMessage(null)} className="text-muted hover:text-primary font-bold">×</button>
        </div>
      )}

      <div className="max-w-3xl flex flex-col gap-6">
        {/* ===================================================================== */}
        {/* 1. LIVING AI COMPANION EVOLUTION & PERSONALITY                        */}
        {/* ===================================================================== */}
        <div
          className="tess-card p-5"
          style={{
            background: 'linear-gradient(135deg, rgba(139, 92, 246, 0.15) 0%, rgba(21, 21, 34, 0.95) 100%)',
            borderColor: 'rgba(139, 92, 246, 0.4)'
          }}
        >
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2.5">
              <Sparkles style={{ width: '1.25rem', height: '1.25rem', color: 'var(--accent)' }} />
              <div>
                <span className="text-[11px] font-bold text-accent uppercase tracking-wider">
                  Stage {preferences?.current_stage || 1}: {preferences?.current_stage === 1 ? 'TESS Seed' : preferences?.current_stage === 2 ? 'TESS Companion' : 'TESS Evolved'}
                </span>
                <h3 className="text-base font-bold text-primary m-0">Living AI Companion & Personality</h3>
              </div>
            </div>

            <div className="text-right">
              <span className="text-xs font-mono font-bold text-primary">
                {preferences?.interaction_count || 0} Interactions
              </span>
              <span className="text-[10px] text-muted block">
                {milestones.length} Milestones Achieved
              </span>
            </div>
          </div>

          <p className="text-xs text-secondary leading-relaxed mb-4">
            {preferences?.current_stage === 1
              ? 'Your companion is in its initial Seed stage. As you complete agent plans, chat, and establish routines, TESS organically adapts to your habits.'
              : preferences?.current_stage === 2
              ? 'Your companion has evolved into an adaptive partner with personalized interaction styles and expanded expression nuances.'
              : 'Your companion is fully evolved, offering deep trajectory alignment and contextual animation presence.'}
          </p>

          <div className="flex items-center justify-between pt-3 border-t border-border text-xs">
            <span className="text-muted">Companion Progression System</span>
            <label className="flex items-center gap-2 cursor-pointer">
              <span className="text-[11px] text-secondary">
                {preferences?.progression_enabled ? 'Progression Active' : 'All Stages Unlocked (Progression Disabled)'}
              </span>
              <input
                type="checkbox"
                checked={preferences?.progression_enabled ?? true}
                onChange={(e) => handleUpdatePreferences({ progression_enabled: e.target.checked })}
                style={{ accentColor: 'var(--accent)' }}
              />
            </label>
          </div>
        </div>

        {/* Personality Presets & Traits */}
        <div className="tess-card p-5">
          <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
            <Heart style={{ width: '1rem', height: '1rem', color: 'var(--accent)' }} />
            Adaptive Personality Preset
          </h3>
          <p className="text-xs text-secondary mb-4">
            Select your companion's baseline demeanor. Safety, honesty, and grounded guidance remain guaranteed.
          </p>

          <div className="grid grid-cols-5 gap-2.5 mb-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)' }}>
            {(['CALM', 'FRIENDLY', 'PROFESSIONAL', 'PLAYFUL', 'FOCUSED'] as const).map((preset) => (
              <button
                key={preset}
                onClick={() => handleUpdatePreferences({ personality: preset })}
                className={`text-xs p-2.5 rounded-xl font-semibold border flex flex-col items-center gap-1 transition-all cursor-pointer ${
                  preferences?.personality === preset
                    ? 'border-accent bg-accent/20 text-primary'
                    : 'border-border bg-secondary text-secondary hover:text-primary'
                }`}
              >
                <span>{preset}</span>
              </button>
            ))}
          </div>

          <div className="grid grid-cols-3 gap-3 pt-3 border-t border-border text-xs" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)' }}>
            <div>
              <label className="text-[11px] text-muted block mb-1">Communication Style</label>
              <select
                value={preferences?.communication_style || 'BALANCED'}
                onChange={(e) => handleUpdatePreferences({ communication_style: e.target.value as any })}
                className="tess-input w-full text-xs"
              >
                <option value="CONCISE">Concise (High Signal)</option>
                <option value="BALANCED">Balanced</option>
                <option value="DETAILED">Detailed / Thorough</option>
              </select>
            </div>

            <div>
              <label className="text-[11px] text-muted block mb-1">Encouragement Style</label>
              <select
                value={preferences?.encouragement_style || 'GENTLE'}
                onChange={(e) => handleUpdatePreferences({ encouragement_style: e.target.value as any })}
                className="tess-input w-full text-xs"
              >
                <option value="GENTLE">Gentle & Grounded</option>
                <option value="ENERGETIC">Energetic & Upbeat</option>
                <option value="PRAGMATIC">Pragmatic & Objective</option>
              </select>
            </div>

            <div>
              <label className="text-[11px] text-muted block mb-1">Formality</label>
              <select
                value={preferences?.formality || 'NEUTRAL'}
                onChange={(e) => handleUpdatePreferences({ formality: e.target.value as any })}
                className="tess-input w-full text-xs"
              >
                <option value="CASUAL">Casual & Approachable</option>
                <option value="NEUTRAL">Neutral</option>
                <option value="FORMAL">Formal & Structured</option>
              </select>
            </div>
          </div>
        </div>

        {/* Mascot Theme & Quiet Mode */}
        <div className="tess-card p-5">
          <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
            <Sparkles style={{ width: '1rem', height: '1rem', color: 'var(--accent)' }} />
            Mascot Appearance & Theme Palette
          </h3>
          <p className="text-xs text-secondary mb-4">
            Customize colors, animation intensity, and quiet hours.
          </p>

          <div className="mb-4">
            <label className="text-[11px] text-muted block mb-2 font-medium">Color Palette</label>
            <div className="flex items-center gap-3">
              {Object.entries(THEME_COLORS).map(([name, hex]) => (
                <button
                  key={name}
                  onClick={() => handleUpdatePreferences({ mascot_theme: name as any })}
                  className={`flex items-center gap-2 px-3 py-1.5 rounded-xl border text-xs font-semibold cursor-pointer transition-all ${
                    preferences?.mascot_theme === name
                      ? 'border-accent bg-accent/20 text-primary'
                      : 'border-border bg-secondary text-secondary hover:text-primary'
                  }`}
                >
                  <span className="w-3 h-3 rounded-full" style={{ backgroundColor: hex }} />
                  <span>{name}</span>
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4 pt-3 border-t border-border text-xs" style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)' }}>
            <div>
              <label className="text-[11px] text-muted block mb-1">Animation Intensity</label>
              <select
                value={preferences?.animation_level || 'NORMAL'}
                onChange={(e) => handleUpdatePreferences({ animation_level: e.target.value as any })}
                className="tess-input w-full text-xs"
              >
                <option value="MINIMAL">Minimal (No pulsing/scaling)</option>
                <option value="NORMAL">Normal</option>
                <option value="LIVELY">Lively (Extra bounce & pulse)</option>
              </select>
            </div>

            <div>
              <label className="text-[11px] text-muted block mb-1">Quiet Mode</label>
              <label className="flex items-center justify-between p-2 rounded-lg bg-secondary cursor-pointer mt-0.5">
                <span className="text-xs text-primary flex items-center gap-1.5">
                  {preferences?.quiet_mode ? (
                    <VolumeX style={{ width: '0.9rem', height: '0.9rem', color: 'var(--danger)' }} />
                  ) : (
                    <Volume2 style={{ width: '0.9rem', height: '0.9rem', color: 'var(--success)' }} />
                  )}
                  {preferences?.quiet_mode ? 'Quiet Mode (Silent & Resting)' : 'Standard Sound & Alerts'}
                </span>
                <input
                  type="checkbox"
                  checked={preferences?.quiet_mode ?? false}
                  onChange={(e) => handleUpdatePreferences({ quiet_mode: e.target.checked })}
                  style={{ accentColor: 'var(--accent)' }}
                />
              </label>
            </div>
          </div>
        </div>

        {/* ===================================================================== */}
        {/* 2. ADAPTIVE PERSONAL ROUTINES                                         */}
        {/* ===================================================================== */}
        <div className="tess-card p-5">
          <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
            <Clock style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
            Personal Routines Intelligence ({routines.length})
          </h3>
          <p className="text-xs text-secondary mb-4">
            Schedule morning briefings, workday checkpoints, or evening reviews aligned with your personal schedule.
          </p>

          <form onSubmit={handleCreateRoutine} className="flex flex-col gap-3 mb-5 p-3 rounded-xl bg-secondary">
            <div className="flex gap-3">
              <input
                type="text"
                placeholder="Routine name (e.g. Morning Briefing)"
                value={newRoutineName}
                onChange={(e) => setNewRoutineName(e.target.value)}
                className="tess-input flex-1 text-xs"
                required
              />

              <select
                value={newRoutineType}
                onChange={(e) => setNewRoutineType(e.target.value)}
                className="tess-input text-xs"
                style={{ width: '180px' }}
              >
                <option value="MORNING_BRIEFING">Morning Briefing</option>
                <option value="DAILY_PLANNING">Daily Planning</option>
                <option value="WORKDAY_CHECK_IN">Workday Check-in</option>
                <option value="EVENING_REVIEW">Evening Review</option>
                <option value="WEEKLY_REVIEW">Weekly Review</option>
                <option value="GOAL_CHECK_IN">Goal Alignment</option>
              </select>

              <input
                type="time"
                value={newRoutineTime}
                onChange={(e) => setNewRoutineTime(e.target.value)}
                className="tess-input text-xs"
                style={{ width: '110px' }}
                required
              />
            </div>

            <div className="flex justify-end">
              <button type="submit" className="btn-primary text-xs" disabled={!newRoutineName.trim()}>
                <Plus style={{ width: '0.85rem', height: '0.85rem' }} />
                <span>Create Routine</span>
              </button>
            </div>
          </form>

          {routines.length === 0 ? (
            <div className="text-xs text-muted py-4 text-center">
              No routines scheduled yet. Add a morning briefing or evening review above.
            </div>
          ) : (
            <div className="space-y-2">
              {routines.map((r) => (
                <div
                  key={r.id}
                  className="flex items-center justify-between p-3 rounded-lg bg-secondary text-xs"
                >
                  <div className="flex items-center gap-3">
                    <input
                      type="checkbox"
                      checked={r.enabled}
                      onChange={() => handleToggleRoutine(r)}
                      style={{ accentColor: 'var(--accent)' }}
                      title={r.enabled ? 'Enabled' : 'Disabled'}
                    />
                    <div>
                      <span className={`font-semibold ${r.enabled ? 'text-primary' : 'text-muted line-through'}`}>
                        {r.routine_name}
                      </span>
                      <div className="text-[11px] text-muted flex items-center gap-2 mt-0.5">
                        <span className="font-mono text-accent">{r.preferred_time}</span>
                        <span>•</span>
                        <span>{r.days_of_week?.join(', ') || 'Weekdays'}</span>
                        <span>•</span>
                        <span className="uppercase text-[10px]">{r.routine_type}</span>
                      </div>
                    </div>
                  </div>

                  <button
                    onClick={() => handleDeleteRoutine(r.id)}
                    className="btn-danger p-1.5"
                    title="Delete routine"
                  >
                    <Trash2 style={{ width: '0.85rem', height: '0.85rem' }} />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Companion Milestones & History */}
        <div className="tess-card p-5">
          <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
            <Award style={{ width: '1.1rem', height: '1.1rem', color: '#F59E0B' }} />
            Companion Milestones & Activity History
          </h3>
          <p className="text-xs text-secondary mb-4">
            Evolutionary milestones achieved through continuous cross-device collaboration.
          </p>

          {milestones.length === 0 ? (
            <div className="text-xs text-muted py-2 text-center">No milestones unlocked yet.</div>
          ) : (
            <div className="space-y-2 mb-4">
              {milestones.map((m) => (
                <div key={m.id} className="p-2.5 bg-secondary rounded-lg flex items-center justify-between text-xs">
                  <div>
                    <span className="font-bold text-primary block">{m.title}</span>
                    <span className="text-muted text-[11px]">{m.description}</span>
                  </div>
                  <span className="text-[10px] font-mono text-accent">
                    {new Date(m.achieved_at).toLocaleDateString()}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* ===================================================================== */}
        {/* 3. FLOATING COMPANION MASCOT                                          */}
        {/* ===================================================================== */}
        <div className="tess-card p-5">
          <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
            <Eye style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
            Floating Companion Mascot
          </h3>
          <p className="text-xs text-secondary mb-4">
            A lightweight, frameless companion window that stays on top and reflects TESS's active state.
          </p>

          <div className="flex items-center justify-between p-3 rounded-lg bg-secondary">
            <div>
              <div className="text-xs font-semibold text-primary">Always-on-top Floating Window</div>
              <div className="text-[11px] text-muted">
                {floatingVisible ? 'Mascot is currently visible on desktop' : 'Mascot is currently hidden'}
              </div>
            </div>
            <button
              onClick={() => setFloatingVisible(!floatingVisible)}
              className={floatingVisible ? 'btn-secondary text-xs' : 'btn-primary text-xs'}
            >
              {floatingVisible ? 'Hide Mascot' : 'Show Mascot'}
            </button>
          </div>
        </div>

        {/* ===================================================================== */}
        {/* 4. DESKTOP NOTIFICATIONS                                              */}
        {/* ===================================================================== */}
        <div className="tess-card p-5">
          <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
            <Bell style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
            Desktop Notifications
          </h3>
          <p className="text-xs text-secondary mb-4">
            Configure alerts for deadline warnings, proactive interventions, and agent execution results.
          </p>

          <div className="flex flex-col gap-2.5">
            {[
              { key: 'enabled' as const, label: 'Enable Desktop Notifications', desc: 'Master switch for notifications' },
              { key: 'futureRisks' as const, label: 'Future Risks & Trajectory Shifts', desc: 'Alerts when probability of overdue spikes' },
              { key: 'deadlines' as const, label: 'Upcoming Deadlines', desc: 'Alerts when tasks approach due date' },
              { key: 'interventions' as const, label: 'Proactive Interventions', desc: 'Actionable suggestions generated by TESS' },
              { key: 'agentResults' as const, label: 'Agent Action Results', desc: 'Confirmations and execution results' },
              { key: 'detailedPreviews' as const, label: 'Detailed Previews', desc: 'Mask private details if disabled' }
            ].map((item) => (
              <label
                key={item.key}
                className="flex items-center justify-between p-3 rounded-lg cursor-pointer bg-secondary"
              >
                <div>
                  <div className="text-xs font-medium text-primary">{item.label}</div>
                  <div className="text-[11px] text-muted">{item.desc}</div>
                </div>
                <input
                  type="checkbox"
                  checked={notifSettings[item.key]}
                  onChange={() => handleToggleNotif(item.key)}
                  className="cursor-pointer"
                  style={{ accentColor: 'var(--accent)', width: '1.1rem', height: '1.1rem' }}
                />
              </label>
            ))}
          </div>
        </div>

        {/* ===================================================================== */}
        {/* 5. CONNECTED DEVICES                                                  */}
        {/* ===================================================================== */}
        <div className="tess-card p-5">
          <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
            <Smartphone style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
            Connected Devices ({devices.length})
          </h3>
          <p className="text-xs text-secondary mb-4">
            All devices connected to this TESS account share conversations, memory, companion routines, and actions.
          </p>

          <div className="flex flex-col gap-2">
            {devices.map((dev) => (
              <div
                key={dev.id}
                className="flex items-center justify-between p-2.5 rounded-lg bg-secondary text-xs"
              >
                <div className="flex items-center gap-2.5">
                  <Laptop style={{ width: '0.9rem', height: '0.9rem', color: 'var(--accent)' }} />
                  <div>
                    <span className="font-semibold text-primary">{dev.device_name}</span>
                    <span className="text-[10px] text-muted block uppercase">Platform: {dev.platform}</span>
                  </div>
                </div>
                <span className="text-[10px] font-mono text-muted">
                  Last seen: {new Date(dev.last_seen_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* ===================================================================== */}
        {/* 6. ACCOUNT & SYSTEM INFORMATION                                       */}
        {/* ===================================================================== */}
        <div className="tess-card p-5">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-sm font-bold text-primary m-0">TESS Account</h3>
              <p className="text-xs text-muted mt-1 mb-0">
                Logged in as <span className="font-semibold text-primary">{user?.email || 'Active User'}</span>
              </p>
              <p className="text-[11px] text-muted font-mono mt-0.5">User ID: {user?.id}</p>
            </div>
            <button onClick={signOut} className="btn-danger">
              <LogOut style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Sign Out</span>
            </button>
          </div>
        </div>

        <div className="tess-card p-5">
          <h3 className="text-sm font-bold text-primary mb-2 flex items-center gap-2">
            <Info style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
            Application Information
          </h3>
          <div className="text-xs text-muted leading-relaxed">
            <div><strong className="text-primary">System:</strong> TESS Cross-Device AI Companion</div>
            <div><strong className="text-primary">Version:</strong> 0.1.0 (Phase 10 Living AI Companion)</div>
            <div><strong className="text-primary">Architecture:</strong> Tauri 2 + React + TypeScript + FastAPI</div>
            <div><strong className="text-primary">Backend API:</strong> Connected ({apiService ? 'Active' : 'Offline'})</div>
          </div>
        </div>
      </div>
    </div>
  );
};
