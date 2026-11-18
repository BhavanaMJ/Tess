import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Keyboard-aware Message Composer with submission protection and theme-adaptive styling.
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback? onVoicePressed;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
    this.onVoicePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSecondary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final hintColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: 10.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (onVoicePressed != null) ...[
              IconButton(
                icon: const Icon(Icons.mic_none_rounded),
                color: AppColors.tessTeal,
                tooltip: 'Voice Input',
                onPressed: isSending ? null : onVoicePressed,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: AppRadius.pill,
                  border: Border.all(
                    color: isSending
                        ? borderColor
                        : AppColors.tessTeal.withOpacity(0.25),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  controller: controller,
                  enabled: !isSending,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!isSending) onSend();
                  },
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.5,
                  ),
                  decoration: InputDecoration(
                    hintText: isSending
                        ? 'TESS is thinking...'
                        : 'Ask TESS anything or give a task...',
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSending
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.vibrantMint, AppColors.tessTeal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isSending ? inputBg : null,
                border: isSending ? Border.all(color: borderColor, width: 1.0) : null,
                boxShadow: isSending
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.vibrantMint.withOpacity(0.35),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isSending ? null : onSend,
                  child: Center(
                    child: isSending
                        ? const SizedBox(
                            width: 18.0,
                            height: 18.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.tessTeal,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 19.0,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
