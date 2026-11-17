import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_message_model.dart';

/// Holographic Chat Bubble representing a message in the conversation stream.
class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAssistantAvatar(),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.violet.withOpacity(0.25)
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16.0),
                      topRight: const Radius.circular(16.0),
                      bottomLeft: Radius.circular(isUser ? 16.0 : 4.0),
                      bottomRight: Radius.circular(isUser ? 4.0 : 16.0),
                    ),
                    border: Border.all(
                      color: message.hasFailed
                          ? AppColors.danger
                          : (isUser
                              ? AppColors.violet.withOpacity(0.5)
                              : AppColors.border),
                      width: 1.0,
                    ),
                    boxShadow: [
                      if (!isUser)
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.05),
                          blurRadius: 8.0,
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        message.content,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.0,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.formattedTime,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.0,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (message.isPending) ...[
                            const SizedBox(width: 6.0),
                            const SizedBox(
                              width: 10.0,
                              height: 10.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.violetLight,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (message.hasFailed && onRetry != null) ...[
                  const SizedBox(height: 4.0),
                  InkWell(
                    onTap: onRetry,
                    borderRadius: BorderRadius.circular(4.0),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 2.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 12.0,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            'Failed to transmit. Tap to retry.',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8.0),
        ],
      ),
    );
  }

  Widget _buildAssistantAvatar() {
    return Container(
      width: 30.0,
      height: 30.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.violet, AppColors.cyan],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withOpacity(0.4),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'T',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.0,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
