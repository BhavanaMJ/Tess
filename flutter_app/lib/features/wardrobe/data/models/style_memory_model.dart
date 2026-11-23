import '../../domain/entities/style_memory.dart';

class StyleMemoryModel {
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
  final String updatedAt;

  StyleMemoryModel({
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

  factory StyleMemoryModel.fromJson(Map<String, dynamic> json) {
    return StyleMemoryModel(
      userId: json['user_id'] ?? '',
      stylePersona: json['style_persona'] ?? 'Casual Classic',
      preferredColors: (json['preferred_colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      preferredCategories: (json['preferred_categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      preferredOccasions: (json['preferred_occasions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      avoidedCombinations: (json['avoided_combinations'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      favoritePairingRules: (json['favorite_pairing_rules'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      notes: json['notes'],
      topWornColors: (json['top_worn_colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      topWornCategories: (json['top_worn_categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      dominantOccasions: (json['dominant_occasions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      interactionSummary: json['interaction_summary'] ?? '',
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  StyleMemory toDomain() {
    return StyleMemory(
      userId: userId,
      stylePersona: stylePersona,
      preferredColors: preferredColors,
      preferredCategories: preferredCategories,
      preferredOccasions: preferredOccasions,
      avoidedCombinations: avoidedCombinations,
      favoritePairingRules: favoritePairingRules,
      notes: notes,
      topWornColors: topWornColors,
      topWornCategories: topWornCategories,
      dominantOccasions: dominantOccasions,
      interactionSummary: interactionSummary,
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }
}
