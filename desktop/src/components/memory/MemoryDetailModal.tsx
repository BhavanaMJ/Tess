import React, { useEffect, useState } from 'react';
import { Memory } from '../../types';
import {
  X,
  Brain,
  Star,
  CheckCircle2,
  Trash2,
  Check,
  ShieldCheck,
  Terminal,
  Sparkles
} from 'lucide-react';

interface MemoryDetailModalProps {
  memory: Memory | null;
  isOpen: boolean;
  onClose: () => void;
  onUpdate: (id: string, updates: Partial<Memory>) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
}

export const MemoryDetailModal: React.FC<MemoryDetailModalProps> = ({
  memory,
  isOpen,
  onClose,
  onUpdate,
  onDelete
}) => {
  const [content, setContent] = useState('');
  const [category, setCategory] = useState('');
  const [importance, setImportance] = useState(3);
  const [isConfirmed, setIsConfirmed] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (memory) {
      setContent(memory.content);
      setCategory(memory.category);
      setImportance(memory.importance || 3);
      setIsConfirmed(memory.is_confirmed !== false);
    }
  }, [memory]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) onClose();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen || !memory) return null;

  const handleSave = async () => {
    setSaving(true);
    try {
      await onUpdate(memory.id, {
        content: content.trim(),
        category,
        importance,
        is_confirmed: isConfirmed
      });
      onClose();
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (confirm('Delete this memory from TESS long-term knowledge store?')) {
      await onDelete(memory.id);
      onClose();
    }
  };

  return (
    <div
      className="fixed inset-0 flex items-center justify-center p-4 z-50 animate-fadeIn"
      style={{ backgroundColor: 'rgba(0, 0, 0, 0.75)', backdropFilter: 'blur(6px)' }}
      onClick={onClose}
    >
      <div
        className="tess-card w-full max-w-xl max-h-[85vh] flex flex-col overflow-hidden shadow-2xl animate-scaleUp"
        style={{
          backgroundColor: 'var(--bg-primary)',
          borderColor: 'rgba(139, 92, 246, 0.4)'
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Header */}
        <div className="p-5 border-b border-[rgba(255,255,255,0.08)] flex items-start justify-between gap-4">
          <div className="flex items-center gap-3">
            <div
              className="p-2.5 rounded-xl shrink-0"
              style={{
                backgroundColor: 'rgba(139, 92, 246, 0.15)',
                color: '#A78BFA',
                border: '1px solid rgba(139, 92, 246, 0.3)'
              }}
            >
              <Brain style={{ width: '1.25rem', height: '1.25rem' }} />
            </div>
            <div>
              <div className="font-mono text-[10px] text-muted uppercase tracking-wider">
                Memory Item #{memory.id.slice(0, 8)}
              </div>
              <h3 className="text-base font-bold text-primary tracking-tight m-0">
                Cognitive Continuity Inspector
              </h3>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg text-muted hover:text-primary transition-colors cursor-pointer"
            style={{ background: 'none', border: 'none' }}
          >
            <X style={{ width: '1.2rem', height: '1.2rem' }} />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-5 overflow-y-auto flex-1 flex flex-col gap-4">
          {/* Content Field */}
          <div>
            <label className="text-xs font-mono text-muted uppercase tracking-wider block mb-1.5">
              Knowledge Content:
            </label>
            <textarea
              className="tess-input text-xs w-full p-3 resize-none"
              rows={3}
              value={content}
              onChange={(e) => setContent(e.target.value)}
            />
          </div>

          {/* Category & Importance */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-mono text-muted uppercase tracking-wider block mb-1.5">
                Category:
              </label>
              <select
                className="tess-input text-xs w-full font-mono"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              >
                <option value="preference">Preference</option>
                <option value="goal">Goal</option>
                <option value="project">Project Context</option>
                <option value="workflow">Workflow</option>
                <option value="commitment">Commitment</option>
                <option value="routine">Routine</option>
                <option value="fact">Personal Fact</option>
              </select>
            </div>

            <div>
              <label className="text-xs font-mono text-muted uppercase tracking-wider block mb-1.5">
                Importance Level:
              </label>
              <select
                className="tess-input text-xs w-full font-mono"
                value={importance}
                onChange={(e) => setImportance(Number(e.target.value))}
              >
                <option value={1}>1 (Low)</option>
                <option value={2}>2 (Normal)</option>
                <option value={3}>3 (High)</option>
                <option value={4}>4 (Critical)</option>
                <option value={5}>5 (Core Directive)</option>
              </select>
            </div>
          </div>

          {/* Confirmation Toggle */}
          <div className="p-3 rounded-xl bg-secondary flex items-center justify-between text-xs">
            <div>
              <div className="font-semibold text-primary">Confirmation Status</div>
              <div className="text-[11px] text-muted">
                {isConfirmed ? 'Verified personal truth used in AI context' : 'Marked as unverified / tentative'}
              </div>
            </div>
            <label className="flex items-center gap-2 cursor-pointer">
              <span className="font-mono text-xs font-bold" style={{ color: isConfirmed ? '#34D399' : '#FB7185' }}>
                {isConfirmed ? 'CONFIRMED' : 'UNCONFIRMED'}
              </span>
              <input
                type="checkbox"
                checked={isConfirmed}
                onChange={(e) => setIsConfirmed(e.target.checked)}
                style={{ accentColor: '#34D399', width: '1.1rem', height: '1.1rem' }}
              />
            </label>
          </div>

          {/* AI Continuity Context Preview */}
          <div className="p-3.5 rounded-xl border border-[rgba(139,92,246,0.3)] bg-[rgba(139,92,246,0.06)]">
            <div className="flex items-center gap-2 text-xs font-bold text-accent mb-1 font-mono uppercase">
              <Sparkles style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>Prompt Continuity Formatting</span>
            </div>
            <pre className="font-mono text-[11px] p-2 rounded bg-[rgba(0,0,0,0.4)] text-secondary overflow-x-auto m-0 leading-relaxed">
              {`- [${category.toUpperCase()}] ${content} (Importance: ${importance}/5, Confirmed: ${isConfirmed})`}
            </pre>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="p-4 border-t border-[rgba(255,255,255,0.08)] bg-[rgba(0,0,0,0.2)] flex items-center justify-between gap-3">
          <button
            type="button"
            onClick={handleDelete}
            className="btn-danger text-xs"
          >
            <Trash2 style={{ width: '0.85rem', height: '0.85rem' }} />
            <span>Delete Memory</span>
          </button>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onClose}
              className="btn-secondary text-xs"
            >
              <span>Cancel</span>
            </button>
            <button
              type="button"
              onClick={handleSave}
              disabled={saving || !content.trim()}
              className="btn-primary text-xs"
            >
              <Check style={{ width: '0.85rem', height: '0.85rem' }} />
              <span>{saving ? 'Updating...' : 'Save Changes'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

