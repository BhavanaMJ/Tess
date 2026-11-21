import React, { useState } from 'react';
import { Message } from '../../types';
import { Bot, User, Copy, Check, RefreshCw, Terminal } from 'lucide-react';

interface ChatMessageItemProps {
  message: Message;
  isFailed?: boolean;
  onRetry?: () => void;
}

export const ChatMessageItem: React.FC<ChatMessageItemProps> = ({
  message,
  isFailed = false,
  onRetry
}) => {
  const [copied, setCopied] = useState(false);
  const isUser = message.role === 'user';

  const handleCopy = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const formatTimestamp = (dateStr: string) => {
    try {
      const d = new Date(dateStr);
      if (isNaN(d.getTime())) return '';
      return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch {
      return '';
    }
  };

  // Custom formatted markdown / prose renderer
  const renderFormattedContent = (content: string) => {
    // Split by fenced code blocks: ```lang\ncode\n```
    const parts = content.split(/(```[\s\S]*?```)/g);

    return parts.map((part, index) => {
      if (part.startsWith('```') && part.endsWith('```')) {
        const lines = part.slice(3, -3).trim().split('\n');
        let language = 'code';
        let codeLines = lines;
        if (lines[0] && !lines[0].includes(' ') && lines.length > 1) {
          language = lines[0].trim();
          codeLines = lines.slice(1);
        }
        const codeText = codeLines.join('\n');

        return (
          <div
            key={index}
            className="my-2.5 rounded-lg overflow-hidden border border-[rgba(255,255,255,0.1)] bg-[#070913] text-xs font-mono"
          >
            <div className="flex items-center justify-between px-3 py-1.5 bg-[rgba(255,255,255,0.04)] border-b border-[rgba(255,255,255,0.06)] text-[11px] text-muted select-none">
              <span className="flex items-center gap-1.5 uppercase font-semibold text-[#A78BFA]">
                <Terminal style={{ width: '0.75rem', height: '0.75rem' }} />
                {language || 'text'}
              </span>
              <button
                type="button"
                onClick={() => handleCopy(codeText)}
                className="flex items-center gap-1 text-[11px] text-muted hover:text-primary transition-colors cursor-pointer bg-transparent border-none p-0"
                title="Copy code"
              >
                {copied ? (
                  <>
                    <Check style={{ width: '0.75rem', height: '0.75rem', color: '#34D399' }} />
                    <span className="text-[#34D399]">Copied</span>
                  </>
                ) : (
                  <>
                    <Copy style={{ width: '0.75rem', height: '0.75rem' }} />
                    <span>Copy</span>
                  </>
                )}
              </button>
            </div>
            <pre className="p-3 overflow-x-auto text-[#E2E8F0] m-0 leading-relaxed font-mono">
              <code>{codeText}</code>
            </pre>
          </div>
        );
      }

      // Format non-code paragraphs: bold, inline code, list items
      const paragraphs = part.split(/\n\n+/);
      return (
        <div key={index} className="space-y-2">
          {paragraphs.map((p, pIdx) => {
            const trimmed = p.trim();
            if (!trimmed) return null;

            // List item detection
            const lines = trimmed.split('\n');
            const isBulletList = lines.every((l) => /^\s*[-*•]\s+/.test(l));
            const isNumberedList = lines.every((l) => /^\s*\d+\.\s+/.test(l));

            if (isBulletList) {
              return (
                <ul key={pIdx} className="list-disc list-inside space-y-1 my-1 pl-1">
                  {lines.map((line, lIdx) => (
                    <li key={lIdx} className="leading-relaxed">
                      {formatInlineText(line.replace(/^\s*[-*•]\s+/, ''))}
                    </li>
                  ))}
                </ul>
              );
            }

            if (isNumberedList) {
              return (
                <ol key={pIdx} className="list-decimal list-inside space-y-1 my-1 pl-1">
                  {lines.map((line, lIdx) => (
                    <li key={lIdx} className="leading-relaxed">
                      {formatInlineText(line.replace(/^\s*\d+\.\s+/, ''))}
                    </li>
                  ))}
                </ol>
              );
            }

            // Heading detection
            if (trimmed.startsWith('### ')) {
              return (
                <h4 key={pIdx} className="text-xs font-bold text-[#A78BFA] mt-2 mb-1">
                  {formatInlineText(trimmed.slice(4))}
                </h4>
              );
            }
            if (trimmed.startsWith('## ')) {
              return (
                <h3 key={pIdx} className="text-sm font-bold text-primary mt-3 mb-1">
                  {formatInlineText(trimmed.slice(3))}
                </h3>
              );
            }
            if (trimmed.startsWith('# ')) {
              return (
                <h2 key={pIdx} className="text-sm font-extrabold text-primary mt-3 mb-1">
                  {formatInlineText(trimmed.slice(2))}
                </h2>
              );
            }

            return (
              <p key={pIdx} className="leading-relaxed m-0 whitespace-pre-wrap">
                {formatInlineText(trimmed)}
              </p>
            );
          })}
        </div>
      );
    });
  };

  // Helper to format inline code (`code`), bold (**text**), italic (*text*)
  const formatInlineText = (text: string): React.ReactNode => {
    const inlineCodeRegex = /(`[^`]+`)/g;
    const parts = text.split(inlineCodeRegex);

    return parts.map((part, idx) => {
      if (part.startsWith('`') && part.endsWith('`')) {
        return (
          <code
            key={idx}
            className="px-1.5 py-0.5 rounded bg-[rgba(255,255,255,0.08)] text-[#A78BFA] font-mono text-[11px] border border-[rgba(255,255,255,0.06)]"
          >
            {part.slice(1, -1)}
          </code>
        );
      }

      // Check bold **bold**
      const boldParts = part.split(/(\*\*[^*]+\*\*)/g);
      return boldParts.map((bPart, bIdx) => {
        if (bPart.startsWith('**') && bPart.endsWith('**')) {
          return (
            <strong key={`${idx}-${bIdx}`} className="font-semibold text-primary">
              {bPart.slice(2, -2)}
            </strong>
          );
        }
        return bPart;
      });
    });
  };

  return (
    <div
      className={`flex items-start gap-3 w-full group ${
        isUser ? 'justify-end' : 'justify-start'
      }`}
      data-testid={`chat-message-${message.id}`}
    >
      {/* Bot Avatar */}
      {!isUser && (
        <div
          className="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5"
          style={{
            backgroundColor: 'rgba(53, 185, 165, 0.15)',
            border: '1px solid rgba(53, 185, 165, 0.4)',
            color: 'var(--brand-mint, #35B9A5)'
          }}
          title="TESS Companion AI"
        >
          <Bot style={{ width: '1rem', height: '1rem' }} />
        </div>
      )}

      {/* Message Bubble Container */}
      <div
        className="flex flex-col relative max-w-[82%]"
        style={{ minWidth: '80px' }}
      >
        <div
          className={`p-3.5 rounded-2xl text-xs transition-all ${
            isFailed
              ? 'border border-[#FB7185] bg-[rgba(251,113,133,0.1)]'
              : isUser
              ? 'rounded-tr-sm'
              : 'rounded-tl-sm'
          }`}
          style={{
            backgroundColor: isFailed
              ? 'rgba(251, 113, 133, 0.12)'
              : isUser
              ? 'rgba(139, 92, 246, 0.16)'
              : 'var(--bg-surface-elevated, #171A2D)',
            border: isFailed
              ? '1px solid rgba(251, 113, 133, 0.5)'
              : isUser
              ? '1px solid rgba(139, 92, 246, 0.35)'
              : '1px solid var(--border, rgba(255, 255, 255, 0.08))',
            color: 'var(--text-primary, #F8FAFC)',
            boxShadow: isUser
              ? '0 4px 14px rgba(139, 92, 246, 0.12)'
              : '0 4px 16px rgba(0, 0, 0, 0.25)',
            backdropFilter: 'blur(12px)'
          }}
        >
          {renderFormattedContent(message.content)}
        </div>

        {/* Message Metadata & Action Bar */}
        <div
          className={`flex items-center gap-2 mt-1 px-1 text-[11px] text-muted ${
            isUser ? 'justify-end' : 'justify-start'
          }`}
        >
          <span className="font-mono text-[10px]">
            {formatTimestamp(message.created_at)}
          </span>

          {/* Copy Button */}
          <button
            type="button"
            onClick={() => handleCopy(message.content)}
            className="opacity-0 group-hover:opacity-100 transition-opacity p-0.5 rounded hover:text-primary cursor-pointer bg-transparent border-none flex items-center"
            title="Copy message"
          >
            {copied ? (
              <Check style={{ width: '0.75rem', height: '0.75rem', color: '#34D399' }} />
            ) : (
              <Copy style={{ width: '0.75rem', height: '0.75rem' }} />
            )}
          </button>

          {/* Retry Button if failed */}
          {isFailed && onRetry && (
            <button
              type="button"
              onClick={onRetry}
              className="flex items-center gap-1 text-[#FB7185] hover:text-[#FDA4AF] transition-colors cursor-pointer bg-transparent border-none p-0 ml-1 font-semibold"
              title="Retry sending message"
            >
              <RefreshCw style={{ width: '0.75rem', height: '0.75rem' }} />
              <span>Retry</span>
            </button>
          )}
        </div>
      </div>

      {/* User Avatar */}
      {isUser && (
        <div
          className="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5"
          style={{
            backgroundColor: 'rgba(255, 255, 255, 0.06)',
            border: '1px solid rgba(255, 255, 255, 0.15)',
            color: 'var(--text-secondary, #CBD5E1)'
          }}
          title="You"
        >
          <User style={{ width: '1rem', height: '1rem' }} />
        </div>
      )}
    </div>
  );
};
