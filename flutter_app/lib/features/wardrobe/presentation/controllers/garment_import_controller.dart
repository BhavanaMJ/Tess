import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/garment.dart';
import '../../domain/entities/garment_metadata_v1_1.dart';
import '../../domain/repositories/wardrobe_import_repository.dart';
import '../../data/models/garment_metadata_model_v1_1.dart';

/// Controller coordinating the 4-stage ChatGPT-Assisted Garment Import workflow.
class GarmentImportController extends ChangeNotifier {
  final WardrobeImportRepository _repository;
  final ImagePicker _picker;
  final String userId;

  int _currentStep = 0; // 0: Prepare, 1: Catalogue, 2: JSON, 3: Review
  bool _isUploading = false;
  bool _isValidating = false;
  bool _isRegistering = false;
  String? _errorMessage;

  // Stage 1: Original Garment Photograph
  List<int>? _originalImageBytes;
  String? _originalImageName;
  String? _originalImageRef;
  String? _originalUserNotes;

  // Stage 2: Imported Studio Catalogue Photograph (Mandatory)
  List<int>? _catalogueImageBytes;
  String? _catalogueImageName;
  String? _catalogueImageRef;

  // Stage 3: Metadata JSON Input
  String _rawJson = '';
  List<String> _validationErrors = [];
  List<String> _validationWarnings = [];

  // Stage 4: Parsed & Editable Metadata
  GarmentMetadataV1_1? _metadata;
  Garment? _registeredGarment;

  GarmentImportController({
    required WardrobeImportRepository repository,
    ImagePicker? picker,
    required this.userId,
  })  : _repository = repository,
        _picker = picker ?? ImagePicker();

  int get currentStep => _currentStep;
  bool get isUploading => _isUploading;
  bool get isValidating => _isValidating;
  bool get isRegistering => _isRegistering;
  String? get errorMessage => _errorMessage;

  List<int>? get originalImageBytes => _originalImageBytes;
  String? get originalImageName => _originalImageName;
  String? get originalImageRef => _originalImageRef;
  String? get originalUserNotes => _originalUserNotes;

  List<int>? get catalogueImageBytes => _catalogueImageBytes;
  String? get catalogueImageName => _catalogueImageName;
  String? get catalogueImageRef => _catalogueImageRef;

  String get rawJson => _rawJson;
  List<String> get validationErrors => _validationErrors;
  List<String> get validationWarnings => _validationWarnings;
  GarmentMetadataV1_1? get metadata => _metadata;
  Garment? get registeredGarment => _registeredGarment;

  bool get hasCatalogueImage => _catalogueImageBytes != null || (_catalogueImageRef != null && _catalogueImageRef!.isNotEmpty);
  bool get hasOriginalImage => _originalImageBytes != null || (_originalImageRef != null && _originalImageRef!.isNotEmpty);
  bool get isMetadataValid => _validationErrors.isEmpty && _metadata != null;

  void setOriginalUserNotes(String notes) {
    _originalUserNotes = notes;
    notifyListeners();
  }

  void goToStep(int step) {
    if (step < 0 || step > 3) return;
    if (step >= 2 && !hasCatalogueImage) {
      _errorMessage = 'Please upload a catalogue image before continuing.';
      notifyListeners();
      return;
    }
    if (step >= 3 && _metadata == null) {
      _errorMessage = 'Please paste and validate your garment metadata JSON first.';
      notifyListeners();
      return;
    }
    _currentStep = step;
    _errorMessage = null;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 3) {
      goToStep(_currentStep + 1);
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void setOriginalImageBytes(List<int> bytes, String filename) {
    _originalImageBytes = bytes;
    _originalImageName = filename;
    _originalImageRef = null;
    notifyListeners();
    _saveDraftDebounced();
  }

  void setCatalogueImageBytes(List<int> bytes, String filename) {
    _catalogueImageBytes = bytes;
    _catalogueImageName = filename;
    _catalogueImageRef = null;
    notifyListeners();
    _saveDraftDebounced();
  }

  Future<void> saveDraft() async {
    _saveDraftDebounced();
  }

  // --- STAGE 1: ORIGINAL PHOTO ---
  Future<bool> pickOriginalImage(ImageSource source) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );
      if (file == null) return false;

      final bytes = await file.readAsBytes();
      if (bytes.length > 15 * 1024 * 1024) {
        _errorMessage = 'Original photograph exceeds 15MB limit.';
        notifyListeners();
        return false;
      }

      _originalImageBytes = bytes;
      _originalImageName = file.name;
      _originalImageRef = null; // Reset to force re-upload
      notifyListeners();

