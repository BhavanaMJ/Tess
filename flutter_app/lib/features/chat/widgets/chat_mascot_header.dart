import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
        return 'PROCESSING DIRECTIVE...';
      case MascotState.happy:
        return 'TRAJECTORY SYNCHRONIZED';
      case MascotState.attention:
        return 'CONVERGENCE ALERT DETECTED';
      case MascotState.error:
        return 'TRANSMISSION ANOMALY';
      default:
        return 'COGNITIVE CORE ONLINE';
    }
  }

  Color get _statusColor {
    switch (state) {
      case MascotState.thinking:
        return AppColors.violetLight;
      case MascotState.happy:
        return AppColors.success;
      case MascotState.attention:
        return AppColors.danger;
      case MascotState.error:
        return AppColors.danger;
      default:
        return AppColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary.withOpacity(0.9),
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Small living mascot orb
          MascotWidget(
            state: state,
            size: 38.0,
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
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        const Icon(
                          Icons.expand_more_rounded,
                          size: 16.0,
                          color: AppColors.textMuted,
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
                            fontSize: 10.0,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
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
            icon: const Icon(Icons.forum_outlined, color: AppColors.violetLight),
            tooltip: 'Switch Threads',
            onPressed: onOpenThreads,
          ),
          // Personal Memory Bank action
          IconButton(
            icon: const Icon(Icons.psychology_outlined, color: AppColors.cyan),
            tooltip: 'Personal Memory Bank',
            onPressed: onOpenMemories,
          ),
        ],
      ),
    );
  }
}

