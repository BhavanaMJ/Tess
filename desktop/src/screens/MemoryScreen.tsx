import React, { useEffect, useState } from 'react';
import { apiService } from '../services/api';
import { Memory } from '../types';
import { Brain, Plus, Trash2, Tag, Star, CheckCircle2, AlertCircle, Edit2, Check, ShieldCheck, Sparkles } from 'lucide-react';

export const MemoryScreen: React.FC = () => {
  const [memories, setMemories] = useState<Memory[]>([]);
  const [category, setCategory] = useState('preference');
  const [content, setContent] = useState('');
  const [importance, setImportance] = useState(3);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // In-line edit state
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editContent, setEditContent] = useState('');

  const loadMemories = async () => {
    setLoading(true);
    try {
      const data = await apiService.getMemories();
      setMemories(data);
    } catch (e: any) {
      setError(e.message || 'Failed to load memories');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadMemories();
  }, []);

  const handleAddMemory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!content.trim() || creating) return;

    setCreating(true);
    setError(null);
    try {
      const created = await apiService.createMemory(category, content.trim(), importance);
      setMemories((prev) => [created, ...prev]);
      setContent('');
    } catch (e: any) {
      setError(e.message || 'Failed to create memory');
    } finally {
      setCreating(false);
    }
  };

  const handleUpdateMemory = async (id: string, updates: { content?: string; is_confirmed?: boolean }) => {
    try {
      const updated = await apiService.updateMemory(id, updates);
      setMemories((prev) => prev.map((m) => (m.id === id ? { ...m, ...updated } : m)));
      setEditingId(null);
    } catch (e: any) {
      setError(e.message || 'Failed to update memory');
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await apiService.deleteMemory(id);
      setMemories((prev) => prev.filter((m) => m.id !== id));
    } catch (e: any) {
      setError(e.message || 'Failed to delete memory');
    }
  };

  return (
    <div
      className="flex-1 overflow-y-auto p-6"
      style={{ height: 'calc(100vh - 68px)', position: 'relative', zIndex: 1 }}
    >
      {error && (
        <div
          className="p-3 mb-4 rounded-xl text-xs flex items-center justify-between"
          style={{
            backgroundColor: 'rgba(251, 113, 133, 0.12)',
            color: '#FB7185',
            border: '1px solid rgba(251, 113, 133, 0.3)'
          }}
        >
          <span>{error}</span>
          <button
            onClick={() => setError(null)}
            className="text-muted hover:text-primary cursor-pointer font-bold"
            style={{ background: 'none', border: 'none' }}
          >
            ×
          </button>
        </div>
      )}

      {/* Add Memory Card */}
      <div
        className="tess-card p-5 mb-6"
        style={{
          background: 'linear-gradient(135deg, rgba(139, 92, 246, 0.08) 0%, rgba(17, 20, 38, 0.85) 100%)',
          borderColor: 'rgba(139, 92, 246, 0.3)'
        }}
      >
        <div className="flex items-center gap-2 mb-3">
          <Brain style={{ width: '1.15rem', height: '1.15rem', color: '#A78BFA' }} />
          <h3 className="text-sm font-bold text-primary tracking-wide font-mono uppercase m-0">
            Cognitive Knowledge Core: Inject Memory
          </h3>
        </div>

        <form onSubmit={handleAddMemory} className="flex flex-col gap-3">
          <div className="flex gap-3">
            <select
              className="tess-input text-xs font-mono"
              style={{ width: '180px' }}
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

            <select
              className="tess-input text-xs font-mono"
              style={{ width: '160px' }}
              value={importance}
              onChange={(e) => setImportance(Number(e.target.value))}
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
              onChange={(e) => setContent(e.target.value)}
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
        </form>
      </div>

      {/* Memory List */}
      <div>
        <div className="flex items-center justify-between mb-3.5">
          <div className="flex items-center gap-2">
            <Sparkles style={{ width: '1rem', height: '1rem', color: '#22D3EE' }} />
            <h4 className="text-xs font-bold text-primary font-mono uppercase tracking-wider m-0">
              Persisted Memories & Contextual Provenance ({memories.length})
            </h4>
          </div>
          <span className="text-[11px] font-mono text-muted">
            Cross-Device Synced
          </span>
        </div>

        {loading ? (
          <div className="text-center text-muted py-12 text-xs font-mono">
            Accessing long-term memory store...
          </div>
        ) : memories.length === 0 ? (
          <div className="tess-card text-center py-12">
            <Brain style={{ width: '2rem', height: '2rem', color: 'var(--text-muted)', margin: '0 auto 0.5rem', opacity: 0.5 }} />
            <div className="text-sm font-semibold text-primary">No Memories Encoded Yet</div>
            <p className="text-xs text-muted mt-1 max-w-sm mx-auto">
              Add personal preferences, work habits, or project directives to shape how TESS assists and simulates your future.
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-2.5">
            {memories.map((m) => {
              const isEditing = editingId === m.id;
              return (
                <div
                  key={m.id}
                  className="tess-card p-4 flex items-center justify-between transition-all hover:border-[rgba(139,92,246,0.35)]"
                >
                  <div className="flex items-start gap-3 flex-1 min-w-0 pr-4">
                    <span
                      className="font-mono text-[10px] font-bold px-2 py-0.5 rounded-md uppercase tracking-wider shrink-0 mt-0.5 bg-[rgba(139,92,246,0.12)] text-[#A78BFA] border border-[rgba(139,92,246,0.3)]"
                    >
                      {m.category}
                    </span>

                    <div className="flex-1 min-w-0">
                      {isEditing ? (
                        <div className="flex items-center gap-2">
                          <input
                            type="text"
                            className="tess-input text-xs py-1"
                            value={editContent}
                            onChange={(e) => setEditContent(e.target.value)}
                          />
                          <button
                            onClick={() => handleUpdateMemory(m.id, { content: editContent })}
                            className="p-1 rounded bg-[rgba(52,211,153,0.15)] text-[#34D399] border border-[rgba(52,211,153,0.3)] cursor-pointer"
                          >
                            <Check style={{ width: '0.85rem', height: '0.85rem' }} />
                          </button>
                        </div>
                      ) : (
                        <div className="text-xs font-medium text-primary leading-relaxed">
                          {m.content}
                        </div>
                      )}

                      <div className="flex items-center gap-3 mt-1.5 text-[10px] font-mono text-muted">
                        <span className="flex items-center gap-1 text-[#FBBF24]">
                          <Star style={{ width: '0.7rem', height: '0.7rem', fill: '#FBBF24' }} />
                          LVL {m.importance || 3}
                        </span>

                        {m.provenance && (
                          <span className="text-muted">
                            SOURCE: {m.provenance}
                          </span>
                        )}

                        {m.is_confirmed !== undefined && (
                          <span
                            className="flex items-center gap-1 cursor-pointer"
                            onClick={() => handleUpdateMemory(m.id, { is_confirmed: !m.is_confirmed })}
                            style={{ color: m.is_confirmed ? '#34D399' : 'var(--text-muted)' }}
                          >
                            <CheckCircle2 style={{ width: '0.75rem', height: '0.75rem' }} />
                            {m.is_confirmed ? 'CONFIRMED' : 'UNCONFIRMED'}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-1.5 shrink-0">
                    <button
                      onClick={() => {
                        setEditingId(m.id);
                        setEditContent(m.content);
                      }}
                      className="p-1.5 rounded text-muted hover:text-primary transition-colors cursor-pointer"
                      style={{ background: 'none', border: 'none' }}
                      title="Edit memory"
                    >
                      <Edit2 style={{ width: '0.85rem', height: '0.85rem' }} />
                    </button>
                    <button
                      onClick={() => handleDelete(m.id)}
                      className="p-1.5 rounded text-muted hover:text-[#FB7185] transition-colors cursor-pointer"
                      style={{ background: 'none', border: 'none' }}
                      title="Delete memory"
                    >
                      <Trash2 style={{ width: '0.85rem', height: '0.85rem' }} />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
