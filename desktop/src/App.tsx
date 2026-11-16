import React from 'react';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { MascotProvider } from './contexts/MascotContext';
import { Layout } from './components/Layout';
import { LoginScreen } from './screens/LoginScreen';
import { FloatingMascotWindow } from './mascot/FloatingMascotWindow';

function MainApp() {
  const { session, loading } = useAuth();

  // Multi-window check: if this instance was opened as the floating mascot window
  const isMascotWindow =
    typeof window !== 'undefined' &&
    window.location.search.includes('window=mascot');

  if (isMascotWindow) {
    return <FloatingMascotWindow />;
  }

  if (loading) {
    return (
      <div
        className="w-full h-full flex flex-col items-center justify-center bg-primary"
        style={{ height: '100vh', color: 'var(--text-muted)' }}
      >
        <div
          style={{
            width: '2rem',
            height: '2rem',
            border: '3px solid var(--border)',
            borderTopColor: 'var(--accent)',
            borderRadius: '50%',
            animation: 'spin 0.8s linear infinite'
          }}
        />
        <span className="text-xs mt-3">Connecting to TESS...</span>
        <style>{`
          @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
          }
        `}</style>
      </div>
    );
  }

  if (!session) {
    return <LoginScreen />;
  }

  return <Layout />;
}

export default function App() {
  return (
    <AuthProvider>
      <MascotProvider>
        <MainApp />
      </MascotProvider>
    </AuthProvider>
  );
}

