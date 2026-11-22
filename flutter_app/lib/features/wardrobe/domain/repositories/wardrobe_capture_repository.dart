import '../entities/capture_job.dart';
import '../entities/garment_candidate.dart';

abstract class WardrobeCaptureRepository {
  Future<CaptureJob> uploadAndProcessCapture(
      List<int> imageBytes, String filename);
  Future<CaptureJob> getJobStatus(String jobId);
  Future<List<GarmentCandidate>> getJobCandidates(String jobId);
  Future<GarmentCandidate> updateCandidate(
      String candidateId, Map<String, dynamic> delta);
  Future<CaptureJob> retryJob(String jobId);
  Future<Map<String, dynamic>> confirmJob(String jobId,
      {List<String>? candidateIds});
}
