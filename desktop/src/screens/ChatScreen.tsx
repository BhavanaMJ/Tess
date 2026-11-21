import React, { useEffect, useState, useRef, useCallback } from 'react';
import { apiService } from '../services/api';
import { Conversation, Message } from '../types';
import { useMascot } from '../contexts/MascotContext';
import { ChatSidebar } from '../components/chat/ChatSidebar';
import { ChatMessageItem } from '../components/chat/ChatMessageItem';
import { ChatComposer } from '../components/chat/ChatComposer';
import {
  Bot,
  AlertCircle,
  X,
  Sparkles,
  RefreshCw,
  Plus,
  ArrowRight,
  Target,
  TrendingUp,
  Clock,
  CheckCircle2
} from 'lucide-react';

export const ChatScreen: React.FC = () => {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [currentConvId, setCurrentConvId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [failedMessageText, setFailedMessageText] = useState<string | null>(null);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);

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

  // Mascot Context integration (authoritative single character state)
  const { state: mascotState, setState: setMascotState, triggerEmotion } = useMascot();
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const typingTimerRef = useRef<NodeJS.Timeout | null>(null);

  const scrollToBottom = (behavior: ScrollBehavior = 'smooth') => {
    if (messagesEndRef.current && typeof messagesEndRef.current.scrollIntoView === 'function') {
      messagesEndRef.current.scrollIntoView({ behavior });
    }
  };

  const loadConversations = useCallback(async () => {
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
  }, [currentConvId]);

  const loadMessages = useCallback(async (convId: string) => {
    try {
      setError(null);
      setFailedMessageText(null);
      const msgs = await apiService.getMessages(convId);
      setMessages(msgs);
    } catch (e: any) {
      setError(e.message || 'Failed to load messages');
    }
  }, []);

  useEffect(() => {
    loadConversations();
  }, []);

  useEffect(() => {
    if (currentConvId) {
      loadMessages(currentConvId);
    }
  }, [currentConvId, loadMessages]);

  useEffect(() => {
    scrollToBottom();
  }, [messages, sending]);

  const handleNewConversation = async () => {
    try {
      setError(null);
      const newConv = await apiService.createConversation('Companion Dialogue');
      setConversations((prev) => [newConv, ...prev]);
      setCurrentConvId(newConv.id);
      setMessages([]);
      setFailedMessageText(null);
    } catch (e: any) {
      setError(e.message || 'Failed to create conversation');
    }
  };

  // Debounced typing callback to show listening state
  const handleTyping = () => {
    if (mascotState === 'IDLE') {
      setMascotState('LISTENING');
    }
    if (typingTimerRef.current) {
      clearTimeout(typingTimerRef.current);
    }
    typingTimerRef.current = setTimeout(() => {
      setMascotState('IDLE');
    }, 1500);
  };

  const handleSendMessage = async (textToSend?: string) => {
    const text = (textToSend || inputText).trim();
    if (!text || !currentConvId || sending) return;

    if (!textToSend) setInputText('');
    setSending(true);
    setError(null);
    setFailedMessageText(null);
    setMascotState('THINKING');

    const tempMsgId = 'temp-' + Date.now();
    const tempMsg: Message = {
      id: tempMsgId,
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
      triggerEmotion('HAPPY', 3500);
    } catch (e: any) {
      setError(e.message || 'Failed to transmit message. You can retry below.');
      setFailedMessageText(text);
      triggerEmotion('ERROR', 5000);
    } finally {
      setSending(false);
    }
  };

  const handleRetry = () => {
    if (failedMessageText) {
      // Remove last failed temporary user message to avoid duplicate display
      setMessages((prev) => {
        if (prev.length > 0 && prev[prev.length - 1].role === 'user') {
          return prev.slice(0, -1);
        }
        return prev;
      });
      handleSendMessage(failedMessageText);
    }
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
            triggerEmotion('HAPPY', 3500);
          }
        } catch (err: any) {
          setError('Voice interaction failed: ' + (err.message || String(err)));
          triggerEmotion('ERROR', 5000);
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
      triggerEmotion('ERROR', 5000);
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
      triggerEmotion('HAPPY', 3500);
      setScreenPreviewUrl(null);
      setCapturedImageBlob(null);
    } catch (err: any) {
      setError('Screen analysis failed: ' + (err.message || String(err)));
      triggerEmotion('ERROR', 5000);
    } finally {
      setAnalyzingScreen(false);
    }
  };

  const quickActionPrompts = [
    {
      label: 'Priority Check',
      description: 'Find highest impact focus areas',
      prompt: 'What should I prioritize today based on my goals?',
      icon: Target,
      color: '#34D399'
    },
    {
      label: 'Trajectory Simulation',
      description: 'Forecast end-of-week outcomes',
      prompt: 'Show me where my current trajectory is taking me.',
      icon: TrendingUp,
      color: '#A78BFA'
    },
    {
      label: 'Procrastination Audit',
      description: 'Identify postponed critical work',
      prompt: 'What critical tasks or blockers am I postponing?',
      icon: Clock,
      color: '#FBBF24'
    },
    {
      label: 'Task Execution',
      description: 'Break down an active work package',
      prompt: 'Help me break down and complete my highest impact task.',
      icon: CheckCircle2,
      color: '#22D3EE'
    }
  ];

  const currentConv = conversations.find((c) => c.id === currentConvId);

  // Companion status badge details
  const getMascotStatusPill = () => {
    switch (mascotState) {
      case 'THINKING':
        return { label: 'Thinking...', color: '#A78BFA', bg: 'rgba(167, 139, 250, 0.15)' };
      case 'LISTENING':
        return { label: 'Listening...', color: '#38BDF8', bg: 'rgba(56, 189, 248, 0.15)' };
      case 'SPEAKING':
        return { label: 'Speaking', color: '#34D399', bg: 'rgba(52, 211, 153, 0.15)' };
      case 'VIEWING':
        return { label: 'Analyzing Screen', color: '#22D3EE', bg: 'rgba(34, 211, 238, 0.15)' };
      case 'HAPPY':
        return { label: 'Delighted', color: '#35B9A5', bg: 'rgba(53, 185, 165, 0.15)' };
      case 'ERROR':
        return { label: 'Attention Needed', color: '#FB7185', bg: 'rgba(251, 113, 133, 0.15)' };
      default:
        return { label: 'Companion Ready', color: '#35B9A5', bg: 'rgba(53, 185, 165, 0.12)' };
    }
  };

  const statusPill = getMascotStatusPill();

  return (
    <div className="flex h-full w-full overflow-hidden" data-testid="companion-chat-screen">
      {/* 1. CONVERSATION THREAD RAIL */}
      <ChatSidebar
        conversations={conversations}
        currentConvId={currentConvId}
        onSelectConversation={(id) => setCurrentConvId(id)}
        onNewConversation={handleNewConversation}
        isCollapsed={isSidebarCollapsed}
        onToggleCollapse={() => setIsSidebarCollapsed((prev) => !prev)}
      />

      {/* 2. MAIN CHAT WORKSPACE */}
      <div
        className="flex-1 flex flex-col h-full relative overflow-hidden"
        style={{ backgroundColor: 'var(--bg-primary, #080910)' }}
      >
        {/* Workspace Top Header Bar */}
        <div
          className="px-5 py-3 border-b flex items-center justify-between select-none z-10"
          style={{
            backgroundColor: 'var(--bg-secondary, #0B0D18)',
            borderColor: 'var(--border, rgba(255, 255, 255, 0.08))'
          }}
        >
          <div className="flex items-center gap-3">
            <div>
              <h2 className="text-sm font-bold text-primary m-0 tracking-wide flex items-center gap-2">
                <span>{currentConv?.title || 'Continuous Companion Dialogue'}</span>
              </h2>
              <p className="text-[11px] text-muted m-0 mt-0.5">
                Personal AI Operating System • Context Continuity Active
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            {/* TESS Companion Status Pill (Single character presence sync) */}
            <div
              className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-mono transition-all"
              style={{
                backgroundColor: statusPill.bg,
                color: statusPill.color,
                border: `1px solid ${statusPill.color}40`
              }}
              title="Persistent TESS Companion Status"
            >
              <span
                className="w-1.5 h-1.5 rounded-full"
                style={{
                  backgroundColor: statusPill.color,
                  boxShadow: `0 0 8px ${statusPill.color}`
                }}
              />
              <span className="font-semibold">{statusPill.label}</span>
            </div>

            {/* Refresh Action */}
            <button
              type="button"
              onClick={() => currentConvId && loadMessages(currentConvId)}
              className="p-1.5 rounded-lg text-muted hover:text-primary hover:bg-[rgba(255,255,255,0.06)] transition-all cursor-pointer bg-transparent border-none"
              title="Reload dialogue messages"
            >
              <RefreshCw style={{ width: '0.9rem', height: '0.9rem' }} />
            </button>

            {/* New Dialogue Action */}
            <button
              type="button"
              onClick={handleNewConversation}
              className="p-1.5 rounded-lg text-muted hover:text-primary hover:bg-[rgba(255,255,255,0.06)] transition-all cursor-pointer bg-transparent border-none"
              title="New Dialogue"
            >
              <Plus style={{ width: '1rem', height: '1rem' }} />
            </button>
          </div>
        </div>

        {/* ERROR FEEDBACK BANNER */}
        {error && (
          <div
            className="p-3 text-xs flex items-center justify-between border-b animate-in fade-in z-10"
            style={{
              backgroundColor: 'rgba(251, 113, 133, 0.12)',
              borderColor: 'rgba(251, 113, 133, 0.35)',
              color: '#FB7185'
            }}
          >
            <div className="flex items-center gap-2.5">
              <AlertCircle style={{ width: '1.05rem', height: '1.05rem', flexShrink: 0 }} />
              <span>{error}</span>
              {failedMessageText && (
                <button
                  type="button"
                  onClick={handleRetry}
                  className="underline font-semibold ml-2 hover:text-[#FDA4AF] cursor-pointer bg-transparent border-none p-0 text-xs"
                >
                  Retry now
                </button>
              )}
            </div>
            <button
              type="button"
              onClick={() => setError(null)}
              className="text-[#FB7185] hover:text-[#FDA4AF] cursor-pointer bg-transparent border-none p-1"
            >
              <X style={{ width: '0.95rem', height: '0.95rem' }} />
            </button>
          </div>
        )}

        {/* SCREEN ANALYSIS PREVIEW BANNER */}
        {screenPreviewUrl && (
          <div className="p-3 border-b flex items-center gap-4 bg-[rgba(34,211,238,0.08)] border-[rgba(34,211,238,0.3)] z-10">
            <img
              src={screenPreviewUrl}
              alt="Screen Preview"
              className="w-24 h-16 object-cover rounded-lg border border-[rgba(34,211,238,0.3)] shadow-md"
            />
            <div className="flex-1 flex flex-col gap-1.5">
              <span className="text-xs font-mono font-semibold text-[#22D3EE] uppercase tracking-wider">
                Screen Telemetry Captured
              </span>
              <input
                type="text"
                className="tess-input text-xs py-1.5"
                placeholder="Question about your screen..."
                value={screenQuery}
                onChange={(e) => setScreenQuery(e.target.value)}
              />
            </div>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={confirmScreenAnalysis}
                disabled={analyzingScreen}
                className="btn-cyan text-xs py-1.5 px-3.5"
              >
                {analyzingScreen ? 'Analyzing...' : 'Analyze'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setScreenPreviewUrl(null);
                  setCapturedImageBlob(null);
                }}
                className="p-1.5 text-muted hover:text-primary rounded cursor-pointer bg-transparent border-none"
              >
                <X style={{ width: '1rem', height: '1rem' }} />
              </button>
            </div>
          </div>
        )}

        {/* 3. MESSAGE STREAM CONTAINER */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 flex flex-col gap-4">
          {loading && messages.length === 0 ? (
            <div className="flex-1 flex flex-col items-center justify-center text-muted text-xs gap-2 select-none">
              <RefreshCw className="animate-spin" style={{ width: '1.25rem', height: '1.25rem' }} />
              <span>Loading conversation history...</span>
            </div>
          ) : messages.length === 0 ? (
            /* CONVERSATION EMPTY STATE WITH INTELLIGENT PROMPT STARTERS */
            <div className="flex-1 flex flex-col items-center justify-center text-center p-6 select-none max-w-xl mx-auto">
              <div className="w-14 h-14 rounded-2xl bg-[rgba(53,185,165,0.12)] border border-[rgba(53,185,165,0.35)] flex items-center justify-center mb-4 shadow-lg shadow-[rgba(53,185,165,0.1)]">
                <Sparkles style={{ width: '1.75rem', height: '1.75rem', color: '#35B9A5' }} />
              </div>

              <h3 className="text-lg font-bold text-primary m-0 tracking-wide">
                TESS Continuous Dialogue
              </h3>
              <p className="text-xs text-muted max-w-md mt-2 leading-relaxed">
                I remember your goals, synchronize with your OpenProject workspace, and predict your future trajectories. Ask me anything or trigger a prompt below:
              </p>

              {/* 4 Interactive Starter Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 mt-6 w-full text-left">
                {quickActionPrompts.map((item, idx) => {
                  const Icon = item.icon;
                  return (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => handleSendMessage(item.prompt)}
                      className="p-3 rounded-xl border border-[rgba(255,255,255,0.06)] bg-[rgba(255,255,255,0.02)] hover:border-[rgba(53,185,165,0.4)] hover:bg-[rgba(53,185,165,0.06)] transition-all cursor-pointer group flex flex-col justify-between"
                    >
                      <div className="flex items-center justify-between w-full mb-1">
                        <div className="flex items-center gap-2">
                          <Icon style={{ width: '0.9rem', height: '0.9rem', color: item.color }} />
                          <span className="text-xs font-semibold text-primary group-hover:text-[#35B9A5] transition-colors">
                            {item.label}
                          </span>
                        </div>
                        <ArrowRight
                          style={{
                            width: '0.8rem',
                            height: '0.8rem',
                            opacity: 0.4,
                            color: item.color
                          }}
                          className="group-hover:translate-x-0.5 transition-transform"
                        />
                      </div>
                      <p className="text-[11px] text-muted m-0 line-clamp-1">
                        {item.description}
                      </p>
                    </button>
                  );
                })}
              </div>
            </div>
          ) : (
            /* RENDERED MESSAGE LIST */
            <div className="max-w-4xl w-full mx-auto flex flex-col gap-3.5">
              {messages.map((msg, index) => {
                const isLastMsg = index === messages.length - 1;
                const isFailed = isLastMsg && !!failedMessageText && msg.role === 'user';
                return (
                  <ChatMessageItem
                    key={msg.id}
                    message={msg}
                    isFailed={isFailed}
                    onRetry={handleRetry}
                  />
                );
              })}
            </div>
          )}

          {/* THINKING & SYNTHESIZING INDICATOR */}
          {sending && (
            <div className="max-w-4xl w-full mx-auto flex items-center gap-3 animate-in fade-in duration-200">
              <div
                className="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 animate-pulse"
                style={{
                  backgroundColor: 'rgba(53, 185, 165, 0.2)',
                  border: '1px solid #35B9A5',
                  color: '#35B9A5'
                }}
              >
                <Bot style={{ width: '1rem', height: '1rem' }} />
              </div>
              <div
                className="p-3.5 rounded-2xl rounded-tl-sm flex items-center gap-2.5"
                style={{
                  backgroundColor: 'var(--bg-surface-elevated, #171A2D)',
                  border: '1px solid rgba(53, 185, 165, 0.35)',
                  boxShadow: '0 4px 16px rgba(0, 0, 0, 0.25)'
                }}
              >
                <div className="flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#35B9A5] animate-bounce" style={{ animationDelay: '0ms' }} />
                  <span className="w-1.5 h-1.5 rounded-full bg-[#35B9A5] animate-bounce" style={{ animationDelay: '150ms' }} />
                  <span className="w-1.5 h-1.5 rounded-full bg-[#35B9A5] animate-bounce" style={{ animationDelay: '300ms' }} />
                </div>
                <span className="text-xs font-mono text-[#35B9A5] tracking-wider uppercase ml-1">
                  Synthesizing Response...
                </span>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* 4. MESSAGE COMPOSER */}
        <ChatComposer
          inputText={inputText}
          setInputText={setInputText}
          onSendMessage={handleSendMessage}
          sending={sending}
          isRecording={isRecording}
          onToggleVoice={toggleVoiceRecording}
          onCaptureScreen={triggerScreenCapture}
          onTyping={handleTyping}
        />
      </div>
    </div>
  );
};
