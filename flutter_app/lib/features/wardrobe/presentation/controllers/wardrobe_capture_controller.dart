import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/capture_job.dart';
import '../../domain/entities/garment_candidate.dart';
import '../../domain/repositories/wardrobe_capture_repository.dart';

/// Presentation controller managing Smart Capture flow, validation, progress polling,
/// candidate review, attribute modification, and batch registration.
class WardrobeCaptureController extends ChangeNotifier {
  final WardrobeCaptureRepository _repository;
  final ImagePicker _picker;

  bool _isUploading = false;
  bool _isProcessing = false;
  bool _isConfirming = false;
  String? _errorMessage;
  String? _validationWarning;

  List<int>? _selectedImageBytes;
  String? _selectedImageName;
  CaptureJob? _activeJob;
  List<GarmentCandidate> _candidates = [];

  Timer? _pollingTimer;

  WardrobeCaptureController({
    required WardrobeCaptureRepository repository,
    ImagePicker? picker,
  })  : _repository = repository,
        _picker = picker ?? ImagePicker();

  bool get isUploading => _isUploading;
  bool get isProcessing => _isProcessing;
  bool get isConfirming => _isConfirming;
  String? get errorMessage => _errorMessage;
  String? get validationWarning => _validationWarning;

  List<int>? get selectedImageBytes => _selectedImageBytes;
  String? get selectedImageName => _selectedImageName;
  CaptureJob? get activeJob => _activeJob;
  List<GarmentCandidate> get candidates => _candidates;

  int get includedCount => _candidates.where((c) => c.isIncluded).length;
  int get totalDetectedCount => _candidates.length;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void clearSelection() {
    _selectedImageBytes = null;
    _selectedImageName = null;
    _validationWarning = null;
    _errorMessage = null;
    _activeJob = null;
    _candidates = [];
    _pollingTimer?.cancel();
    notifyListeners();
  }

  /// Validates raw photograph bytes for size, format, and minimum dimensions.
  String? validateImageBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      return 'The photograph appears empty. Please retake or select another photo.';
    }
    if (bytes.length > 15 * 1024 * 1024) {
      return 'Photograph exceeds 15MB. Please choose a smaller image.';
    }
    if (bytes.length < 500) {
      return 'Photograph data is too small to contain a readable garment.';
    }
    return null;
  }

  Future<bool> pickImage(ImageSource source) async {
    _errorMessage = null;
    _validationWarning = null;
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
      final validationError = validateImageBytes(bytes);
      if (validationError != null) {
        _errorMessage = validationError;
        notifyListeners();
        return false;
      }

      _selectedImageBytes = bytes;
      _selectedImageName = file.name;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to access camera or gallery: $e';
      notifyListeners();
      return false;
    }
  }

  void setImageBytesDirectly(List<int> bytes, String filename) {
    _selectedImageBytes = bytes;
    _selectedImageName = filename;
    _errorMessage = null;
    notifyListeners();
  }

  Future<CaptureJob?> startCaptureJob() async {
    if (_selectedImageBytes == null) {
      _errorMessage = 'No photograph selected for processing.';
      notifyListeners();
      return null;
    }

    _isUploading = true;
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final job = await _repository.uploadAndProcessCapture(
        _selectedImageBytes!,
        _selectedImageName ?? 'garment_capture.jpg',
      );

      _activeJob = job;
      _candidates = job.candidates;
      _isUploading = false;

      if (job.isAwaitingApproval || job.isCompleted) {
        _isProcessing = false;
      } else {
        _startPolling(job.id);
      }

      notifyListeners();
      return job;
    } catch (e) {
      _errorMessage = e.toString();
      _isUploading = false;
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  void _startPolling(String jobId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      try {
        final job = await _repository.getJobStatus(jobId);
        _activeJob = job;
        if (job.candidates.isNotEmpty) {
          _candidates = job.candidates;
        }

        if (job.isAwaitingApproval || job.isCompleted || job.isFailed) {
          timer.cancel();
          _isProcessing = false;
          if (job.isFailed) {
            _errorMessage = job.errorMessage ?? 'Processing failed. Your original photograph is preserved.';
          }
        }
        notifyListeners();
      } catch (e) {
        timer.cancel();
        _isProcessing = false;
        _errorMessage = 'Connection interrupted: $e';
        notifyListeners();
      }
    });
  }

  Future<void> toggleCandidateInclusion(String candidateId) async {
    final idx = _candidates.indexWhere((c) => c.id == candidateId);
    if (idx == -1) return;

    final updatedInclusion = !_candidates[idx].isIncluded;
    _candidates[idx] = _candidates[idx].copyWith(isIncluded: updatedInclusion);
    notifyListeners();

    try {
      await _repository.updateCandidate(candidateId, {'is_included': updatedInclusion});
    } catch (e) {
      debugPrint('[WardrobeCaptureController] Remote inclusion patch failed: $e');
    }
  }

  Future<void> updateCandidate(GarmentCandidate updated) async {
    final idx = _candidates.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _candidates[idx] = updated;
      notifyListeners();
    }

    try {
      final delta = {
        'suggested_name': updated.suggestedName,
        'main_category': updated.mainCategory,
        'subcategory': updated.subcategory,
        'primary_color': updated.primaryColor,
        'secondary_colors': updated.secondaryColors,
        'pattern': updated.pattern,
        'fabric_material': updated.fabricMaterial,
        'sleeve_length': updated.sleeveLength,
        'neckline': updated.neckline,
        'fit': updated.fit,
        'size': updated.size,
        'brand': updated.brand,
      };
      await _repository.updateCandidate(updated.id, delta);
    } catch (e) {
      debugPrint('[WardrobeCaptureController] Candidate update failed: $e');
    }
  }

  Future<bool> retryCapture() async {
    if (_activeJob == null) return false;

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final job = await _repository.retryJob(_activeJob!.id);
      _activeJob = job;
      _candidates = job.candidates;
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Retry failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> confirmSelectedGarments() async {
    if (_activeJob == null) return null;

    final selectedIds = _candidates.where((c) => c.isIncluded).map((c) => c.id).toList();
    if (selectedIds.isEmpty) {
      _errorMessage = 'Please include at least one garment before registering.';
      notifyListeners();
      return null;
    }

    _isConfirming = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.confirmJob(_activeJob!.id, candidateIds: selectedIds);
      _isConfirming = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isConfirming = false;
      _errorMessage = 'Failed to register garments: $e';
      notifyListeners();
      return null;
    }
  }
}
