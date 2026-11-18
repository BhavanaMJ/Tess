import 'dart:async';
import 'package:flutter/material.dart';
import 'tess_mascot_state.dart';

/// Controller that coordinates TESS Mascot expressions and transitions
/// across screens, handling state changes, auto-revert timers, and animations.
class TessMascotController extends ChangeNotifier {
  TessMascotState _currentState = TessMascotState.idle;
  TessMascotState _baseState = TessMascotState.idle;
  Timer? _temporaryTimer;

  TessMascotState get currentState => _currentState;
  TessMascotState get state => _currentState;

  TessMascotController([TessMascotState initialState = TessMascotState.idle]) {
    _currentState = initialState;
    _baseState = initialState;
  }

  /// Express a temporary state with auto-revert
  void express(
    TessMascotState tempState, {
    Duration duration = const Duration(milliseconds: 1800),
    TessMascotState? revertTo,
  }) => setTemporaryState(tempState, duration: duration, revertTo: revertTo);

  /// Sets the permanent state of the mascot
  void setState(TessMascotState newState) {
    _temporaryTimer?.cancel();
    _temporaryTimer = null;
    _baseState = newState;
    if (_currentState != newState) {
      _currentState = newState;
      notifyListeners();
    }
  }

  /// Triggers a temporary expression that automatically reverts back to the base state
  void setTemporaryState(
    TessMascotState tempState, {
    Duration duration = const Duration(milliseconds: 1800),
    TessMascotState? revertTo,
  }) {
    _temporaryTimer?.cancel();
    _currentState = tempState;
    notifyListeners();

    _temporaryTimer = Timer(duration, () {
      _currentState = revertTo ?? _baseState;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _temporaryTimer?.cancel();
    super.dispose();
  }
}
