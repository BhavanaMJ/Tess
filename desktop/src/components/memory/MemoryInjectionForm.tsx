import React from 'react';
import { Brain, Plus, Sparkles } from 'lucide-react';

interface MemoryInjectionFormProps {
  category: string;
  onCategoryChange: (cat: string) => void;
  importance: number;
  onImportanceChange: (lvl: number) => void;
  content: string;
  onContentChange: (val: string) => void;
  onSubmit: (e: React.FormEvent) => void;
  creating: boolean;
}

export const MemoryInjectionForm: React.FC<MemoryInjectionFormProps> = ({
  category,
  onCategoryChange,
  importance,
  onImportanceChange,
  content,
  onContentChange,
  onSubmit,
  creating
}) => {
  const starters = [
    { text: 'I work best in 90-minute morning focus blocks', cat: 'preference', lvl: 4 },
    { text: 'Prioritize OpenProject tasks with high risk of overdue', cat: 'workflow', lvl: 4 },
    { text: 'Target Q4 feature freeze deadline on Dec 15', cat: 'goal', lvl: 5 },
    { text: 'Work hours are 09:00 to 18:00 UTC with weekend quiet mode', cat: 'routine', lvl: 3 }
  ];

  return (
    <div
      className="tess-card p-5 mb-6"
      style={{
        background: 'linear-gradient(135deg, rgba(139, 92, 246, 0.08) 0%, rgba(17, 20, 38, 0.95) 100%)',
        borderColor: 'rgba(139, 92, 246, 0.35)'
      }}
    >
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <Brain style={{ width: '1.15rem', height: '1.15rem', color: '#A78BFA' }} />
          <h3 className="text-sm font-bold text-primary tracking-wide font-mono uppercase m-0">
            Cognitive Knowledge Core: Inject Memory
          </h3>
        </div>
        <span className="text-[10px] font-mono text-muted">
          Persisted Across All Connected Devices
        </span>
      </div>

      <form onSubmit={onSubmit} className="flex flex-col gap-3">
        <div className="flex flex-col md:flex-row gap-3">
          <select
            className="tess-input text-xs font-mono"
            style={{ width: '180px' }}
            value={category}
            onChange={(e) => onCategoryChange(e.target.value)}
          >
            <option value="preference">Preference</option>
            <option value="goal">Goal</option>
            <option value="project">Project Context</option>
            <option value="workflow">Workflow</option>
            <option value="commitment">Commitment</option>
            <option value="routine">Routine</option>
            <option value="fact">Personal Fact</option>
          </select>

          <select
            className="tess-input text-xs font-mono"
            style={{ width: '160px' }}
            value={importance}
            onChange={(e) => onImportanceChange(Number(e.target.value))}
          >
            <option value={1}>Importance: 1 (Low)</option>
            <option value={2}>Importance: 2 (Normal)</option>
            <option value={3}>Importance: 3 (High)</option>
            <option value={4}>Importance: 4 (Critical)</option>
            <option value={5}>Importance: 5 (Core Directive)</option>
          </select>

          <input
            type="text"
            className="tess-input text-xs flex-1"
            placeholder="e.g. 'I work best in 90-minute blocks without notifications' or 'Focus on Q4 launch'"
            value={content}
            onChange={(e) => onContentChange(e.target.value)}
            disabled={creating}
          />

          <button
            type="submit"
            disabled={!content.trim() || creating}
            className="btn-primary text-xs shrink-0"
          >
            <Plus style={{ width: '0.85rem', height: '0.85rem' }} />
            <span>{creating ? 'Encoding...' : 'Save Memory'}</span>
          </button>
        </div>

        {/* Suggestion Starters */}
        <div className="flex items-center gap-2 flex-wrap pt-1 text-[11px]">
          <span className="text-muted font-mono text-[10px]">Templates:</span>
          {starters.map((s) => (
            <button
              key={s.text}
              type="button"
              onClick={() => {
                onContentChange(s.text);
                onCategoryChange(s.cat);
                onImportanceChange(s.lvl);
              }}
              className="px-2 py-0.5 rounded-md font-mono text-[10px] transition-all cursor-pointer hover:border-[rgba(139,92,246,0.4)]"
              style={{
                backgroundColor: 'rgba(255, 255, 255, 0.04)',
                color: 'var(--text-secondary)',
                border: '1px solid rgba(255, 255, 255, 0.08)'
              }}
            >
              <span className="text-accent font-semibold mr-1">[{s.cat}]</span>
              <span>{s.text}</span>
            </button>
          ))}
        </div>
      </form>
    </div>
  );
};

