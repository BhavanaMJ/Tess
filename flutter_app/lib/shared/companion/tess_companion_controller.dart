import 'dart:async';
import 'package:flutter/foundation.dart';
import 'tess_emotion.dart';

/// State Controller for the Expressive TESS Companion.
/// Allows application components to command emotion changes, temporary expressions,
/// and smooth returns to idle.
class TessCompanionController extends ChangeNotifier {
  TessEmotion _emotion;
  Timer? _revertTimer;
  bool _isDisposed = false;

  TessCompanionController({TessEmotion initialEmotion = TessEmotion.idle})
      : _emotion = initialEmotion;

  /// Current active emotion
  TessEmotion get emotion => _emotion;

  /// Express a transient emotion with an automatic revert back to idle.
  /// If duration is null, persists until the next express() or setEmotion() call.
  void express(TessEmotion newEmotion, {Duration? duration}) {
    if (_isDisposed) return;
    _revertTimer?.cancel();
    _revertTimer = null;

    if (_emotion != newEmotion) {
      _emotion = newEmotion;
      notifyListeners();
    }

    if (duration != null && newEmotion != TessEmotion.idle) {
      _revertTimer = Timer(duration, () {
        if (!_isDisposed) {
          _emotion = TessEmotion.idle;
          notifyListeners();
        }
      });
    }
  }

  /// Explicitly set emotion indefinitely
  void setEmotion(TessEmotion newEmotion) {
    express(newEmotion, duration: null);
  }

  /// Helper to return immediately to idle
  void resetToIdle() {
    express(TessEmotion.idle);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _revertTimer?.cancel();
    _revertTimer = null;
    super.dispose();
  }
}

