import React from 'react';
import { RefreshCw, Eye, EyeOff } from 'lucide-react';
import { useMascot } from '../contexts/MascotContext';
import { getMascotDetails } from './Mascot';

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
  const { state: mascotState, floatingVisible, setFloatingVisible } = useMascot();
  const mascotDetails = getMascotDetails(mascotState);

  return (
    <header
      className="flex items-center justify-between border-b px-6 py-4"
      style={{
        backgroundColor: 'var(--bg-primary)',
        borderColor: 'var(--border)',
        minHeight: '64px'
      }}
    >
      <div>
        <h1 className="text-xl font-bold" style={{ margin: 0, color: 'var(--text-primary)' }}>
          {title}
        </h1>
        {subtitle && (
          <p className="text-xs" style={{ margin: '0.2rem 0 0', color: 'var(--text-muted)' }}>
            {subtitle}
          </p>
        )}
      </div>

      <div className="flex items-center gap-3">
        {/* Mascot state indicator pill */}
        <div
          className="flex items-center gap-2 px-3 py-1 rounded-full text-xs font-medium"
          style={{
            backgroundColor: `${mascotDetails.color}18`,
            border: `1px solid ${mascotDetails.color}35`,
            color: mascotDetails.color
          }}
        >
          <span className="font-mono font-bold">{mascotDetails.face}</span>
          <span>{mascotDetails.label}</span>
        </div>

        {/* Floating Mascot Toggle */}
        <button
          onClick={() => setFloatingVisible(!floatingVisible)}
          className="btn-secondary"
          style={{ fontSize: '0.8rem', padding: '0.4rem 0.75rem' }}
          title={floatingVisible ? 'Hide floating mascot' : 'Show floating mascot'}
        >
          {floatingVisible ? (
            <>
              <EyeOff style={{ width: '0.9rem', height: '0.9rem' }} />
              <span>Hide Mascot</span>
            </>
          ) : (
            <>
              <Eye style={{ width: '0.9rem', height: '0.9rem' }} />
              <span>Show Mascot</span>
            </>
          )}
        </button>

        {/* Global Refresh Button */}
        {onRefresh && (
          <button
            onClick={onRefresh}
            disabled={isSyncing}
            className="btn-secondary"
            style={{ fontSize: '0.8rem', padding: '0.4rem 0.75rem' }}
            title="Refresh cross-device data"
          >
            <RefreshCw
              style={{
                width: '0.9rem',
                height: '0.9rem',
                animation: isSyncing ? 'spin 1s linear infinite' : 'none'
              }}
            />
            <span>{isSyncing ? 'Syncing...' : 'Sync'}</span>
          </button>
        )}
      </div>

      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `}</style>
    </header>
  );
};

