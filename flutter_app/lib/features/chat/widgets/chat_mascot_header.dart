import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/mascot/tess_mascot.dart';
import '../../home/widgets/mascot_widget.dart';

/// Interactive Chat Mascot Bar displaying real-time cognitive status
class ChatMascotHeader extends StatelessWidget {
  final MascotState state;
  final String activeTitle;
  final VoidCallback onOpenThreads;
  final VoidCallback onOpenMemories;

  const ChatMascotHeader({
    super.key,
    required this.state,
    required this.activeTitle,
    required this.onOpenThreads,
    required this.onOpenMemories,
  });

  String get _statusLabel {
    switch (state) {
      case MascotState.thinking:
        return 'Thinking...';
      case MascotState.happy:
        return 'Ready to assist';
      case MascotState.attention:
        return 'Needs attention';
      case MascotState.error:
        return 'Connection error';
      default:
        return 'TESS is active';
    }
  }

  Color get _statusColor {
    switch (state) {
      case MascotState.thinking:
        return AppColors.tessTeal;
      case MascotState.happy:
        return AppColors.success;
      case MascotState.attention:
        return AppColors.warning;
      case MascotState.error:
        return AppColors.danger;
      default:
        return AppColors.vibrantMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Approved Compact TESS Mascot
          TessMascot(
            state: state.toTessMascotState(),
            size: 38.0,
            showStatusBadge: false,
          ),
          const SizedBox(width: 12.0),
          // Conversation title and cognitive telemetry
          Expanded(
            child: InkWell(
              onTap: onOpenThreads,
              borderRadius: BorderRadius.circular(8.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            activeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 16.0,
                          color: mutedText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        Container(
                          width: 6.0,
                          height: 6.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Thread switcher action
          IconButton(
            icon: Icon(
              Icons.forum_outlined,
              color: isDark ? AppColors.vibrantMint : AppColors.tessTeal,
              size: 20,
            ),
            tooltip: 'Switch Threads',
            onPressed: onOpenThreads,
          ),
          // Personal Memory Bank action
          IconButton(
            icon: const Icon(
              Icons.psychology_outlined,
              color: AppColors.tessTeal,
              size: 20,
            ),
            tooltip: 'Personal Memory Bank',
            onPressed: onOpenMemories,
          ),
        ],
      ),
    );
  }
}
