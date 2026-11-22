import React from 'react';
import { LogOut, Info, Shield, CheckCircle2 } from 'lucide-react';

interface SettingsAccountSectionProps {
  user: any;
  onSignOut: () => void;
  apiConnected: boolean;
}

export const SettingsAccountSection: React.FC<SettingsAccountSectionProps> = ({
  user,
  onSignOut,
  apiConnected
}) => {
  return (
    <div className="flex flex-col gap-6">
      {/* 1. User Profile Card */}
      <div className="tess-card p-5">
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div>
            <h3 className="text-sm font-bold text-primary m-0 flex items-center gap-2">
              <Shield style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
              <span>TESS Account</span>
            </h3>
            <p className="text-xs text-muted mt-1 mb-0">
              Logged in as <span className="font-semibold text-primary">{user?.email || 'Active User'}</span>
            </p>
            <p className="text-[11px] text-muted font-mono mt-0.5">User ID: {user?.id || 'd6dd3895-95c9-414b-8f08-863ba3985492'}</p>
          </div>
          <button type="button" onClick={onSignOut} className="btn-danger text-xs">
            <LogOut style={{ width: '0.85rem', height: '0.85rem' }} />
            <span>Sign Out</span>
          </button>
        </div>
      </div>

      {/* 2. Application Information Card */}
      <div className="tess-card p-5">
        <h3 className="text-sm font-bold text-primary mb-2 flex items-center gap-2">
          <Info style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
          <span>Application Information</span>
        </h3>
        <div className="text-xs text-muted leading-relaxed space-y-1 font-mono">
          <div>
            <strong className="text-primary font-sans">System:</strong> TESS Personal AI Operating System
          </div>
          <div>
            <strong className="text-primary font-sans">Version:</strong> 0.1.0 (Phase 10 Living AI Companion)
          </div>
          <div>
            <strong className="text-primary font-sans">Architecture:</strong> Tauri 2 + React + TypeScript + FastAPI
          </div>
          <div className="flex items-center gap-1.5">
            <strong className="text-primary font-sans">Backend API:</strong>
            <span style={{ color: apiConnected ? '#34D399' : '#FB7185' }}>
              {apiConnected ? 'Connected & Healthy (http://localhost:8000)' : 'Offline'}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
