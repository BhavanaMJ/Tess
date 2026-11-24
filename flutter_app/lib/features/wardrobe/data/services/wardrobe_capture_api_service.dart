import '../../../../core/network/api_client.dart';
import '../models/capture_job_model.dart';
import '../models/garment_candidate_model.dart';

/// API Service for Wardrobe Smart Capture backend endpoints.
class WardrobeCaptureApiService {
  final ApiClient _apiClient;

  WardrobeCaptureApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// POST /api/v1/wardrobe/capture/jobs
  Future<CaptureJobModel> createJob(
      List<int> fileBytes, String filename) async {
    final response = await _apiClient.postMultipart(
      '/api/v1/wardrobe/capture/jobs',
      fileBytes: fileBytes,
      filename: filename,
      fieldName: 'image',
    );

    if (response is Map<String, dynamic>) {
      return CaptureJobModel.fromJson(response);
    }
    throw ApiException(
        statusCode: 500, message: 'Invalid response from capture API');
  }

  /// GET /api/v1/wardrobe/capture/jobs/{id}
  Future<CaptureJobModel> getJob(String jobId) async {
    final response =
        await _apiClient.get('/api/v1/wardrobe/capture/jobs/$jobId');
    if (response is Map<String, dynamic>) {
      return CaptureJobModel.fromJson(response);
    }
    throw ApiException(
        statusCode: 500, message: 'Invalid response fetching capture job');
  }

  /// GET /api/v1/wardrobe/capture/jobs/{id}/candidates
  Future<List<GarmentCandidateModel>> getCandidates(String jobId) async {
    final response =
        await _apiClient.get('/api/v1/wardrobe/capture/jobs/$jobId/candidates');
    if (response is List) {
      return response
          .map((item) =>
              GarmentCandidateModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// PATCH /api/v1/wardrobe/capture/candidates/{id}
  Future<GarmentCandidateModel> patchCandidate(
    String candidateId,
    Map<String, dynamic> delta,
  ) async {
    final response = await _apiClient.patch(
      '/api/v1/wardrobe/capture/candidates/$candidateId',
      body: delta,
    );
    if (response is Map<String, dynamic>) {
      return GarmentCandidateModel.fromJson(response);
    }
    throw ApiException(
        statusCode: 500, message: 'Invalid response updating candidate');
  }

  /// POST /api/v1/wardrobe/capture/jobs/{id}/retry
  Future<CaptureJobModel> retryJob(String jobId) async {
    final response =
        await _apiClient.post('/api/v1/wardrobe/capture/jobs/$jobId/retry');
    if (response is Map<String, dynamic>) {
      return CaptureJobModel.fromJson(response);
    }
    throw ApiException(
        statusCode: 500, message: 'Invalid response retrying capture job');
  }

  /// POST /api/v1/wardrobe/capture/jobs/{id}/confirm
  Future<Map<String, dynamic>> confirmJob(String jobId,
      {List<String>? candidateIds}) async {
    final payload = candidateIds != null ? {'candidate_ids': candidateIds} : {};
    final response = await _apiClient.post(
      '/api/v1/wardrobe/capture/jobs/$jobId/confirm',
      body: payload,
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException(
        statusCode: 500,
        message: 'Invalid response confirming capture garments');
  }

  /// GET /api/v1/wardrobe/capture/jobs/{id}/diagnostic
  Future<Map<String, dynamic>> getJobDiagnostic(String jobId) async {
    final response = await _apiClient.get(
      '/api/v1/wardrobe/capture/jobs/$jobId/diagnostic',
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException(
        statusCode: 500,
        message: 'Invalid response fetching capture job diagnostic');
  }
}
