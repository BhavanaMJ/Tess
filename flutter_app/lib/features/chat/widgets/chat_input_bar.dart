import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Keyboard-aware Message Composer with submission protection and telemetry styling.
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: const Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: isSending
                        ? AppColors.border
                        : AppColors.violet.withOpacity(0.4),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: controller,
                  enabled: !isSending,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!isSending) onSend();
                  },
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.0,
                  ),
                  decoration: InputDecoration(
                    hintText: isSending
                        ? 'TESS is processing cognitive response...'
                        : 'Transmit directive or query to TESS...',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.0,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSending
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.violet, AppColors.cyan],
                      ),
                color: isSending ? AppColors.bgSurface : null,
                border: isSending
                    ? Border.all(color: AppColors.border, width: 1.0)
                    : null,
                boxShadow: isSending
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.4),
                          blurRadius: 8.0,
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
                                AppColors.cyan,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18.0,
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

