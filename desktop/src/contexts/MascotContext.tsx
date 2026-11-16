import React, { createContext, useContext, useEffect, useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { WebviewWindow } from '@tauri-apps/api/webviewWindow';
import { MascotState, CompanionPreferences } from '../types';
import { apiService } from '../services/api';

export const THEME_COLORS: Record<string, string> = {
  PURPLE: '#8B5CF6',
  CYAN: '#06B6D4',
  AMBER: '#F59E0B',
  EMERALD: '#10B981',
  ROSE: '#F43F5E',
  INDIGO: '#6366F1'
};

interface MascotContextType {
  state: MascotState;
  setState: (state: MascotState) => void;
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
}

const MascotContext = createContext<MascotContextType>({
  state: 'IDLE',
  setState: () => {},
  message: null,
  setMessage: () => {},
  hasAttention: false,
  setHasAttention: () => {},
  floatingVisible: true,
  setFloatingVisible: () => {},
  focusMainWindow: async () => {},
  themeColor: '#8B5CF6',
  animationLevel: 'NORMAL',
  stage: 1,
  quietMode: false,
  setCompanionPreferences: () => {},
  refreshCompanion: async () => {}
});

const BROADCAST_NAME = 'tess_mascot_broadcast';
const VISIBILITY_KEY = 'tess_mascot_visible';

export const MascotProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, setInternalState] = useState<MascotState>('IDLE');
  const [message, setInternalMessage] = useState<string | null>(null);
  const [hasAttention, setInternalHasAttention] = useState(false);
  const [floatingVisible, setInternalFloatingVisible] = useState<boolean>(() => {
    const raw = localStorage.getItem(VISIBILITY_KEY);
    return raw !== null ? raw === 'true' : true;
  });
  const [themeColor, setThemeColor] = useState<string>('#8B5CF6');
  const [animationLevel, setAnimationLevel] = useState<'MINIMAL' | 'NORMAL' | 'LIVELY'>('NORMAL');
  const [stage, setStage] = useState<number>(1);
  const [quietMode, setQuietMode] = useState<boolean>(false);

  // Cross-window channel for multi-window Tauri sync
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
      }
    };

    return () => {
      channel.close();
    };
  }, []);

  const broadcast = (payload: any) => {
    if (typeof window !== 'undefined' && 'BroadcastChannel' in window) {
      try {
        const channel = new BroadcastChannel(BROADCAST_NAME);
        channel.postMessage(payload);
        channel.close();
      } catch (_) {}
    }
  };

  const setCompanionPreferences = (prefs: CompanionPreferences) => {
    const color = THEME_COLORS[prefs.mascot_theme] || THEME_COLORS.PURPLE;
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
  };

  const refreshCompanion = async () => {
    try {
      const prefs = await apiService.getCompanionPreferences();
      setCompanionPreferences(prefs);
    } catch (_) {}
  };

  useEffect(() => {
    refreshCompanion();
  }, []);

  const setState = (newState: MascotState) => {
    setInternalState(newState);
    broadcast({ type: 'UPDATE_MASCOT', state: newState });
  };

  const setMessage = (newMsg: string | null) => {
    setInternalMessage(newMsg);
    broadcast({ type: 'UPDATE_MASCOT', message: newMsg });
  };

  const setHasAttention = (att: boolean) => {
    setInternalHasAttention(att);
    broadcast({ type: 'UPDATE_MASCOT', hasAttention: att });
  };

  const setFloatingVisible = async (visible: boolean) => {
    setInternalFloatingVisible(visible);
    localStorage.setItem(VISIBILITY_KEY, String(visible));
    broadcast({ type: 'UPDATE_VISIBILITY', floatingVisible: visible });

    try {
      await invoke('toggle_mascot_window', { visible });
    } catch (_) {}
  };

  const focusMainWindow = async () => {
    console.log('[TESS Mascot] focusMainWindow called');
    try {
      await invoke('focus_main_window');
      console.log('[TESS Mascot] Successfully focused/restored main window via invoke');
    } catch (invokeErr) {
      console.warn('[TESS Mascot] invoke focus_main_window failed, trying WebviewWindow fallback:', invokeErr);
      try {
        const mainWin = await WebviewWindow.getByLabel('main');
        if (mainWin) {
          await mainWin.show();
          await mainWin.unminimize();
          await mainWin.setFocus();
          console.log('[TESS Mascot] Focused main window via WebviewWindow API');
        } else {
          console.error('[TESS Mascot] Main window "main" not found in WebviewWindow registry');
        }
      } catch (windowErr) {
        console.error('[TESS Mascot] Both Tauri focus methods failed:', windowErr);
        if (typeof window !== 'undefined') {
          window.focus();
        }
      }
    }
  };

  return (
    <MascotContext.Provider
      value={{
        state,
        setState,
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
        refreshCompanion
      }}
    >
      {children}
    </MascotContext.Provider>
  );
};

export const useMascot = () => useContext(MascotContext);
