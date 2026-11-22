import React from 'react';
import { Plus, Sparkles, HelpCircle, ArrowRight } from 'lucide-react';

interface AgentObjectiveFormProps {
  objective: string;
  onObjectiveChange: (value: string) => void;
  onSubmit: (e: React.FormEvent) => void;
  creating: boolean;
}

export const AgentObjectiveForm: React.FC<AgentObjectiveFormProps> = ({
  objective,
  onObjectiveChange,
  onSubmit,
  creating
}) => {
  const suggestions = [
    { label: 'Update worklog: 1.5 hours on task #42', category: 'Worklog' },
    { label: 'Prepare briefing notes for quarterly review', category: 'Calendar' },
    { label: 'Browse https://react.dev for docs updates', category: 'Web' },
    { label: 'Send email to team@project.org', category: 'Email' }
  ];

  return (
    <div
      className="tess-card p-4 mb-5"
      style={{
        background: 'linear-gradient(135deg, rgba(139, 92, 246, 0.08) 0%, rgba(17, 20, 38, 0.95) 100%)',
        borderColor: 'rgba(139, 92, 246, 0.35)'
      }}
    >
      <div className="flex items-center justify-between mb-2.5">
        <div className="flex items-center gap-2">
          <Sparkles style={{ width: '1rem', height: '1rem', color: '#A78BFA' }} />
          <h3 className="text-xs font-bold text-primary font-mono uppercase tracking-wider m-0">
            Dispatch Autonomous Agent Objective
          </h3>
        </div>
        <span className="text-[10px] font-mono text-muted">
          Multi-Step Tool Orchestration
        </span>
      </div>

      <form onSubmit={onSubmit} className="flex flex-col gap-2.5">
        <div className="flex gap-2">
          <input
            type="text"
            className="tess-input text-xs flex-1"
            placeholder="e.g. 'Update worklog: 2 hours on task #101' or 'Prepare briefing for meeting'"
            value={objective}
            onChange={(e) => onObjectiveChange(e.target.value)}
            disabled={creating}
          />
          <button
            type="submit"
            disabled={!objective.trim() || creating}
            className="btn-primary text-xs shrink-0"
          >
            <Plus style={{ width: '0.85rem', height: '0.85rem' }} />
            <span>{creating ? 'Formulating Plan...' : 'Generate Agent Plan'}</span>
          </button>
        </div>

        {/* Suggested Objective Starters */}
        <div className="flex items-center gap-2 flex-wrap pt-1 text-[11px]">
          <span className="text-muted font-mono text-[10px]">Starters:</span>
          {suggestions.map((s) => (
            <button
              key={s.label}
              type="button"
              onClick={() => onObjectiveChange(s.label)}
              className="px-2 py-0.5 rounded-md font-mono text-[10px] transition-all cursor-pointer hover:border-[rgba(139,92,246,0.4)]"
              style={{
                backgroundColor: 'rgba(255, 255, 255, 0.04)',
                color: 'var(--text-secondary)',
                border: '1px solid rgba(255, 255, 255, 0.08)'
              }}
            >
              <span className="text-accent font-semibold mr-1">[{s.category}]</span>
              <span>{s.label}</span>
            </button>
          ))}
        </div>
      </form>
    </div>
  );
};
