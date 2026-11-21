import React, { createContext, useContext, useEffect, useState, useRef, useCallback } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { WebviewWindow } from '@tauri-apps/api/webviewWindow';
import { MascotState, CompanionPreferences } from '../types';
import { apiService } from '../services/api';

export const THEME_COLORS: Record<string, string> = {
  MINT: '#35B9A5',
  TEAL: '#168F83',
  PURPLE: '#8B5CF6',
  CYAN: '#06B6D4',
  AMBER: '#F59E0B',
  EMERALD: '#10B981',
  ROSE: '#F43F5E',
  INDIGO: '#6366F1'
};

// Authoritative Emotion Priority Scores (higher scores cannot be clobbered by lower ones)
export const EMOTION_PRIORITIES: Record<MascotState, number> = {
  ERROR: 90,
  CONFIRMING: 85,
  ATTENTION: 80,
  INTERVENING: 75,
  ACTING: 65,
  PLANNING: 60,
  THINKING: 55,
  SPEAKING: 50,
  LISTENING: 50,
  VIEWING: 50,
  BROWSING: 45,
  READING: 45,
  SUCCESS: 45,
  HAPPY: 40,
  CURIOUS: 30,
  RESTING: 20,
  SLEEPING: 15,
  IDLE: 10
};

interface MascotContextType {
  state: MascotState;
  setState: (state: MascotState) => void;
  triggerEmotion: (emotion: MascotState, durationMs?: number, message?: string) => void;
  message: string | null;
  setMessage: (msg: string | null) => void;
  hasAttention: boolean;
  setHasAttention: (att: boolean) => void;
  floatingVisible: boolean;
  setFloatingVisible: (visible: boolean) => void;
  focusMainWindow: () => Promise<void>;
  themeColor: string;
  animationLevel: 'MINIMAL' | 'NORMAL' | 'LIVELY';
  stage: number;
  quietMode: boolean;
  setCompanionPreferences: (prefs: CompanionPreferences) => void;
  refreshCompanion: () => Promise<void>;
  // Phase D3: Interactive Companion Panel
  isPanelOpen: boolean;
  openPanel: () => void;
  closePanel: () => void;
  togglePanel: () => void;
}

const MascotContext = createContext<MascotContextType>({
  state: 'IDLE',
  setState: () => {},
  triggerEmotion: () => {},
  message: null,
  setMessage: () => {},
  hasAttention: false,
  setHasAttention: () => {},
  floatingVisible: true,
  setFloatingVisible: () => {},
  focusMainWindow: async () => {},
  themeColor: '#168F83',
  animationLevel: 'NORMAL',
  stage: 1,
  quietMode: false,
  setCompanionPreferences: () => {},
  refreshCompanion: async () => {},
  isPanelOpen: false,
  openPanel: () => {},
  closePanel: () => {},
  togglePanel: () => {}
});

const BROADCAST_NAME = 'tess_mascot_broadcast';
const VISIBILITY_KEY = 'tess_mascot_visible';

