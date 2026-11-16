import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Mascot } from '../components/Mascot';
import { Lock, Mail, ArrowRight, AlertCircle } from 'lucide-react';

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

    const res = isSignUp
      ? await signUp(email, password)
      : await signIn(email, password);

    if (res.error) {
      setError(res.error);
    }
    setLoading(false);
  };

  return (
    <div
      className="w-full h-full flex items-center justify-center p-6 bg-primary"
      style={{ minHeight: '100vh' }}
    >
      <div
        className="tess-card p-8 flex flex-col items-center"
        style={{
          width: '100%',
          maxWidth: '420px',
          borderColor: 'var(--border)',
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)'
        }}
      >
        <Mascot state="IDLE" size="lg" />

        <h2 className="text-2xl font-bold mt-4 mb-1 text-primary">TESS</h2>
        <p className="text-xs text-muted mb-6 text-center">
          Sign in to your cross-device personal AI companion.
        </p>

        {error && (
          <div
            className="w-full p-3 mb-4 rounded-lg text-xs flex items-center gap-2"
            style={{ backgroundColor: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', border: '1px solid var(--border)' }}
          >
            <AlertCircle style={{ width: '1rem', height: '1rem', flexShrink: 0 }} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="w-full flex flex-col gap-3">
          <div>
            <label className="text-xs font-semibold text-secondary block mb-1">Email</label>
            <div className="relative flex items-center">
              <Mail
                style={{
                  position: 'absolute',
                  left: '0.75rem',
                  width: '1rem',
                  height: '1rem',
                  color: 'var(--text-muted)'
                }}
              />
              <input
                type="email"
                className="tess-input"
                style={{ paddingLeft: '2.25rem' }}
                placeholder="name@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-semibold text-secondary block mb-1">Password</label>
            <div className="relative flex items-center">
              <Lock
                style={{
                  position: 'absolute',
                  left: '0.75rem',
                  width: '1rem',
                  height: '1rem',
                  color: 'var(--text-muted)'
                }}
              />
              <input
                type="password"
                className="tess-input"
                style={{ paddingLeft: '2.25rem' }}
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
          </div>

          <button
            type="submit"
            className="btn-primary w-full justify-center mt-3"
            disabled={loading}
          >
            <span>{loading ? 'Authenticating...' : isSignUp ? 'Create TESS Account' : 'Sign In'}</span>
            <ArrowRight style={{ width: '0.9rem', height: '0.9rem' }} />
          </button>
        </form>

        <div className="mt-6 text-xs text-muted">
          {isSignUp ? 'Already have an account? ' : "Don't have an account? "}
          <button
            onClick={() => {
              setIsSignUp(!isSignUp);
              setError(null);
            }}
            className="font-semibold text-accent cursor-pointer"
            style={{ background: 'none', border: 'none', padding: 0 }}
          >
            {isSignUp ? 'Sign In' : 'Sign Up'}
          </button>
        </div>
      </div>
    </div>
  );
};

