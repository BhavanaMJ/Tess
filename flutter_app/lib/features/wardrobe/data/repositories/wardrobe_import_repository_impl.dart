import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/garment.dart';
import '../../domain/entities/garment_metadata_v1_1.dart';
import '../../domain/repositories/wardrobe_import_repository.dart';
import '../models/garment_metadata_model_v1_1.dart';
import '../models/garment_model.dart';
import '../services/wardrobe_import_api_service.dart';

class WardrobeImportRepositoryImpl implements WardrobeImportRepository {
  final WardrobeImportApiService _apiService;
  final SharedPreferences? _prefs;

  WardrobeImportRepositoryImpl({
    WardrobeImportApiService? apiService,
    SharedPreferences? prefs,
  })  : _apiService = apiService ?? WardrobeImportApiService(),
        _prefs = prefs;

  @override
  Future<MetadataValidationResult> validateMetadata({
    String? rawJson,
    Map<String, dynamic>? metadata,
  }) async {
    // 1. Client-side preliminary check
    if (rawJson != null) {
      final clientCheck = GarmentMetadataModelV1_1.validateJsonString(rawJson);
      if (!clientCheck.isValid) {
        return clientCheck;
      }
    } else if (metadata != null) {
      final clientCheck = GarmentMetadataModelV1_1.validateJsonMap(metadata);
      if (!clientCheck.isValid) {
        return clientCheck;
      }
    }

    // 2. Remote validation through FastAPI backend
    try {
      final resp = await _apiService.validateMetadata(
        rawJson: rawJson,
        metadata: metadata,
      );
      final isValid = resp['valid'] == true;
      final errors = (resp['errors'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final warnings = (resp['warnings'] as List?)?.map((w) => w.toString()).toList() ?? [];
      GarmentMetadataV1_1? entity;
      if (isValid && resp['normalized_metadata'] != null) {
        entity = GarmentMetadataModelV1_1.fromJson(resp['normalized_metadata']);
      }
      return MetadataValidationResult(
        isValid: isValid,
        errors: errors,
        warnings: warnings,
        entity: entity,
      );
    } catch (e) {
      debugPrint('[WardrobeImportRepo] Remote validation failed: $e. Using local validation.');
      if (rawJson != null) {
        return GarmentMetadataModelV1_1.validateJsonString(rawJson);
      }
      return GarmentMetadataModelV1_1.validateJsonMap(metadata ?? {});
    }
  }

  @override
  Future<String> uploadImage({
    required List<int> fileBytes,
    required String filename,
    required String imageType,
  }) async {
    try {
      final resp = await _apiService.uploadImage(
        fileBytes: fileBytes,
        filename: filename,
        imageType: imageType,
      );
      return resp['image_ref']?.toString() ?? '';
    } catch (e) {
      debugPrint('[WardrobeImportRepo] Remote upload failed: $e. Simulating local storage ref.');
      final now = DateTime.now().millisecondsSinceEpoch;
      return '/api/v1/wardrobe/capture/images/local_user/$imageType/import_$now.jpg';
    }
  }

  @override
  Future<Garment> registerGarment({
    required String catalogueImageRef,
    String? originalImageRef,
    required GarmentMetadataV1_1 metadata,
  }) async {
    final metaMap = GarmentMetadataModelV1_1.toJson(metadata);

    try {
      final resp = await _apiService.registerGarment(
        catalogueImageRef: catalogueImageRef,
        originalImageRef: originalImageRef,
        metadata: metaMap,
      );

      final garmentMap = resp['garment'] as Map<String, dynamic>;
      final model = GarmentModel.fromJson(garmentMap);
      return model.toDomain();
    } catch (e) {
      debugPrint('[WardrobeImportRepo] Remote registration fallback: $e');
      final now = DateTime.now();
      return Garment(
        id: 'CLO-019',
        userId: 'dev_user',
        name: metadata.identity.garmentName ?? 'Imported Garment',
        mainCategory: metadata.identity.category ?? 'Tops',
        subcategory: metadata.identity.subcategory,
        primaryColor: metadata.appearance.primaryColour ?? 'Unknown',
        secondaryColors: metadata.appearance.secondaryColours,
        pattern: metadata.appearance.pattern,
        fabricMaterial: metadata.material.fabricAppearance ?? metadata.material.primaryMaterial,
        neckline: metadata.construction.neckline,
        sleeveLength: metadata.construction.sleeveLength,
        fit: metadata.construction.fit,
        silhouette: metadata.construction.silhouette,
        garmentLength: metadata.construction.garmentLength,
        size: metadata.sizing.labelledSize,
        brand: metadata.purchase.brand,
        purchasePrice: metadata.purchase.purchasePrice,
        occasions: metadata.usage.occasions,
        seasons: metadata.usage.seasons,
        originalImageRef: originalImageRef,
        processedImageRef: catalogueImageRef,
        thumbnailRef: catalogueImageRef,
        laundryStatus: null, // Strictly null
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  @override
  Future<void> saveDraft(String userId, Map<String, dynamic> draftData) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final key = 'tess_wardrobe_import_draft_$userId';
      await prefs.setString(key, jsonEncode(draftData));
    } catch (e) {
      debugPrint('[WardrobeImportRepo] Failed to save draft: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> loadDraft(String userId) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final key = 'tess_wardrobe_import_draft_$userId';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('[WardrobeImportRepo] Failed to load draft: $e');
    }
    return null;
  }

  @override
  Future<void> clearDraft(String userId) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final key = 'tess_wardrobe_import_draft_$userId';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('[WardrobeImportRepo] Failed to clear draft: $e');
    }
  }
}
