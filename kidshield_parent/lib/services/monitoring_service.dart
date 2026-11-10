import '../models/location_model.dart';
import '../models/app_usage_model.dart';
import '../models/app_info_model.dart';
import '../models/restriction_model.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class MonitoringService {
  final ApiService _api = ApiService();

  final Map<String, List<AppInfoModel>> _cachedApps = {};
  final Map<String, RestrictionModel> _cachedRestrictions = {};
  final List<NotificationModel> _cachedNotifications = [];

  MonitoringService();

  Future<LocationModel?> getLatestLocation(String childId) async {
    try {
      final loc = await _api.getLatestLocation(childId);
      if (loc != null) {
        return LocationModel.fromMap(loc);
      }
    } catch (_) {}
    return null;
  }

  Future<List<LocationModel>> getLocationHistory(String childId, {int limit = 50}) async {
    try {
      final list = await _api.getLocationHistory(childId, limit: limit);
      return list.map((item) => LocationModel.fromMap(item)).toList();
    } catch (_) {}
    return [];
  }

  Future<bool> sendLocation({
    required String childId,
    required double latitude,
    required double longitude,
    required String address,
    int batteryLevel = 85,
  }) async {
    return _api.sendLocation(
      childId: childId,
      latitude: latitude,
      longitude: longitude,
      address: address,
      batteryLevel: batteryLevel,
    );
  }

  static bool isExcludedApp(String packageName, String appName) {
    if (packageName.isEmpty) return true;
    final p = packageName.toLowerCase();
    final n = appName.toLowerCase();
    return p.contains('launcher') ||
        p.contains('systemui') ||
        p.contains('honeyboard') ||
        p.contains('inputmethod') ||
        p.contains('kidshield') ||
        n.contains('one ui home') ||
        n.contains('launcher') ||
        n.contains('system ui');
  }

  Future<Map<String, dynamic>> getAppUsageData(String childId) async {
    try {
      return await _api.getAppUsage(childId);
    } catch (_) {
      return {};
    }
  }

  Future<List<AppUsageModel>> getAppUsage(String childId) async {
    try {
      final res = await _api.getAppUsage(childId);
      if (res['usage'] != null && (res['usage'] as List).isNotEmpty) {
        return (res['usage'] as List)
            .map((item) => AppUsageModel.fromMap(item as Map<String, dynamic>))
            .where((item) => !isExcludedApp(item.packageName, item.appName))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> syncInstalledApps({
    required String childId,
    required List<Map<String, dynamic>> apps,
  }) async {
    _cachedApps.remove(childId);
    return _api.syncInstalledApps(childId: childId, apps: apps);
  }

  Future<bool> syncAppUsage({
    required String childId,
    required List<Map<String, dynamic>> usageData,
  }) async {
    return _api.syncAppUsage(childId: childId, usageData: usageData);
  }

  Future<List<AppInfoModel>> getInstalledApps(String childId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedApps.containsKey(childId) && _cachedApps[childId]!.isNotEmpty) {
      return _cachedApps[childId]!;
    }
    try {
      final list = await _api.getInstalledApps(childId);
      if (list.isNotEmpty) {
        final apps = list
            .map((item) => AppInfoModel.fromMap(item as Map<String, dynamic>))
            .toList();
        _cachedApps[childId] = apps;
        return apps;
      }
    } catch (_) {}
    return [];
  }

  Future<void> toggleAppBlockStatus({
    required String childId,
    required String packageName,
    required bool isBlocked,
  }) async {
    try {
      await _api.toggleAppBlock(childId, packageName, isBlocked);
    } catch (_) {}

    if (_cachedApps.containsKey(childId)) {
      final index = _cachedApps[childId]!.indexWhere((a) => a.packageName == packageName);
      if (index != -1) {
        _cachedApps[childId]![index] =
            _cachedApps[childId]![index].copyWith(isBlocked: isBlocked);
      }
    }
  }

  Future<bool> approveAppInstallation({
    required String childId,
    required String packageName,
  }) async {
    final success = await _api.approveApp(childId, packageName);
    if (_cachedApps.containsKey(childId)) {
      final index = _cachedApps[childId]!.indexWhere((a) => a.packageName == packageName);
      if (index != -1) {
        _cachedApps[childId]![index] = _cachedApps[childId]![index].copyWith(
          isParentApproved: true,
          isNewlyInstalled: false,
          isBlocked: false,
        );
      }
    }
    return success;
  }

  Future<bool> rejectAppInstallation({
    required String childId,
    required String packageName,
  }) async {
    final success = await _api.rejectApp(childId, packageName);
    if (_cachedApps.containsKey(childId)) {
      final index = _cachedApps[childId]!.indexWhere((a) => a.packageName == packageName);
      if (index != -1) {
        _cachedApps[childId]![index] = _cachedApps[childId]![index].copyWith(
          isParentApproved: false,
          isNewlyInstalled: false,
          isBlocked: true,
        );
      }
    }
    return success;
  }

  Future<RestrictionModel> getRestrictions(String childId) async {
    if (_cachedRestrictions.containsKey(childId)) {
      return _cachedRestrictions[childId]!;
    }
    try {
      final res = await _api.getRestrictions(childId);
      if (res != null) {
        final model = RestrictionModel.fromMap(res);
        _cachedRestrictions[childId] = model;
        return model;
      }
    } catch (_) {}

    final defaultModel = RestrictionModel();
    _cachedRestrictions[childId] = defaultModel;
    return defaultModel;
  }

  Future<List<NotificationModel>> getNotifications(String childId) async {
    try {
      final list = await _api.getNotifications();
      if (list.isNotEmpty) {
        return list.map((item) {
          final id = item['_id'] ?? item['id'] ?? 'notif_1';
          return NotificationModel.fromMap(item as Map<String, dynamic>, id);
        }).toList();
      }
    } catch (_) {}
    return List.from(_cachedNotifications);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _api.markNotificationAsRead(notificationId);
    } catch (_) {}
    final index = _cachedNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _cachedNotifications[index] = _cachedNotifications[index].copyWith(isRead: true);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _api.markAllNotificationsRead();
    } catch (_) {}
    for (int i = 0; i < _cachedNotifications.length; i++) {
      _cachedNotifications[i] = _cachedNotifications[i].copyWith(isRead: true);
    }
  }
}
