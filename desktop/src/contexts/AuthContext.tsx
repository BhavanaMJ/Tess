import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase, setSessionToken, apiService } from '../services/api';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signIn: (email: string, pass: string) => Promise<{ error?: string }>;
  signUp: (email: string, pass: string) => Promise<{ error?: string }>;
  signOut: () => Promise<void>;
  refreshSession: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  session: null,
  loading: true,
  signIn: async () => ({}),
  signUp: async () => ({}),
  signOut: async () => {},
  refreshSession: async () => {}
});

const getOrCreateDeviceId = (): string => {
  let id = localStorage.getItem('tess_desktop_device_id');
  if (!id) {
    id = 'desktop-' + Math.random().toString(36).substring(2, 12);
    localStorage.setItem('tess_desktop_device_id', id);
  }
  return id;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  const registerCurrentDevice = async (currentUser: User) => {
    try {
      const deviceId = getOrCreateDeviceId();
      const platform = navigator.userAgent.includes('Win')
        ? 'windows'
        : navigator.userAgent.includes('Mac')
        ? 'macos'
        : 'linux';
      await apiService.registerDevice(deviceId, `TESS Desktop (${platform})`, platform);
    } catch (_) {}
  };

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setSessionToken(session);
      setLoading(false);
      if (session?.user) {
        registerCurrentDevice(session.user);
      }
    });

    const {
      data: { subscription }
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      setSessionToken(session);
      setLoading(false);
      if (session?.user) {
        registerCurrentDevice(session.user);
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const signIn = async (email: string, pass: string) => {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password: pass
      });
      if (error) return { error: error.message };
      setSession(data.session);
      setUser(data.user);
      setSessionToken(data.session);
      if (data.user) {
        registerCurrentDevice(data.user);
      }
      return {};
    } catch (e: any) {
      return { error: e.message || 'Authentication failed' };
    }
  };

  const signUp = async (email: string, pass: string) => {
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password: pass
      });
      if (error) return { error: error.message };
      setSession(data.session);
      setUser(data.user);
      setSessionToken(data.session);
      return {};
    } catch (e: any) {
      return { error: e.message || 'Sign up failed' };
    }
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    setSession(null);
    setUser(null);
    setSessionToken(null);
  };

  const refreshSession = async () => {
    const { data } = await supabase.auth.getSession();
    setSession(data.session);
    setUser(data.session?.user ?? null);
    setSessionToken(data.session);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        session,
        loading,
        signIn,
        signUp,
        signOut,
        refreshSession
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);

