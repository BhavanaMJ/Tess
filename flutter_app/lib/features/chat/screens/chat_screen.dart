import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/mascot_widget.dart';
import '../../memory/screens/memory_screen.dart';
import '../../voice/screens/voice_screen.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_mascot_header.dart';
import '../widgets/conversation_sheet.dart';

/// ChatScreen implements the live conversational AI operating system experience.
/// Connects to FastAPI `/api/v1/conversations` and `/api/v1/conversations/{id}/messages`.
class ChatScreen extends StatefulWidget {
  final ChatService? chatService;

  const ChatScreen({super.key, this.chatService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ConversationModel> _conversations = [];
  ConversationModel? _activeConversation;
  List<ChatMessageModel> _messages = [];

  bool _isLoadingThreads = true;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _errorMessage;
  MascotState _mascotState = MascotState.idle;

  @override
  void initState() {
    super.initState();
    _chatService = widget.chatService ?? ChatService();
    _initChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize conversations list and select or spawn the active thread
  Future<void> _initChat() async {
    setState(() {
      _isLoadingThreads = true;
      _errorMessage = null;
    });

    try {
      final threads = await _chatService.getConversations();
      if (!mounted) return;

      setState(() {
        _conversations = threads;
        _isLoadingThreads = false;
      });

      if (threads.isNotEmpty) {
        await _selectConversation(threads.first);
      } else {
        // Automatically spawn a default thread if user has none
        await _createNewConversation(title: 'Mission Briefing');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingThreads = false;
        _errorMessage = 'Failed to load conversations: $e';
        _mascotState = MascotState.error;
      });
    }
  }

  /// Select an existing conversation and load message history
  Future<void> _selectConversation(ConversationModel conversation) async {
    setState(() {
      _activeConversation = conversation;
      _isLoadingMessages = true;
      _errorMessage = null;
      _mascotState = MascotState.idle;
    });

    try {
      final history = await _chatService.getMessages(conversation.id);
      if (!mounted) return;

      setState(() {
        _messages = history;
        _isLoadingMessages = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
        _errorMessage = 'Failed to retrieve messages: $e';
        _mascotState = MascotState.error;
      });
    }
  }

  /// Spawn a new conversation thread
  Future<void> _createNewConversation({String title = 'New Conversation'}) async {
    setState(() {
      _isLoadingMessages = true;
      _errorMessage = null;
    });

    try {
      final created = await _chatService.createConversation(title: title);
      if (!mounted) return;

      setState(() {
        _conversations.insert(0, created);
        _activeConversation = created;
        _messages = [];
        _isLoadingMessages = false;
        _mascotState = MascotState.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
        _errorMessage = 'Failed to initialize thread: $e';
        _mascotState = MascotState.error;
      });
    }
  }

  /// Transmit a message to TESS with optimistic UI rendering and deduplication
  Future<void> _handleSendMessage({String? retryText}) async {
    final text = retryText ?? _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (_activeConversation == null) {
      await _createNewConversation();
      if (_activeConversation == null) return;
    }

    final convId = _activeConversation!.id;
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final pendingUserMessage = ChatMessageModel(
      id: tempId,
      conversationId: convId,
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
      isPending: true,
      hasFailed: false,
    );

    if (retryText == null) {
      _textController.clear();
    }

    setState(() {
      if (retryText != null) {
        // Replace failed message with pending state
        final idx = _messages.indexWhere((m) => m.content == retryText && m.hasFailed);
        if (idx != -1) {
          _messages[idx] = pendingUserMessage;
        } else {
          _messages.add(pendingUserMessage);
        }
      } else {
        _messages.add(pendingUserMessage);
      }
      _isSending = true;
      _errorMessage = null;
      _mascotState = MascotState.thinking;
    });

    _scrollToBottom();

    try {
      final responseText = await _chatService.sendMessage(
        conversationId: convId,
        message: text,
      );

      if (!mounted) return;

      // Determine emotional Mascot state based on cognitive response content
      final lowerRes = responseText.toLowerCase();
      final hasWarning = lowerRes.contains('overdue') ||
          lowerRes.contains('risk') ||
          lowerRes.contains('warning') ||
          lowerRes.contains('alert') ||
          lowerRes.contains('attention');

      final assistantMessage = ChatMessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: convId,
        role: 'assistant',
        content: responseText,
        createdAt: DateTime.now(),
      );

      setState(() {
        // Mark user message as delivered
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(isPending: false);
        }
        _messages.add(assistantMessage);
        _isSending = false;
        _mascotState = hasWarning ? MascotState.attention : MascotState.happy;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(
            isPending: false,
            hasFailed: true,
          );
        }
        _isSending = false;
        _errorMessage = 'Transmission failed: $e';
        _mascotState = MascotState.error;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openConversationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ConversationSheet(
        conversations: _conversations,
        activeConversationId: _activeConversation?.id,
        isLoading: _isLoadingThreads,
        onSelect: _selectConversation,
        onNewConversation: () => _createNewConversation(
          title: 'Transmission #${_conversations.length + 1}',
        ),
      ),
    );
  }

  void _navigateToMemoryBank() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MemoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTitle = _activeConversation?.title ?? 'TESS Neural Interface';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TESS COGNITIVE CHAT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppColors.cyan,
              ),
            ),
            Text(
              'Autonomous Intelligence // Neural Link Online',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.0,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: AppColors.cyan),
            tooltip: 'Voice Interaction Core',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.psychology_outlined, color: AppColors.cyan),
            tooltip: 'Personal Memory Bank',
            onPressed: _navigateToMemoryBank,
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.violetLight),
            tooltip: 'Conversation Threads',
            onPressed: _openConversationSelector,
          ),
        ],
      ),
      body: Column(
        children: [
          // Cognitive Mascot Status Header
          ChatMascotHeader(
            state: _mascotState,
            activeTitle: activeTitle,
            onOpenThreads: _openConversationSelector,
            onOpenMemories: _navigateToMemoryBank,
          ),

          // Error banner if transmission fails
          if (_errorMessage != null) _buildErrorBanner(),

          // Chat Messages List
          Expanded(
            child: _isLoadingMessages
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return ChatBubble(
                            message: msg,
                            onRetry: msg.hasFailed
                                ? () => _handleSendMessage(retryText: msg.content)
                                : null,
                          );
                        },
                      ),
          ),

          // Message Input Bar
          ChatInputBar(
            controller: _textController,
            isSending: _isSending,
            onSend: () => _handleSendMessage(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16.0, color: AppColors.danger),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _errorMessage ?? 'Cognitive transmission issue',
              style: const TextStyle(color: AppColors.danger, fontSize: 11.5),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 14.0, color: AppColors.danger),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violet.withOpacity(0.1),
                border: Border.all(color: AppColors.violet.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 28.0,
                color: AppColors.violetLight,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'No Transmissions in this Thread',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Consult TESS on your active work packages, productivity metrics, future trajectories, or ask questions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