      // Auto-save draft
      _saveDraftDebounced();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to pick original image: $e';
      notifyListeners();
      return false;
    }
  }

  void removeOriginalImage() {
    _originalImageBytes = null;
    _originalImageName = null;
    _originalImageRef = null;
    _errorMessage = null;
    notifyListeners();
    _saveDraftDebounced();
  }

  // --- STAGE 2: CATALOGUE PHOTO ---
  Future<bool> pickCatalogueImage(ImageSource source) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 92,
      );
      if (file == null) return false;

      final bytes = await file.readAsBytes();
      if (bytes.length > 15 * 1024 * 1024) {
        _errorMessage = 'Catalogue photograph exceeds 15MB limit.';
        notifyListeners();
        return false;
      }

      _catalogueImageBytes = bytes;
      _catalogueImageName = file.name;
      _catalogueImageRef = null;
      notifyListeners();

      _saveDraftDebounced();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to pick catalogue image: $e';
      notifyListeners();
      return false;
    }
  }

  void removeCatalogueImage() {
    _catalogueImageBytes = null;
    _catalogueImageName = null;
    _catalogueImageRef = null;
    _errorMessage = null;
    notifyListeners();
    _saveDraftDebounced();
  }

  // --- STAGE 3: METADATA JSON ---
  void setRawJson(String json) {
    _rawJson = json;
    _validationErrors = [];
    _validationWarnings = [];
    notifyListeners();
    _saveDraftDebounced();
  }

  void clearJson() {
    _rawJson = '';
    _validationErrors = [];
    _validationWarnings = [];
    _metadata = null;
    notifyListeners();
    _saveDraftDebounced();
  }

  Future<bool> validateMetadata() async {
    if (_rawJson.trim().isEmpty) {
      _validationErrors = ['Please paste your garment metadata JSON.'];
      notifyListeners();
      return false;
    }

    _isValidating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.validateMetadata(rawJson: _rawJson);
      _isValidating = false;

      if (result.isValid && result.entity != null) {
        _metadata = result.entity;
        _validationErrors = [];
        _validationWarnings = result.warnings;
        notifyListeners();
        _saveDraftDebounced();
        return true;
      } else {
        _validationErrors = result.errors;
        _validationWarnings = result.warnings;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isValidating = false;
      _validationErrors = ['Validation failed: $e'];
      notifyListeners();
      return false;
    }
  }

  // --- STAGE 4: METADATA EDITING & REGISTRATION ---
  void updateMetadata(GarmentMetadataV1_1 updated) {
    _metadata = updated;
    notifyListeners();
    _saveDraftDebounced();
  }

  Future<bool> registerGarment() async {
    if (_metadata == null) {
      _errorMessage = 'Metadata must be validated before registration.';
      notifyListeners();
      return false;
    }

    if (!hasCatalogueImage) {
      _errorMessage = 'Please upload a catalogue image before continuing.';
      notifyListeners();
      return false;
    }

    _isRegistering = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload catalogue image if not already uploaded
      String catRef = _catalogueImageRef ?? '';
      if (catRef.isEmpty && _catalogueImageBytes != null) {
        _isUploading = true;
        notifyListeners();
        try {
          catRef = await _repository.uploadImage(
            fileBytes: _catalogueImageBytes!,
            filename: _catalogueImageName ?? 'catalogue.jpg',
            imageType: 'catalogue',
          );
          _catalogueImageRef = catRef;
        } finally {
          _isUploading = false;
        }
      }

      // 2. Upload original image if provided and not yet uploaded
      String? origRef = _originalImageRef;
      if ((origRef == null || origRef.isEmpty) && _originalImageBytes != null) {
        _isUploading = true;
        notifyListeners();
        try {
          origRef = await _repository.uploadImage(
            fileBytes: _originalImageBytes!,
            filename: _originalImageName ?? 'original.jpg',
            imageType: 'original',
          );
          _originalImageRef = origRef;
        } finally {
          _isUploading = false;
        }
      }

      // 3. Register garment
      final created = await _repository.registerGarment(
        catalogueImageRef: catRef,
        originalImageRef: origRef,
        metadata: _metadata!,
      );

      _registeredGarment = created;
      _isRegistering = false;
      notifyListeners();

      // Clear draft on successful registration
      await _repository.clearDraft(userId);
      return true;
    } catch (e) {
      _isRegistering = false;
      _errorMessage = 'Registration failed: $e. Your inputs have been preserved to retry.';
      notifyListeners();
      return false;
    }
  }

  // --- DRAFT MANAGEMENT ---
  void _saveDraftDebounced() {
    final draft = <String, dynamic>{
      'currentStep': _currentStep,
      'originalImageName': _originalImageName,
      'originalImageRef': _originalImageRef,
      'originalUserNotes': _originalUserNotes,
      'catalogueImageName': _catalogueImageName,
      'catalogueImageRef': _catalogueImageRef,
      'rawJson': _rawJson,
      if (_metadata != null) 'metadata': GarmentMetadataModelV1_1.toJson(_metadata!),
    };
    _repository.saveDraft(userId, draft);
  }

  Future<bool> loadDraftIfExists() async {
    final draft = await _repository.loadDraft(userId);
    if (draft == null) return false;

    try {
      _currentStep = (draft['currentStep'] as num?)?.toInt() ?? 0;
      _originalImageName = draft['originalImageName']?.toString();
      _originalImageRef = draft['originalImageRef']?.toString();
      _originalUserNotes = draft['originalUserNotes']?.toString();
      _catalogueImageName = draft['catalogueImageName']?.toString();
      _catalogueImageRef = draft['catalogueImageRef']?.toString();
      _rawJson = draft['rawJson']?.toString() ?? '';

      if (draft['metadata'] != null) {
        _metadata = GarmentMetadataModelV1_1.fromJson(draft['metadata'] as Map<String, dynamic>);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[GarmentImportController] Failed to parse draft: $e');
      return false;
    }
  }

  Future<void> clearAll() async {
    _currentStep = 0;
    _originalImageBytes = null;
    _originalImageName = null;
    _originalImageRef = null;
    _originalUserNotes = null;
    _catalogueImageBytes = null;
    _catalogueImageName = null;
    _catalogueImageRef = null;
    _rawJson = '';
    _validationErrors = [];
    _validationWarnings = [];
    _metadata = null;
    _registeredGarment = null;
    _errorMessage = null;
    await _repository.clearDraft(userId);
    notifyListeners();
  }
}
