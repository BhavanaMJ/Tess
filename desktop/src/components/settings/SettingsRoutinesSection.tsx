import React, { useState } from 'react';
import { CompanionRoutine, CompanionMilestone } from '../../types';
import { Clock, Plus, Trash2, Award, Calendar } from 'lucide-react';

interface SettingsRoutinesSectionProps {
  routines: CompanionRoutine[];
  milestones: CompanionMilestone[];
  onCreateRoutine: (name: string, type: string, time: string) => Promise<void>;
  onToggleRoutine: (routine: CompanionRoutine) => Promise<void>;
  onDeleteRoutine: (id: string) => Promise<void>;
}

export const SettingsRoutinesSection: React.FC<SettingsRoutinesSectionProps> = ({
  routines,
  milestones,
  onCreateRoutine,
  onToggleRoutine,
  onDeleteRoutine
}) => {
  const [newRoutineName, setNewRoutineName] = useState('');
  const [newRoutineType, setNewRoutineType] = useState('MORNING_BRIEFING');
  const [newRoutineTime, setNewRoutineTime] = useState('08:30');
  const [creating, setCreating] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newRoutineName.trim() || creating) return;
    setCreating(true);
    try {
      await onCreateRoutine(newRoutineName.trim(), newRoutineType, newRoutineTime);
      setNewRoutineName('');
    } finally {
      setCreating(false);
    }
  };

  return (
    <div className="flex flex-col gap-6">
      {/* 1. Personal Routines Card */}
      <div className="tess-card p-5">
        <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
          <Clock style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
          <span>Personal Routines Intelligence ({routines.length})</span>
        </h3>
        <p className="text-xs text-secondary mb-4">
          Schedule morning briefings, workday checkpoints, or evening reviews aligned with your personal schedule.
        </p>

        {/* Create Routine Form */}
        <form onSubmit={handleSubmit} className="flex flex-col gap-3 mb-5 p-3 rounded-xl bg-secondary">
          <div className="flex flex-col md:flex-row gap-3">
            <input
              type="text"
              placeholder="Routine name (e.g. Morning Briefing)"
              value={newRoutineName}
              onChange={(e) => setNewRoutineName(e.target.value)}
              className="tess-input flex-1 text-xs"
              required
              disabled={creating}
            />

            <select
              value={newRoutineType}
              onChange={(e) => setNewRoutineType(e.target.value)}
              className="tess-input text-xs font-mono"
              style={{ width: '180px' }}
              disabled={creating}
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
              className="tess-input text-xs font-mono"
              style={{ width: '110px' }}
              required
              disabled={creating}
            />
          </div>

          <div className="flex justify-end">
            <button
              type="submit"
              className="btn-primary text-xs"
              disabled={!newRoutineName.trim() || creating}
            >
              <Plus style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>{creating ? 'Scheduling...' : 'Create Routine'}</span>
            </button>
          </div>
        </form>

        {/* Routines List */}
        {routines.length === 0 ? (
          <div className="text-xs text-muted py-4 text-center font-mono">
            No routines scheduled yet. Add a morning briefing or evening review above.
          </div>
        ) : (
          <div className="space-y-2">
            {routines.map((r) => (
              <div
                key={r.id}
                className="flex items-center justify-between p-3 rounded-lg bg-secondary text-xs transition-colors hover:border-[rgba(139,92,246,0.35)]"
                style={{ border: '1px solid var(--border)' }}
              >
                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    checked={r.enabled}
                    onChange={() => onToggleRoutine(r)}
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
                      <span className="uppercase text-[10px] font-mono">{r.routine_type}</span>
                    </div>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={() => onDeleteRoutine(r.id)}
                  className="btn-danger p-1.5 cursor-pointer"
                  title="Delete routine"
                >
                  <Trash2 style={{ width: '0.85rem', height: '0.85rem' }} />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* 2. Milestones & Achievements Card */}
      <div className="tess-card p-5">
        <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
          <Award style={{ width: '1.1rem', height: '1.1rem', color: '#F59E0B' }} />
          <span>Companion Milestones & Activity History</span>
        </h3>
        <p className="text-xs text-secondary mb-4">
          Evolutionary milestones achieved through continuous cross-device collaboration.
        </p>

        {milestones.length === 0 ? (
          <div className="text-xs text-muted py-2 text-center font-mono">No milestones unlocked yet.</div>
        ) : (
          <div className="space-y-2">
            {milestones.map((m) => (
              <div
                key={m.id}
                className="p-2.5 bg-secondary rounded-lg flex items-center justify-between text-xs"
                style={{ border: '1px solid var(--border)' }}
              >
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
    </div>
  );
};

