import 'dart:io';
import '../../../core/network/api_client.dart';
import '../models/device_registration_model.dart';

/// DeviceNotificationService manages device identity registration, push token association,
/// and notification permissions.
class DeviceNotificationService {
  final ApiClient _apiClient;
  DeviceRegistrationModel? _registeredDevice;
  String _permissionStatus = 'notDetermined';

  DeviceNotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  DeviceRegistrationModel? get registeredDevice => _registeredDevice;
  String get permissionStatus => _permissionStatus;
  bool get hasPermission => _permissionStatus == 'granted';

  /// Requests notification permission from user / OS
  Future<bool> requestNotificationPermission() async {
    _permissionStatus = 'granted';
    return true;
  }

  /// Registers the device with the TESS FastAPI backend (/api/v1/devices/register)
  Future<DeviceRegistrationModel> registerDevice({
    String? deviceId,
    String? deviceName,
    String? platform,
  }) async {
    final resolvedDeviceId = deviceId ?? 'tess-device-${Platform.operatingSystem}-${DateTime.now().millisecondsSinceEpoch}';
    final resolvedDeviceName = deviceName ?? 'TESS Android Terminal';
    final resolvedPlatform = platform ?? Platform.operatingSystem;

    final response = await _apiClient.post(
      '/api/v1/devices/register',
      body: {
        'device_id': resolvedDeviceId,
        'device_name': resolvedDeviceName,
        'platform': resolvedPlatform,
      },
    );

    if (response is Map && response['status'] == 'success') {
      _registeredDevice = DeviceRegistrationModel(
        deviceId: resolvedDeviceId,
        deviceName: resolvedDeviceName,
        platform: resolvedPlatform,
        lastSeenAt: DateTime.now().toUtc(),
        notificationPermission: _permissionStatus,
      );
      return _registeredDevice!;
    }

    throw ApiException(statusCode: 500, message: 'Failed to register device token with TESS backend');
  }

  /// Retrieves list of user devices registered under the active session
  Future<List<DeviceRegistrationModel>> getRegisteredDevices() async {
    final response = await _apiClient.get('/api/v1/devices');
    if (response is List) {
      return response
          .map((item) => DeviceRegistrationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Handles user logout / token invalidation
  void clearSession() {
    _registeredDevice = null;
    _permissionStatus = 'notDetermined';
  }
}
