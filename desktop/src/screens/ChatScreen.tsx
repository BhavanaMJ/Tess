import React, { useEffect, useState, useRef } from 'react';
import { apiService } from '../services/api';
import { Conversation, Message } from '../types';
import { useMascot } from '../contexts/MascotContext';
import {
  Plus,
  Send,
  MessageSquare,
  Bot,
  User,
  AlertCircle,
  Mic,
  MicOff,
  Monitor,
  X,
  Copy,
  Check,
  Sparkles,
  Compass,
  Clock,
  ShieldAlert,
  ArrowRight
} from 'lucide-react';

export const ChatScreen: React.FC = () => {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [currentConvId, setCurrentConvId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  // Phase 8: Voice Assistant state
  const [isRecording, setIsRecording] = useState(false);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const currentAudioRef = useRef<HTMLAudioElement | null>(null);

  // Phase 8: Screen Understanding state
  const [capturedImageBlob, setCapturedImageBlob] = useState<Blob | null>(null);
  const [screenPreviewUrl, setScreenPreviewUrl] = useState<string | null>(null);
  const [screenQuery, setScreenQuery] = useState('Explain what is on this screen and any potential errors.');
  const [analyzingScreen, setAnalyzingScreen] = useState(false);

  const { setState: setMascotState } = useMascot();
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const loadConversations = async () => {
    try {
      setLoading(true);
      const convs = await apiService.getConversations();
      setConversations(convs);
      if (convs.length > 0 && !currentConvId) {
        setCurrentConvId(convs[0].id);
      } else if (convs.length === 0) {
        handleNewConversation();
      }
    } catch (e: any) {
      setError(e.message || 'Failed to load conversations');
    } finally {
      setLoading(false);
    }
  };

  const loadMessages = async (convId: string) => {
    try {
      setError(null);
      const msgs = await apiService.getMessages(convId);
      setMessages(msgs);
    } catch (e: any) {
      setError(e.message || 'Failed to load messages');
    }
  };

  useEffect(() => {
    loadConversations();
  }, []);

  useEffect(() => {
    if (currentConvId) {
      loadMessages(currentConvId);
    }
  }, [currentConvId]);

  useEffect(() => {
    scrollToBottom();
  }, [messages, sending]);

  const handleNewConversation = async () => {
    try {
      const newConv = await apiService.createConversation('Companion Dialogue');
      setConversations((prev) => [newConv, ...prev]);
      setCurrentConvId(newConv.id);
      setMessages([]);
    } catch (e: any) {
      setError(e.message || 'Failed to create conversation');
    }
  };

  const handleSendMessage = async (textToSend?: string) => {
    const text = textToSend || inputText.trim();
    if (!text || !currentConvId || sending) return;

    if (!textToSend) setInputText('');
    setSending(true);
    setMascotState('THINKING');

    const tempMsg: Message = {
      id: 'temp-' + Date.now(),
      conversation_id: currentConvId,
      role: 'user',
      content: text,
      created_at: new Date().toISOString()
    };
    setMessages((prev) => [...prev, tempMsg]);

    try {
      const res = await apiService.sendMessage(currentConvId, text);
      const botMsg: Message = {
        id: 'bot-' + Date.now(),
        conversation_id: currentConvId,
        role: 'assistant',
        content: res.response,
        created_at: new Date().toISOString()
      };
      setMessages((prev) => [...prev, botMsg]);
      setMascotState('IDLE');
    } catch (e: any) {
      setError(e.message || 'Failed to send message');
      setMascotState('ERROR');
    } finally {
      setSending(false);
    }
  };

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  // Phase 8: Voice Assistant Handler
  const toggleVoiceRecording = async () => {
    if (currentAudioRef.current) {
      currentAudioRef.current.pause();
      currentAudioRef.current = null;
    }

    if (isRecording) {
      if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
        mediaRecorderRef.current.stop();
      }
      setIsRecording(false);
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      audioChunksRef.current = [];
      const recorder = new MediaRecorder(stream);

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) audioChunksRef.current.push(e.data);
      };

      recorder.onstop = async () => {
        stream.getTracks().forEach((track) => track.stop());
        const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/wav' });
        if (audioBlob.size < 100) return;

        setMascotState('THINKING');
        setSending(true);

        try {
          const res = await apiService.voiceInteract(audioBlob);

          if (currentConvId) {
            const userMsg: Message = {
              id: 'voice-user-' + Date.now(),
              conversation_id: currentConvId,
              role: 'user',
              content: res.transcript,
              created_at: new Date().toISOString()
            };
            const botMsg: Message = {
              id: 'voice-bot-' + Date.now(),
              conversation_id: currentConvId,
              role: 'assistant',
              content: res.response_text,
              created_at: new Date().toISOString()
            };
            setMessages((prev) => [...prev, userMsg, botMsg]);
          }

          if (res.audio_base64) {
            setMascotState('SPEAKING');
            const audio = new Audio(`data:audio/wav;base64,${res.audio_base64}`);
            currentAudioRef.current = audio;
            audio.onended = () => {
              setMascotState('IDLE');
              currentAudioRef.current = null;
            };
            await audio.play();
          } else {
            setMascotState('IDLE');
          }
        } catch (err: any) {
          setError('Voice interaction failed: ' + (err.message || String(err)));
          setMascotState('ERROR');
        } finally {
          setSending(false);
        }
      };

      mediaRecorderRef.current = recorder;
      recorder.start();
      setIsRecording(true);
      setMascotState('LISTENING');
    } catch (err: any) {
      setError('Microphone access denied: ' + err.message);
      setMascotState('ERROR');
    }
  };

  // Phase 8: Screen Capture Handler (User-Authorized)
  const triggerScreenCapture = async () => {
    try {
      const stream = await navigator.mediaDevices.getDisplayMedia({ video: true });
      const video = document.createElement('video');
      video.srcObject = stream;
      await video.play();

      const canvas = document.createElement('canvas');
      canvas.width = video.videoWidth || 1280;
      canvas.height = video.videoHeight || 720;
      const ctx = canvas.getContext('2d');
      ctx?.drawImage(video, 0, 0, canvas.width, canvas.height);

      stream.getTracks().forEach((track) => track.stop());

      canvas.toBlob((blob) => {
        if (blob) {
          setCapturedImageBlob(blob);
          setScreenPreviewUrl(URL.createObjectURL(blob));
        }
      }, 'image/jpeg', 0.85);
    } catch (err: any) {
      if (err.name !== 'NotAllowedError') {
        setError('Screen capture failed: ' + err.message);
      }
    }
  };

  const confirmScreenAnalysis = async () => {
    if (!capturedImageBlob || !currentConvId) return;
    setAnalyzingScreen(true);
    setMascotState('VIEWING');

    try {
      const result = await apiService.analyzeScreen(capturedImageBlob, screenQuery);

      const userMsg: Message = {
        id: 'screen-user-' + Date.now(),
        conversation_id: currentConvId,
        role: 'user',
        content: `[Visual Telemetry Query]: ${screenQuery}`,
        created_at: new Date().toISOString()
      };
      const botMsg: Message = {
        id: 'screen-bot-' + Date.now(),
        conversation_id: currentConvId,
        role: 'assistant',
        content: result.analysis,
        created_at: new Date().toISOString()
      };
      setMessages((prev) => [...prev, userMsg, botMsg]);
      setMascotState('IDLE');
      setScreenPreviewUrl(null);
      setCapturedImageBlob(null);
    } catch (err: any) {
      setError('Screen analysis failed: ' + (err.message || String(err)));
      setMascotState('ERROR');
    } finally {
      setAnalyzingScreen(false);
    }
  };

  const quickActionPrompts = [
    { label: 'Priority Check', prompt: 'What should I prioritize today?' },
    { label: 'Future Simulation', prompt: 'Show me where my current trajectory is taking me.' },
    { label: 'Procrastination Audit', prompt: 'What important work am I postponing?' },
    { label: 'Task Execution', prompt: 'Help me complete an overdue task on OpenProject.' }
  ];

  return (
    <div className="flex h-full" style={{ height: 'calc(100vh - 68px)' }}>
      {/* CONVERSATION THREAD RAIL */}
      <div
        className="flex flex-col border-r select-none"
        style={{
          width: '260px',
          backgroundColor: 'var(--bg-secondary)',
          borderColor: 'var(--border)'
        }}
      >
        <div className="p-3 border-b border-[rgba(255,255,255,0.06)]">
          <button
            onClick={handleNewConversation}
            className="btn-primary w-full text-xs justify-center"
          >
            <Plus style={{ width: '0.9rem', height: '0.9rem' }} />
            <span>New Dialogue</span>
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-2 flex flex-col gap-1">
          {conversations.map((conv) => {
            const isSelected = currentConvId === conv.id;
            return (
              <button
                key={conv.id}
                onClick={() => setCurrentConvId(conv.id)}
                className="flex items-center gap-2.5 p-2 rounded-lg text-xs w-full text-left truncate cursor-pointer transition-all"
                style={{
                  backgroundColor: isSelected ? 'rgba(139, 92, 246, 0.12)' : 'transparent',
                  color: isSelected ? '#FFFFFF' : 'var(--text-secondary)',
                  border: isSelected ? '1px solid rgba(139, 92, 246, 0.35)' : '1px solid transparent'
                }}
              >
                <MessageSquare
                  style={{
                    width: '0.85rem',
                    height: '0.85rem',
                    color: isSelected ? '#A78BFA' : 'var(--text-muted)',
                    flexShrink: 0
                  }}
                />
                <span className="truncate">{conv.title || 'Untitled Session'}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* CHAT MESSAGES & COMPOSER CONTAINER */}
      <div className="flex-1 flex flex-col h-full bg-primary relative overflow-hidden">
        {error && (
          <div
            className="p-3 text-xs flex items-center justify-between border-b"
            style={{
              backgroundColor: 'rgba(251, 113, 133, 0.1)',
              borderColor: 'rgba(251, 113, 133, 0.3)',
              color: '#FB7185'
            }}
          >
            <div className="flex items-center gap-2">
              <AlertCircle style={{ width: '1rem', height: '1rem' }} />
              <span>{error}</span>
            </div>
            <button
              onClick={() => setError(null)}
              className="text-muted hover:text-primary cursor-pointer"
              style={{ background: 'none', border: 'none' }}
            >
              <X style={{ width: '0.9rem', height: '0.9rem' }} />
            </button>
          </div>
        )}

        {/* SCREEN ANALYSIS PREVIEW BANNER */}
        {screenPreviewUrl && (
          <div
            className="p-3 border-b flex items-center gap-4 bg-[rgba(34,211,238,0.06)] border-[rgba(34,211,238,0.25)]"
          >
            <img
              src={screenPreviewUrl}
              alt="Screen Preview"
              className="w-24 h-16 object-cover rounded-md border border-[rgba(34,211,238,0.3)] shadow-md"
            />
            <div className="flex-1 flex flex-col gap-1.5">
              <span className="text-xs font-mono font-semibold text-[#22D3EE] uppercase tracking-wider">
                Screen Telemetry Captured
              </span>
              <input
                type="text"
                className="tess-input text-xs py-1"
                placeholder="Question about your screen..."
                value={screenQuery}
                onChange={(e) => setScreenQuery(e.target.value)}
              />
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={confirmScreenAnalysis}
                disabled={analyzingScreen}
                className="btn-cyan text-xs py-1.5 px-3"
              >
                {analyzingScreen ? 'Analyzing...' : 'Analyze'}
              </button>
              <button
                onClick={() => {
                  setScreenPreviewUrl(null);
                  setCapturedImageBlob(null);
                }}
                className="p-1.5 text-muted hover:text-primary rounded cursor-pointer"
                style={{ background: 'none', border: 'none' }}
              >
                <X style={{ width: '1rem', height: '1rem' }} />
              </button>
            </div>
          </div>
        )}

        {/* MESSAGE STREAM */}
        <div className="flex-1 overflow-y-auto p-6 flex flex-col gap-4">
          {messages.length === 0 ? (
            <div className="flex-1 flex flex-col items-center justify-center text-center p-8 select-none">
              <div className="w-14 h-14 rounded-full bg-[rgba(139,92,246,0.12)] border border-[rgba(139,92,246,0.35)] flex items-center justify-center mb-3">
                <Sparkles style={{ width: '1.75rem', height: '1.75rem', color: '#A78BFA' }} />
              </div>
              <h3 className="text-base font-bold text-primary m-0 tracking-wide">
                TESS Continuous Dialogue
              </h3>
              <p className="text-xs text-muted max-w-sm mt-1.5 leading-relaxed">
                I remember your context, synchronize with your OpenProject workspace, and predict future trajectories.
              </p>

              {/* Quick Action Suggestions */}
              <div className="grid grid-cols-2 gap-2 mt-6 max-w-md w-full">
                {quickActionPrompts.map((item, idx) => (
                  <button
                    key={idx}
                    onClick={() => handleSendMessage(item.prompt)}
                    className="p-2.5 rounded-lg text-left text-xs bg-[rgba(255,255,255,0.02)] border border-[rgba(255,255,255,0.06)] hover:border-[rgba(139,92,246,0.4)] hover:bg-[rgba(139,92,246,0.06)] text-secondary hover:text-primary transition-all cursor-pointer flex items-center justify-between group"
                  >
                    <span>{item.label}</span>
                    <ArrowRight style={{ width: '0.75rem', height: '0.75rem', opacity: 0.5 }} />
                  </button>
                ))}
              </div>
            </div>
          ) : (
            messages.map((msg) => {
              const isUser = msg.role === 'user';
              return (
                <div
                  key={msg.id}
                  className={`flex items-start gap-3 ${isUser ? 'justify-end' : 'justify-start'}`}
                >
                  {!isUser && (
                    <div
                      className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0"
                      style={{
                        backgroundColor: 'rgba(139, 92, 246, 0.15)',
                        border: '1px solid rgba(139, 92, 246, 0.4)',
                        color: '#A78BFA'
                      }}
                    >
                      <Bot style={{ width: '0.95rem', height: '0.95rem' }} />
                    </div>
                  )}

                  <div
                    className="flex flex-col group relative"
                    style={{ maxWidth: '78%' }}
                  >
                    <div
                      className="p-3.5 rounded-2xl text-xs leading-relaxed transition-all"
                      style={{
                        backgroundColor: isUser
                          ? 'rgba(139, 92, 246, 0.18)'
                          : 'rgba(23, 26, 45, 0.85)',
                        border: isUser
                          ? '1px solid rgba(139, 92, 246, 0.4)'
                          : '1px solid rgba(255, 255, 255, 0.08)',
                        color: '#F8FAFC',
                        boxShadow: isUser
                          ? '0 4px 16px rgba(139, 92, 246, 0.15)'
                          : '0 4px 20px rgba(0, 0, 0, 0.3)',
                        backdropFilter: 'blur(16px)'
                      }}
                    >
                      <div className="whitespace-pre-wrap">{msg.content}</div>
                    </div>

                    <div className="flex items-center gap-2 mt-1 px-1">
                      <span className="font-mono text-[10px] text-muted">
                        {new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                      <button
                        onClick={() => copyToClipboard(msg.content, msg.id)}
                        className="opacity-0 group-hover:opacity-100 transition-opacity text-muted hover:text-primary cursor-pointer p-0"
                        style={{ background: 'none', border: 'none' }}
                        title="Copy message"
                      >
                        {copiedId === msg.id ? (
                          <Check style={{ width: '0.75rem', height: '0.75rem', color: '#34D399' }} />
                        ) : (
                          <Copy style={{ width: '0.75rem', height: '0.75rem' }} />
                        )}
                      </button>
                    </div>
                  </div>

                  {isUser && (
                    <div
                      className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0"
                      style={{
                        backgroundColor: 'rgba(255, 255, 255, 0.06)',
                        border: '1px solid rgba(255, 255, 255, 0.15)',
                        color: 'var(--text-secondary)'
                      }}
                    >
                      <User style={{ width: '0.95rem', height: '0.95rem' }} />
                    </div>
                  )}
                </div>
              );
            })
          )}

          {/* Thinking Holographic Wave Indicator */}
          {sending && (
            <div className="flex items-center gap-3">
              <div
                className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 animate-pulse"
                style={{
                  backgroundColor: 'rgba(139, 92, 246, 0.2)',
                  border: '1px solid #8B5CF6',
                  color: '#A78BFA'
                }}
              >
                <Bot style={{ width: '0.95rem', height: '0.95rem' }} />
              </div>
              <div
                className="p-3 rounded-2xl flex items-center gap-1.5"
                style={{
                  backgroundColor: 'rgba(23, 26, 45, 0.85)',
                  border: '1px solid rgba(139, 92, 246, 0.3)'
                }}
              >
                <span className="w-1.5 h-1.5 rounded-full bg-[#8B5CF6] animate-ping" />
                <span className="text-xs font-mono text-[#A78BFA] tracking-wider uppercase ml-1">
                  Synthesizing Response...
                </span>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* CHAT COMPOSER WITH VOICE & SCREEN AFFORDANCES */}
        <div
          className="p-4 border-t border-[rgba(255,255,255,0.06)]"
          style={{ backgroundColor: 'var(--bg-secondary)' }}
        >
          <form
            onSubmit={(e) => {
              e.preventDefault();
              handleSendMessage();
            }}
            className="flex items-end gap-2"
          >
            {/* Voice Input Button */}
            <button
              type="button"
              onClick={toggleVoiceRecording}
              className={`p-2.5 rounded-xl transition-all cursor-pointer flex-shrink-0 ${
                isRecording
                  ? 'bg-[#FB7185] text-white shadow-[0_0_15px_#FB7185] animate-pulse'
                  : 'bg-[rgba(255,255,255,0.04)] text-secondary hover:text-primary hover:bg-[rgba(255,255,255,0.08)]'
              }`}
              style={{ border: '1px solid var(--border)' }}
              title={isRecording ? 'Stop Recording' : 'Voice Interaction'}
            >
              {isRecording ? (
                <MicOff style={{ width: '1.05rem', height: '1.05rem' }} />
              ) : (
                <Mic style={{ width: '1.05rem', height: '1.05rem' }} />
              )}
            </button>

            {/* Screen Capture Button */}
            <button
              type="button"
              onClick={triggerScreenCapture}
              className="p-2.5 rounded-xl bg-[rgba(255,255,255,0.04)] text-secondary hover:text-primary hover:bg-[rgba(255,255,255,0.08)] transition-all cursor-pointer flex-shrink-0"
              style={{ border: '1px solid var(--border)' }}
              title="Capture & Analyze Screen Telemetry"
            >
              <Monitor style={{ width: '1.05rem', height: '1.05rem' }} />
            </button>

            {/* Multiline Composer Input */}
            <div className="flex-1 relative">
              <textarea
                ref={textareaRef}
                className="tess-input resize-none py-2 px-3 text-xs"
                placeholder={
                  isRecording
                    ? 'Listening to your voice...'
                    : 'Communicate with TESS (Enter to send, Shift+Enter for newline)...'
                }
                rows={1}
                value={inputText}
                onChange={(e) => setInputText(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    handleSendMessage();
                  }
                }}
                disabled={sending || isRecording}
                style={{ minHeight: '40px', maxHeight: '120px' }}
              />
            </div>

            {/* Send Button */}
            <button
              type="submit"
              disabled={!inputText.trim() || sending || isRecording}
              className="btn-primary py-2 px-4 rounded-xl flex-shrink-0"
              title="Transmit Message"
            >
              <Send style={{ width: '0.95rem', height: '0.95rem' }} />
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};
