import React from 'react';
import { ProductivityTask } from '../../types';
import {
  X,
  Folder,
  User,
  Clock,
  Calendar,
  AlertTriangle,
  Bot,
  Copy,
  Check,
  ExternalLink
} from 'lucide-react';

interface TaskDetailModalProps {
  task: ProductivityTask | null;
  onClose: () => void;
  onDiscussWithTess?: (task: ProductivityTask) => void;
}

export const TaskDetailModal: React.FC<TaskDetailModalProps> = ({
  task,
  onClose,
  onDiscussWithTess
}) => {
  const [copied, setCopied] = React.useState(false);

  if (!task) return null;

  const isOverdue = !!task.due_date && new Date(task.due_date) < new Date();
  const isHighPriority = (task.priority || '').toUpperCase() === 'HIGH';

  const handleCopyPrompt = () => {
    const prompt = `Help me with work package #${task.external_id}: "${task.title}". Priority: ${task.priority || 'Normal'}, Status: ${task.status || 'Active'}. Description: ${task.description || 'None'}`;
    navigator.clipboard.writeText(prompt);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in"
      onClick={onClose}
    >
      <div
        className="w-full max-w-xl rounded-2xl border flex flex-col max-h-[90vh] overflow-hidden shadow-2xl"
        style={{
          backgroundColor: 'var(--bg-secondary, #0B0D18)',
          borderColor: 'var(--border, rgba(255, 255, 255, 0.12))'
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="p-5 border-b border-[rgba(255,255,255,0.08)] flex items-start justify-between gap-4">
          <div className="flex items-start gap-3 flex-1 min-w-0">
            <span className="font-mono text-xs px-2.5 py-1 rounded-lg font-bold bg-[rgba(139,92,246,0.15)] text-[#A78BFA] border border-[rgba(139,92,246,0.35)] shrink-0 mt-0.5">
              #{task.external_id}
            </span>
            <div className="min-w-0">
              <h3 className="text-base font-bold text-primary m-0 leading-snug">
                {task.title}
              </h3>
              <div className="flex items-center gap-2 mt-1.5">
                {task.status && (
                  <span className="px-2 py-0.5 rounded-md bg-[rgba(255,255,255,0.06)] text-[11px] font-mono text-secondary border border-[rgba(255,255,255,0.08)]">
                    {task.status}
                  </span>
                )}
                {task.priority && (
                  <span
                    className="text-[10px] font-mono font-bold px-2 py-0.5 rounded-full uppercase"
                    style={{
                      backgroundColor: isHighPriority ? 'rgba(251, 113, 133, 0.15)' : 'rgba(255, 255, 255, 0.04)',
                      color: isHighPriority ? '#FB7185' : 'var(--text-muted)'
                    }}
                  >
                    {task.priority} Priority
                  </span>
                )}
              </div>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg text-muted hover:text-primary hover:bg-[rgba(255,255,255,0.06)] transition-all cursor-pointer bg-transparent border-none flex-shrink-0"
            title="Close dialog"
          >
            <X style={{ width: '1.1rem', height: '1.1rem' }} />
          </button>
        </div>

        {/* Content Body */}
        <div className="p-5 overflow-y-auto space-y-5 text-xs">
          {/* Metadata Grid */}
          <div className="grid grid-cols-2 gap-3 p-3.5 rounded-xl bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.06)]">
            <div className="flex flex-col gap-1">
              <span className="text-[10px] font-mono uppercase text-muted">Project</span>
              <div className="flex items-center gap-1.5 font-medium text-secondary">
                <Folder style={{ width: '0.85rem', height: '0.85rem', color: '#22D3EE' }} />
                <span>{task.project || 'Default Workspace'}</span>
              </div>
            </div>

            <div className="flex flex-col gap-1">
              <span className="text-[10px] font-mono uppercase text-muted">Assignee</span>
              <div className="flex items-center gap-1.5 font-medium text-secondary">
                <User style={{ width: '0.85rem', height: '0.85rem', color: '#A78BFA' }} />
                <span>{task.assignee || 'Unassigned'}</span>
              </div>
            </div>

            <div className="flex flex-col gap-1">
              <span className="text-[10px] font-mono uppercase text-muted">Due Date</span>
              <div
                className="flex items-center gap-1.5 font-mono"
                style={{ color: isOverdue ? '#FB7185' : 'var(--text-secondary)' }}
              >
                {isOverdue ? (
                  <AlertTriangle style={{ width: '0.85rem', height: '0.85rem' }} />
                ) : (
                  <Clock style={{ width: '0.85rem', height: '0.85rem' }} />
                )}
                <span>{task.due_date ? new Date(task.due_date).toLocaleDateString() : 'No due date'}</span>
              </div>
            </div>

            <div className="flex flex-col gap-1">
              <span className="text-[10px] font-mono uppercase text-muted">Source Provider</span>
              <div className="flex items-center gap-1.5 font-medium text-secondary">
                <ExternalLink style={{ width: '0.85rem', height: '0.85rem', color: '#35B9A5' }} />
                <span className="capitalize">{task.source || 'OpenProject'}</span>
              </div>
            </div>
          </div>

          {/* Completion Percent Bar */}
          {typeof task.completion_percent === 'number' && (
            <div>
              <div className="flex justify-between text-[11px] font-mono mb-1.5">
                <span className="text-muted">Progress</span>
                <span className="text-[#35B9A5] font-bold">{task.completion_percent}%</span>
              </div>
              <div className="w-full h-2 rounded-full bg-[rgba(255,255,255,0.06)] overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-[#168F83] to-[#35B9A5] rounded-full transition-all"
                  style={{ width: `${task.completion_percent}%` }}
                />
              </div>
            </div>
          )}

          {/* Description */}
          <div>
            <span className="text-[11px] font-mono uppercase tracking-wider text-muted block mb-2">
              Work Package Description
            </span>
            <div className="p-3.5 rounded-xl bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.06)] text-secondary leading-relaxed whitespace-pre-wrap">
              {task.description || 'No detailed description provided for this work package.'}
            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="p-4 border-t border-[rgba(255,255,255,0.08)] flex items-center justify-between gap-3 bg-[rgba(255,255,255,0.01)]">
          <button
            type="button"
            onClick={handleCopyPrompt}
            className="btn-secondary text-xs py-2 px-3 flex items-center gap-1.5"
            title="Copy prompt with task details"
          >
            {copied ? (
              <>
                <Check style={{ width: '0.85rem', height: '0.85rem', color: '#34D399' }} />
                <span className="text-[#34D399]">Copied Prompt</span>
              </>
            ) : (
              <>
                <Copy style={{ width: '0.85rem', height: '0.85rem' }} />
                <span>Copy for TESS</span>
              </>
            )}
          </button>

          <div className="flex items-center gap-2">
            {onDiscussWithTess && (
              <button
                type="button"
                onClick={() => onDiscussWithTess(task)}
                className="btn-primary text-xs py-2 px-3.5 flex items-center gap-1.5"
              >
                <Bot style={{ width: '0.9rem', height: '0.9rem' }} />
                <span>Discuss with TESS</span>
              </button>
            )}

            <button
              type="button"
              onClick={onClose}
              className="p-2 px-3 rounded-xl border border-[rgba(255,255,255,0.1)] text-secondary hover:text-primary hover:bg-[rgba(255,255,255,0.04)] text-xs cursor-pointer bg-transparent"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
