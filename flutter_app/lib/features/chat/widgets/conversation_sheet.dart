import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/conversation_model.dart';

/// Modal Bottom Sheet allowing the user to view, switch, or start new conversation threads.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final handleColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border(
          top: BorderSide(
            color: AppColors.tessTeal.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.08),
            blurRadius: 16.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                  color: handleColor,
                  borderRadius: AppRadius.pill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.tessTeal.withOpacity(0.12),
                          borderRadius: AppRadius.sm,
                        ),
                        child: const Icon(
                          Icons.forum_outlined,
                          size: 16,
                          color: AppColors.tessTeal,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Conversations',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onNewConversation();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18.0, color: AppColors.tessTeal),
                    label: const Text(
                      'New Thread',
                      style: TextStyle(
                        color: AppColors.tessTeal,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor, height: 24),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.tessTeal),
                ),
              )
            else if (conversations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No conversations yet.\nStart one to chat with TESS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, fontSize: 13.5),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => Divider(
                    color: borderColor,
                    height: 1.0,
                    indent: 20.0,
                    endIndent: 20.0,
                  ),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final isActive = conv.id == activeConversationId;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 4.0,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.tessTeal.withOpacity(0.15)
                              : Colors.transparent,
                        ),
                        child: Icon(
                          isActive
                              ? Icons.chat_bubble_rounded
                              : Icons.chat_bubble_outline_rounded,
                          color: isActive ? AppColors.tessTeal : textSecondary,
                          size: 18.0,
                        ),
                      ),
                      title: Text(
                        conv.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive ? textPrimary : textSecondary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14.5,
                        ),
                      ),
                      subtitle: Text(
                        conv.formattedDate,
                        style: TextStyle(
                          color: textSecondary.withOpacity(0.8),
                          fontSize: 11.5,
                        ),
                      ),
                      trailing: isActive
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 3.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tessTeal.withOpacity(0.15),
                                borderRadius: AppRadius.pill,
                                border: Border.all(
                                  color: AppColors.tessTeal.withOpacity(0.4),
                                ),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: AppColors.tessTeal,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
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
