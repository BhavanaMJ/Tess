import '../entities/garment.dart';
import '../entities/garment_metadata_v1_1.dart';
import '../../data/models/garment_metadata_model_v1_1.dart';

abstract class WardrobeImportRepository {
  Future<MetadataValidationResult> validateMetadata({
    String? rawJson,
    Map<String, dynamic>? metadata,
  });

  Future<String> uploadImage({
    required List<int> fileBytes,
    required String filename,
    required String imageType,
  });

  Future<Garment> registerGarment({
    required String catalogueImageRef,
    String? originalImageRef,
    required GarmentMetadataV1_1 metadata,
  });

  Future<void> saveDraft(String userId, Map<String, dynamic> draftData);
  Future<Map<String, dynamic>?> loadDraft(String userId);
  Future<void> clearDraft(String userId);
}
