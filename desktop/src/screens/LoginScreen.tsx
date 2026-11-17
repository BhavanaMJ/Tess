import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Mascot } from '../components/Mascot';
import { Lock, Mail, ArrowRight, AlertCircle, Sparkles } from 'lucide-react';

export const LoginScreen: React.FC = () => {
  const { signIn, signUp } = useAuth();
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password || loading) return;

    setLoading(true);
    setError(null);

    const cleanEmail = email.trim().toLowerCase();
    const res = isSignUp
      ? await signUp(cleanEmail, password)
      : await signIn(cleanEmail, password);

    if (res.error) {
      setError(res.error);
    }
    setLoading(false);
  };

  return (
    <div
      className="w-full h-full flex items-center justify-center p-6 bg-primary relative overflow-hidden"
      style={{ minHeight: '100vh', position: 'relative' }}
    >
      {/* Cosmic background gradient aura */}
      <div
        className="absolute w-96 h-96 rounded-full pointer-events-none"
        style={{
          background: 'radial-gradient(circle, rgba(139, 92, 246, 0.15) 0%, transparent 70%)',
          filter: 'blur(50px)',
          top: '20%',
          left: '50%',
          transform: 'translate(-50%, -50%)'
        }}
      />

      <div
        className="tess-card p-8 flex flex-col items-center relative z-10"
        style={{
          width: '100%',
          maxWidth: '430px',
          borderColor: 'rgba(139, 92, 246, 0.35)',
          boxShadow: '0 16px 48px rgba(0, 0, 0, 0.6), 0 0 24px rgba(139, 92, 246, 0.15)',
          background: 'rgba(17, 20, 38, 0.85)',
          backdropFilter: 'blur(24px)',
          WebkitBackdropFilter: 'blur(24px)'
        }}
      >
        <Mascot state="IDLE" size="lg" />

        <div className="flex items-center gap-1.5 mt-4 mb-1">
          <h2 className="text-2xl font-bold font-mono tracking-wider text-primary m-0">
            TESS
          </h2>
          <span className="text-[10px] font-mono font-bold px-2 py-0.5 rounded-full bg-[rgba(34,211,238,0.1)] text-[#22D3EE] border border-[rgba(34,211,238,0.3)]">
            OS
          </span>
        </div>

        <p className="text-xs text-muted mb-6 text-center font-medium">
          Personal Future Simulator + AI Operating System
        </p>

        {error && (
          <div
            className="w-full p-3 mb-4 rounded-xl text-xs flex items-center gap-2"
            style={{
              backgroundColor: 'rgba(251, 113, 133, 0.12)',
              color: '#FB7185',
              border: '1px solid rgba(251, 113, 133, 0.3)'
            }}
          >
            <AlertCircle style={{ width: '1rem', height: '1rem', flexShrink: 0 }} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="w-full flex flex-col gap-3.5">
          <div>
            <label className="text-[11px] font-mono uppercase tracking-wider text-secondary block mb-1">
              Email Identity
            </label>
            <div className="relative flex items-center">
              <Mail
                style={{
                  position: 'absolute',
                  left: '0.85rem',
                  width: '1rem',
                  height: '1rem',
                  color: 'var(--text-muted)'
                }}
              />
              <input
                type="email"
                className="tess-input"
                style={{ paddingLeft: '2.5rem' }}
                placeholder="identity@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoCapitalize="none"
                autoCorrect="off"
                required
              />
            </div>
          </div>

          <div>
            <label className="text-[11px] font-mono uppercase tracking-wider text-secondary block mb-1">
              Passkey / Password
            </label>
            <div className="relative flex items-center">
              <Lock
                style={{
                  position: 'absolute',
                  left: '0.85rem',
                  width: '1rem',
                  height: '1rem',
                  color: 'var(--text-muted)'
                }}
              />
              <input
                type="password"
                className="tess-input"
                style={{ paddingLeft: '2.5rem' }}
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
          </div>

          <button
            type="submit"
            className="btn-primary w-full justify-center mt-3 py-2.5"
            disabled={loading}
          >
            <span>{loading ? 'Authenticating...' : isSignUp ? 'Create TESS Account' : 'Sign In'}</span>
            <ArrowRight style={{ width: '0.9rem', height: '0.9rem' }} />
          </button>
        </form>

        <div className="mt-6 text-xs text-muted font-medium">
          {isSignUp ? 'Already registered? ' : "New companion instance? "}
          <button
            onClick={() => {
              setIsSignUp(!isSignUp);
              setError(null);
            }}
            className="font-semibold text-accent cursor-pointer hover:underline"
            style={{ background: 'none', border: 'none', padding: 0 }}
          >
            {isSignUp ? 'Sign In' : 'Sign Up'}
          </button>
        </div>
      </div>
    </div>
  );
};
