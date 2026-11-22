import '../companion/tess_emotion.dart';

/// The nine canonical expressive states for the TESS Mascot Companion
/// according to the TESS Expressive Companion Design Specification v1.0.
enum TessMascotState {
  /// Baseline resting state: relaxed breathing, periodic natural blinks.
  idle,

  /// Processing queries, running semantic inference, or querying external APIs.
  thinking,

  /// Positive outcome, query resolved, friendly greeting, milestone achieved.
  happy,

  /// Alert, deadline risk detected, anomaly found, requires user vigilance.
  attention,

  /// Formulating multi-step agent execution plan, scheduling actions.
  planning,

  /// Awaiting explicit user confirmation before executing a consequential step.
  confirming,

  /// Actively executing an authorized plan or tool action.
  acting,

  /// Action succeeded, worklog posted, goal achieved.
  success,

  /// Request failure, network offline, permission denied.
  error,
}

extension TessMascotStateX on TessMascotState {
  String get displayName {
    switch (this) {
      case TessMascotState.idle:
        return 'Idle';
      case TessMascotState.thinking:
        return 'Thinking';
      case TessMascotState.happy:
        return 'Happy';
      case TessMascotState.attention:
        return 'Attention';
      case TessMascotState.planning:
        return 'Planning';
      case TessMascotState.confirming:
        return 'Confirming';
      case TessMascotState.acting:
        return 'Acting';
      case TessMascotState.success:
        return 'Success';
      case TessMascotState.error:
        return 'Error';
    }
  }

  String get cognitiveStatus {
    switch (this) {
      case TessMascotState.idle:
        return 'TESS Companion Online';
      case TessMascotState.thinking:
        return 'Thinking...';
      case TessMascotState.happy:
        return 'Ready to help';
      case TessMascotState.attention:
        return 'Attention required';
      case TessMascotState.planning:
        return 'Planning steps...';
      case TessMascotState.confirming:
        return 'Awaiting confirmation';
      case TessMascotState.acting:
        return 'Executing task...';
      case TessMascotState.success:
        return 'Goal achieved';
      case TessMascotState.error:
        return 'Connection error';
    }
  }

  /// Convert to equivalent TessEmotion
  TessEmotion toTessEmotion() {
    switch (this) {
      case TessMascotState.idle:
        return TessEmotion.idle;
      case TessMascotState.thinking:
        return TessEmotion.thinking;
      case TessMascotState.happy:
        return TessEmotion.happy;
      case TessMascotState.attention:
        return TessEmotion.attention;
      case TessMascotState.planning:
        return TessEmotion.planning;
      case TessMascotState.confirming:
        return TessEmotion.confirming;
      case TessMascotState.acting:
        return TessEmotion.acting;
      case TessMascotState.success:
        return TessEmotion.success;
      case TessMascotState.error:
        return TessEmotion.error;
    }
  }
}
