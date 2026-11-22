import React, { useEffect, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useMascot } from '../contexts/MascotContext';
import {
  getNotificationSettings,
  saveNotificationSettings
} from '../services/notifications';
import { apiService } from '../services/api';
import {
  NotificationSettings,
  UserDevice,
  CompanionPreferences,
  CompanionRoutine,
  CompanionMilestone,
  CompanionActivity
} from '../types';
import { SettingsNavTabs, SettingsTabId } from '../components/settings/SettingsNavTabs';
import { SettingsCompanionSection } from '../components/settings/SettingsCompanionSection';
import { SettingsRoutinesSection } from '../components/settings/SettingsRoutinesSection';
import { SettingsNotificationsSection } from '../components/settings/SettingsNotificationsSection';
import { SettingsDevicesSection } from '../components/settings/SettingsDevicesSection';
import { SettingsAccountSection } from '../components/settings/SettingsAccountSection';
import { CheckCircle2, AlertCircle } from 'lucide-react';

export const SettingsScreen: React.FC = () => {
  const { user, signOut } = useAuth();
  const { floatingVisible, setFloatingVisible, setCompanionPreferences } = useMascot();

  const [activeTab, setActiveTab] = useState<SettingsTabId>('ALL');

  // Notification & devices state
  const [notifSettings, setNotifSettings] = useState<NotificationSettings>(getNotificationSettings());
  const [devices, setDevices] = useState<UserDevice[]>([]);
  const [savedMessage, setSavedMessage] = useState<string | null>(null);

  // Companion states
  const [preferences, setPreferences] = useState<CompanionPreferences | null>(null);
  const [routines, setRoutines] = useState<CompanionRoutine[]>([]);
  const [milestones, setMilestones] = useState<CompanionMilestone[]>([]);
  const [activities, setActivities] = useState<CompanionActivity[]>([]);

  const loadAllCompanionData = async () => {
    try {
      const [prefData, routineData, milestoneData, activityData] = await Promise.allSettled([
        apiService.getCompanionPreferences(),
        apiService.getCompanionRoutines(),
        apiService.getCompanionMilestones(),
        apiService.getCompanionActivity(15)
      ]);

      if (prefData.status === 'fulfilled') {
        setPreferences(prefData.value);
        setCompanionPreferences(prefData.value);
      }
      if (routineData.status === 'fulfilled') setRoutines(routineData.value);
      if (milestoneData.status === 'fulfilled') setMilestones(milestoneData.value);
      if (activityData.status === 'fulfilled') setActivities(activityData.value);
    } catch (_) {}
  };

  useEffect(() => {
    apiService.getUserDevices().then(setDevices).catch(() => {});
    loadAllCompanionData();
  }, []);

  const handleToggleNotif = (key: keyof NotificationSettings) => {
    const updated = { ...notifSettings, [key]: !notifSettings[key] };
    setNotifSettings(updated);
    saveNotificationSettings(updated);
    setSavedMessage('Notification preferences saved');
    setTimeout(() => setSavedMessage(null), 3000);
  };

  const handleUpdatePreferences = async (updates: Partial<CompanionPreferences>) => {
    try {
      const updated = await apiService.updateCompanionPreferences(updates);
      setPreferences(updated);
      setCompanionPreferences(updated);
      setSavedMessage('Companion preferences updated & synced across devices');
      setTimeout(() => setSavedMessage(null), 3000);
    } catch (e: any) {
      setSavedMessage(e.message || 'Failed to update preferences');
      setTimeout(() => setSavedMessage(null), 3000);
    }
  };

  const handleCreateRoutine = async (name: string, type: string, time: string) => {
    try {
      const created = await apiService.createCompanionRoutine({
        routine_name: name,
        routine_type: type,
        preferred_time: time,
        days_of_week: ['MON', 'TUE', 'WED', 'THU', 'FRI'],
        timezone: 'UTC'
      });
      setRoutines((prev) => [...prev, created]);
      setSavedMessage(`Routine "${created.routine_name}" scheduled`);
      setTimeout(() => setSavedMessage(null), 3000);
    } catch (e: any) {
      setSavedMessage(e.message || 'Failed to create routine');
      setTimeout(() => setSavedMessage(null), 3000);
    }
  };

  const handleToggleRoutine = async (routine: CompanionRoutine) => {
    try {
      const updated = await apiService.updateCompanionRoutine(routine.id, { enabled: !routine.enabled });
      setRoutines((prev) => prev.map((r) => (r.id === routine.id ? updated : r)));
    } catch (_) {}
  };

  const handleDeleteRoutine = async (id: string) => {
    try {
      await apiService.deleteCompanionRoutine(id);
      setRoutines((prev) => prev.filter((r) => r.id !== id));
      setSavedMessage('Routine removed');
      setTimeout(() => setSavedMessage(null), 3000);
    } catch (_) {}
  };

  return (
    <div
      className="flex-1 overflow-y-auto p-6"
      style={{ height: 'calc(100vh - 68px)', position: 'relative', zIndex: 1 }}
    >
      {/* Toast Save Message */}
      {savedMessage && (
        <div
          className="p-3 mb-4 rounded-xl text-xs flex items-center justify-between animate-fadeIn"
          style={{
            backgroundColor: 'rgba(52, 211, 153, 0.12)',
            color: '#34D399',
            border: '1px solid rgba(52, 211, 153, 0.3)'
          }}
        >
          <span className="flex items-center gap-2">
            <CheckCircle2 style={{ width: '0.9rem', height: '0.9rem' }} />
            {savedMessage}
          </span>
          <button
            type="button"
            onClick={() => setSavedMessage(null)}
            className="text-muted hover:text-primary font-bold cursor-pointer"
            style={{ background: 'none', border: 'none' }}
          >
            ×
          </button>
        </div>
      )}

      {/* Nav Tabs Bar */}
      <SettingsNavTabs
        activeTab={activeTab}
        onTabChange={setActiveTab}
        counts={{
          routines: routines.length,
          devices: devices.length,
          milestones: milestones.length
        }}
      />

      {/* Settings Sections Container */}
      <div className="max-w-3xl flex flex-col gap-6">
        {/* Tab 1: Companion & Demeanor */}
        {(activeTab === 'ALL' || activeTab === 'COMPANION') && (
          <SettingsCompanionSection
            preferences={preferences}
            milestones={milestones}
            onUpdatePreferences={handleUpdatePreferences}
          />
        )}

        {/* Tab 2: Routines & Automation */}
        {(activeTab === 'ALL' || activeTab === 'ROUTINES') && (
          <SettingsRoutinesSection
            routines={routines}
            milestones={milestones}
            onCreateRoutine={handleCreateRoutine}
            onToggleRoutine={handleToggleRoutine}
            onDeleteRoutine={handleDeleteRoutine}
          />
        )}

        {/* Tab 3: Mascot & Notifications */}
        {(activeTab === 'ALL' || activeTab === 'NOTIFICATIONS') && (
          <SettingsNotificationsSection
            floatingVisible={floatingVisible}
            onToggleFloating={() => setFloatingVisible(!floatingVisible)}
            notifSettings={notifSettings}
            onToggleNotif={handleToggleNotif}
          />
        )}

        {/* Tab 4: Connected Devices */}
        {(activeTab === 'ALL' || activeTab === 'DEVICES') && (
          <SettingsDevicesSection devices={devices} />
        )}

        {/* Tab 5: Account & System Information */}
        {(activeTab === 'ALL' || activeTab === 'ACCOUNT') && (
          <SettingsAccountSection
            user={user}
            onSignOut={signOut}
            apiConnected={Boolean(apiService)}
          />
        )}
      </div>
    </div>
  );
};
