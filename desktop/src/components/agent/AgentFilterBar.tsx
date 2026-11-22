import React from 'react';
import { Search, RotateCw, Filter } from 'lucide-react';

interface AgentFilterBarProps {
  searchQuery: string;
  onSearchChange: (query: string) => void;
  selectedStatus: string;
  onStatusChange: (status: string) => void;
  onRefresh: () => void;
  loading: boolean;
  counts: Record<string, number>;
}

export const AgentFilterBar: React.FC<AgentFilterBarProps> = ({
  searchQuery,
  onSearchChange,
  selectedStatus,
  onStatusChange,
  onRefresh,
  loading,
  counts
}) => {
  const statusTabs = [
    { id: 'ALL', label: 'All Plans' },
    { id: 'READY', label: 'Ready / Approval' },
    { id: 'EXECUTING', label: 'Executing' },
    { id: 'SUCCESS', label: 'Success' },
    { id: 'FAILED', label: 'Failed' },
    { id: 'CANCELLED', label: 'Cancelled' }
  ];

  return (
    <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3 mb-4 pb-3 border-b border-[rgba(255,255,255,0.06)]">
      {/* Search Input */}
      <div className="relative flex-1 max-w-md">
        <Search
          style={{
            width: '0.9rem',
            height: '0.9rem',
            position: 'absolute',
            left: '0.75rem',
            top: '50%',
            transform: 'translateY(-50%)',
            color: 'var(--text-muted)'
          }}
        />
        <input
          type="text"
          placeholder="Search by objective, tool, or plan ID..."
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
          className="tess-input text-xs w-full pl-8 pr-3"
        />
        {searchQuery && (
          <button
            type="button"
            onClick={() => onSearchChange('')}
            className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted hover:text-primary text-xs"
            style={{ background: 'none', border: 'none', cursor: 'pointer' }}
          >
            ×
          </button>
        )}
      </div>

      {/* Status Filter Pills */}
      <div className="flex items-center gap-1.5 overflow-x-auto py-1">
        {statusTabs.map((tab) => {
          const count = counts[tab.id] ?? 0;
          const isActive = selectedStatus === tab.id;
          return (
            <button
              key={tab.id}
              type="button"
              onClick={() => onStatusChange(tab.id)}
              className="px-2.5 py-1 rounded-lg text-xs font-mono font-medium transition-all shrink-0 flex items-center gap-1.5 cursor-pointer"
              style={{
                backgroundColor: isActive ? 'rgba(139, 92, 246, 0.2)' : 'var(--bg-secondary)',
                color: isActive ? '#A78BFA' : 'var(--text-secondary)',
                border: `1px solid ${isActive ? 'rgba(139, 92, 246, 0.4)' : 'var(--border)'}`
              }}
            >
              <span>{tab.label}</span>
              <span
                className="text-[10px] px-1.5 py-0.2 rounded-full"
                style={{
                  backgroundColor: isActive ? 'rgba(139, 92, 246, 0.3)' : 'rgba(255, 255, 255, 0.06)',
                  color: isActive ? '#FFFFFF' : 'var(--text-muted)'
                }}
              >
                {count}
              </span>
            </button>
          );
        })}

        <button
          type="button"
          onClick={onRefresh}
          disabled={loading}
          title="Refresh plans"
          className="p-1.5 rounded-lg text-muted hover:text-primary transition-all cursor-pointer border border-[var(--border)] ml-1 shrink-0"
          style={{ backgroundColor: 'var(--bg-secondary)' }}
        >
          <RotateCw
            style={{
              width: '0.85rem',
              height: '0.85rem',
              animation: loading ? 'spin 1s linear infinite' : 'none'
            }}
          />
        </button>
      </div>
    </div>
  );
};
