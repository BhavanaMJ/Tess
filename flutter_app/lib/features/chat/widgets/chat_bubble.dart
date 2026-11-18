import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_message_model.dart';

/// Refined Chat Bubble for the conversational stream.
/// Adapts gracefully to Light and Dark themes with comfortable typography and spacing.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    // Background & text color logic
    Color bubbleBg;
    Color textColor;
    BorderSide borderSide;

    if (isUser) {
      bubbleBg = isDark
          ? AppColors.tessTeal.withValues(alpha: 0.35)
          : AppColors.vibrantMint.withValues(alpha: 0.20);
      textColor = primaryText;
      borderSide = BorderSide(
        color: isDark ? AppColors.vibrantMint.withValues(alpha: 0.4) : AppColors.tessTeal.withValues(alpha: 0.35),
        width: 1.0,
      );
    } else {
      bubbleBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
      textColor = primaryText;
      borderSide = BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        width: 1.0,
      );
    }

    if (message.hasFailed) {
      borderSide = const BorderSide(color: AppColors.danger, width: 1.2);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAssistantAvatar(isDark),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16.0),
                      topRight: const Radius.circular(16.0),
                      bottomLeft: Radius.circular(isUser ? 16.0 : 4.0),
                      bottomRight: Radius.circular(isUser ? 4.0 : 16.0),
                    ),
                    border: Border.fromBorderSide(borderSide),
                    boxShadow: [
                      if (!isUser && !isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        message.content,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14.0,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.formattedTime,
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (message.isPending) ...[
                            const SizedBox(width: 6.0),
                            const SizedBox(
                              width: 10.0,
                              height: 10.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.tessTeal),
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
                      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 12.0, color: AppColors.danger),
                          SizedBox(width: 4.0),
                          Text(
                            'Failed to transmit. Tap to retry.',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
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

  Widget _buildAssistantAvatar(bool isDark) {
    return Container(
      width: 28.0,
      height: 28.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.vibrantMint, AppColors.tessTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.vibrantMint.withValues(alpha: isDark ? 0.35 : 0.20),
            blurRadius: 6.0,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'T',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}
