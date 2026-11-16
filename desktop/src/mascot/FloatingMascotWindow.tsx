import React, { useEffect, useRef, useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { useMascot } from '../contexts/MascotContext';
import { Mascot } from '../components/Mascot';
import { ExternalLink, X, Move, EyeOff, MessageSquare } from 'lucide-react';

const POS_STORAGE_KEY = 'tess_mascot_pos';

export const FloatingMascotWindow: React.FC = () => {
  const { state, message, setMessage, focusMainWindow, setFloatingVisible, themeColor, animationLevel, stage, quietMode } = useMascot();
  const [showMenu, setShowMenu] = useState(false);
  
  const isDraggingRef = useRef(false);
  const dragStartRef = useRef<{ screenX: number; screenY: number; winX: number; winY: number } | null>(null);
  const currentPosRef = useRef<{ x: number; y: number }>({ x: 1720, y: 820 });

  // Set transparency class on HTML & body for native frameless window rendering
  useEffect(() => {
    document.documentElement.classList.add('mascot-window');
    document.body.classList.add('mascot-window');

    // Restore persisted position
    try {
      const saved = localStorage.getItem(POS_STORAGE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (typeof parsed.x === 'number' && typeof parsed.y === 'number') {
          currentPosRef.current = parsed;
          invoke('set_mascot_position', { x: parsed.x, y: parsed.y }).catch(() => {});
        }
      } else {
        invoke<[number, number]>('get_mascot_position')
          .then(([x, y]) => {
            currentPosRef.current = { x, y };
          })
          .catch(() => {});
      }
    } catch (_) {}

    return () => {
      document.documentElement.classList.remove('mascot-window');
      document.body.classList.remove('mascot-window');
    };
  }, []);

  const handlePointerDown = async (e: React.PointerEvent) => {
    if (e.button !== 0) return; // Left click only for dragging/clicking
    e.preventDefault();

    try {
      (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    } catch (_) {}

    // Refresh current native window position before drag starts
    try {
      const [x, y] = await invoke<[number, number]>('get_mascot_position');
      currentPosRef.current = { x, y };
    } catch (_) {}

    dragStartRef.current = {
      screenX: e.screenX,
      screenY: e.screenY,
      winX: currentPosRef.current.x,
      winY: currentPosRef.current.y
    };
    isDraggingRef.current = false;
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!dragStartRef.current) return;
    const dx = e.screenX - dragStartRef.current.screenX;
    const dy = e.screenY - dragStartRef.current.screenY;

    if (!isDraggingRef.current && Math.hypot(dx, dy) > 4) {
      isDraggingRef.current = true;
    }

    if (isDraggingRef.current) {
      const newX = Math.round(dragStartRef.current.winX + dx);
      const newY = Math.round(dragStartRef.current.winY + dy);
      currentPosRef.current = { x: newX, y: newY };
      invoke('set_mascot_position', { x: newX, y: newY }).catch(() => {});
    }
  };

  const handlePointerUp = (e: React.PointerEvent) => {
    if (!dragStartRef.current) return;
    try {
      (e.currentTarget as HTMLElement).releasePointerCapture(e.pointerId);
    } catch (_) {}

    const wasDragging = isDraggingRef.current;
    const finalPos = currentPosRef.current;
    dragStartRef.current = null;
    isDraggingRef.current = false;

    if (wasDragging) {
      // Save position to localStorage
      try {
        localStorage.setItem(POS_STORAGE_KEY, JSON.stringify(finalPos));
        console.log('[TESS Mascot] Persisted position:', finalPos);
      } catch (_) {}
    } else if (e.button === 0) {
      // Click detected
      console.log('[TESS Mascot] Mascot clicked, opening main window...');
      focusMainWindow();
    }
  };

  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setShowMenu((prev) => !prev);
  };

  const handleDismissMessage = (e: React.MouseEvent) => {
    e.stopPropagation();
    setMessage(null);
  };

  return (
    <div
      className="w-full h-full p-2 flex flex-col items-center justify-center select-none bg-transparent"
      onClick={() => setShowMenu(false)}
    >
      <div
        onClick={() => {
          if (!isDraggingRef.current) {
            focusMainWindow();
          }
        }}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        onContextMenu={handleContextMenu}
        className="group relative cursor-pointer bg-[#181824]/95 backdrop-blur-md border border-[#2D2D3F] hover:border-[#8B5CF6] rounded-3xl p-3 shadow-2xl flex flex-col items-center transition-all duration-200 hover:scale-105"
        title="Left click to open TESS, Drag to move, Right click for options"
      >
        {/* Subtle drag handle indicator */}
        <div
          data-tauri-drag-region
          className="absolute top-1.5 p-1 cursor-grab active:cursor-grabbing opacity-30 group-hover:opacity-80 transition-opacity"
          title="Drag to move mascot"
        >
          <Move className="w-3 h-3 text-[#A1A1AA] pointer-events-none" />
        </div>

        <div className="mt-2 pointer-events-none">
          <Mascot
            state={quietMode ? 'RESTING' : state}
            size="md"
            showLabel={false}
            themeColor={themeColor}
            animationLevel={animationLevel}
            stage={stage}
          />
        </div>

        <div className="mt-2 flex items-center gap-1 text-[10px] font-medium text-[#A1A1AA] group-hover:text-[#8B5CF6] pointer-events-none">
          <span>TESS</span>
          <ExternalLink className="w-2.5 h-2.5 opacity-60 group-hover:opacity-100" />
        </div>

        {/* Floating contextual message bubble */}
        {message && (
          <div
            onClick={(e) => e.stopPropagation()}
            className="absolute -top-12 left-1/2 -translate-x-1/2 w-48 bg-[#1E1E2E] text-[#E4E4E7] border border-[#8B5CF6]/50 rounded-xl px-2.5 py-1.5 text-[11px] shadow-xl flex items-start justify-between gap-1 z-50 animate-fade-in"
          >
            <span className="truncate">{message}</span>
            <button
              onClick={handleDismissMessage}
              className="text-[#71717A] hover:text-[#FFFFFF] p-0.5 rounded"
            >
              <X className="w-3 h-3" />
            </button>
          </div>
        )}

        {/* Right-click Context Menu */}
        {showMenu && (
          <div
            onClick={(e) => e.stopPropagation()}
            className="absolute top-full mt-2 w-44 bg-[#1E1E2E] border border-[#2D2D3F] rounded-xl shadow-2xl p-1 z-50 text-xs flex flex-col gap-0.5 animate-fade-in"
          >
            <button
              onClick={() => {
                setShowMenu(false);
                focusMainWindow();
              }}
              className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg text-[#E4E4E7] hover:bg-[#8B5CF6]/20 hover:text-[#FFFFFF] transition-colors text-left"
            >
              <ExternalLink className="w-3.5 h-3.5 text-[#8B5CF6]" />
              <span>Open TESS</span>
            </button>
            <button
              onClick={() => {
                setShowMenu(false);
                focusMainWindow();
              }}
              className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg text-[#E4E4E7] hover:bg-[#8B5CF6]/20 hover:text-[#FFFFFF] transition-colors text-left"
            >
              <MessageSquare className="w-3.5 h-3.5 text-[#3B82F6]" />
              <span>Chat</span>
            </button>
            <button
              onClick={() => {
                setShowMenu(false);
                setFloatingVisible(false);
              }}
              className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg text-[#E4E4E7] hover:bg-[#EF4444]/20 hover:text-[#EF4444] transition-colors text-left"
            >
              <EyeOff className="w-3.5 h-3.5" />
              <span>Hide Mascot</span>
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