export const MascotProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, setInternalState] = useState<MascotState>('IDLE');
  const [message, setInternalMessage] = useState<string | null>(null);
  const [hasAttention, setInternalHasAttention] = useState(false);
  const [isPanelOpen, setIsPanelOpen] = useState(false);

  const [floatingVisible, setInternalFloatingVisible] = useState<boolean>(() => {
    try {
      const raw = localStorage.getItem(VISIBILITY_KEY);
      return raw !== null ? raw === 'true' : true;
    } catch {
      return true;
    }
  });

  const [themeColor, setThemeColor] = useState<string>('#168F83');
  const [animationLevel, setAnimationLevel] = useState<'MINIMAL' | 'NORMAL' | 'LIVELY'>('NORMAL');
  const [stage, setStage] = useState<number>(1);
  const [quietMode, setQuietMode] = useState<boolean>(false);

  const transitionSeqRef = useRef<number>(0);
  const baselineStateRef = useRef<MascotState>('IDLE');

  const broadcast = useCallback((payload: any) => {
    if (typeof window !== 'undefined' && 'BroadcastChannel' in window) {
      try {
        const channel = new BroadcastChannel(BROADCAST_NAME);
        channel.postMessage(payload);
        channel.close();
      } catch (_) {}
    }
  }, []);

  // Cross-window channel for multi-window Tauri synchronization
  useEffect(() => {
    if (typeof window === 'undefined' || !('BroadcastChannel' in window)) return;
    const channel = new BroadcastChannel(BROADCAST_NAME);

    channel.onmessage = (event) => {
      const data = event.data;
      if (!data) return;
      if (data.type === 'UPDATE_MASCOT') {
        if (data.state !== undefined) setInternalState(data.state);
        if (data.message !== undefined) setInternalMessage(data.message);
        if (data.hasAttention !== undefined) setInternalHasAttention(data.hasAttention);
      } else if (data.type === 'UPDATE_VISIBILITY') {
        if (data.floatingVisible !== undefined) setInternalFloatingVisible(data.floatingVisible);
      } else if (data.type === 'UPDATE_COMPANION') {
        if (data.themeColor !== undefined) setThemeColor(data.themeColor);
        if (data.animationLevel !== undefined) setAnimationLevel(data.animationLevel);
        if (data.stage !== undefined) setStage(data.stage);
        if (data.quietMode !== undefined) setQuietMode(data.quietMode);
      } else if (data.type === 'OPEN_COMPANION_PANEL') {
        setIsPanelOpen(true);
      }
    };

    return () => {
      channel.close();
    };
  }, []);

  const openPanel = useCallback(() => {
    setIsPanelOpen(true);
    broadcast({ type: 'OPEN_COMPANION_PANEL' });
  }, [broadcast]);

  const closePanel = useCallback(() => {
    setIsPanelOpen(false);
  }, []);

  const togglePanel = useCallback(() => {
    setIsPanelOpen((prev) => {
      const next = !prev;
      if (next) broadcast({ type: 'OPEN_COMPANION_PANEL' });
      return next;
    });
  }, [broadcast]);

  const setCompanionPreferences = useCallback((prefs: CompanionPreferences) => {
    const color = THEME_COLORS[prefs.mascot_theme] || THEME_COLORS.TEAL || '#168F83';
    setThemeColor(color);
    setAnimationLevel(prefs.animation_level || 'NORMAL');
    setStage(prefs.current_stage || 1);
    setQuietMode(prefs.quiet_mode || false);
    broadcast({
      type: 'UPDATE_COMPANION',
      themeColor: color,
      animationLevel: prefs.animation_level,
      stage: prefs.current_stage,
      quietMode: prefs.quiet_mode
    });
  }, [broadcast]);

  const refreshCompanion = useCallback(async () => {
    try {
      const prefs = await apiService.getCompanionPreferences();
      setCompanionPreferences(prefs);
    } catch (_) {}
  }, [setCompanionPreferences]);

  useEffect(() => {
    refreshCompanion();
  }, [refreshCompanion]);

  /**
   * Authoritative state update respecting baseline persistence
   */
  const setState = useCallback((newState: MascotState) => {
    transitionSeqRef.current += 1;
    // States like IDLE or ATTENTION become the persistent baseline
    if (newState === 'IDLE' || newState === 'ATTENTION' || newState === 'RESTING') {
      baselineStateRef.current = newState;
    }
    setInternalState(newState);
    broadcast({ type: 'UPDATE_MASCOT', state: newState });
  }, [broadcast]);

  /**
   * Temporary emotion trigger with auto-revert to baseline
   */
  const triggerEmotion = useCallback((
    emotion: MascotState,
    durationMs: number = 3500,
    msg?: string
  ) => {
    transitionSeqRef.current += 1;
    const currentSeq = transitionSeqRef.current;

    setInternalState(emotion);
    if (msg !== undefined) {
      setInternalMessage(msg);
      broadcast({ type: 'UPDATE_MASCOT', state: emotion, message: msg });
    } else {
      broadcast({ type: 'UPDATE_MASCOT', state: emotion });
    }

    // Schedule return to baseline
    setTimeout(() => {
      if (transitionSeqRef.current === currentSeq) {
        setInternalState(baselineStateRef.current);
        if (msg) setInternalMessage(null);
        broadcast({ type: 'UPDATE_MASCOT', state: baselineStateRef.current, message: null });
      }
    }, durationMs);
  }, [broadcast]);

  const setMessage = useCallback((newMsg: string | null) => {
    setInternalMessage(newMsg);
    broadcast({ type: 'UPDATE_MASCOT', message: newMsg });
  }, [broadcast]);

  const setHasAttention = useCallback((att: boolean) => {
    setInternalHasAttention(att);
    broadcast({ type: 'UPDATE_MASCOT', hasAttention: att });
  }, [broadcast]);

  const setFloatingVisible = useCallback(async (visible: boolean) => {
    setInternalFloatingVisible(visible);
    try {
      localStorage.setItem(VISIBILITY_KEY, String(visible));
    } catch (_) {}
    broadcast({ type: 'UPDATE_VISIBILITY', floatingVisible: visible });

    try {
      await invoke('toggle_mascot_window', { visible });
    } catch (_) {
      try {
        const mascotWin = await WebviewWindow.getByLabel('mascot');
        if (mascotWin) {
          if (visible) await mascotWin.show();
          else await mascotWin.hide();
        }
      } catch (_) {}
    }
  }, [broadcast]);

  const focusMainWindow = useCallback(async () => {
    try {
      await invoke('focus_main_window');
    } catch (_) {
      try {
        const mainWin = await WebviewWindow.getByLabel('main');
        if (mainWin) {
          await mainWin.unminimize();
          await mainWin.show();
          await mainWin.setFocus();
        }
      } catch (_) {}
    }
  }, []);

  return (
    <MascotContext.Provider
      value={{
        state,
        setState,
        triggerEmotion,
        message,
        setMessage,
        hasAttention,
        setHasAttention,
        floatingVisible,
        setFloatingVisible,
        focusMainWindow,
        themeColor,
        animationLevel,
        stage,
        quietMode,
        setCompanionPreferences,
        refreshCompanion,
        isPanelOpen,
        openPanel,
        closePanel,
        togglePanel
      }}
    >
      {children}
    </MascotContext.Provider>
  );
};

export const useMascot = () => useContext(MascotContext);
