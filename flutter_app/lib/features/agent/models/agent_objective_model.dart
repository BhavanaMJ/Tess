/// Model encapsulating an agent objective prompt and client-side validation.
class AgentObjectiveModel {
  final String objective;

  const AgentObjectiveModel({required this.objective});

  Map<String, dynamic> toJson() => {'objective': objective};

  bool get isValid => objective.trim().length >= 3;

  String? get validationError {
    if (objective.trim().isEmpty) {
      return 'Objective prompt cannot be empty.';
    }
    if (objective.trim().length < 3) {
      return 'Please provide a more descriptive objective.';
    }
    return null;
  }

  /// Preset objective prompts supported by the TESS Agent Planner
  static const List<String> suggestions = [
    'Update my OpenProject worklog: 2 hours on task 1',
    'Prepare me for tomorrow\'s meeting',
    'Browse https://github.com and search updates',
    'Read report document.txt',
    'Send email to team@project.org',
  ];
}

