import 'outfit.dart';

class ActualWearRecord {
  final String id;
  final String userId;
  final String outfitId;
  final String outfitName;
  final Outfit outfit;
  final String? planId;
  final String actualWornDate; // YYYY-MM-DD
  final DateTime wornAt;
  final List<String> garmentsUpdated;
  final int wearCount;
  final String? notes;
  final DateTime createdAt;

  const ActualWearRecord({
    required this.id,
    required this.userId,
    required this.outfitId,
    required this.outfitName,
    required this.outfit,
    this.planId,
    required this.actualWornDate,
    required this.wornAt,
    this.garmentsUpdated = const [],
    this.wearCount = 1,
    this.notes,
    required this.createdAt,
  });
}

