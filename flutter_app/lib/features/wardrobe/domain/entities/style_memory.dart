/// Personal Style Memory Entity.
class StyleMemory {
  final String userId;
  final String stylePersona;
  final List<String> preferredColors;
  final List<String> preferredCategories;
  final List<String> preferredOccasions;
  final List<Map<String, dynamic>> avoidedCombinations;
  final List<Map<String, dynamic>> favoritePairingRules;
  final String? notes;
  final List<String> topWornColors;
  final List<String> topWornCategories;
  final List<String> dominantOccasions;
  final String interactionSummary;
  final DateTime updatedAt;

  const StyleMemory({
    required this.userId,
    required this.stylePersona,
    required this.preferredColors,
    required this.preferredCategories,
    required this.preferredOccasions,
    this.avoidedCombinations = const [],
    this.favoritePairingRules = const [],
    this.notes,
    this.topWornColors = const [],
    this.topWornCategories = const [],
    this.dominantOccasions = const [],
    required this.interactionSummary,
    required this.updatedAt,
  });
}

