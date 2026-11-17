import '../../../core/network/api_client.dart';
import '../models/screen_analysis_model.dart';

/// ScreenAnalysisService manages user-consented screen understanding requests,
/// payload validation, and vision AI analysis through FastAPI /api/v1/screen/analyze.
class ScreenAnalysisService {
  final ApiClient _apiClient;

  // Maximum allowed screenshot payload: 10 MB
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  ScreenAnalysisService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Validates that bytes correspond to valid PNG or JPEG image format
  static bool isValidImageFormat(List<int> bytes) {
    if (bytes.length < 8) return false;
    // Check PNG signature: 89 50 4E 47 0D 0A 1A 0A
    final isPng = bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47;
    // Check JPEG signature: FF D8 FF
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    return isPng || isJpeg;
  }

  /// Submits an explicitly user-consented screen capture for vision AI analysis
  Future<ScreenAnalysisModel> analyzeScreen({
    required List<int> imageBytes,
    required String query,
    required bool hasUserConsent,
    String filename = 'screenshot.jpg',
  }) async {
    // 1. Strict Consent Guard: Privacy requirement
    if (!hasUserConsent) {
      throw ApiException(
        statusCode: 403,
        message: 'Screen capture rejected: Explicit user consent is mandatory.',
      );
    }

    // 2. Size Validation
    if (imageBytes.isEmpty) {
      throw ApiException(statusCode: 400, message: 'Screenshot buffer is empty.');
    }
    if (imageBytes.length > maxFileSizeBytes) {
      throw ApiException(
        statusCode: 400,
        message: 'Screenshot exceeds maximum payload limit (10MB).',
      );
    }

    // 3. Format Validation
    if (!isValidImageFormat(imageBytes)) {
      throw ApiException(
        statusCode: 400,
        message: 'Unsupported image format. Please provide PNG or JPEG screenshot bytes.',
      );
    }

    // 4. Submit to FastAPI backend
    final response = await _apiClient.postMultipart(
      '/api/v1/screen/analyze',
      fileBytes: imageBytes,
      filename: filename,
      fieldName: 'file',
      fields: {'query': query.trim().isNotEmpty ? query.trim() : 'Explain what is on the screen and any errors.'},
    );

    if (response is Map<String, dynamic>) {
      return ScreenAnalysisModel.fromJson(response);
    }

    throw ApiException(
      statusCode: 500,
      message: 'Unexpected response from vision intelligence engine.',
    );
  }
}
