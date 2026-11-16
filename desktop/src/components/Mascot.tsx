import React from 'react';
import { MascotState } from '../types';

interface MascotProps {
  state: MascotState;
  size?: 'sm' | 'md' | 'lg';
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
  const pulse = animationLevel === 'MINIMAL' ? false : details.pulse;

  const sizeClasses = {
    sm: 'w-10 h-10 text-xs',
    md: 'w-16 h-16 text-base',
    lg: 'w-24 h-24 text-2xl'
  }[size];

  const stageBadge = stage === 2 ? '✦' : stage === 3 ? '★' : null;

  return (
    <div className={`flex flex-col items-center justify-center ${className}`}>
      <div
        className={`relative flex items-center justify-center rounded-2xl border-2 transition-all duration-300 ${sizeClasses} ${
          pulse ? 'animate-pulse' : ''
        } ${animationLevel === 'LIVELY' && pulse ? 'scale-105' : ''}`}
        style={{
          borderColor: color,
          backgroundColor: `${color}15`,
          boxShadow: stage >= 3 ? `0 0 24px ${color}50, inset 0 0 12px ${color}20` : `0 0 16px ${color}30`
        }}
      >
        <span
          className="font-mono font-bold tracking-wider select-none"
          style={{ color }}
        >
          {details.face}
        </span>
        {state === 'ATTENTION' || state === 'INTERVENING' || state === 'CONFIRMING' ? (
          <span
            className="absolute -top-1 -right-1 w-3 h-3 rounded-full border-2 border-[#12121A]"
            style={{ backgroundColor: color }}
          />
        ) : null}
        {stageBadge && (
          <span
            className="absolute -bottom-1 -right-1 text-[10px] px-1 rounded-full font-bold bg-[#12121A] border"
            style={{ color, borderColor: color }}
            title={`Stage ${stage}`}
          >
            {stageBadge}
          </span>
        )}
      </div>
      {showLabel && (
        <span
          className="mt-2 text-xs font-medium px-2 py-0.5 rounded-full"
          style={{ color, backgroundColor: `${color}20` }}
        >
          {details.label}
        </span>
      )}
    </div>
  );
};
