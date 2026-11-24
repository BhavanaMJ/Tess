import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/wardrobe_capture_controller.dart';
import '../theme/wardrobe_theme.dart';
import 'capture_processing_screen.dart';

/// Screen allowing the user to capture or select a photo of single or multiple garments.
/// Includes client-side image validation (size, resolution, format, brightness) and preview.
class SmartCaptureScreen extends StatefulWidget {
  final WardrobeCaptureController controller;

  const SmartCaptureScreen({
    super.key,
    required this.controller,
  });

  @override
  State<SmartCaptureScreen> createState() => _SmartCaptureScreenState();
}

class _SmartCaptureScreenState extends State<SmartCaptureScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WardrobeTheme.voidBg,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: WardrobeTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Smart Capture',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final hasImage = widget.controller.selectedImageBytes != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Informational Banner
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.spatialSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WardrobeTheme.borderViolet),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: WardrobeTheme.electricViolet
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_awesome_rounded,
                            color: WardrobeTheme.softViolet, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Garment Recognition',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: WardrobeTheme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Capture single garments or complete outfits. TESS will separate each item cleanly into your wardrobe.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: WardrobeTheme.textSecondary,
                                  height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Error Message Banner if validation failed
                if (widget.controller.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          WardrobeTheme.statusCritical.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: WardrobeTheme.statusCritical
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: WardrobeTheme.statusCritical, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.controller.errorMessage!,
                            style: TextStyle(
                                fontSize: 12,
                                color: WardrobeTheme.statusCritical),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Image Preview or Placeholder
                if (hasImage) ...[
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      color: WardrobeTheme.spatialSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WardrobeTheme.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.memory(
                          Uint8List.fromList(
                              widget.controller.selectedImageBytes!),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 320,
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                              onPressed: () =>
                                  widget.controller.clearSelection(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              widget.controller.pickImage(ImageSource.camera),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retake'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WardrobeTheme.textSecondary,
                            side: BorderSide(color: WardrobeTheme.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CaptureProcessingScreen(
                                  controller: widget.controller,
                                ),
                              ),
                            );
                          },
                          icon:
                              const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: const Text('Analyze Clothes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WardrobeTheme.electricViolet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Source Selector Area
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: WardrobeTheme.spatialSurface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: WardrobeTheme.border, width: 1.5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 48,
                            color: WardrobeTheme.electricViolet
                                .withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add a Photograph',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: WardrobeTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select from gallery or snap a photo with your camera',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: WardrobeTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Option A: Take Photo
                  ElevatedButton.icon(
                    onPressed: () =>
                        widget.controller.pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Take Photograph',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WardrobeTheme.electricViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option B: Upload Photo
                  OutlinedButton.icon(
                    onPressed: () =>
                        widget.controller.pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Select from Gallery',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WardrobeTheme.electricCyan,
                      side: BorderSide(color: WardrobeTheme.borderCyan),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
