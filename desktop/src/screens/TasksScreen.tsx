import React, { useEffect, useState } from 'react';
import { apiService } from '../services/api';
import { ProductivityTask, ProductivitySummary } from '../types';
import {
  CheckSquare,
  RefreshCw,
  Clock,
  Filter,
  AlertTriangle,
  Folder,
  User,
  ShieldCheck,
  Zap,
  Activity
} from 'lucide-react';

export const TasksScreen: React.FC = () => {
  const [tasks, setTasks] = useState<ProductivityTask[]>([]);
  const [summary, setSummary] = useState<ProductivitySummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [filterPriority, setFilterPriority] = useState<string>('ALL');
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  const loadTasks = async () => {
    setLoading(true);
    setStatusMessage(null);
    try {
      const [tList, tSum] = await Promise.all([
        apiService.getProductivityTasks(),
        apiService.getProductivitySummary()
      ]);
      setTasks(tList);
      setSummary(tSum);
    } catch (e: any) {
      setStatusMessage(`Unable to load tasks: ${e.message}`);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadTasks();
  }, []);

  const handleSync = async () => {
    setSyncing(true);
    setStatusMessage(null);
    try {
      const res = await apiService.syncOpenProject();
      setStatusMessage(`Synchronized successfully (${res.synced_tasks ?? 0} tasks updated)`);
      await loadTasks();
    } catch (e: any) {
      setStatusMessage(`OpenProject sync failed: ${e.message}`);
    } finally {
      setSyncing(false);
    }
  };

  const filteredTasks = tasks.filter((t) => {
    if (filterPriority !== 'ALL') {
      const p = (t.priority || '').toUpperCase();
      if (p !== filterPriority) return false;
    }
    if (filterStatus !== 'ALL') {
      const s = (t.status || '').toUpperCase();
      if (filterStatus === 'OVERDUE') {
        if (!t.due_date) return false;
        return new Date(t.due_date) < new Date();
      }
      if (s !== filterStatus) return false;
    }
    return true;
  });

  return (
    <div
      className="flex-1 overflow-y-auto p-6"
      style={{ height: 'calc(100vh - 68px)', position: 'relative', zIndex: 1 }}
    >
      {/* Top action & metrics bar */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3 text-xs">
          <div className="tess-card py-2 px-3.5 flex items-center gap-2">
            <Activity style={{ width: '0.85rem', height: '0.85rem', color: '#22D3EE' }} />
            <span className="text-muted font-mono uppercase text-[11px]">Total:</span>
            <span className="font-bold text-primary font-mono text-sm">{tasks.length}</span>
          </div>

          <div
            className="tess-card py-2 px-3.5 flex items-center gap-2"
            style={{ borderColor: 'rgba(251, 113, 133, 0.3)' }}
          >
            <span className="font-mono uppercase text-[11px]" style={{ color: '#FB7185' }}>Overdue:</span>
            <span className="font-bold font-mono text-sm" style={{ color: '#FB7185' }}>
              {summary?.overdue ?? 0}
            </span>
          </div>

          <div
            className="tess-card py-2 px-3.5 flex items-center gap-2"
            style={{ borderColor: 'rgba(251, 191, 36, 0.3)' }}
          >
            <span className="font-mono uppercase text-[11px]" style={{ color: '#FBBF24' }}>Due Today:</span>
            <span className="font-bold font-mono text-sm" style={{ color: '#FBBF24' }}>
              {summary?.due_today ?? 0}
            </span>
          </div>
        </div>

        <button onClick={handleSync} disabled={syncing} className="btn-primary text-xs">
          <RefreshCw
            style={{
              width: '0.85rem',
              height: '0.85rem',
              animation: syncing ? 'spin 1s linear infinite' : 'none'
            }}
          />
          <span>{syncing ? 'Syncing OpenProject...' : 'Sync OpenProject'}</span>
        </button>
      </div>

      {statusMessage && (
        <div
          className="p-3 mb-4 rounded-xl text-xs flex items-center justify-between"
          style={{
            backgroundColor: statusMessage.includes('failed') ? 'rgba(251, 113, 133, 0.12)' : 'rgba(52, 211, 153, 0.12)',
            color: statusMessage.includes('failed') ? '#FB7185' : '#34D399',
            border: `1px solid ${statusMessage.includes('failed') ? 'rgba(251, 113, 133, 0.3)' : 'rgba(52, 211, 153, 0.3)'}`
          }}
        >
          <span>{statusMessage}</span>
          <button
            onClick={() => setStatusMessage(null)}
            className="text-muted hover:text-primary cursor-pointer font-bold"
            style={{ background: 'none', border: 'none' }}
          >
            ×
          </button>
        </div>
      )}

      {/* Filter toolbar */}
      <div className="tess-card flex items-center justify-between mb-4 py-2.5 px-4 bg-[rgba(11,13,24,0.6)]">
        <div className="flex items-center gap-3">
          <Filter style={{ width: '0.9rem', height: '0.9rem', color: '#22D3EE' }} />
          <span className="text-xs font-mono uppercase text-muted tracking-wider">Filter:</span>

          <select
            className="tess-input py-1 px-2.5 text-xs font-mono"
            style={{ width: 'auto' }}
            value={filterPriority}
            onChange={(e) => setFilterPriority(e.target.value)}
          >
            <option value="ALL">All Priorities</option>
            <option value="HIGH">High Priority</option>
            <option value="NORMAL">Normal Priority</option>
            <option value="LOW">Low Priority</option>
          </select>

          <select
            className="tess-input py-1 px-2.5 text-xs font-mono"
            style={{ width: 'auto' }}
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
          >
            <option value="ALL">All Statuses</option>
            <option value="OVERDUE">Overdue Only</option>
            <option value="IN SPECIFICATION">In Specification</option>
            <option value="IN PROGRESS">In Progress</option>
            <option value="DEVELOPED">Developed</option>
          </select>
        </div>

        <div className="text-xs font-mono text-muted">
          Showing {filteredTasks.length} of {tasks.length} packages
        </div>
      </div>

      {/* Task List */}
      {loading ? (
        <div className="text-center text-muted py-12 text-xs font-mono">Loading telemetry tasks...</div>
      ) : filteredTasks.length === 0 ? (
        <div className="tess-card text-center py-12">
          <CheckSquare style={{ width: '2rem', height: '2rem', color: 'var(--text-muted)', margin: '0 auto 0.5rem' }} />
          <div className="text-sm font-semibold text-primary">No tasks match your active filter</div>
          <div className="text-xs text-muted mt-1">Try clearing filters or click Sync OpenProject.</div>
        </div>
      ) : (
        <div className="flex flex-col gap-2.5">
          {filteredTasks.map((task) => {
            const isOverdue = task.due_date && new Date(task.due_date) < new Date();
            const isHighPriority = task.priority && task.priority.toUpperCase() === 'HIGH';
            return (
              <div
                key={task.id}
                className="tess-card flex items-center justify-between p-3.5 transition-all hover:border-[rgba(139,92,246,0.35)]"
                style={{
                  borderColor: isOverdue ? 'rgba(251, 113, 133, 0.35)' : 'var(--border)'
                }}
              >
                <div className="flex items-start gap-3 flex-1 min-w-0">
                  <span
                    className="font-mono text-xs px-2 py-0.5 rounded-md font-semibold mt-0.5 bg-[rgba(139,92,246,0.12)] text-[#A78BFA] border border-[rgba(139,92,246,0.3)] shrink-0"
                  >
                    #{task.external_id}
                  </span>
                  <div className="min-w-0 pr-3">
                    <div className="text-xs font-semibold text-primary truncate tracking-tight">{task.title}</div>
                    <div className="flex items-center gap-3 mt-1 text-[11px] text-muted font-mono">
                      {task.project && (
                        <span className="flex items-center gap-1">
                          <Folder style={{ width: '0.75rem', height: '0.75rem' }} />
                          {task.project}
                        </span>
                      )}
                      {task.assignee && (
                        <span className="flex items-center gap-1">
                          <User style={{ width: '0.75rem', height: '0.75rem' }} />
                          {task.assignee}
                        </span>
                      )}
                      {task.status && (
                        <span className="px-1.5 py-0.2 rounded bg-[rgba(255,255,255,0.04)] text-[10px] text-secondary border border-[rgba(255,255,255,0.06)]">
                          {task.status}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-3 flex-shrink-0">
                  {task.due_date && (
                    <div
                      className="flex items-center gap-1 text-[11px] font-mono px-2 py-1 rounded-md"
                      style={{
                        backgroundColor: isOverdue ? 'rgba(251, 113, 133, 0.12)' : 'rgba(255, 255, 255, 0.03)',
                        color: isOverdue ? '#FB7185' : 'var(--text-secondary)',
                        border: `1px solid ${isOverdue ? 'rgba(251, 113, 133, 0.3)' : 'var(--border)'}`
                      }}
                    >
                      {isOverdue && <AlertTriangle style={{ width: '0.75rem', height: '0.75rem' }} />}
                      <Clock style={{ width: '0.75rem', height: '0.75rem' }} />
                      <span>{task.due_date}</span>
                    </div>
                  )}

                  {task.priority && (
                    <span
                      className="text-[10px] font-mono font-bold px-2 py-0.5 rounded-full uppercase"
                      style={{
                        backgroundColor: isHighPriority ? 'rgba(251, 113, 133, 0.15)' : 'rgba(255, 255, 255, 0.04)',
                        color: isHighPriority ? '#FB7185' : 'var(--text-muted)',
                        border: `1px solid ${isHighPriority ? 'rgba(251, 113, 133, 0.3)' : 'var(--border)'}`
                      }}
                    >
                      {task.priority}
                    </span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
