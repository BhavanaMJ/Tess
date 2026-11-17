/// Model representing an action confirmation record and fingerprint validation.
class ActionConfirmationModel {
  final String id;
  final String status; // PENDING, CONFIRMED, CANCELLED, EXPIRED
  final DateTime? expiresAt;
  final String summary;

  const ActionConfirmationModel({
    required this.id,
    required this.status,
    this.expiresAt,
    this.summary = '',
  });

  factory ActionConfirmationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedExpiry;
    final expStr = json['expires_at'];
    if (expStr != null) {
      try {
        parsedExpiry = DateTime.parse(expStr.toString()).toUtc();
      } catch (_) {}
    }

    return ActionConfirmationModel(
      id: json['id']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
      expiresAt: parsedExpiry,
      summary: json['summary']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'expires_at': expiresAt?.toIso8601String(),
      'summary': summary,
    };
  }

  bool get isPending => status == 'PENDING' && !isExpired;
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCancelled => status == 'CANCELLED';

  bool get isExpired {
    if (status == 'EXPIRED') return true;
    if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!)) {
      return true;
    }
    return false;
  }

  /// Extracts parameter fingerprint [fp:xxxx] if present in the summary
  String? get fingerprint {
    if (summary.contains('[fp:')) {
      final parts = summary.split('[fp:');
      if (parts.length > 1) {
        return parts[1].split(']')[0];
      }
    }
    return null;
  }

  /// Clean human-readable summary without internal fingerprint tag
  String get displaySummary {
    if (summary.contains('[fp:')) {
      return summary.replaceAll(RegExp(r'\s*\[fp:[^\]]+\]'), '').trim();
    }
    return summary;
  }
}

