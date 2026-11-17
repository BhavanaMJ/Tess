import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/conversation_model.dart';

/// Modal Bottom Sheet allowing the commander to view, switch, or spawn new conversation threads.
class ConversationSheet extends StatelessWidget {
  final List<ConversationModel> conversations;
  final String? activeConversationId;
  final ValueChanged<ConversationModel> onSelect;
  final VoidCallback onNewConversation;
  final bool isLoading;

  const ConversationSheet({
    super.key,
    required this.conversations,
    required this.activeConversationId,
    required this.onSelect,
    required this.onNewConversation,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        border: Border(
          top: BorderSide(color: AppColors.violet, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TRANSMISSION THREADS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppColors.cyan,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onNewConversation();
                    },
                    icon: const Icon(Icons.add, size: 16.0, color: AppColors.violetLight),
                    label: const Text(
                      'New Thread',
                      style: TextStyle(
                        color: AppColors.violetLight,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.cyan),
                ),
              )
            else if (conversations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No active transmission threads found.\nStart a new conversation to communicate with TESS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13.0),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.border,
                    height: 1.0,
                    indent: 20.0,
                    endIndent: 20.0,
                  ),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final isActive = conv.id == activeConversationId;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 4.0,
                      ),
                      leading: Icon(
                        isActive
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                        color: isActive ? AppColors.cyan : AppColors.textMuted,
                        size: 20.0,
                      ),
                      title: Text(
                        conv.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14.0,
                        ),
                      ),
                      subtitle: Text(
                        conv.formattedDate,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                      trailing: isActive
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: AppColors.cyan.withOpacity(0.5),
                                ),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(conv);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
