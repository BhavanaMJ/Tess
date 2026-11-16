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
  User
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
    <div className="flex-1 overflow-y-auto p-6" style={{ height: 'calc(100vh - 64px)' }}>
      {/* Top action & metrics bar */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4 text-xs">
          <div className="tess-card py-2 px-3">
            <span className="text-muted">Total: </span>
            <span className="font-bold text-primary">{tasks.length}</span>
          </div>
          <div className="tess-card py-2 px-3">
            <span style={{ color: 'var(--danger)' }}>Overdue: </span>
            <span className="font-bold" style={{ color: 'var(--danger)' }}>
              {summary?.overdue ?? 0}
            </span>
          </div>
          <div className="tess-card py-2 px-3">
            <span style={{ color: 'var(--warning)' }}>Due Today: </span>
            <span className="font-bold" style={{ color: 'var(--warning)' }}>
              {summary?.due_today ?? 0}
            </span>
          </div>
        </div>

        <button onClick={handleSync} disabled={syncing} className="btn-primary text-xs">
          <RefreshCw
            style={{
              width: '0.9rem',
              height: '0.9rem',
              animation: syncing ? 'spin 1s linear infinite' : 'none'
            }}
          />
          <span>{syncing ? 'Syncing OpenProject...' : 'Sync OpenProject'}</span>
        </button>
      </div>

      {statusMessage && (
        <div
          className="p-3 mb-4 rounded-lg text-xs"
          style={{
            backgroundColor: statusMessage.includes('failed') ? 'rgba(239, 68, 68, 0.1)' : 'rgba(16, 185, 129, 0.1)',
            color: statusMessage.includes('failed') ? 'var(--danger)' : 'var(--success)',
            border: '1px solid var(--border)'
          }}
        >
          {statusMessage}
        </div>
      )}

      {/* Filter toolbar */}
      <div className="tess-card flex items-center justify-between mb-4 py-2 px-4">
        <div className="flex items-center gap-3">
          <Filter style={{ width: '0.9rem', height: '0.9rem', color: 'var(--text-muted)' }} />
          <span className="text-xs text-muted font-medium">Filter by:</span>

          <select
            className="tess-input py-1 px-2 text-xs"
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
            className="tess-input py-1 px-2 text-xs"
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

        <div className="text-xs text-muted">
          Showing {filteredTasks.length} of {tasks.length} tasks
        </div>
      </div>

      {/* Task List */}
      {loading ? (
        <div className="text-center text-muted py-12 text-sm">Loading productivity tasks...</div>
      ) : filteredTasks.length === 0 ? (
        <div className="tess-card text-center py-12">
          <CheckSquare style={{ width: '2rem', height: '2rem', color: 'var(--text-muted)', margin: '0 auto 0.5rem' }} />
          <div className="text-sm font-semibold text-primary">No tasks match your filter</div>
          <div className="text-xs text-muted mt-1">Try clearing filters or click Sync OpenProject.</div>
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {filteredTasks.map((task) => {
            const isOverdue = task.due_date && new Date(task.due_date) < new Date();
            return (
              <div
                key={task.id}
                className="tess-card flex items-center justify-between p-3.5 transition-colors"
              >
                <div className="flex items-start gap-3 flex-1 min-w-0">
                  <span
                    className="font-mono text-xs px-2 py-0.5 rounded font-semibold mt-0.5"
                    style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--accent-light)' }}
                  >
                    #{task.external_id}
                  </span>
                  <div className="min-w-0">
                    <div className="text-sm font-medium text-primary truncate">{task.title}</div>
                    <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                      {task.project && (
                        <span className="flex items-center gap-1">
                          <Folder style={{ width: '0.8rem', height: '0.8rem' }} />
                          {task.project}
                        </span>
                      )}
                      {task.assignee && (
                        <span className="flex items-center gap-1">
                          <User style={{ width: '0.8rem', height: '0.8rem' }} />
                          {task.assignee}
                        </span>
                      )}
                      {task.status && (
                        <span className="px-1.5 py-0.2 rounded bg-secondary text-[11px]">
                          {task.status}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-3 flex-shrink-0">
                  {task.due_date && (
                    <div
                      className="flex items-center gap-1 text-xs font-medium px-2 py-1 rounded"
                      style={{
                        backgroundColor: isOverdue ? '#EF444420' : 'var(--bg-secondary)',
                        color: isOverdue ? 'var(--danger)' : 'var(--text-secondary)'
                      }}
                    >
                      {isOverdue && <AlertTriangle style={{ width: '0.8rem', height: '0.8rem' }} />}
                      <Clock style={{ width: '0.8rem', height: '0.8rem' }} />
                      <span>{task.due_date}</span>
                    </div>
                  )}

                  {task.priority && (
                    <span
                      className="text-xs font-semibold px-2 py-0.5 rounded"
                      style={{
                        backgroundColor:
                          task.priority.toUpperCase() === 'HIGH'
                            ? '#EF444420'
                            : 'var(--bg-secondary)',
                        color:
                          task.priority.toUpperCase() === 'HIGH'
                            ? 'var(--danger)'
                            : 'var(--text-muted)'
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

