import '../../../../core/network/api_client.dart';

/// API service for ChatGPT-Assisted Garment Import endpoints.
class WardrobeImportApiService {
  final ApiClient _apiClient;

  WardrobeImportApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// POST /api/v1/wardrobe/import/validate-metadata
  Future<Map<String, dynamic>> validateMetadata({
    String? rawJson,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = <String, dynamic>{};
    if (rawJson != null) payload['raw_json'] = rawJson;
    if (metadata != null) payload['metadata'] = metadata;

    final response = await _apiClient.post(
      '/api/v1/wardrobe/import/validate-metadata',
      body: payload,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException(
      statusCode: 500,
      message: 'Invalid response from metadata validation API',
    );
  }

  /// POST /api/v1/wardrobe/import/upload-image
  Future<Map<String, dynamic>> uploadImage({
    required List<int> fileBytes,
    required String filename,
    required String imageType, // "catalogue" or "original"
  }) async {
    final response = await _apiClient.postMultipart(
      '/api/v1/wardrobe/import/upload-image',
      fileBytes: fileBytes,
      filename: filename,
      fieldName: 'image',
      fields: {'image_type': imageType},
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException(
      statusCode: 500,
      message: 'Invalid response from import image upload API',
    );
  }

  /// POST /api/v1/wardrobe/import/register
  Future<Map<String, dynamic>> registerGarment({
    required String catalogueImageRef,
    String? originalImageRef,
    required Map<String, dynamic> metadata,
  }) async {
    final payload = {
      'catalogue_image_ref': catalogueImageRef,
      'original_image_ref': originalImageRef,
      'metadata': metadata,
      'user_verified': true,
    };

    final response = await _apiClient.post(
      '/api/v1/wardrobe/import/register',
      body: payload,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException(
      statusCode: 500,
      message: 'Invalid response from garment import registration API',
    );
  }
}
