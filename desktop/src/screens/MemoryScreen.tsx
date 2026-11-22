import React, { useEffect, useState, useMemo } from 'react';
import { apiService } from '../services/api';
import { Memory } from '../types';
import { useMascot } from '../contexts/MascotContext';
import { MemoryMetricsOverview } from '../components/memory/MemoryMetricsOverview';
import { MemoryFilterBar } from '../components/memory/MemoryFilterBar';
import { MemoryCard } from '../components/memory/MemoryCard';
import { MemoryInjectionForm } from '../components/memory/MemoryInjectionForm';
import { MemoryDetailModal } from '../components/memory/MemoryDetailModal';
import {
  Brain,
  Sparkles,
  AlertCircle,
  CheckCircle2,
  Database
} from 'lucide-react';

export const MemoryScreen: React.FC = () => {
  const [memories, setMemories] = useState<Memory[]>([]);
  const [category, setCategory] = useState('preference');
  const [content, setContent] = useState('');
  const [importance, setImportance] = useState(3);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [statusMessage, setStatusMessage] = useState<{ text: string; error?: boolean } | null>(null);

  // Filters & Search
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('ALL');

  // Deep-dive detail modal
  const [inspectingMemory, setInspectingMemory] = useState<Memory | null>(null);

  const { setState: setMascotState } = useMascot();

  const loadMemories = async () => {
    setLoading(true);
    try {
      const data = await apiService.getMemories();
      setMemories(data);
    } catch (e: any) {
      setStatusMessage({ text: e.message || 'Failed to load memories', error: true });
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
    setStatusMessage(null);
    setMascotState('PLANNING');

    try {
      const created = await apiService.createMemory(category, content.trim(), importance);
      setMemories((prev) => [created, ...prev]);
      setContent('');
      setMascotState('SUCCESS');
      setStatusMessage({ text: 'Memory encoded into long-term cognitive store.' });
    } catch (e: any) {
      setStatusMessage({ text: e.message || 'Failed to create memory', error: true });
      setMascotState('ERROR');
    } finally {
      setCreating(false);
    }
  };

  const handleUpdateMemory = async (id: string, updates: Partial<Memory>) => {
    try {
      const updated = await apiService.updateMemory(id, updates);
      setMemories((prev) => prev.map((m) => (m.id === id ? { ...m, ...updated } : m)));
      setStatusMessage({ text: 'Memory updated successfully.' });
    } catch (e: any) {
      setStatusMessage({ text: e.message || 'Failed to update memory', error: true });
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await apiService.deleteMemory(id);
      setMemories((prev) => prev.filter((m) => m.id !== id));
      setStatusMessage({ text: 'Memory deleted.' });
    } catch (e: any) {
      setStatusMessage({ text: e.message || 'Failed to delete memory', error: true });
    }
  };

  // Filter & Search
  const filteredMemories = useMemo(() => {
    return memories.filter((m) => {
      // Category filter
      if (selectedCategory !== 'ALL') {
        if (selectedCategory === 'CONFIRMED' && m.is_confirmed === false) return false;
        if (selectedCategory === 'UNCONFIRMED' && m.is_confirmed !== false) return false;
        if (selectedCategory === 'CORE' && (m.importance || 3) < 4) return false;
        if (!['CONFIRMED', 'UNCONFIRMED', 'CORE'].includes(selectedCategory)) {
          if (m.category.toLowerCase() !== selectedCategory.toLowerCase()) return false;
        }
      }

      // Search query
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchesContent = m.content.toLowerCase().includes(q);
        const matchesCategory = m.category.toLowerCase().includes(q);
        const matchesProvenance = m.provenance?.toLowerCase().includes(q) || false;
        if (!matchesContent && !matchesCategory && !matchesProvenance) return false;
      }

      return true;
    });
  }, [memories, selectedCategory, searchQuery]);

  const categoryCounts = useMemo(() => {
    const counts: Record<string, number> = {
      ALL: memories.length,
      preference: 0,
      goal: 0,
      project: 0,
      workflow: 0,
      commitment: 0,
      routine: 0,
      fact: 0
    };
    memories.forEach((m) => {
      const cat = m.category.toLowerCase();
      if (counts[cat] !== undefined) {
        counts[cat]++;
      }
    });
    return counts;
  }, [memories]);

  return (
    <div
      className="flex-1 overflow-y-auto p-6"
      style={{ height: 'calc(100vh - 68px)', position: 'relative', zIndex: 1 }}
    >
      {/* Status / Alert Banner */}
      {statusMessage && (
        <div
          className="p-3 mb-4 rounded-xl text-xs flex items-center justify-between animate-fadeIn"
          style={{
            backgroundColor: statusMessage.error
              ? 'rgba(251, 113, 133, 0.12)'
              : 'rgba(52, 211, 153, 0.12)',
            color: statusMessage.error ? '#FB7185' : '#34D399',
            border: `1px solid ${statusMessage.error ? 'rgba(251, 113, 133, 0.3)' : 'rgba(52, 211, 153, 0.3)'}`
          }}
        >
          <span className="flex items-center gap-2">
            {statusMessage.error ? (
              <AlertCircle style={{ width: '0.9rem', height: '0.9rem' }} />
            ) : (
              <CheckCircle2 style={{ width: '0.9rem', height: '0.9rem' }} />
            )}
            {statusMessage.text}
          </span>
          <button
            type="button"
            onClick={() => setStatusMessage(null)}
            className="text-muted hover:text-primary cursor-pointer font-bold"
            style={{ background: 'none', border: 'none' }}
          >
            ×
          </button>
        </div>
      )}

      {/* Top Section: Metrics Overview */}
      <MemoryMetricsOverview
        memories={memories}
        selectedCategory={selectedCategory}
        onSelectCategory={setSelectedCategory}
      />

      {/* Inject Memory Form */}
      <MemoryInjectionForm
        category={category}
        onCategoryChange={setCategory}
        importance={importance}
        onImportanceChange={setImportance}
        content={content}
        onContentChange={setContent}
        onSubmit={handleAddMemory}
        creating={creating}
      />

      {/* Filter and Search Bar */}
      <MemoryFilterBar
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        selectedCategory={selectedCategory}
        onCategoryChange={setSelectedCategory}
        onRefresh={loadMemories}
        loading={loading}
        categoryCounts={categoryCounts}
      />

      {/* Memory List Header */}
      <div className="flex items-center justify-between mb-3.5">
        <div className="flex items-center gap-2">
          <Sparkles style={{ width: '1rem', height: '1rem', color: '#22D3EE' }} />
          <h4 className="text-xs font-bold text-primary font-mono uppercase tracking-wider m-0">
            Persisted Memories & Contextual Provenance ({filteredMemories.length})
          </h4>
        </div>
        <span className="text-[11px] font-mono text-muted">
          Cross-Device Synced
        </span>
      </div>

      {/* Memory Cards Stream */}
      {loading && memories.length === 0 ? (
        <div className="text-center text-muted py-12 text-xs font-mono">
          Accessing long-term memory store...
        </div>
      ) : filteredMemories.length === 0 ? (
        <div className="tess-card text-center py-12">
          <Brain
            style={{
              width: '2rem',
              height: '2rem',
              color: 'var(--text-muted)',
              margin: '0 auto 0.5rem',
              opacity: 0.5
            }}
          />
          <div className="text-sm font-semibold text-primary">No Memories Found</div>
          <p className="text-xs text-muted mt-1 max-w-sm mx-auto">
            {memories.length === 0
              ? 'Add personal preferences, work habits, or project directives to shape how TESS assists and simulates your future.'
              : 'No memories match your active category filter or search query.'}
          </p>
        </div>
      ) : (
        <div className="flex flex-col gap-2.5">
          {filteredMemories.map((m) => (
            <MemoryCard
              key={m.id}
              memory={m}
              onUpdate={handleUpdateMemory}
              onDelete={handleDelete}
              onInspect={(mem) => setInspectingMemory(mem)}
            />
          ))}
        </div>
      )}

      {/* Memory Detail & Continuity Modal */}
      <MemoryDetailModal
        memory={inspectingMemory}
        isOpen={Boolean(inspectingMemory)}
        onClose={() => setInspectingMemory(null)}
        onUpdate={handleUpdateMemory}
        onDelete={handleDelete}
      />
    </div>
  );
};
