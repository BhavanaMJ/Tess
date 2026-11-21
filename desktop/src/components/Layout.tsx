import React, { useState, useEffect, useCallback } from 'react';
import { Sidebar, ScreenTab } from './Sidebar';
import { Header } from './Header';
import { CommandPalette } from './CommandPalette';
import { HomeScreen } from '../screens/HomeScreen';
import { ChatScreen } from '../screens/ChatScreen';
import { TasksScreen } from '../screens/TasksScreen';
import { FuturesScreen } from '../screens/FuturesScreen';
import { InterventionsScreen } from '../screens/InterventionsScreen';
import { AgentActivityScreen } from '../screens/AgentActivityScreen';
import { MemoryScreen } from '../screens/MemoryScreen';
import { SettingsScreen } from '../screens/SettingsScreen';
import { apiService } from '../services/api';
import { notifyDesktop } from '../services/notifications';
import { useMascot } from '../contexts/MascotContext';

export const Layout: React.FC = () => {
  const [currentTab, setCurrentTab] = useState<ScreenTab>('home');
  const [isSyncing, setIsSyncing] = useState(false);
  const [isCommandPaletteOpen, setIsCommandPaletteOpen] = useState(false);
  const [badgeCounts, setBadgeCounts] = useState<{
    interventions?: number;
    tasks?: number;
    agentPlans?: number;
  }>({});

  const { setState: setMascotState, setMessage: setMascotMessage, setFloatingVisible } = useMascot();

  const refreshGlobalMetrics = useCallback(async () => {
    setIsSyncing(true);
    try {
      const [sumRes, invRes, planRes, routineRes] = await Promise.allSettled([
        apiService.getProductivitySummary(),
        apiService.getInterventions(),
        apiService.getAgentPlans(),
        apiService.checkDueRoutines()
      ]);

      let pendingInvs = 0;
      let activeTasks = 0;
      let pendingPlans = 0;

      if (routineRes.status === 'fulfilled' && routineRes.value?.count > 0) {
        const firstDue = routineRes.value.due_routines[0];
        notifyDesktop(firstDue.title, firstDue.message, 'interventions');
        setMascotState('HAPPY');
        setMascotMessage(firstDue.title);
      }

      if (invRes.status === 'fulfilled') {
        const active = invRes.value.filter((i) => i.status === 'SENT');
        pendingInvs = active.length;
        if (active.length > 0) {
          notifyDesktop(
            'Proactive Intervention',
            active[0].message,
            'interventions'
          );
          setMascotState('INTERVENING');
          setMascotMessage(active[0].title);
        }
      }

      if (sumRes.status === 'fulfilled') {
        activeTasks = sumRes.value.total_active;
        if (sumRes.value.overdue > 0) {
          notifyDesktop(
            'Overdue Task Warning',
            `You have ${sumRes.value.overdue} overdue task(s) on OpenProject.`,
            'deadlines'
          );
        }
      }

      if (planRes.status === 'fulfilled') {
        pendingPlans = planRes.value.filter((p) => p.status === 'READY' || p.status === 'PLANNING').length;
      }

      setBadgeCounts({
        interventions: pendingInvs,
        tasks: activeTasks,
        agentPlans: pendingPlans
      });
    } catch (_) {}
    finally {
      setIsSyncing(false);
    }
  }, [setMascotState, setMascotMessage]);

  useEffect(() => {
    refreshGlobalMetrics();
    // 60-second background polling for cross-device sync
    const interval = setInterval(refreshGlobalMetrics, 60000);
    return () => clearInterval(interval);
  }, [refreshGlobalMetrics]);

  // Global Keyboard Shortcuts (Ctrl+K / Cmd+K and ⌘1-⌘8 Module switching)
  useEffect(() => {
    const handleGlobalShortcuts = (e: KeyboardEvent) => {
      // Toggle Command Palette
      if ((e.ctrlKey || e.metaKey) && (e.key === 'k' || e.key === 'K')) {
        e.preventDefault();
        setIsCommandPaletteOpen((prev) => !prev);
        return;
      }

      // Quick Module Switching: ⌘1 .. ⌘8
      if ((e.ctrlKey || e.metaKey) && !e.shiftKey && !e.altKey) {
        const keyMap: Record<string, ScreenTab> = {
          '1': 'home',
          '2': 'chat',
          '3': 'tasks',
          '4': 'futures',
          '5': 'interventions',
          '6': 'agent',
          '7': 'memory',
          '8': 'settings'
        };
        if (keyMap[e.key]) {
          e.preventDefault();
          setCurrentTab(keyMap[e.key]);
        }
      }
    };

    window.addEventListener('keydown', handleGlobalShortcuts);
    return () => window.removeEventListener('keydown', handleGlobalShortcuts);
  }, []);

  const getScreenTitle = (tab: ScreenTab) => {
    switch (tab) {
      case 'home':
        return { title: 'Dashboard', subtitle: 'Overview of your productivity, futures, and agents' };
      case 'chat':
        return { title: 'TESS Companion Chat', subtitle: 'Continuous conversation history shared across devices' };
      case 'tasks':
        return { title: 'Productivity Tasks', subtitle: 'OpenProject synchronized work packages and deadlines' };
      case 'futures':
        return { title: 'Future Simulation Engine', subtitle: 'Probabilistic trajectory and counterfactual scenario modeling' };
      case 'interventions':
        return { title: 'Proactive Interventions', subtitle: 'AI-generated guidance and automated agent fixes' };
      case 'agent':
        return { title: 'Agent & Action Layer', subtitle: 'Deterministic planning, execution, and confirmation safeguards' };
      case 'memory':
        return { title: 'Personal Memory', subtitle: 'Persistent user preferences, habits, and context' };
      case 'settings':
        return { title: 'Desktop Settings', subtitle: 'Notification preferences, mascot visibility, and devices' };
    }
  };

  const { title, subtitle } = getScreenTitle(currentTab);

  return (
    <div className="flex w-full h-full bg-primary" style={{ height: '100vh', width: '100vw' }}>
      <Sidebar
        currentTab={currentTab}
        onSelectTab={setCurrentTab}
        onOpenCommandPalette={() => setIsCommandPaletteOpen(true)}
        badgeCounts={badgeCounts}
      />

      <div className="flex-1 flex flex-col h-full overflow-hidden bg-primary">
        <Header
          title={title}
          subtitle={subtitle}
          isSyncing={isSyncing}
          onRefresh={refreshGlobalMetrics}
          onOpenCommandPalette={() => setIsCommandPaletteOpen(true)}
        />

        <main className="flex-1 overflow-hidden relative">
          {currentTab === 'home' && (
            <HomeScreen
              onNavigate={setCurrentTab}
              onOpenCommandPalette={() => setIsCommandPaletteOpen(true)}
            />
          )}
          {currentTab === 'chat' && <ChatScreen />}
          {currentTab === 'tasks' && <TasksScreen />}
          {currentTab === 'futures' && <FuturesScreen />}
          {currentTab === 'interventions' && <InterventionsScreen onNavigate={setCurrentTab} />}
          {currentTab === 'agent' && <AgentActivityScreen />}
          {currentTab === 'memory' && <MemoryScreen />}
          {currentTab === 'settings' && <SettingsScreen />}
        </main>
      </div>

      {/* Global Command Palette and Search Modal */}
      <CommandPalette
        isOpen={isCommandPaletteOpen}
        onClose={() => setIsCommandPaletteOpen(false)}
        onNavigate={setCurrentTab}
        onRefresh={refreshGlobalMetrics}
        onToggleMascot={() => setFloatingVisible(true)}
      />
    </div>
  );
};
