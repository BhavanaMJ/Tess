import React from 'react';
import { Sparkles, ArrowRight, Compass, Search } from 'lucide-react';
import { Mascot } from '../Mascot';
import { MascotState, User } from '../../types';
import { ScreenTab } from '../Sidebar';

interface DashboardWelcomeProps {
  user: User | null;
  mascotState: MascotState;
  overdueCount: number;
  activeInterventionsCount: number;
  hasRiskPredictions: boolean;
  onNavigate: (tab: ScreenTab) => void;
  onOpenCommandPalette?: () => void;
}

export const DashboardWelcome: React.FC<DashboardWelcomeProps> = ({
  user,
  mascotState,
  overdueCount,
  activeInterventionsCount,
  hasRiskPredictions,
  onNavigate,
  onOpenCommandPalette
}) => {
  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  };

  const getFormattedDate = () => {
    return new Intl.DateTimeFormat('en-US', {
      weekday: 'long',
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    }).format(new Date());
  };

  const getContextualMessage = () => {
    if (activeInterventionsCount > 0) {
      return 'TESS detected a potential divergence in your trajectory. An urgent intervention requires your review to realign your day.';
    }
    if (overdueCount > 0) {
      return `You have ${overdueCount} overdue work package${overdueCount > 1 ? 's' : ''} requiring immediate attention to protect your upcoming commitments.`;
    }
    if (hasRiskPredictions) {
      return 'Future simulations indicate elevated friction in your upcoming 24h horizon. Review suggested preventive paths below.';
    }
    return 'Your velocity is steady and balanced. TESS is actively observing context, predicting potential trajectories, and standing by.';
  };

  const userName = user?.email ? user.email.split('@')[0] : 'Operator';

  return (
    <div
      className="tess-card p-6 relative overflow-hidden transition-all duration-300"
      style={{
        background: 'linear-gradient(135deg, rgba(23, 26, 45, 0.9) 0%, rgba(11, 13, 24, 0.96) 100%)',
        borderColor: 'rgba(22, 143, 131, 0.35)',
        boxShadow: '0 8px 32px rgba(0, 0, 0, 0.45), inset 0 0 24px rgba(22, 143, 131, 0.06)'
      }}
    >
      {/* Subtle Ambient Brand Gradient Glow */}
      <div
        className="absolute -top-20 -right-20 w-72 h-72 rounded-full pointer-events-none"
        style={{
          background: 'radial-gradient(circle, rgba(53, 185, 165, 0.15) 0%, rgba(169, 154, 217, 0.08) 50%, transparent 75%)',
          filter: 'blur(35px)'
        }}
      />

      <div className="flex flex-col md:flex-row items-center justify-between gap-6 relative z-10">
        <div className="flex-1 min-w-0">
          {/* Header Metadata Pill */}
          <div className="flex flex-wrap items-center gap-2 mb-2.5">
            <div className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-[rgba(22,143,131,0.15)] border border-[rgba(53,185,165,0.35)]">
              <Sparkles style={{ width: '0.8rem', height: '0.8rem', color: '#35B9A5' }} />
              <span className="text-[11px] font-mono font-bold text-[#35B9A5] tracking-wider uppercase">
                Personal AI Command Centre
              </span>
            </div>
            <span className="text-[11px] font-mono text-muted">
              {getFormattedDate()}
            </span>
          </div>

          {/* Time-Aware Greeting & User Identity */}
          <h2 className="text-2xl md:text-3xl font-bold tracking-tight text-primary m-0">
            {getGreeting()}, <span style={{ color: '#BDF2E4' }}>{userName}</span>
          </h2>

          {/* Context-Driven TESS Guidance */}
          <p className="text-xs text-secondary mt-2 max-w-2xl leading-relaxed m-0 font-medium">
            {getContextualMessage()}
          </p>

          {/* Quick Context Action Triggers */}
          <div className="flex flex-wrap items-center gap-3 mt-5">
            <button
              onClick={() => onNavigate('chat')}
              className="btn-primary text-xs flex items-center gap-1.5"
              style={{
                background: 'linear-gradient(135deg, #168F83 0%, #08776E 100%)',
                borderColor: '#35B9A5'
              }}
            >
              <span>Talk to TESS</span>
              <ArrowRight style={{ width: '0.85rem', height: '0.85rem' }} />
            </button>

            <button
              onClick={() => onNavigate('futures')}
              className="btn-secondary text-xs flex items-center gap-1.5"
              style={{
                borderColor: 'rgba(169, 154, 217, 0.4)',
                color: '#A99AD9'
              }}
            >
              <Compass style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Simulate Trajectory</span>
            </button>

            {onOpenCommandPalette && (
              <button
                onClick={onOpenCommandPalette}
                className="hidden sm:flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-mono text-muted hover:text-primary transition-all duration-200 cursor-pointer"
                style={{
                  backgroundColor: 'rgba(255, 255, 255, 0.03)',
                  border: '1px solid var(--border)'
                }}
                title="Open Global Search (⌘K)"
              >
                <Search style={{ width: '0.8rem', height: '0.8rem', color: '#35B9A5' }} />
                <span>Command Search (⌘K)</span>
              </button>
            )}
          </div>
        </div>

        {/* TESS Expressive Companion Orb */}
        <div className="flex flex-col items-center justify-center p-2 shrink-0">
          <div
            className="p-3 rounded-2xl transition-all duration-300"
            style={{
              background: 'radial-gradient(circle, rgba(22, 143, 131, 0.12) 0%, rgba(17, 20, 38, 0.5) 80%)',
              border: '1px solid rgba(53, 185, 165, 0.25)'
            }}
          >
            <Mascot state={mascotState} size="lg" showLabel={true} />
          </div>
        </div>
      </div>
    </div>
  );
};
