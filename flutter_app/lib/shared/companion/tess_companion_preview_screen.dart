import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../widgets/tess_button.dart';
import '../widgets/tess_card.dart';
import 'tess_companion.dart';
import 'tess_companion_controller.dart';
import 'tess_emotion.dart';

/// Development Showcase & Preview Screen for the Expressive TESS Companion.
/// Allows interactive cycling and inspection of all 9 emotions, size scaling,
/// animation playback, and temporary expression testing.
class TessCompanionPreviewScreen extends StatefulWidget {
  const TessCompanionPreviewScreen({super.key});

  @override
  State<TessCompanionPreviewScreen> createState() => _TessCompanionPreviewScreenState();
}

class _TessCompanionPreviewScreenState extends State<TessCompanionPreviewScreen> {
  late final TessCompanionController _controller;
  double _size = 120.0;
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    _controller = TessCompanionController(initialEmotion: TessEmotion.idle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Companion Expression Lab'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => ThemeController.instance.toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Companion Stage Card
              TessCard(
                padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
                child: Column(
                  children: [
                    Center(
                      child: TessCompanion(
                        controller: _controller,
                        size: _size,
                        animate: _animate,
                        onTap: () {
                          // Tap to trigger a quick joyful bounce
                          _controller.express(TessEmotion.happy, duration: const Duration(seconds: 2));
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final emotion = _controller.emotion;
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                color: emotion.auraColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: emotion.auraColor.withValues(alpha: 0.4),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8.0,
                                    height: 8.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: emotion.auraColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    emotion.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              emotion.label,
                              style: TextStyle(
                                fontSize: 13.0,
                                color: secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // 2. Emotion Selector Chips
              Text(
                'Active Emotion State',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 10.0),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: TessEmotion.values.map((emotion) {
                      final isSelected = _controller.emotion == emotion;
                      return ChoiceChip(
                        label: Text(emotion.name),
                        selected: isSelected,
                        selectedColor: AppColors.tessTeal.withValues(alpha: 0.25),
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        labelStyle: TextStyle(
                          fontSize: 12.0,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.tessTeal : primaryText,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.tessTeal : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        onSelected: (_) {
                          _controller.setEmotion(emotion);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24.0),

              // 3. Transient Expression Triggers
              Text(
                'Transient Expressions (Auto-Revert)',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 10.0),
              Row(
                children: [
                  Expanded(
                    child: TessButton(
                      label: 'Thinking (3s)',
                      variant: TessButtonVariant.secondary,
                      onPressed: () => _controller.express(TessEmotion.thinking, duration: const Duration(seconds: 3)),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: TessButton(
                      label: 'Happy (2s)',
                      variant: TessButtonVariant.secondary,
                      onPressed: () => _controller.express(TessEmotion.happy, duration: const Duration(seconds: 2)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              Row(
                children: [
                  Expanded(
                    child: TessButton(
                      label: 'Attention (2.5s)',
                      variant: TessButtonVariant.secondary,
                      onPressed: () => _controller.express(TessEmotion.attention, duration: const Duration(milliseconds: 2500)),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: TessButton(
                      label: 'Success (2s)',
                      variant: TessButtonVariant.secondary,
                      onPressed: () => _controller.express(TessEmotion.success, duration: const Duration(seconds: 2)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              // 4. Companion Dimension Controls
              TessCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Size: ${_size.toInt()}px',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Animate',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: secondaryText,
                              ),
                            ),
                            Switch.adaptive(
                              value: _animate,
                              activeColor: AppColors.tessTeal,
                              onChanged: (val) => setState(() => _animate = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Slider(
                      value: _size,
                      min: 40.0,
                      max: 200.0,
                      divisions: 16,
                      activeColor: AppColors.tessTeal,
                      onChanged: (val) => setState(() => _size = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

