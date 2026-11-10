import 'package:flutter/services.dart';
import 'api_service.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static const MethodChannel _channel = MethodChannel('com.kidshield.child/permissions');
  final ApiService _api = ApiService();

  /// Check actual system status of all required permissions
  Future<Map<String, bool>> checkAllPermissions() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('checkAllPermissions');
      if (res != null) {
        return {
          'location': (res['location'] as bool?) ?? false,
          'backgroundLocation': (res['backgroundLocation'] as bool?) ?? false,
          'usage': (res['usage'] as bool?) ?? false,
          'notification': (res['notification'] as bool?) ?? false,
          'batteryOptimization': (res['batteryOptimization'] as bool?) ?? false,
        };
      }
    } catch (_) {}
    return {
      'location': false,
      'backgroundLocation': false,
      'usage': false,
      'notification': false,
      'batteryOptimization': false,
    };
  }

  /// Triggers Android OS Location Permission Dialog (Fine/Coarse/Background)
  Future<bool> requestLocationPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestLocationPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Launches Android System "Usage Access" Settings screen
  Future<bool> requestUsagePermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestUsagePermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Triggers Android 13+ Notification Prompt or opens App Notification Settings
  Future<bool> requestNotificationPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests exemption from Android Battery Optimizations (Keep-alive)
  Future<bool> requestBatteryOptimization() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestBatteryOptimization');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the app's application details page in Android Settings
  Future<bool> openAppSettings() async {
    try {
      final res = await _channel.invokeMethod<bool>('openAppSettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Syncs real device permission flags to MongoDB backend
  Future<bool> syncPermissionsWithBackend(String childId) async {
    if (childId.isEmpty) return false;
    try {
      final perms = await checkAllPermissions();
      return await _api.updateChildPermissions(
        childId: childId,
        locationPermissionEnabled: perms['location'] ?? false,
        usagePermissionEnabled: perms['usage'] ?? false,
        notificationPermissionEnabled: perms['notification'] ?? false,
      );
    } catch (_) {
      return false;
    }
  }
}

