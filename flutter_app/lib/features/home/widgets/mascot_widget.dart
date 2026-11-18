import 'package:flutter/material.dart';
import '../../../shared/mascot/tess_mascot.dart';
import '../../../shared/mascot/tess_mascot_state.dart';

/// Legacy MascotState enum preserved for 100% backwards compatibility
/// across existing feature controllers and tests.
enum MascotState {
  idle,
  thinking,
  listening,
  speaking,
  intervening,
  planning,
  attention,
  happy,
  error,
}

extension MascotStateX on MascotState {
  TessMascotState toTessMascotState() {
    switch (this) {
      case MascotState.happy:
        return TessMascotState.happy;
      case MascotState.thinking:
      case MascotState.speaking:
        return TessMascotState.thinking;
      case MascotState.planning:
        return TessMascotState.planning;
      case MascotState.attention:
      case MascotState.intervening:
        return TessMascotState.attention;
      case MascotState.error:
        return TessMascotState.error;
      case MascotState.idle:
      case MascotState.listening:
        return TessMascotState.idle;
    }
  }
}

/// MascotWidget renders the approved TESS Expressive Companion mascot
/// using the fluid organic silhouette and brand color identity.
class MascotWidget extends StatelessWidget {
  final MascotState state;
  final double size;

  const MascotWidget({
    super.key,
    this.state = MascotState.idle,
    this.size = 72.0,
  });

  @override
  Widget build(BuildContext context) {
    return TessMascot(
      state: state.toTessMascotState(),
      size: size,
      showStatusBadge: false,
    );
  }
}
