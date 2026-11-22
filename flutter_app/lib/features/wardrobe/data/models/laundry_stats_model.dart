import '../../domain/entities/laundry_stats.dart';

class LaundryStatsModel {
  final int totalGarments;
  final int cleanCount;
  final int wornCount;
  final int washingCount;
  final int dryingCount;
  final int storedCount;
  final int unassignedCount;
  final int activeBatchesCount;

  const LaundryStatsModel({
    required this.totalGarments,
    required this.cleanCount,
    required this.wornCount,
    required this.washingCount,
    required this.dryingCount,
    required this.storedCount,
    required this.unassignedCount,
    this.activeBatchesCount = 0,
  });

  factory LaundryStatsModel.fromJson(Map<String, dynamic> json) {
    return LaundryStatsModel(
      totalGarments: (json['total_garments'] as num?)?.toInt() ?? 0,
      cleanCount: (json['clean_count'] as num?)?.toInt() ?? 0,
      wornCount: (json['worn_count'] as num?)?.toInt() ?? 0,
      washingCount: (json['washing_count'] as num?)?.toInt() ?? 0,
      dryingCount: (json['drying_count'] as num?)?.toInt() ?? 0,
      storedCount: (json['stored_count'] as num?)?.toInt() ?? 0,
      unassignedCount: (json['unassigned_count'] as num?)?.toInt() ?? 0,
      activeBatchesCount: (json['active_batches_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_garments': totalGarments,
      'clean_count': cleanCount,
      'worn_count': wornCount,
      'washing_count': washingCount,
      'drying_count': dryingCount,
      'stored_count': storedCount,
      'unassigned_count': unassignedCount,
      'active_batches_count': activeBatchesCount,
    };
  }

  LaundryStats toDomain() {
    return LaundryStats(
      totalGarments: totalGarments,
      cleanCount: cleanCount,
      wornCount: wornCount,
      washingCount: washingCount,
      dryingCount: dryingCount,
      storedCount: storedCount,
      unassignedCount: unassignedCount,
      activeBatchesCount: activeBatchesCount,
    );
  }
}
