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
        return 'Synthesizing Intelligence...';
      case TessMascotState.happy:
        return 'Trajectory Harmonized';
      case TessMascotState.attention:
        return 'Risk Divergence Detected';
      case TessMascotState.planning:
        return 'Formulating Action Steps...';
      case TessMascotState.confirming:
        return 'Confirmation Barrier Active';
      case TessMascotState.acting:
        return 'Executing Autonomous Plan...';
      case TessMascotState.success:
        return 'Objective Successfully Met';
      case TessMascotState.error:
        return 'Connection Anomaly';
    }
  }
}
