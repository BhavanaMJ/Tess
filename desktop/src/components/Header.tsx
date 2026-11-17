import React from 'react';
import { RefreshCw, ExternalLink, Activity, Wifi } from 'lucide-react';
import { useMascot } from '../contexts/MascotContext';

interface HeaderProps {
  title: string;
  subtitle?: string;
  isSyncing?: boolean;
  onRefresh?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  title,
  subtitle,
  isSyncing = false,
  onRefresh
}) => {
  const { setFloatingVisible, state: mascotState } = useMascot();

  return (
    <header
      className="flex items-center justify-between px-6 select-none relative z-10"
      style={{
        height: '68px',
        backgroundColor: 'var(--bg-secondary)',
        borderBottom: '1px solid var(--border)',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)'
      }}
    >
      <div>
        <div className="flex items-center gap-2.5">
          <h1 className="text-lg font-bold text-primary tracking-wide m-0">
            {title}
          </h1>
          <span className="text-[10px] font-mono px-2 py-0.5 rounded-full font-semibold uppercase tracking-wider bg-[rgba(139,92,246,0.12)] text-[#A78BFA] border border-[rgba(139,92,246,0.25)]">
            AI CORE
          </span>
        </div>
        {subtitle && (
          <p className="text-xs text-muted mt-0.5 m-0 font-medium">
            {subtitle}
          </p>
        )}
      </div>

      <div className="flex items-center gap-3">
        {/* Real-time System Sync Badge */}
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-[rgba(255,255,255,0.03)] border border-[rgba(255,255,255,0.06)]">
          <span
            className="w-2 h-2 rounded-full"
            style={{
              backgroundColor: isSyncing ? '#22D3EE' : '#34D399',
              boxShadow: isSyncing
                ? '0 0 8px #22D3EE'
                : '0 0 8px #34D399',
              animation: isSyncing ? 'pulse 1s infinite' : 'none'
            }}
          />
          <span className="font-mono text-[11px] text-secondary tracking-wider">
            {isSyncing ? 'SYNCING...' : 'LIVE'}
          </span>
        </div>

        {/* Mascot Presence State Indicator */}
        <div className="hidden md:flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[rgba(139,92,246,0.08)] border border-[rgba(139,92,246,0.25)]">
          <Activity style={{ width: '0.85rem', height: '0.85rem', color: '#A78BFA' }} />
          <span className="font-mono text-[11px] font-semibold text-[#A78BFA] tracking-wider uppercase">
            {mascotState}
          </span>
        </div>

        {/* Manual Refresh Telemetry Button */}
        {onRefresh && (
          <button
            onClick={onRefresh}
            disabled={isSyncing}
            className="p-2 rounded-lg text-muted hover:text-primary transition-all duration-200 hover:bg-[rgba(255,255,255,0.05)] cursor-pointer"
            style={{ background: 'none', border: '1px solid var(--border)' }}
            title="Refresh System Data"
          >
            <RefreshCw
              style={{
                width: '0.95rem',
                height: '0.95rem',
                animation: isSyncing ? 'spin 1s linear infinite' : 'none'
              }}
            />
          </button>
        )}

        {/* Floating Mascot Launcher */}
        <button
          onClick={() => setFloatingVisible(true)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold cursor-pointer transition-all duration-200"
          style={{
            backgroundColor: 'rgba(34, 211, 238, 0.1)',
            color: '#22D3EE',
            border: '1px solid rgba(34, 211, 238, 0.35)'
          }}
          title="Launch Floating Holographic Companion"
        >
          <ExternalLink style={{ width: '0.85rem', height: '0.85rem' }} />
          <span>Hologram</span>
        </button>
      </div>
    </header>
  );
};
