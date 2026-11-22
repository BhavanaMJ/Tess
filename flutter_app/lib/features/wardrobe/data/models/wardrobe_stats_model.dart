import '../../domain/entities/wardrobe_stats.dart';

/// DTO for WardrobeStats serialization.
class WardrobeStatsModel {
  final int totalGarments;
  final int cleanCount;
  final int wornCount;
  final int inLaundryCount;
  final int storedCount;
  final int unassignedCount;

  const WardrobeStatsModel({
    required this.totalGarments,
    required this.cleanCount,
    required this.wornCount,
    required this.inLaundryCount,
    required this.storedCount,
    required this.unassignedCount,
  });

  factory WardrobeStatsModel.fromJson(Map<String, dynamic> json) {
    return WardrobeStatsModel(
      totalGarments: (json['total_garments'] as num?)?.toInt() ?? 0,
      cleanCount: (json['clean_count'] as num?)?.toInt() ?? 0,
      wornCount: (json['worn_count'] as num?)?.toInt() ?? 0,
      inLaundryCount: (json['in_laundry_count'] as num?)?.toInt() ?? 0,
      storedCount: (json['stored_count'] as num?)?.toInt() ?? 0,
      unassignedCount: (json['unassigned_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_garments': totalGarments,
      'clean_count': cleanCount,
      'worn_count': wornCount,
      'in_laundry_count': inLaundryCount,
      'stored_count': storedCount,
      'unassigned_count': unassignedCount,
    };
  }

  WardrobeStats toDomain() {
    return WardrobeStats(
      totalGarments: totalGarments,
      cleanCount: cleanCount,
      wornCount: wornCount,
      inLaundryCount: inLaundryCount,
      storedCount: storedCount,
      unassignedCount: unassignedCount,
    );
  }
}
