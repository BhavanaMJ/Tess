import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/garment_import_controller.dart';
import '../theme/wardrobe_theme.dart';

class ImportStage1Prepare extends StatelessWidget {
  final GarmentImportController controller;

  const ImportStage1Prepare({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = controller.originalImageBytes != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ChatGPT Project Instructions Banner
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: WardrobeTheme.spatialSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WardrobeTheme.borderViolet),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: WardrobeTheme.electricViolet.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology_rounded,
                          color: WardrobeTheme.softViolet, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use ChatGPT to Create Catalogue & Metadata',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: WardrobeTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'ChatGPT Project: TESS — AI GARMENT CATALOGUE & METADATA GENERATOR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: WardrobeTheme.electricCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Take or select a clear photograph of your complete garment.\n'
                  '2. Upload it to your ChatGPT Project.\n'
                  '3. ChatGPT generates a studio catalogue photograph and Schema 1.1 JSON metadata.\n'
                  '4. Import both back into TESS for automated validation and review.',
                  style: TextStyle(
                    fontSize: 11,
                    color: WardrobeTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 12, color: WardrobeTheme.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Manual transfer workflow: TESS safely imports and validates your external ChatGPT outputs.',
                          style: TextStyle(fontSize: 10, color: WardrobeTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'ORIGINAL GARMENT PHOTOGRAPH (OPTIONAL BUT RECOMMENDED)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: WardrobeTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          if (hasImage) ...[
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WardrobeTheme.borderSubtle),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.memory(
                    Uint8List.fromList(controller.originalImageBytes!),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 280,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        tooltip: 'Remove Photograph',
                        onPressed: () => controller.removeOriginalImage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.pickOriginalImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Replace Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WardrobeTheme.textSecondary,
                      side: BorderSide(color: WardrobeTheme.border),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.pickOriginalImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Retake Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WardrobeTheme.textSecondary,
                      side: BorderSide(color: WardrobeTheme.border),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: WardrobeTheme.borderSubtle,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 44, color: WardrobeTheme.softViolet),
                  const SizedBox(height: 12),
                  Text(
                    'Attach Original Clothing Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select a photo from your gallery or take a new one to preserve your original garment reference.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: WardrobeTheme.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => controller.pickOriginalImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                        label: const Text('Device Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WardrobeTheme.electricViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => controller.pickOriginalImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: WardrobeTheme.textPrimary,
                          side: BorderSide(color: WardrobeTheme.border),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Optional Garment Notes
          Text(
            'OPTIONAL NOTES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: WardrobeTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: 2,
            initialValue: controller.originalUserNotes ?? '',
            onChanged: (val) => controller.setOriginalUserNotes(val),
            style: TextStyle(fontSize: 12, color: WardrobeTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Wedding gift, dry cleaned once, purchased in Jaipur...',
              hintStyle: TextStyle(fontSize: 12, color: WardrobeTheme.textMuted),
              filled: true,
              fillColor: WardrobeTheme.spatialSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: WardrobeTheme.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: WardrobeTheme.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: WardrobeTheme.borderViolet),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
