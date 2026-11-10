import 'package:flutter/services.dart';
import 'api_service.dart';

class LocationSyncService {
  static const MethodChannel _gpsChannel = MethodChannel('com.kidshield.child/gps');
  final ApiService _api = ApiService();

  bool _isSharingEnabled = true;
  bool get isSharingEnabled => _isSharingEnabled;

  void toggleLocationSharing(bool enabled) {
    _isSharingEnabled = enabled;
  }

  /// Starts native Android Foreground Service with ongoing notification for continuous 24/7 background tracking
  Future<void> startNativeForegroundService(String childId) async {
    if (childId.isEmpty) return;
    try {
      await _gpsChannel.invokeMethod('startBackgroundLocationService', {
        'childId': childId,
        'baseUrl': ApiService.baseUrl,
      });
    } catch (_) {}
  }

  /// Stops native Android Foreground Service
  Future<void> stopNativeForegroundService() async {
    try {
      await _gpsChannel.invokeMethod('stopBackgroundLocationService');
    } catch (_) {}
  }

  /// Queries whether native foreground service is active
  Future<bool> isNativeServiceRunning() async {
    try {
      final res = await _gpsChannel.invokeMethod<bool>('isBackgroundLocationServiceRunning');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendLocationUpdate({
    required String childId,
    required double latitude,
    required double longitude,
    required String address,
    required int batteryLevel,
  }) async {
    if (!_isSharingEnabled) return;

    try {
      await _api.sendLocation(
        childId: childId,
        latitude: latitude,
        longitude: longitude,
        address: address,
        batteryLevel: batteryLevel,
      );
    } catch (_) {}
  }
}
