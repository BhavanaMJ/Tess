import React, { useState, useMemo } from 'react';
import { Conversation } from '../../types';
import {
  Plus,
  MessageSquare,
  Search,
  X,
  ChevronLeft,
  ChevronRight,
  Sparkles
} from 'lucide-react';

interface ChatSidebarProps {
  conversations: Conversation[];
  currentConvId: string | null;
  onSelectConversation: (id: string) => void;
  onNewConversation: () => void;
  isCollapsed: boolean;
  onToggleCollapse: () => void;
}

export const ChatSidebar: React.FC<ChatSidebarProps> = ({
  conversations,
  currentConvId,
  onSelectConversation,
  onNewConversation,
  isCollapsed,
  onToggleCollapse
}) => {
  const [searchQuery, setSearchQuery] = useState('');

  const filteredConversations = useMemo(() => {
    if (!searchQuery.trim()) return conversations;
    const q = searchQuery.toLowerCase();
    return conversations.filter((c) =>
      (c.title || 'Untitled Dialogue').toLowerCase().includes(q)
    );
  }, [conversations, searchQuery]);

  const formatRelativeTime = (dateStr?: string) => {
    if (!dateStr) return '';
    try {
      const d = new Date(dateStr);
      if (isNaN(d.getTime())) return '';
      const now = new Date();
      const diffMs = now.getTime() - d.getTime();
      const diffMins = Math.floor(diffMs / (1000 * 60));
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
      const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

      if (diffMins < 1) return 'Just now';
      if (diffMins < 60) return `${diffMins}m ago`;
      if (diffHours < 24) return `${diffHours}h ago`;
      if (diffDays === 1) return 'Yesterday';
      if (diffDays < 7) return `${diffDays}d ago`;
      return d.toLocaleDateString([], { month: 'short', day: 'numeric' });
    } catch {
      return '';
    }
  };

  if (isCollapsed) {
    return (
      <div
        className="flex flex-col items-center py-3 border-r select-none transition-all duration-200 z-10"
        style={{
          width: '56px',
          backgroundColor: 'var(--bg-secondary, #0B0D18)',
          borderColor: 'var(--border, rgba(255, 255, 255, 0.08))'
        }}
      >
        {/* Expand Toggle */}
        <button
          type="button"
          onClick={onToggleCollapse}
          className="p-2 rounded-lg text-muted hover:text-primary hover:bg-[rgba(255,255,255,0.06)] transition-all cursor-pointer bg-transparent border-none mb-3"
          title="Expand Conversation Rail"
        >
          <ChevronRight style={{ width: '1.1rem', height: '1.1rem' }} />
        </button>

        {/* New Chat Icon Button */}
        <button
          type="button"
          onClick={onNewConversation}
          className="w-10 h-10 rounded-xl flex items-center justify-center bg-gradient-to-br from-[#8B5CF6] to-[#6D28D9] text-white shadow-md hover:brightness-110 transition-all cursor-pointer border-none mb-4"
          title="New Dialogue"
        >
          <Plus style={{ width: '1.1rem', height: '1.1rem' }} />
        </button>

        {/* Mini Conversation Icons */}
        <div className="flex-1 w-full overflow-y-auto flex flex-col items-center gap-1.5 px-1">
          {conversations.slice(0, 8).map((conv) => {
            const isSelected = currentConvId === conv.id;
            return (
              <button
                key={conv.id}
                onClick={() => onSelectConversation(conv.id)}
                className="w-9 h-9 rounded-lg flex items-center justify-center transition-all cursor-pointer border-none"
                style={{
                  backgroundColor: isSelected
                    ? 'rgba(139, 92, 246, 0.2)'
                    : 'transparent',
                  color: isSelected ? '#A78BFA' : 'var(--text-muted)'
                }}
                title={conv.title || 'Untitled Dialogue'}
              >
                <MessageSquare style={{ width: '0.9rem', height: '0.9rem' }} />
              </button>
            );
          })}
        </div>
      </div>
    );
  }

  return (
    <div
      className="flex flex-col border-r select-none transition-all duration-200 z-10 flex-shrink-0"
      style={{
        width: '280px',
        backgroundColor: 'var(--bg-secondary, #0B0D18)',
        borderColor: 'var(--border, rgba(255, 255, 255, 0.08))'
      }}
    >
      {/* Header with New Dialogue & Collapse action */}
      <div className="p-3 border-b border-[rgba(255,255,255,0.06)] flex items-center gap-2">
        <button
          type="button"
          onClick={onNewConversation}
          className="btn-primary flex-1 text-xs justify-center py-2"
          title="Start a new companion dialogue"
        >
          <Plus style={{ width: '0.9rem', height: '0.9rem' }} />
          <span>New Dialogue</span>
        </button>
        <button
          type="button"
          onClick={onToggleCollapse}
          className="p-2 rounded-lg text-muted hover:text-primary hover:bg-[rgba(255,255,255,0.06)] transition-all cursor-pointer bg-transparent border-none flex-shrink-0"
          title="Collapse Sidebar"
        >
          <ChevronLeft style={{ width: '1.05rem', height: '1.05rem' }} />
        </button>
      </div>

      {/* Search Input Filter */}
      <div className="px-3 pt-2.5 pb-1">
        <div className="relative flex items-center">
          <Search
            style={{
              position: 'absolute',
              left: '9px',
              width: '0.8rem',
              height: '0.8rem',
              color: 'var(--text-muted)'
            }}
          />
          <input
            type="text"
            className="tess-input w-full pl-7 pr-7 py-1 text-xs rounded-lg"
            placeholder="Search dialogues..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          {searchQuery && (
            <button
              type="button"
              onClick={() => setSearchQuery('')}
              className="absolute right-2 p-0.5 text-muted hover:text-primary cursor-pointer bg-transparent border-none"
              title="Clear search"
            >
              <X style={{ width: '0.75rem', height: '0.75rem' }} />
            </button>
          )}
        </div>
      </div>

      {/* Conversations Count & Label */}
      <div className="px-3 py-1.5 flex items-center justify-between text-[11px] font-mono text-muted uppercase tracking-wider">
        <span>Dialogues</span>
        <span>{filteredConversations.length}</span>
      </div>

      {/* Scrollable Conversation List */}
      <div className="flex-1 overflow-y-auto px-2 py-1 flex flex-col gap-1">
        {filteredConversations.length === 0 ? (
          <div className="p-4 text-center text-xs text-muted flex flex-col items-center justify-center gap-1.5 select-none">
            <Sparkles style={{ width: '1rem', height: '1rem', opacity: 0.4 }} />
            <span>{searchQuery ? 'No matching dialogues' : 'No conversations yet'}</span>
          </div>
        ) : (
          filteredConversations.map((conv) => {
            const isSelected = currentConvId === conv.id;
            return (
              <button
                key={conv.id}
                type="button"
                onClick={() => onSelectConversation(conv.id)}
                className={`flex items-start gap-2.5 p-2 rounded-xl text-xs w-full text-left cursor-pointer transition-all border ${
                  isSelected
                    ? 'border-[rgba(139,92,246,0.4)] bg-[rgba(139,92,246,0.12)] text-primary shadow-sm'
                    : 'border-transparent hover:border-[rgba(255,255,255,0.06)] hover:bg-[rgba(255,255,255,0.03)] text-secondary'
                }`}
              >
                <div
                  className="mt-0.5 p-1 rounded-md flex-shrink-0"
                  style={{
                    backgroundColor: isSelected
                      ? 'rgba(139, 92, 246, 0.25)'
                      : 'rgba(255, 255, 255, 0.04)',
                    color: isSelected ? '#A78BFA' : 'var(--text-muted)'
                  }}
                >
                  <MessageSquare style={{ width: '0.8rem', height: '0.8rem' }} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-medium truncate leading-tight">
                    {conv.title || 'Untitled Dialogue'}
                  </div>
                  <div className="text-[10px] text-muted font-mono mt-0.5 flex items-center justify-between">
                    <span>{formatRelativeTime(conv.updated_at || conv.created_at)}</span>
                  </div>
                </div>
              </button>
            );
          })
        )}
      </div>
    </div>
  );
};

