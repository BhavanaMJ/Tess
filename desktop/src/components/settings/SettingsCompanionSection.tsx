import React from 'react';
import { CompanionPreferences, CompanionMilestone } from '../../types';
import { THEME_COLORS } from '../../contexts/MascotContext';
import { Sparkles, Heart, Volume2, VolumeX, ShieldCheck } from 'lucide-react';

interface SettingsCompanionSectionProps {
  preferences: CompanionPreferences | null;
  milestones: CompanionMilestone[];
  onUpdatePreferences: (updates: Partial<CompanionPreferences>) => Promise<void>;
}

export const SettingsCompanionSection: React.FC<SettingsCompanionSectionProps> = ({
  preferences,
  milestones,
  onUpdatePreferences
}) => {
  return (
    <div className="flex flex-col gap-6">
      {/* 1. Evolution Stage Card */}
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
              <span className="text-[11px] font-bold text-accent uppercase tracking-wider font-mono">
                Stage {preferences?.current_stage || 1}:{' '}
                {preferences?.current_stage === 1
                  ? 'TESS Seed'
                  : preferences?.current_stage === 2
                  ? 'TESS Companion'
                  : 'TESS Evolved'}
              </span>
              <h3 className="text-base font-bold text-primary m-0">Living AI Companion & Personality</h3>
            </div>
          </div>

          <div className="text-right">
            <span className="text-xs font-mono font-bold text-primary">
              {preferences?.interaction_count || 0} Interactions
            </span>
            <span className="text-[10px] text-muted block font-mono">
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

        <div className="flex items-center justify-between pt-3 border-t border-[rgba(255,255,255,0.08)] text-xs">
          <span className="text-muted">Companion Progression System</span>
          <label className="flex items-center gap-2 cursor-pointer">
            <span className="text-[11px] text-secondary">
              {preferences?.progression_enabled
                ? 'Progression Active'
                : 'All Stages Unlocked (Progression Disabled)'}
            </span>
            <input
              type="checkbox"
              checked={preferences?.progression_enabled ?? true}
              onChange={(e) => onUpdatePreferences({ progression_enabled: e.target.checked })}
              style={{ accentColor: 'var(--accent)' }}
            />
          </label>
        </div>
      </div>

      {/* 2. Personality Presets & Demeanor */}
      <div className="tess-card p-5">
        <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
          <Heart style={{ width: '1rem', height: '1rem', color: 'var(--accent)' }} />
          <span>Adaptive Personality Preset</span>
        </h3>
        <p className="text-xs text-secondary mb-4">
          Select your companion's baseline demeanor. Safety, honesty, and grounded guidance remain guaranteed.
        </p>

        <div className="grid grid-cols-5 gap-2.5 mb-4">
          {(['CALM', 'FRIENDLY', 'PROFESSIONAL', 'PLAYFUL', 'FOCUSED'] as const).map((preset) => (
            <button
              key={preset}
              type="button"
              onClick={() => onUpdatePreferences({ personality: preset })}
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

        <div className="grid grid-cols-1 md:grid-cols-3 gap-3 pt-3 border-t border-[rgba(255,255,255,0.08)] text-xs">
          <div>
            <label className="text-[11px] text-muted block mb-1 font-mono">Communication Style</label>
            <select
              value={preferences?.communication_style || 'BALANCED'}
              onChange={(e) => onUpdatePreferences({ communication_style: e.target.value as any })}
              className="tess-input w-full text-xs font-mono"
            >
              <option value="CONCISE">Concise (High Signal)</option>
              <option value="BALANCED">Balanced</option>
              <option value="DETAILED">Detailed / Thorough</option>
            </select>
          </div>

          <div>
            <label className="text-[11px] text-muted block mb-1 font-mono">Encouragement Style</label>
            <select
              value={preferences?.encouragement_style || 'GENTLE'}
              onChange={(e) => onUpdatePreferences({ encouragement_style: e.target.value as any })}
              className="tess-input w-full text-xs font-mono"
            >
              <option value="GENTLE">Gentle & Grounded</option>
              <option value="ENERGETIC">Energetic & Upbeat</option>
              <option value="PRAGMATIC">Pragmatic & Objective</option>
            </select>
          </div>

          <div>
            <label className="text-[11px] text-muted block mb-1 font-mono">Formality</label>
            <select
              value={preferences?.formality || 'NEUTRAL'}
              onChange={(e) => onUpdatePreferences({ formality: e.target.value as any })}
              className="tess-input w-full text-xs font-mono"
            >
              <option value="CASUAL">Casual & Approachable</option>
              <option value="NEUTRAL">Neutral</option>
              <option value="FORMAL">Formal & Structured</option>
            </select>
          </div>
        </div>
      </div>

      {/* 3. Mascot Theme & Quiet Mode */}
      <div className="tess-card p-5">
        <h3 className="text-sm font-bold text-primary mb-1 flex items-center gap-2">
          <Sparkles style={{ width: '1rem', height: '1rem', color: 'var(--accent)' }} />
          <span>Mascot Appearance & Theme Palette</span>
        </h3>
        <p className="text-xs text-secondary mb-4">
          Customize colors, animation intensity, and quiet mode hours.
        </p>

        <div className="mb-4">
          <label className="text-[11px] text-muted block mb-2 font-mono uppercase">Color Palette</label>
          <div className="flex items-center gap-3 flex-wrap">
            {Object.entries(THEME_COLORS).map(([name, hex]) => (
              <button
                key={name}
                type="button"
                onClick={() => onUpdatePreferences({ mascot_theme: name as any })}
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

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-3 border-t border-[rgba(255,255,255,0.08)] text-xs">
          <div>
            <label className="text-[11px] text-muted block mb-1 font-mono">Animation Intensity</label>
            <select
              value={preferences?.animation_level || 'NORMAL'}
              onChange={(e) => onUpdatePreferences({ animation_level: e.target.value as any })}
              className="tess-input w-full text-xs font-mono"
            >
              <option value="MINIMAL">Minimal (No pulsing/scaling)</option>
              <option value="NORMAL">Normal</option>
              <option value="LIVELY">Lively (Extra bounce & pulse)</option>
            </select>
          </div>

          <div>
            <label className="text-[11px] text-muted block mb-1 font-mono">Quiet Mode</label>
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
                onChange={(e) => onUpdatePreferences({ quiet_mode: e.target.checked })}
                style={{ accentColor: 'var(--accent)' }}
              />
            </label>
          </div>
        </div>
      </div>
    </div>
  );
};

