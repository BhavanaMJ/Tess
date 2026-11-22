import React from 'react';
import { RefreshCw, ExternalLink, Activity, Search, Sun, Moon } from 'lucide-react';
import { useMascot } from '../contexts/MascotContext';
import { useTheme } from '../contexts/ThemeContext';

interface HeaderProps {
  title: string;
  subtitle?: string;
  isSyncing?: boolean;
  onRefresh?: () => void;
  onOpenCommandPalette?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  title,
  subtitle,
  isSyncing = false,
  onRefresh,
  onOpenCommandPalette
}) => {
  const { setFloatingVisible, state: mascotState, togglePanel } = useMascot();
  const { theme, toggleTheme } = useTheme();

  return (
    <header
      className="flex items-center justify-between px-6 select-none relative z-10 shrink-0"
      style={{
        height: '68px',
        backgroundColor: 'var(--bg-secondary)',
        borderBottom: '1px solid var(--border)',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)'
      }}
    >
      {/* Breadcrumb Navigation & Title */}
      <div className="flex flex-col justify-center">
        <nav aria-label="Breadcrumb" className="flex items-center gap-1.5 text-[11px] font-mono text-muted">
          <span className="tracking-widest font-semibold text-primary">TESS</span>
          <span className="text-muted/50">/</span>
          <span className="text-[#A78BFA] font-medium tracking-wide">{title}</span>
        </nav>
        {subtitle && (
          <p className="text-xs text-muted mt-0.5 m-0 font-medium truncate max-w-[420px]">
            {subtitle}
          </p>
        )}
      </div>

      {/* Global Command Palette Trigger Bar */}
      {onOpenCommandPalette && (
        <button
          onClick={onOpenCommandPalette}
          className="hidden md:flex items-center gap-2.5 px-3.5 py-1.5 rounded-lg text-xs transition-all duration-200 cursor-pointer hover:border-[rgba(139,92,246,0.35)] hover:bg-[rgba(255,255,255,0.05)]"
          style={{
            backgroundColor: 'rgba(255, 255, 255, 0.03)',
            border: '1px solid var(--border)',
            color: 'var(--text-muted)'
          }}
          title="Open Command Palette (Ctrl+K or ⌘K)"
        >
          <Search style={{ width: '0.85rem', height: '0.85rem', color: '#A78BFA' }} />
          <span className="text-xs text-muted">Search commands, tasks, memories...</span>
          <kbd className="ml-3 px-1.5 py-0.5 text-[10px] font-mono rounded bg-[rgba(255,255,255,0.06)] border border-[rgba(255,255,255,0.1)] text-secondary">
            ⌘K
          </kbd>
        </button>
      )}

      {/* Contextual Actions Area */}
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

        {/* Interactive Mascot Presence State Indicator */}
        <button
          onClick={togglePanel}
          className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[rgba(53,185,165,0.1)] border border-[rgba(53,185,165,0.3)] hover:bg-[rgba(53,185,165,0.2)] transition-all cursor-pointer"
          style={{ background: 'none' }}
          title="Open TESS Companion Panel (⌘M)"
        >
          <Activity style={{ width: '0.85rem', height: '0.85rem', color: '#35B9A5' }} />
          <span className="font-mono text-[11px] font-semibold text-[#35B9A5] tracking-wider uppercase">
            {mascotState}
          </span>
        </button>

        {/* Manual Refresh Telemetry Button */}
        {onRefresh && (
          <button
            onClick={onRefresh}
            disabled={isSyncing}
            className="p-2 rounded-lg text-muted hover:text-primary transition-all duration-200 hover:bg-[rgba(255,255,255,0.05)] cursor-pointer"
            style={{ background: 'none', border: '1px solid var(--border)' }}
            title="Refresh System Data"
            aria-label="Refresh System Data"
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

        {/* Theme Toggle Button (Light / Dark) */}
        <button
          onClick={toggleTheme}
          className="p-2 rounded-lg text-muted hover:text-primary transition-all duration-200 hover:bg-[rgba(255,255,255,0.05)] cursor-pointer"
          style={{ background: 'none', border: '1px solid var(--border)' }}
          title={theme === 'dark' ? 'Switch to Light Theme' : 'Switch to Dark Theme'}
          aria-label={theme === 'dark' ? 'Switch to Light Theme' : 'Switch to Dark Theme'}
        >
          {theme === 'dark' ? (
            <Sun style={{ width: '0.95rem', height: '0.95rem', color: '#FBBF24' }} />
          ) : (
            <Moon style={{ width: '0.95rem', height: '0.95rem', color: '#168F83' }} />
          )}
        </button>

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
