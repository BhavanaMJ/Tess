import React from 'react';
import { MascotState } from '../types';

interface MascotProps {
  state: MascotState;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showLabel?: boolean;
  themeColor?: string;
  animationLevel?: 'MINIMAL' | 'NORMAL' | 'LIVELY';
  stage?: number;
  className?: string;
}

export const getMascotDetails = (state: MascotState) => {
  switch (state) {
    case 'HAPPY':
      return { face: '^_^', color: '#10B981', label: 'Happy', pulse: false };
    case 'CURIOUS':
      return { face: 'o_O?', color: '#06B6D4', label: 'Curious', pulse: true };
    case 'LISTENING':
      return { face: 'O_o', color: '#3B82F6', label: 'Listening...', pulse: true };
    case 'THINKING':
      return { face: 'O_O', color: '#8B5CF6', label: 'Thinking...', pulse: true };
    case 'SPEAKING':
      return { face: '^o^', color: '#10B981', label: 'Speaking...', pulse: true };
    case 'VIEWING':
      return { face: '◉_◉', color: '#06B6D4', label: 'Viewing Screen', pulse: true };
    case 'BROWSING':
      return { face: '•‿•', color: '#F59E0B', label: 'Browsing Web', pulse: true };
    case 'READING':
      return { face: '•_•', color: '#6366F1', label: 'Reading Document', pulse: true };
    case 'ATTENTION':
      return { face: 'O_O!', color: '#EF4444', label: 'Needs Attention', pulse: true };
    case 'INTERVENING':
      return { face: 'O_O!', color: '#F59E0B', label: 'Intervention', pulse: true };
    case 'PLANNING':
      return { face: '-_-', color: '#8B5CF6', label: 'Planning', pulse: false };
    case 'CONFIRMING':
      return { face: '?_?', color: '#F59E0B', label: 'Requires Confirmation', pulse: true };
    case 'ACTING':
      return { face: '-_-', color: '#8B5CF6', label: 'Executing Action', pulse: true };
    case 'SUCCESS':
      return { face: '^_^!!', color: '#10B981', label: 'Completed', pulse: false };
    case 'ERROR':
      return { face: 'X_X', color: '#EF4444', label: 'Error Occurred', pulse: false };
    case 'RESTING':
    case 'SLEEPING':
      return { face: 'u_u', color: '#6B7280', label: 'Resting', pulse: false };
    case 'IDLE':
    default:
      return { face: '•_•', color: '#8B5CF6', label: 'Idle', pulse: false };
  }
};

export const Mascot: React.FC<MascotProps> = ({
  state,
  size = 'md',
  showLabel = false,
  themeColor,
  animationLevel = 'NORMAL',
  stage = 1,
  className = ''
}) => {
  const details = getMascotDetails(state);
  const color = (state === 'IDLE' || state === 'PLANNING') && themeColor ? themeColor : details.color;
  const isAnimated = animationLevel !== 'MINIMAL';

  const pixelDimensions = {
    sm: { box: 38, core: 26, font: '0.65rem' },
    md: { box: 64, core: 44, font: '0.95rem' },
    lg: { box: 96, core: 68, font: '1.35rem' },
    xl: { box: 140, core: 98, font: '1.85rem' }
  }[size];

  const stageBadge = stage === 2 ? '✦' : stage === 3 ? '★' : null;

  return (
    <div
      className={`flex flex-col items-center justify-center relative select-none ${className}`}
      style={{ '--mascot-glow-color': color } as React.CSSProperties}
    >
      <div
        className="relative flex items-center justify-center"
        style={{
          width: `${pixelDimensions.box}px`,
          height: `${pixelDimensions.box}px`
        }}
      >
        {/* Outer Orbital Holographic Ring */}
        {isAnimated && (
          <svg
            className="absolute inset-0 w-full h-full pointer-events-none animate-orbital-cw"
            viewBox="0 0 100 100"
            style={{
              opacity: state === 'RESTING' ? 0.2 : 0.65,
              animationDuration: state === 'ACTING' || state === 'THINKING' ? '4s' : '14s'
            }}
          >
            <circle
              cx="50"
              cy="50"
              r="46"
              fill="none"
              stroke={color}
              strokeWidth="1.5"
              strokeDasharray="18 12 6 12"
              strokeOpacity="0.8"
            />
            <circle cx="50" cy="4" r="2.5" fill={color} />
            <circle cx="96" cy="50" r="1.5" fill="#22D3EE" />
          </svg>
        )}

        {/* Inner Counter-Rotating Ring */}
        {isAnimated && size !== 'sm' && (
          <svg
            className="absolute inset-0 w-full h-full pointer-events-none animate-orbital-ccw"
            viewBox="0 0 100 100"
            style={{
              transform: 'scale(0.8)',
              opacity: state === 'RESTING' ? 0.15 : 0.45,
              animationDuration: '9s'
            }}
          >
            <circle
              cx="50"
              cy="50"
              r="44"
              fill="none"
              stroke="#22D3EE"
              strokeWidth="1"
              strokeDasharray="30 20"
              strokeOpacity="0.7"
            />
          </svg>
        )}

        {/* Ambient Holographic Core with Breathing Glow */}
        <div
          className={`relative flex items-center justify-center rounded-full transition-all duration-300 ${
            isAnimated ? 'animate-orb-breathing' : ''
          }`}
          style={{
            width: `${pixelDimensions.core}px`,
            height: `${pixelDimensions.core}px`,
            background: `radial-gradient(circle at 35% 35%, ${color}33 0%, #0B0D18 80%)`,
            border: `1.5px solid ${color}`,
            boxShadow: `0 0 ${stage >= 3 ? '26px' : '16px'} ${color}55, inset 0 0 14px ${color}33`
          }}
        >
          {/* Digital Expression Face */}
          <span
            className="font-mono font-bold tracking-wider select-none z-10"
            style={{
              color,
              fontSize: pixelDimensions.font,
              textShadow: `0 0 8px ${color}`
            }}
          >
            {details.face}
          </span>

          {/* Attention / Intervening Marker */}
          {(state === 'ATTENTION' || state === 'INTERVENING' || state === 'CONFIRMING') && (
            <span
              className="absolute -top-1 -right-1 w-3 h-3 rounded-full border-2 border-[#080910] animate-pulse"
              style={{
                backgroundColor: color,
                boxShadow: `0 0 8px ${color}`
              }}
            />
          )}

          {/* Evolutionary Stage Badge */}
          {stageBadge && (
            <span
              className="absolute -bottom-1 -right-1 text-xs select-none"
              style={{
                color: stage === 3 ? '#F59E0B' : '#A78BFA',
                filter: `drop-shadow(0 0 4px ${color})`
              }}
            >
              {stageBadge}
            </span>
          )}
        </div>
      </div>

      {showLabel && (
        <div className="flex items-center gap-1.5 mt-2">
          <span
            className="w-1.5 h-1.5 rounded-full"
            style={{ backgroundColor: color, boxShadow: `0 0 6px ${color}` }}
          />
          <span
            className="font-mono text-xs font-semibold tracking-wider uppercase"
            style={{ color: 'var(--text-secondary)' }}
          >
            {details.label}
          </span>
        </div>
      )}
    </div>
  );
};
