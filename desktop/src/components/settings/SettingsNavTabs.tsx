import React from 'react';
import { Sparkles, Heart, Clock, Bell, Smartphone, Info, Layers } from 'lucide-react';

export type SettingsTabId = 'COMPANION' | 'ROUTINES' | 'NOTIFICATIONS' | 'DEVICES' | 'ACCOUNT' | 'ALL';

interface SettingsNavTabsProps {
  activeTab: SettingsTabId;
  onTabChange: (tab: SettingsTabId) => void;
  counts: {
    routines: number;
    devices: number;
    milestones: number;
  };
}

export const SettingsNavTabs: React.FC<SettingsNavTabsProps> = ({
  activeTab,
  onTabChange,
  counts
}) => {
  const tabs = [
    { id: 'COMPANION' as const, label: 'Companion & Demeanor', icon: Heart },
    { id: 'ROUTINES' as const, label: 'Routines & Automation', icon: Clock, count: counts.routines },
    { id: 'NOTIFICATIONS' as const, label: 'Mascot & Notifications', icon: Bell },
    { id: 'DEVICES' as const, label: 'Connected Devices', icon: Smartphone, count: counts.devices },
    { id: 'ACCOUNT' as const, label: 'Account & System', icon: Info },
    { id: 'ALL' as const, label: 'All Settings', icon: Layers }
  ];

  return (
    <div className="flex items-center gap-1.5 overflow-x-auto pb-2 mb-6 border-b border-[rgba(255,255,255,0.06)]">
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = activeTab === tab.id;
        return (
          <button
            key={tab.id}
            type="button"
            onClick={() => onTabChange(tab.id)}
            className="px-3 py-1.5 rounded-xl text-xs font-mono font-medium transition-all shrink-0 flex items-center gap-2 cursor-pointer"
            style={{
              backgroundColor: isActive ? 'rgba(139, 92, 246, 0.2)' : 'var(--bg-secondary)',
              color: isActive ? '#A78BFA' : 'var(--text-secondary)',
              border: `1px solid ${isActive ? 'rgba(139, 92, 246, 0.4)' : 'var(--border)'}`
            }}
          >
            <Icon style={{ width: '0.85rem', height: '0.85rem' }} />
            <span>{tab.label}</span>
            {tab.count !== undefined && (
              <span
                className="text-[10px] px-1.5 py-0.2 rounded-full"
                style={{
                  backgroundColor: isActive ? 'rgba(139, 92, 246, 0.3)' : 'rgba(255, 255, 255, 0.06)',
                  color: isActive ? '#FFFFFF' : 'var(--text-muted)'
                }}
              >
                {tab.count}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
};

