import 'base_entity.dart';

/// User Profile Model representing commander persona in TESS.
/// Demonstrates:
/// - Sound Null Safety (non-nullable vs nullable types)
/// - Null-aware coalescing operators (??)
/// - Dart collections (List<String>, Map<String, dynamic>)
class UserProfile extends BaseEntity implements Displayable {
  final String fullName;
  final String email;
  final String? callsign; // Nullable: user may not have customized their callsign
  final List<String> skillTags;
  final Map<String, String> telemetryPreferences;

  UserProfile({
    required super.id,
    required this.fullName,
    required this.email,
    this.callsign,
    List<String>? skillTags,
    Map<String, String>? telemetryPreferences,
    super.createdAt,
  })  : skillTags = skillTags ?? const ['COMMANDER', 'NEURAL_SYNC'],
        telemetryPreferences = telemetryPreferences ?? const {
          'ambientGlow': 'enabled',
          'predictiveHorizon': '72h',
        };

  /// Effective callsign using null-coalescing operator
  String get effectiveCallsign => callsign ?? 'Commander $fullName';

  @override
  String get displayTitle => fullName;

  @override
  String get displaySubtitle => effectiveCallsign;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'callsign': callsign,
      'skillTags': skillTags,
      'telemetryPreferences': telemetryPreferences,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

