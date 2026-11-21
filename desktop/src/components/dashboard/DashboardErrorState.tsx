import React from 'react';
import { AlertTriangle, RefreshCw } from 'lucide-react';

interface DashboardErrorStateProps {
  onRetry: () => void;
  errorMessage?: string;
}

export const DashboardErrorState: React.FC<DashboardErrorStateProps> = ({
  onRetry,
  errorMessage = 'Unable to establish connection with TESS AI Backend service.'
}) => {
  return (
    <div className="flex-1 flex flex-col items-center justify-center p-8 text-center" style={{ height: 'calc(100vh - 68px)' }}>
      <div className="w-16 h-16 rounded-2xl bg-[rgba(251,113,133,0.12)] border border-[rgba(251,113,133,0.3)] flex items-center justify-center mb-4">
        <AlertTriangle style={{ width: '2rem', height: '2rem', color: '#FB7185' }} />
      </div>

      <h3 className="text-lg font-bold text-primary tracking-wide m-0">
        Command Centre Telemetry Disconnected
      </h3>

      <p className="text-xs text-muted max-w-md mt-2 leading-relaxed">
        {errorMessage}
      </p>

      <div className="mt-5 flex items-center gap-3">
        <button
          onClick={onRetry}
          className="btn-primary text-xs flex items-center gap-2"
          style={{
            background: 'linear-gradient(135deg, #168F83 0%, #08776E 100%)',
            borderColor: '#35B9A5'
          }}
        >
          <RefreshCw style={{ width: '0.85rem', height: '0.85rem' }} />
          <span>Retry Reconnection</span>
        </button>
      </div>
    </div>
  );
};
