/// Model representing a registered device and notification credentials.
class DeviceRegistrationModel {
  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime? lastSeenAt;
  final String notificationPermission; // 'granted', 'denied', 'notDetermined'

  const DeviceRegistrationModel({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.lastSeenAt,
    this.notificationPermission = 'notDetermined',
  });

  factory DeviceRegistrationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString()).toUtc();
      } catch (_) {
        return null;
      }
    }

    return DeviceRegistrationModel(
      deviceId: json['device_id']?.toString() ?? '',
      deviceName: json['device_name']?.toString() ?? 'Mobile Device',
      platform: json['platform']?.toString() ?? 'android',
      lastSeenAt: parseDate(json['last_seen_at']),
      notificationPermission: json['notification_permission']?.toString() ?? 'granted',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
    };
  }

  bool get isNotificationsEnabled => notificationPermission == 'granted';
}

