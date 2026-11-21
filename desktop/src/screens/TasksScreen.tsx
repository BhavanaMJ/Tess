import React, { useEffect, useState, useMemo, useCallback } from 'react';
import { apiService } from '../services/api';
import { ProductivityTask, ProductivitySummary } from '../types';
import { useMascot } from '../contexts/MascotContext';
import { TaskMetricsOverview } from '../components/tasks/TaskMetricsOverview';
import { TaskToolbar } from '../components/tasks/TaskToolbar';
import { TaskCard } from '../components/tasks/TaskCard';
import { TaskDetailModal } from '../components/tasks/TaskDetailModal';
import {
  CheckSquare,
  AlertCircle,
  X,
  RefreshCw,
  FolderOpen
} from 'lucide-react';

interface TasksScreenProps {
  onNavigateToChat?: (initialPrompt?: string) => void;
}

export const TasksScreen: React.FC<TasksScreenProps> = ({ onNavigateToChat }) => {
  const [tasks, setTasks] = useState<ProductivityTask[]>([]);
  const [summary, setSummary] = useState<ProductivitySummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [priorityFilter, setPriorityFilter] = useState<string>('ALL');
  const [sortBy, setSortBy] = useState<string>('DUE_DATE');
  const [selectedTask, setSelectedTask] = useState<ProductivityTask | null>(null);
  const [statusMessage, setStatusMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const { triggerEmotion } = useMascot();

  const loadTasks = useCallback(async () => {
    setLoading(true);
    try {
      const [tList, tSum] = await Promise.all([
        apiService.getProductivityTasks(),
        apiService.getProductivitySummary()
      ]);
      setTasks(tList || []);
      setSummary(tSum || null);
    } catch (e: any) {
      setStatusMessage({
        type: 'error',
        text: `Unable to load tasks: ${e.message || String(e)}`
      });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadTasks();
  }, [loadTasks]);

  const handleSync = async () => {
    setSyncing(true);
    setStatusMessage(null);
    try {
      const res = await apiService.syncOpenProject();
      setStatusMessage({
        type: 'success',
        text: `Synchronized successfully (${res.synced_tasks ?? 0} packages updated)`
      });
      triggerEmotion('HAPPY', 3000);
      await loadTasks();
    } catch (e: any) {
      setStatusMessage({
        type: 'error',
        text: `OpenProject synchronization failed: ${e.message || String(e)}`
      });
      triggerEmotion('ERROR', 4000);
    } finally {
      setSyncing(false);
    }
  };

  // Filter and sort tasks
  const filteredTasks = useMemo(() => {
    return tasks
      .filter((task) => {
        // Search filter
        if (searchQuery.trim()) {
          const q = searchQuery.toLowerCase();
          const matchesTitle = (task.title || '').toLowerCase().includes(q);
          const matchesId = (task.external_id || '').toLowerCase().includes(q);
          const matchesDesc = (task.description || '').toLowerCase().includes(q);
          const matchesProject = (task.project || '').toLowerCase().includes(q);
          if (!matchesTitle && !matchesId && !matchesDesc && !matchesProject) {
            return false;
          }
        }

        // Priority filter
        if (priorityFilter !== 'ALL') {
          const p = (task.priority || '').toUpperCase();
          if (p !== priorityFilter) return false;
        }

        // Status filter
        if (statusFilter !== 'ALL') {
          const s = (task.status || '').toUpperCase();
          const today = new Date();
          today.setHours(0, 0, 0, 0);

          if (statusFilter === 'OVERDUE') {
            if (!task.due_date) return false;
            return new Date(task.due_date) < new Date();
          }
          if (statusFilter === 'DUE_TODAY') {
            if (!task.due_date) return false;
            const dueDate = new Date(task.due_date);
            dueDate.setHours(0, 0, 0, 0);
            return dueDate.getTime() === today.getTime();
          }
          if (statusFilter === 'HIGH_PRIORITY') {
            return (task.priority || '').toUpperCase() === 'HIGH';
          }
          if (statusFilter === 'DUE_WEEK') {
            if (!task.due_date) return false;
            const dueDate = new Date(task.due_date);
            const nextWeek = new Date();
            nextWeek.setDate(nextWeek.getDate() + 7);
            return dueDate >= today && dueDate <= nextWeek;
          }
          if (s !== statusFilter) return false;
        }

        return true;
      })
      .sort((a, b) => {
        // Sorting logic
        if (sortBy === 'DUE_DATE') {
          if (!a.due_date) return 1;
          if (!b.due_date) return -1;
          return new Date(a.due_date).getTime() - new Date(b.due_date).getTime();
        }
        if (sortBy === 'PRIORITY') {
          const weight: Record<string, number> = { HIGH: 3, NORMAL: 2, LOW: 1 };
          const pA = weight[(a.priority || '').toUpperCase()] || 0;
          const pB = weight[(b.priority || '').toUpperCase()] || 0;
          return pB - pA;
        }
        if (sortBy === 'TITLE') {
          return (a.title || '').localeCompare(b.title || '');
        }
        if (sortBy === 'CREATED_AT') {
          return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
        }
        return 0;
      });
  }, [tasks, searchQuery, priorityFilter, statusFilter, sortBy]);

  const handleDiscussWithTess = (task: ProductivityTask) => {
    setSelectedTask(null);
    if (onNavigateToChat) {
      onNavigateToChat(`I want to work on work package #${task.external_id}: "${task.title}". What is the best step forward?`);
    }
  };

  return (
    <div
      className="flex-1 overflow-y-auto p-4 sm:p-6 w-full h-full relative"
      style={{ zIndex: 1 }}
      data-testid="tasks-screen-container"
    >
      {/* 1. TOP METRICS OVERVIEW */}
      <TaskMetricsOverview
        summary={summary}
        totalTasks={tasks.length}
        activeFilter={statusFilter}
        onSelectFilter={(f) => setStatusFilter(f)}
      />

      {/* STATUS & FEEDBACK NOTIFICATION BANNER */}
      {statusMessage && (
        <div
          className="p-3 mb-4 rounded-xl text-xs flex items-center justify-between border animate-in fade-in"
          style={{
            backgroundColor:
              statusMessage.type === 'error'
                ? 'rgba(251, 113, 133, 0.12)'
                : 'rgba(52, 211, 153, 0.12)',
            color: statusMessage.type === 'error' ? '#FB7185' : '#34D399',
            borderColor:
              statusMessage.type === 'error'
                ? 'rgba(251, 113, 133, 0.35)'
                : 'rgba(52, 211, 153, 0.35)'
          }}
        >
          <div className="flex items-center gap-2">
            <AlertCircle style={{ width: '1rem', height: '1rem' }} />
            <span>{statusMessage.text}</span>
          </div>
          <button
            type="button"
            onClick={() => setStatusMessage(null)}
            className="text-muted hover:text-primary cursor-pointer p-0.5 bg-transparent border-none"
          >
            <X style={{ width: '0.9rem', height: '0.9rem' }} />
          </button>
        </div>
      )}

      {/* 2. FILTER & SORT TOOLBAR */}
      <TaskToolbar
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        statusFilter={statusFilter}
        onStatusFilterChange={setStatusFilter}
        priorityFilter={priorityFilter}
        onPriorityFilterChange={setPriorityFilter}
        sortBy={sortBy}
        onSortChange={setSortBy}
        syncing={syncing}
        onSync={handleSync}
        filteredCount={filteredTasks.length}
        totalCount={tasks.length}
      />

      {/* 3. TASK LIST / SKELETON / EMPTY STATES */}
      {loading ? (
        <div className="space-y-3 py-6">
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className="tess-card p-4 rounded-xl flex items-center justify-between animate-pulse"
            >
              <div className="flex items-center gap-3 flex-1">
                <div className="w-12 h-6 rounded bg-[rgba(255,255,255,0.06)]" />
                <div className="space-y-2 flex-1">
                  <div className="w-1/3 h-4 rounded bg-[rgba(255,255,255,0.06)]" />
                  <div className="w-1/4 h-3 rounded bg-[rgba(255,255,255,0.04)]" />
                </div>
              </div>
              <div className="w-20 h-6 rounded bg-[rgba(255,255,255,0.06)]" />
            </div>
          ))}
        </div>
      ) : filteredTasks.length === 0 ? (
        <div className="tess-card text-center py-16 px-4 rounded-2xl flex flex-col items-center justify-center select-none">
          <div className="w-14 h-14 rounded-2xl bg-[rgba(255,255,255,0.03)] border border-[rgba(255,255,255,0.08)] flex items-center justify-center mb-4 text-muted">
            <CheckSquare style={{ width: '1.75rem', height: '1.75rem', opacity: 0.6 }} />
          </div>
          <h3 className="text-sm font-bold text-primary m-0">
            {searchQuery || statusFilter !== 'ALL' || priorityFilter !== 'ALL'
              ? 'No packages match your active filters'
              : 'No active work packages found'}
          </h3>
          <p className="text-xs text-muted max-w-sm mt-1.5 mb-4 leading-relaxed">
            {searchQuery || statusFilter !== 'ALL' || priorityFilter !== 'ALL'
              ? 'Try adjusting your search query, clearing filters, or synchronizing from OpenProject.'
              : 'Sync with OpenProject to import your assigned work packages, tasks, and deadlines.'}
          </p>
          <div className="flex items-center gap-2">
            {(searchQuery || statusFilter !== 'ALL' || priorityFilter !== 'ALL') && (
              <button
                type="button"
                onClick={() => {
                  setSearchQuery('');
                  setStatusFilter('ALL');
                  setPriorityFilter('ALL');
                }}
                className="btn-secondary text-xs py-1.5 px-3"
              >
                Reset Filters
              </button>
            )}
            <button
              type="button"
              onClick={handleSync}
              disabled={syncing}
              className="btn-primary text-xs py-1.5 px-3 flex items-center gap-1.5"
            >
              <RefreshCw
                style={{
                  width: '0.8rem',
                  height: '0.8rem',
                  animation: syncing ? 'spin 1s linear infinite' : 'none'
                }}
              />
              <span>{syncing ? 'Syncing...' : 'Sync OpenProject'}</span>
            </button>
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-2.5 pb-8">
          <div className="text-[11px] font-mono text-muted uppercase tracking-wider flex items-center justify-between px-1">
            <span>Work Packages</span>
            <span>
              Showing {filteredTasks.length} of {tasks.length}
            </span>
          </div>

          {filteredTasks.map((task) => (
            <TaskCard
              key={task.id}
              task={task}
              isSelected={selectedTask?.id === task.id}
              onSelect={(t) => setSelectedTask(t)}
            />
          ))}
        </div>
      )}

      {/* 4. TASK DETAIL MODAL */}
      <TaskDetailModal
        task={selectedTask}
        onClose={() => setSelectedTask(null)}
        onDiscussWithTess={handleDiscussWithTess}
      />
    </div>
  );
};
