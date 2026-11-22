import React from 'react';
import { UserDevice } from '../../types';
import { Smartphone, Laptop, Tablet, CheckCircle2 } from 'lucide-react';

interface SettingsDevicesSectionProps {
  devices: UserDevice[];
}

export const SettingsDevicesSection: React.FC<SettingsDevicesSectionProps> = ({ devices }) => {
  const getDeviceIcon = (platform: string) => {
    const p = platform.toLowerCase();
    if (p.includes('mobile') || p.includes('android') || p.includes('ios')) return Smartphone;
    if (p.includes('tablet') || p.includes('ipad')) return Tablet;
    return Laptop;
  };

  return (
    <div className="tess-card p-5">
      <div className="flex items-center justify-between mb-1">
        <h3 className="text-sm font-bold text-primary m-0 flex items-center gap-2">
          <Smartphone style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
          <span>Connected Devices ({devices.length})</span>
        </h3>
        <span className="text-[10px] font-mono text-[#34D399] flex items-center gap-1">
          <CheckCircle2 style={{ width: '0.75rem', height: '0.75rem' }} />
          <span>Cross-Device Mesh Active</span>
        </span>
      </div>
      <p className="text-xs text-secondary mb-4">
        All devices connected to this TESS account share conversations, memory, companion routines, and actions.
      </p>

      {devices.length === 0 ? (
        <div className="text-xs text-muted py-6 text-center font-mono">
          No external devices registered.
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {devices.map((dev) => {
            const Icon = getDeviceIcon(dev.platform);
            return (
              <div
                key={dev.id}
                className="flex items-center justify-between p-3 rounded-lg bg-secondary text-xs transition-colors hover:border-[rgba(139,92,246,0.35)]"
                style={{ border: '1px solid var(--border)' }}
              >
                <div className="flex items-center gap-3">
                  <div
                    className="p-2 rounded-lg"
                    style={{ backgroundColor: 'rgba(139, 92, 246, 0.12)', color: 'var(--accent)' }}
                  >
                    <Icon style={{ width: '1rem', height: '1rem' }} />
                  </div>
                  <div>
                    <span className="font-semibold text-primary">{dev.device_name}</span>
                    <span className="text-[10px] text-muted block uppercase font-mono mt-0.5">
                      Platform: {dev.platform}
                    </span>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-[10px] font-mono text-muted block">
                    Last seen: {new Date(dev.last_seen_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                  <span className="text-[10px] font-mono text-[#34D399]">Connected</span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
