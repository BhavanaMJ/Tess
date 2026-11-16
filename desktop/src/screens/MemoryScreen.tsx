import React, { useEffect, useState } from 'react';
import { apiService } from '../services/api';
import { Memory } from '../types';
import { Brain, Plus, Trash2, Tag, Star, CheckCircle2, AlertCircle, Edit2, Check } from 'lucide-react';

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
    <div className="flex-1 overflow-y-auto p-6" style={{ height: 'calc(100vh - 64px)' }}>
      {/* Add Memory Card */}
      <div className="tess-card p-5 mb-6">
        <h3 className="text-sm font-bold text-primary mb-3 flex items-center gap-2">
          <Brain style={{ width: '1.1rem', height: '1.1rem', color: 'var(--accent)' }} />
          Add to TESS Long-Term Memory
        </h3>

        <form onSubmit={handleAddMemory} className="flex flex-col gap-3">
          <div className="flex gap-3">
            <select
              className="tess-input text-xs"
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
              className="tess-input text-xs"
              style={{ width: '140px' }}
              value={importance}
              onChange={(e) => setImportance(Number(e.target.value))}
            >
              <option value={1}>Low Priority (1)</option>
              <option value={2}>Normal (2)</option>
              <option value={3}>Important (3)</option>
              <option value={4}>High (4)</option>
              <option value={5}>Critical (5)</option>
            </select>
          </div>

          <div className="flex gap-2">
            <input
              type="text"
              className="tess-input text-xs flex-1"
              placeholder="e.g. Always schedule OpenProject worklog reviews in the late afternoon"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              disabled={creating}
            />
            <button type="submit" className="btn-primary text-xs cursor-pointer" disabled={!content.trim() || creating}>
              <Plus style={{ width: '0.9rem', height: '0.9rem' }} />
              <span>Save Memory</span>
            </button>
          </div>
        </form>
      </div>

      {error && (
        <div
          className="p-3 mb-4 rounded-lg text-xs"
          style={{ backgroundColor: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', border: '1px solid var(--border)' }}
        >
          {error}
        </div>
      )}

      {/* Memories List */}
      <div>
        <h4 className="text-sm font-bold text-primary mb-3">Persisted Memories ({memories.length})</h4>

        {loading ? (
          <div className="text-center text-muted py-8 text-xs">Loading personal memories...</div>
        ) : memories.length === 0 ? (
          <div className="tess-card text-center py-8 text-xs text-muted">
            No memories stored yet. TESS learns contextual details from conversations or direct entries above.
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {memories.map((mem) => {
              const isEditing = editingId === mem.id;
              const isConfirmed = mem.is_confirmed !== false;

              return (
                <div
                  key={mem.id}
                  className="tess-card flex items-center justify-between p-3.5"
                >
                  <div className="flex items-start gap-3 flex-1 mr-3">
                    <span
                      className="text-[10px] font-bold px-2 py-0.5 rounded uppercase mt-0.5"
                      style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--accent-light)' }}
                    >
                      {mem.category}
                    </span>
                    <div className="flex-1">
                      {isEditing ? (
                        <div className="flex items-center gap-2">
                          <input
                            type="text"
                            value={editContent}
                            onChange={(e) => setEditContent(e.target.value)}
                            className="tess-input text-xs flex-1"
                          />
                          <button
                            onClick={() => handleUpdateMemory(mem.id, { content: editContent })}
                            className="btn-primary p-1.5 text-xs cursor-pointer"
                          >
                            <Check style={{ width: '0.8rem', height: '0.8rem' }} />
                          </button>
                          <button
                            onClick={() => setEditingId(null)}
                            className="btn-secondary p-1.5 text-xs cursor-pointer"
                          >
                            Cancel
                          </button>
                        </div>
                      ) : (
                        <div className="text-xs text-primary">{mem.content}</div>
                      )}

                      <div className="flex items-center gap-3 mt-1 text-[11px] text-muted">
                        <span className="flex items-center gap-0.5">
                          <Star style={{ width: '0.75rem', height: '0.75rem', color: 'var(--warning)' }} />
                          Importance {mem.importance}
                        </span>

                        <span className="text-[10px] font-mono text-secondary">
                          Source: {mem.provenance || 'USER_STATED'}
                        </span>

                        <button
                          onClick={() => handleUpdateMemory(mem.id, { is_confirmed: !isConfirmed })}
                          className="flex items-center gap-1 text-[10px] font-semibold cursor-pointer hover:underline"
                          style={{ color: isConfirmed ? 'var(--success)' : 'var(--warning)' }}
                          title="Click to toggle confirmation"
                        >
                          {isConfirmed ? (
                            <CheckCircle2 style={{ width: '0.75rem', height: '0.75rem' }} />
                          ) : (
                            <AlertCircle style={{ width: '0.75rem', height: '0.75rem' }} />
                          )}
                          {isConfirmed ? 'Confirmed Fact' : 'Inferred (Unconfirmed)'}
                        </button>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-1.5">
                    {!isEditing && (
                      <button
                        onClick={() => {
                          setEditingId(mem.id);
                          setEditContent(mem.content);
                        }}
                        className="btn-secondary p-1.5 cursor-pointer"
                        title="Edit memory"
                      >
                        <Edit2 style={{ width: '0.8rem', height: '0.8rem' }} />
                      </button>
                    )}
                    <button
                      onClick={() => handleDelete(mem.id)}
                      className="btn-danger p-1.5 cursor-pointer"
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
