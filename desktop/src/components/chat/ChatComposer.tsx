import React, { useRef, useEffect } from 'react';
import { Send, Mic, MicOff, Monitor } from 'lucide-react';

interface ChatComposerProps {
  inputText: string;
  setInputText: (text: string) => void;
  onSendMessage: (text?: string) => void;
  sending: boolean;
  isRecording: boolean;
  onToggleVoice: () => void;
  onCaptureScreen: () => void;
  onTyping?: () => void;
}

export const ChatComposer: React.FC<ChatComposerProps> = ({
  inputText,
  setInputText,
  onSendMessage,
  sending,
  isRecording,
  onToggleVoice,
  onCaptureScreen,
  onTyping
}) => {
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // Auto-resize textarea as content changes
  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      const scrollHeight = textareaRef.current.scrollHeight;
      // Clamp between 40px and 140px
      const newHeight = Math.min(Math.max(scrollHeight, 40), 140);
      textareaRef.current.style.height = `${newHeight}px`;
    }
  }, [inputText]);

  // Handle keydown for Enter to send vs Shift+Enter for newline
  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      if (inputText.trim() && !sending && !isRecording) {
        onSendMessage();
      }
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setInputText(e.target.value);
    if (onTyping) {
      onTyping();
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (inputText.trim() && !sending && !isRecording) {
      onSendMessage();
    }
  };

  return (
    <div
      className="p-3 border-t select-none"
      style={{
        backgroundColor: 'var(--bg-secondary, #0B0D18)',
        borderColor: 'var(--border, rgba(255, 255, 255, 0.08))'
      }}
    >
      <form onSubmit={handleSubmit} className="flex items-end gap-2 max-w-4xl mx-auto">
        {/* Voice Interaction Mic Button */}
        <button
          type="button"
          onClick={onToggleVoice}
          className={`p-2.5 rounded-xl transition-all cursor-pointer flex-shrink-0 flex items-center justify-center border ${
            isRecording
              ? 'bg-[#FB7185] text-white border-[#FB7185] shadow-[0_0_16px_rgba(251,113,133,0.6)] animate-pulse'
              : 'bg-[rgba(255,255,255,0.04)] text-secondary hover:text-primary hover:bg-[rgba(255,255,255,0.08)] border-[rgba(255,255,255,0.08)]'
          }`}
          title={isRecording ? 'Stop Recording' : 'Voice Assistant (Push to Speak)'}
          aria-label={isRecording ? 'Stop Recording' : 'Start Voice Recording'}
        >
          {isRecording ? (
            <MicOff style={{ width: '1.05rem', height: '1.05rem' }} />
          ) : (
            <Mic style={{ width: '1.05rem', height: '1.05rem' }} />
          )}
        </button>

        {/* Screen Capture Telemetry Button */}
        <button
          type="button"
          onClick={onCaptureScreen}
          disabled={sending || isRecording}
          className="p-2.5 rounded-xl bg-[rgba(255,255,255,0.04)] text-secondary hover:text-primary hover:bg-[rgba(255,255,255,0.08)] transition-all cursor-pointer flex-shrink-0 flex items-center justify-center border border-[rgba(255,255,255,0.08)] disabled:opacity-40 disabled:cursor-not-allowed"
          title="Capture & Analyze Screen Telemetry"
          aria-label="Capture Screen"
        >
          <Monitor style={{ width: '1.05rem', height: '1.05rem' }} />
        </button>

        {/* Auto-Resizing Multiline Textarea */}
        <div className="flex-1 relative">
          <textarea
            ref={textareaRef}
            className="tess-input w-full resize-none py-2.5 px-3.5 text-xs rounded-xl transition-all"
            placeholder={
              isRecording
                ? 'Listening to your voice...'
                : sending
                ? 'TESS is synthesizing a response...'
                : 'Communicate with TESS (Enter to send, Shift+Enter for newline)...'
            }
            rows={1}
            value={inputText}
            onChange={handleChange}
            onKeyDown={handleKeyDown}
            disabled={sending || isRecording}
            style={{
              minHeight: '40px',
              maxHeight: '140px',
              backgroundColor: 'var(--bg-surface, #111426)',
              borderColor: 'var(--border, rgba(255, 255, 255, 0.08))',
              lineHeight: '1.4'
            }}
          />
        </div>

        {/* Send Action Button */}
        <button
          type="submit"
          disabled={!inputText.trim() || sending || isRecording}
          className="btn-primary p-2.5 rounded-xl flex-shrink-0 flex items-center justify-center disabled:opacity-40 disabled:cursor-not-allowed"
          title="Send message"
          aria-label="Send Message"
        >
          <Send style={{ width: '1rem', height: '1rem' }} />
        </button>
      </form>
    </div>
  );
};

