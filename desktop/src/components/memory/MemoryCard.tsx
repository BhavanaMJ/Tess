import React, { useState } from 'react';
import { Memory } from '../../types';
import {
  Star,
  CheckCircle2,
  AlertCircle,
  Edit2,
  Trash2,
  Check,
  X,
  Sparkles,
  ExternalLink,
  ShieldCheck
} from 'lucide-react';

interface MemoryCardProps {
  memory: Memory;
  onUpdate: (id: string, updates: Partial<Memory>) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
  onInspect: (memory: Memory) => void;
}

export const MemoryCard: React.FC<MemoryCardProps> = ({
  memory,
  onUpdate,
  onDelete,
  onInspect
}) => {
  const [isEditing, setIsEditing] = useState(false);
  const [draftContent, setDraftContent] = useState(memory.content);
  const [saving, setSaving] = useState(false);

  const handleSaveEdit = async () => {
    if (!draftContent.trim() || draftContent === memory.content) {
      setIsEditing(false);
      return;
    }
    setSaving(true);
    try {
      await onUpdate(memory.id, { content: draftContent.trim() });
      setIsEditing(false);
    } finally {
      setSaving(false);
    }
  };

  const handleToggleConfirm = async () => {
    const nextVal = memory.is_confirmed === false ? true : false;
    await onUpdate(memory.id, { is_confirmed: nextVal });
  };

  const getCategoryColor = (cat: string) => {
    switch (cat.toLowerCase()) {
      case 'preference':
        return { bg: 'rgba(139, 92, 246, 0.12)', color: '#A78BFA', border: 'rgba(139, 92, 246, 0.3)' };
      case 'goal':
        return { bg: 'rgba(34, 211, 238, 0.12)', color: '#22D3EE', border: 'rgba(34, 211, 238, 0.3)' };
      case 'project':
        return { bg: 'rgba(52, 211, 153, 0.12)', color: '#34D399', border: 'rgba(52, 211, 153, 0.3)' };
      case 'workflow':
        return { bg: 'rgba(251, 191, 36, 0.12)', color: '#FBBF24', border: 'rgba(251, 191, 36, 0.3)' };
      case 'commitment':
        return { bg: 'rgba(251, 113, 133, 0.12)', color: '#FB7185', border: 'rgba(251, 113, 133, 0.3)' };
      default:
        return { bg: 'rgba(255, 255, 255, 0.08)', color: 'var(--text-secondary)', border: 'var(--border)' };
    }
  };

  const catStyle = getCategoryColor(memory.category);
  const isConfirmed = memory.is_confirmed !== false;

  return (
    <div className="tess-card p-4 flex flex-col md:flex-row items-start md:items-center justify-between gap-3 transition-all hover:border-[rgba(139,92,246,0.35)]">
      <div className="flex items-start gap-3 flex-1 min-w-0 pr-2">
        {/* Category Pill */}
        <span
          className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-md uppercase tracking-wider shrink-0 mt-0.5"
          style={{
            backgroundColor: catStyle.bg,
            color: catStyle.color,
            border: `1px solid ${catStyle.border}`
          }}
        >
          {memory.category}
        </span>

        {/* Content Body */}
        <div className="flex-1 min-w-0">
          {isEditing ? (
            <div className="flex items-center gap-2">
              <input
                type="text"
                className="tess-input text-xs py-1 flex-1"
                value={draftContent}
                onChange={(e) => setDraftContent(e.target.value)}
                disabled={saving}
                autoFocus
              />
              <button
                type="button"
                onClick={handleSaveEdit}
                disabled={saving}
                className="p-1.5 rounded bg-[rgba(52,211,153,0.15)] text-[#34D399] border border-[rgba(52,211,153,0.3)] cursor-pointer"
                title="Save changes"
              >
                <Check style={{ width: '0.85rem', height: '0.85rem' }} />
              </button>
              <button
                type="button"
                onClick={() => {
                  setDraftContent(memory.content);
                  setIsEditing(false);
                }}
                className="p-1.5 rounded text-muted hover:text-primary cursor-pointer"
                style={{ background: 'none', border: 'none' }}
                title="Cancel"
              >
                <X style={{ width: '0.85rem', height: '0.85rem' }} />
              </button>
            </div>
          ) : (
            <div
              onClick={() => onInspect(memory)}
              className="text-xs font-medium text-primary leading-relaxed cursor-pointer hover:text-accent transition-colors"
            >
              {memory.content}
            </div>
          )}

          {/* Meta Details Row */}
          <div className="flex items-center gap-3 mt-1.5 text-[10px] font-mono text-muted flex-wrap">
            {/* Importance Level */}
            <span className="flex items-center gap-1 text-[#FBBF24]">
              <Star style={{ width: '0.7rem', height: '0.7rem', fill: '#FBBF24' }} />
              LVL {memory.importance || 3}
            </span>

            {/* Provenance */}
            {memory.provenance && (
              <span className="text-muted">
                SOURCE: {memory.provenance}
              </span>
            )}

            {/* Confirmation Toggle */}
            <button
              type="button"
              onClick={handleToggleConfirm}
              className="flex items-center gap-1 cursor-pointer transition-colors"
              style={{
                color: isConfirmed ? '#34D399' : 'var(--text-muted)',
                background: 'none',
                border: 'none',
                padding: 0
              }}
              title={isConfirmed ? 'Click to mark as unconfirmed' : 'Click to confirm this fact'}
            >
              <CheckCircle2 style={{ width: '0.75rem', height: '0.75rem' }} />
              <span>{isConfirmed ? 'CONFIRMED' : 'UNCONFIRMED'}</span>
            </button>

            {/* Date */}
            {memory.created_at && (
              <span className="text-muted">
                {new Date(memory.created_at).toLocaleDateString()}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Action Controls */}
      <div className="flex items-center gap-1.5 shrink-0 self-end md:self-center">
        <button
          type="button"
          onClick={() => onInspect(memory)}
          className="p-1.5 rounded text-muted hover:text-primary transition-colors cursor-pointer"
          style={{ background: 'none', border: 'none' }}
          title="Inspect details & continuity context"
        >
          <ExternalLink style={{ width: '0.85rem', height: '0.85rem' }} />
        </button>

        <button
          type="button"
          onClick={() => {
            setDraftContent(memory.content);
            setIsEditing(true);
          }}
          className="p-1.5 rounded text-muted hover:text-primary transition-colors cursor-pointer"
          style={{ background: 'none', border: 'none' }}
          title="Edit memory text"
        >
          <Edit2 style={{ width: '0.85rem', height: '0.85rem' }} />
        </button>

        <button
          type="button"
          onClick={() => onDelete(memory.id)}
          className="p-1.5 rounded text-muted hover:text-[#FB7185] transition-colors cursor-pointer"
          style={{ background: 'none', border: 'none' }}
          title="Delete memory"
        >
          <Trash2 style={{ width: '0.85rem', height: '0.85rem' }} />
        </button>
      </div>
    </div>
  );
};
