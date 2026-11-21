import React from 'react';
import {
  Search,
  X,
  Filter,
  ArrowUpDown,
  RefreshCw
} from 'lucide-react';

interface TaskToolbarProps {
  searchQuery: string;
  onSearchChange: (q: string) => void;
  statusFilter: string;
  onStatusFilterChange: (s: string) => void;
  priorityFilter: string;
  onPriorityFilterChange: (p: string) => void;
  sortBy: string;
  onSortChange: (sort: string) => void;
  syncing: boolean;
  onSync: () => void;
  filteredCount: number;
  totalCount: number;
}

export const TaskToolbar: React.FC<TaskToolbarProps> = ({
  searchQuery,
  onSearchChange,
  statusFilter,
  onStatusFilterChange,
  priorityFilter,
  onPriorityFilterChange,
  sortBy,
  onSortChange,
  syncing,
  onSync,
  filteredCount,
  totalCount
}) => {
  return (
    <div className="tess-card p-3 rounded-xl mb-4 flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3 select-none">
      {/* Search Input */}
      <div className="relative flex items-center flex-1 min-w-[200px]">
        <Search
          style={{
            position: 'absolute',
            left: '10px',
            width: '0.85rem',
            height: '0.85rem',
            color: 'var(--text-muted)'
          }}
        />
        <input
          type="text"
          className="tess-input w-full pl-8 pr-7 py-1.5 text-xs rounded-lg font-sans"
          placeholder="Search work packages, titles, IDs, projects..."
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
        />
        {searchQuery && (
          <button
            type="button"
            onClick={() => onSearchChange('')}
            className="absolute right-2 p-0.5 text-muted hover:text-primary cursor-pointer bg-transparent border-none"
            title="Clear search"
          >
            <X style={{ width: '0.75rem', height: '0.75rem' }} />
          </button>
        )}
      </div>

      {/* Filter and Sort Controls */}
      <div className="flex flex-wrap items-center gap-2">
        {/* Status Filter */}
        <div className="flex items-center gap-1.5 bg-[rgba(255,255,255,0.03)] px-2 py-1 rounded-lg border border-[rgba(255,255,255,0.06)]">
          <Filter style={{ width: '0.75rem', height: '0.75rem', color: '#22D3EE' }} />
          <select
            className="bg-transparent border-none text-xs font-mono text-secondary focus:outline-none cursor-pointer p-0"
            value={statusFilter}
            onChange={(e) => onStatusFilterChange(e.target.value)}
            aria-label="Filter status"
          >
            <option value="ALL" className="bg-[#0B0D18] text-white">All Statuses</option>
            <option value="OVERDUE" className="bg-[#0B0D18] text-[#FB7185]">Overdue Only</option>
            <option value="DUE_TODAY" className="bg-[#0B0D18] text-[#FBBF24]">Due Today</option>
            <option value="HIGH_PRIORITY" className="bg-[#0B0D18] text-[#FB7185]">High Priority</option>
            <option value="IN PROGRESS" className="bg-[#0B0D18] text-[#38BDF8]">In Progress</option>
            <option value="IN SPECIFICATION" className="bg-[#0B0D18] text-[#A78BFA]">In Specification</option>
            <option value="DEVELOPED" className="bg-[#0B0D18] text-[#34D399]">Developed</option>
          </select>
        </div>

        {/* Priority Filter */}
        <div className="flex items-center gap-1.5 bg-[rgba(255,255,255,0.03)] px-2 py-1 rounded-lg border border-[rgba(255,255,255,0.06)]">
          <select
            className="bg-transparent border-none text-xs font-mono text-secondary focus:outline-none cursor-pointer p-0"
            value={priorityFilter}
            onChange={(e) => onPriorityFilterChange(e.target.value)}
            aria-label="Filter priority"
          >
            <option value="ALL" className="bg-[#0B0D18] text-white">All Priorities</option>
            <option value="HIGH" className="bg-[#0B0D18] text-[#FB7185]">High Priority</option>
            <option value="NORMAL" className="bg-[#0B0D18] text-[#22D3EE]">Normal Priority</option>
            <option value="LOW" className="bg-[#0B0D18] text-gray-400">Low Priority</option>
          </select>
        </div>

        {/* Sort By Dropdown */}
        <div className="flex items-center gap-1.5 bg-[rgba(255,255,255,0.03)] px-2 py-1 rounded-lg border border-[rgba(255,255,255,0.06)]">
          <ArrowUpDown style={{ width: '0.75rem', height: '0.75rem', color: '#A78BFA' }} />
          <select
            className="bg-transparent border-none text-xs font-mono text-secondary focus:outline-none cursor-pointer p-0"
            value={sortBy}
            onChange={(e) => onSortChange(e.target.value)}
            aria-label="Sort packages"
          >
            <option value="DUE_DATE" className="bg-[#0B0D18] text-white">Sort: Due Date</option>
            <option value="PRIORITY" className="bg-[#0B0D18] text-white">Sort: Priority</option>
            <option value="TITLE" className="bg-[#0B0D18] text-white">Sort: Title (A-Z)</option>
            <option value="CREATED_AT" className="bg-[#0B0D18] text-white">Sort: Created Date</option>
          </select>
        </div>

        {/* Sync OpenProject Action Button */}
        <button
          type="button"
          onClick={onSync}
          disabled={syncing}
          className="btn-primary text-xs py-1.5 px-3 flex items-center gap-1.5"
          title="Synchronize tasks from OpenProject"
        >
          <RefreshCw
            style={{
              width: '0.85rem',
              height: '0.85rem',
              animation: syncing ? 'spin 1s linear infinite' : 'none'
            }}
          />
          <span>{syncing ? 'Syncing...' : 'Sync OpenProject'}</span>
        </button>
      </div>
    </div>
  );
};
