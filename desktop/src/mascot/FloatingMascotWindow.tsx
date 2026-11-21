import React, { useEffect, useRef, useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { useMascot } from '../contexts/MascotContext';
import { Mascot } from '../components/Mascot';
import { ExternalLink, X, Move, EyeOff, MessageSquare } from 'lucide-react';

const POS_STORAGE_KEY = 'tess_mascot_pos';
// Sidebar width is 260px; 320px guarantees zero overlap with sidebar navigation or Memory Core
const MIN_SIDEBAR_CLEARANCE_X = 320;

export const FloatingMascotWindow: React.FC = () => {
  const {
    state,
    message,
    setMessage,
    focusMainWindow,
    setFloatingVisible,
    themeColor,
    animationLevel,
    stage,
    quietMode,
    openPanel
  } = useMascot();
  const [showMenu, setShowMenu] = useState(false);
  
  const isDraggingRef = useRef(false);
  const dragStartRef = useRef<{ screenX: number; screenY: number; winX: number; winY: number } | null>(null);
  const currentPosRef = useRef<{ x: number; y: number }>({ x: 1200, y: 650 });

  // Set transparency class on HTML & body for native frameless window rendering
  useEffect(() => {
    document.documentElement.classList.add('mascot-window');
    document.body.classList.add('mascot-window');

    const screenW = typeof window !== 'undefined' ? window.screen.availWidth || 1440 : 1440;
    const screenH = typeof window !== 'undefined' ? window.screen.availHeight || 900 : 900;
    const defaultSafeX = Math.max(MIN_SIDEBAR_CLEARANCE_X, screenW - 220);
    const defaultSafeY = Math.max(100, screenH - 280);

    // Restore persisted position with sidebar clearance validation
    try {
      const saved = localStorage.getItem(POS_STORAGE_KEY);
      let posX = defaultSafeX;
      let posY = defaultSafeY;

      if (saved) {
        const parsed = JSON.parse(saved);
        if (typeof parsed.x === 'number' && typeof parsed.y === 'number') {
          // Strictly clamp x so it NEVER overlaps sidebar (x >= MIN_SIDEBAR_CLEARANCE_X)
          posX = Math.max(MIN_SIDEBAR_CLEARANCE_X, Math.min(parsed.x, screenW - 160));
          posY = Math.max(60, Math.min(parsed.y, screenH - 200));
        }
      }

      currentPosRef.current = { x: posX, y: posY };
      invoke('set_mascot_position', { x: posX, y: posY }).catch(() => {});
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
      const screenW = window.screen.availWidth || 1440;
      const screenH = window.screen.availHeight || 900;
      // Clamp so mascot can NEVER be dragged into the left sidebar (x >= MIN_SIDEBAR_CLEARANCE_X)
      const rawX = Math.round(dragStartRef.current.winX + dx);
      const rawY = Math.round(dragStartRef.current.winY + dy);
      const safeX = Math.max(MIN_SIDEBAR_CLEARANCE_X, Math.min(rawX, screenW - 160));
      const safeY = Math.max(40, Math.min(rawY, screenH - 180));

      currentPosRef.current = { x: safeX, y: safeY };
      invoke('set_mascot_position', { x: safeX, y: safeY }).catch(() => {});
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
      } catch (_) {}
    } else if (e.button === 0) {
      // Click detected: focus main window and open companion panel
      focusMainWindow();
      openPanel();
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
            openPanel();
          }
        }}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        onContextMenu={handleContextMenu}
        className="group relative cursor-pointer bg-[#0B0D18]/95 backdrop-blur-md border border-[rgba(22,143,131,0.3)] hover:border-[#35B9A5] rounded-3xl p-3 shadow-2xl flex flex-col items-center transition-all duration-200 hover:scale-105"
        title="Left click to open TESS Companion, Drag to move, Right click for options"
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

        <div className="mt-2 flex items-center gap-1 text-[10px] font-medium text-[#A1A1AA] group-hover:text-[#35B9A5] pointer-events-none">
          <span>TESS</span>
          <ExternalLink className="w-2.5 h-2.5 opacity-60 group-hover:opacity-100" />
        </div>

        {/* Floating contextual message bubble */}
        {message && (
          <div
            onClick={(e) => e.stopPropagation()}
            className="absolute -top-12 left-1/2 -translate-x-1/2 w-48 bg-[#111426] text-primary border border-[rgba(53,185,165,0.4)] rounded-xl px-2.5 py-1.5 text-[11px] shadow-xl flex items-start justify-between gap-1 z-50 animate-fade-in"
          >
            <span className="truncate">{message}</span>
            <button
              onClick={handleDismissMessage}
              className="text-muted hover:text-primary p-0.5 rounded cursor-pointer"
              style={{ background: 'none', border: 'none' }}
            >
              <X className="w-3 h-3" />
            </button>
          </div>
        )}

        {/* Right-click Context Menu */}
        {showMenu && (
          <div
            onClick={(e) => e.stopPropagation()}
            className="absolute top-full mt-2 w-44 bg-[#111426] border border-[rgba(255,255,255,0.1)] rounded-xl shadow-2xl p-1 z-50 text-xs flex flex-col gap-0.5 animate-fade-in"
          >
            <button
              onClick={() => {
                setShowMenu(false);
                focusMainWindow();
                openPanel();
              }}
              className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg text-primary hover:bg-[rgba(53,185,165,0.2)] transition-colors text-left cursor-pointer"
              style={{ background: 'none', border: 'none' }}
            >
              <ExternalLink className="w-3.5 h-3.5 text-[#35B9A5]" />
              <span>Open Companion</span>
            </button>
            <button
              onClick={() => {
                setShowMenu(false);
                focusMainWindow();
              }}
              className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg text-primary hover:bg-[rgba(53,185,165,0.2)] transition-colors text-left cursor-pointer"
              style={{ background: 'none', border: 'none' }}
            >
              <MessageSquare className="w-3.5 h-3.5 text-[#22D3EE]" />
              <span>Chat</span>
            </button>
            <button
              onClick={() => {
                setShowMenu(false);
                setFloatingVisible(false);
              }}
              className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg text-primary hover:bg-[rgba(251,113,133,0.2)] hover:text-[#FB7185] transition-colors text-left cursor-pointer"
              style={{ background: 'none', border: 'none' }}
            >
              <EyeOff className="w-3.5 h-3.5 text-[#FB7185]" />
              <span>Hide Mascot</span>
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
