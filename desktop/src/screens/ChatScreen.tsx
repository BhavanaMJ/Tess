import React, { useEffect, useState, useRef } from 'react';
import { apiService } from '../services/api';
import { Conversation, Message } from '../types';
import { useMascot } from '../contexts/MascotContext';
import { Plus, Send, MessageSquare, Bot, User, AlertCircle, Mic, MicOff, Monitor, X } from 'lucide-react';

export const ChatScreen: React.FC = () => {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [currentConvId, setCurrentConvId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Phase 8: Voice Assistant state
  const [isRecording, setIsRecording] = useState(false);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const currentAudioRef = useRef<HTMLAudioElement | null>(null);

  // Phase 8: Screen Understanding state
  const [capturedImageBlob, setCapturedImageBlob] = useState<Blob | null>(null);
  const [screenPreviewUrl, setScreenPreviewUrl] = useState<string | null>(null);
  const [screenQuery, setScreenQuery] = useState('Explain what is on this screen and any errors.');
  const [analyzingScreen, setAnalyzingScreen] = useState(false);

  const { setState: setMascotState } = useMascot();
  const messagesEndRef = useRef<HTMLDivElement>(null);

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
      const newConv = await apiService.createConversation('Desktop Conversation');
      setConversations((prev) => [newConv, ...prev]);
      setCurrentConvId(newConv.id);
      setMessages([]);
    } catch (e: any) {
      setError(e.message || 'Failed to create conversation');
    }
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim() || !currentConvId || sending) return;

    const userText = inputText.trim();
    setInputText('');
    setSending(true);
    setMascotState('THINKING');

    // Optimistic user message
    const tempMsg: Message = {
      id: 'temp-' + Date.now(),
      conversation_id: currentConvId,
      role: 'user',
      content: userText,
      created_at: new Date().toISOString()
    };
    setMessages((prev) => [...prev, tempMsg]);

    try {
      const res = await apiService.sendMessage(currentConvId, userText);
      // Assistant response message
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

  // Phase 8: Voice Interaction Handler
  const toggleVoiceRecording = async () => {
    // If currently playing audio, allow voice interruption
    if (currentAudioRef.current) {
      currentAudioRef.current.pause();
      currentAudioRef.current = null;
    }

    if (isRecording) {
      // Stop recording
      if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
        mediaRecorderRef.current.stop();
      }
      setIsRecording(false);
      return;
    }

    // Start user-authorized microphone recording
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      audioChunksRef.current = [];
      const recorder = new MediaRecorder(stream);

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) {
          audioChunksRef.current.push(e.data);
        }
      };

      recorder.onstop = async () => {
        stream.getTracks().forEach((track) => track.stop());
        const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/wav' });
        if (audioBlob.size < 100) return;

        setMascotState('THINKING');
        setSending(true);

        try {
          const res = await apiService.voiceInteract(audioBlob);

          // Add messages to chat
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

          // Play synthesized audio response
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
      setError('Microphone access denied or unavailable: ' + err.message);
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
        content: `[Screen Capture Query]: ${screenQuery}`,
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

  return (
    <div className="flex h-full" style={{ height: 'calc(100vh - 64px)' }}>
      {/* Conversations List Sub-sidebar */}
      <div
        className="flex flex-col border-r"
        style={{
          width: '260px',
          backgroundColor: 'var(--bg-secondary)',
          borderColor: 'var(--border)'
        }}
      >
        <div className="p-3 border-b" style={{ borderColor: 'var(--border)' }}>
          <button onClick={handleNewConversation} className="btn-primary w-full text-xs justify-center">
            <Plus style={{ width: '0.9rem', height: '0.9rem' }} />
            <span>New Conversation</span>
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-2 flex flex-col gap-1">
          {conversations.map((conv) => {
            const isSelected = currentConvId === conv.id;
            return (
              <button
                key={conv.id}
                onClick={() => setCurrentConvId(conv.id)}
                className="flex items-center gap-2.5 p-2 rounded-lg text-xs w-full text-left truncate cursor-pointer transition-colors"
                style={{
                  backgroundColor: isSelected ? 'var(--bg-card)' : 'transparent',
                  color: isSelected ? 'var(--text-primary)' : 'var(--text-secondary)',
                  border: isSelected ? '1px solid var(--border)' : '1px solid transparent'
                }}
              >
                <MessageSquare style={{ width: '0.9rem', height: '0.9rem', flexShrink: 0 }} />
                <span className="truncate">{conv.title || 'Conversation'}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Chat Messages Panel */}
      <div className="flex-1 flex flex-col h-full bg-primary">
        {error && (
          <div
            className="flex items-center gap-2 p-3 text-xs"
            style={{ backgroundColor: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', borderBottom: '1px solid var(--border)' }}
          >
            <AlertCircle style={{ width: '1rem', height: '1rem' }} />
            <span>{error}</span>
          </div>
        )}

        <div className="flex-1 overflow-y-auto p-6 flex flex-col gap-4">
          {messages.length === 0 && !loading && (
            <div className="text-center text-muted my-auto text-sm">
              <Bot style={{ width: '2rem', height: '2rem', margin: '0 auto 0.5rem', color: 'var(--accent)' }} />
              <div>Start a conversation with TESS.</div>
              <div className="text-xs text-muted mt-1">Ask questions, request actions, or discuss your tasks.</div>
            </div>
          )}

          {messages.map((msg) => {
            const isUser = msg.role === 'user';
            return (
              <div
                key={msg.id}
                className={`flex gap-3 max-w-2xl ${isUser ? 'self-end flex-row-reverse' : 'self-start'}`}
              >
                <div
                  className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0"
                  style={{
                    backgroundColor: isUser ? 'var(--accent)' : 'var(--bg-card)',
                    border: '1px solid var(--border)'
                  }}
                >
                  {isUser ? (
                    <User style={{ width: '0.85rem', height: '0.85rem', color: 'white' }} />
                  ) : (
                    <Bot style={{ width: '0.85rem', height: '0.85rem', color: 'var(--accent)' }} />
                  )}
                </div>

                <div
                  className="p-3 rounded-2xl text-sm"
                  style={{
                    backgroundColor: isUser ? 'var(--accent)' : 'var(--bg-card)',
                    color: isUser ? '#FFFFFF' : 'var(--text-primary)',
                    border: isUser ? 'none' : '1px solid var(--border)',
                    lineHeight: '1.5'
                  }}
                >
                  {msg.content}
                </div>
              </div>
            );
          })}

          {sending && (
            <div className="flex gap-3 self-start items-center text-xs text-muted">
              <div className="w-7 h-7 rounded-full flex items-center justify-center bg-card border">
                <Bot style={{ width: '0.85rem', height: '0.85rem', color: 'var(--accent)' }} />
              </div>
              <div className="p-3 rounded-2xl bg-card border text-xs text-muted flex items-center gap-2">
                <span>TESS is thinking</span>
                <span className="font-mono text-accent">...</span>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* Screen Preview & Consent Modal */}
        {screenPreviewUrl && (
          <div className="p-4 border-t bg-secondary flex flex-col gap-3" style={{ borderColor: 'var(--border)' }}>
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-primary flex items-center gap-2">
                <Monitor style={{ width: '1rem', height: '1rem', color: 'var(--accent)' }} />
                <span>Screen Capture Preview (User Consent Required)</span>
              </span>
              <button
                onClick={() => {
                  setScreenPreviewUrl(null);
                  setCapturedImageBlob(null);
                }}
                className="text-muted hover:text-primary p-1"
              >
                <X style={{ width: '1rem', height: '1rem' }} />
              </button>
            </div>

            <div className="flex gap-4 items-start">
              <img
                src={screenPreviewUrl}
                alt="Captured screen preview"
                className="w-48 h-28 object-cover rounded-lg border"
                style={{ borderColor: 'var(--border)' }}
              />
              <div className="flex-1 flex flex-col gap-2">
                <label className="text-xs text-muted">What would you like TESS to explain or investigate?</label>
                <input
                  type="text"
                  className="tess-input w-full text-xs"
                  value={screenQuery}
                  onChange={(e) => setScreenQuery(e.target.value)}
                  placeholder="e.g. Explain this error or describe the UI"
                />
                <div className="flex gap-2 mt-1">
                  <button
                    type="button"
                    onClick={confirmScreenAnalysis}
                    className="btn-primary text-xs"
                    disabled={analyzingScreen}
                  >
                    {analyzingScreen ? 'Analyzing Context...' : 'Analyze Screen'}
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setScreenPreviewUrl(null);
                      setCapturedImageBlob(null);
                    }}
                    className="btn-secondary text-xs"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Input Form */}
        <form onSubmit={handleSendMessage} className="p-4 border-t flex gap-2 items-center" style={{ borderColor: 'var(--border)' }}>
          {/* Screen Understanding trigger button */}
          <button
            type="button"
            onClick={triggerScreenCapture}
            className="p-2.5 rounded-xl border hover:border-accent transition-colors"
            style={{
              backgroundColor: 'var(--bg-secondary)',
              borderColor: 'var(--border)',
              color: 'var(--text-secondary)'
            }}
            title="Capture screen for TESS to explain"
          >
            <Monitor style={{ width: '1.1rem', height: '1.1rem' }} />
          </button>

          {/* Voice Assistant trigger button */}
          <button
            type="button"
            onClick={toggleVoiceRecording}
            className={`p-2.5 rounded-xl border transition-all ${
              isRecording ? 'animate-pulse text-white' : 'text-secondary hover:border-accent'
            }`}
            style={{
              backgroundColor: isRecording ? 'var(--danger)' : 'var(--bg-secondary)',
              borderColor: isRecording ? 'var(--danger)' : 'var(--border)'
            }}
            title={isRecording ? 'Listening... Click to stop and send' : 'Speak to TESS'}
          >
            {isRecording ? (
              <MicOff style={{ width: '1.1rem', height: '1.1rem' }} />
            ) : (
              <Mic style={{ width: '1.1rem', height: '1.1rem' }} />
            )}
          </button>

          <input
            type="text"
            className="tess-input flex-1"
            placeholder={isRecording ? "Listening to your voice..." : "Type a message to TESS..."}
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            disabled={sending || isRecording}
          />

          <button type="submit" className="btn-primary" disabled={!inputText.trim() || sending || isRecording}>
            <Send style={{ width: '1rem', height: '1rem' }} />
            <span>Send</span>
          </button>
        </form>
      </div>
    </div>
  );
};

