import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/location_model.dart';
import '../models/app_usage_model.dart';
import '../models/app_info_model.dart';
import '../models/restriction_model.dart';
import '../models/notification_model.dart';
import '../services/monitoring_service.dart';

class MonitoringProvider extends ChangeNotifier {
  static const MethodChannel _parentGpsChannel = MethodChannel('com.kidshield.parent/gps');
  static const MethodChannel _parentAppsChannel = MethodChannel('com.kidshield.parent/apps');
  static const MethodChannel _emergencyChannel = MethodChannel('com.kidshield.parent/emergency');
  final MonitoringService _monitoringService = MonitoringService();

  LocationModel? _currentLocation;
  List<LocationModel> _locationHistory = [];
  List<AppUsageModel> _appUsage = [];
  List<AppInfoModel> _installedApps = [];
  RestrictionModel? _restrictions;
  List<NotificationModel> _notifications = [];

  bool _isLoading = false;
  String? _errorMessage;

  LocationModel? get currentLocation => _currentLocation;
  List<LocationModel> get locationHistory => _locationHistory;
  List<AppUsageModel> get appUsage => _appUsage;
  List<AppInfoModel> get installedApps => _installedApps;
  RestrictionModel? get restrictions => _restrictions;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Active Emergency SOS Alert (Unread SOS alert)
  NotificationModel? get activeEmergencyAlert {
    try {
      return _notifications.firstWhere(
        (n) => n.type == NotificationType.sosEmergency && !n.isRead,
      );
    } catch (_) {
      return null;
    }
  }

  bool get hasActiveEmergency => activeEmergencyAlert != null;

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  int? _backendTotalMinutesToday;
  int? _backendTotalMinutesWeekly;
  int? _backendTotalMinutesMonthly;
  List<double> _backendWeeklyBreakdown = [];
  List<double> _backendMonthlyBreakdown = [];

  int get totalScreenTimeMinutesToday {
    if (_backendTotalMinutesToday != null) {
      return _backendTotalMinutesToday!;
    }
    return _appUsage
        .where((a) => !MonitoringService.isExcludedApp(a.packageName, a.appName))
        .fold(0, (sum, item) => sum + item.usageMinutesToday);
  }

  int get totalScreenTimeMinutesWeekly {
    if (_backendTotalMinutesWeekly != null) {
      return _backendTotalMinutesWeekly!;
    }
    return _appUsage
        .where((a) => !MonitoringService.isExcludedApp(a.packageName, a.appName))
        .fold(0, (sum, item) => sum + item.usageMinutesWeekly);
  }

  int get totalScreenTimeMinutesMonthly {
    if (_backendTotalMinutesMonthly != null) {
      return _backendTotalMinutesMonthly!;
    }
    return _appUsage
        .where((a) => !MonitoringService.isExcludedApp(a.packageName, a.appName))
        .fold(0, (sum, item) => sum + item.usageMinutesMonthly);
  }

  List<double> get todayHourlyMinutes {
    final todayMinutes = totalScreenTimeMinutesToday.toDouble();
    if (todayMinutes <= 0) return List<double>.filled(6, 0.0);

    // 6 time blocks: 6 AM, 9 AM, 12 PM, 3 PM, 6 PM, 9 PM
    final currentHour = DateTime.now().hour;
    int elapsedBlocks = 1;
    if (currentHour < 9) {
      elapsedBlocks = 1;
    } else if (currentHour < 12) {
      elapsedBlocks = 2;
    } else if (currentHour < 15) {
      elapsedBlocks = 3;
    } else if (currentHour < 18) {
      elapsedBlocks = 4;
    } else if (currentHour < 21) {
      elapsedBlocks = 5;
    } else {
      elapsedBlocks = 6;
    }

    final result = List<double>.filled(6, 0.0);
    final base = (todayMinutes / elapsedBlocks).roundToDouble();
    double allocated = 0;
    for (int i = 0; i < elapsedBlocks - 1; i++) {
      result[i] = base;
      allocated += base;
    }
    result[elapsedBlocks - 1] = (todayMinutes - allocated).clamp(0.0, 1440.0);
    return result;
  }

  List<double> get weeklyScreenTimeMinutes {
    if (_backendWeeklyBreakdown.isNotEmpty && _backendWeeklyBreakdown.length == 7) {
      return _backendWeeklyBreakdown;
    }
    final todayWeekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final todayMinutes = totalScreenTimeMinutesToday.toDouble();
    final days = List<double>.filled(7, 0.0);
    final todayIndex = (todayWeekday - 1).clamp(0, 6);
    days[todayIndex] = todayMinutes;
    return days;
  }

  List<double> get monthlyWeeksScreenTimeMinutes {
    if (_backendMonthlyBreakdown.isNotEmpty && _backendMonthlyBreakdown.length == 4) {
      return _backendMonthlyBreakdown;
    }
    final result = List<double>.filled(4, 0.0);
    result[3] = totalScreenTimeMinutesWeekly.toDouble();
    return result;
  }

  List<AppUsageModel> get topUsedApps {
    final list = _appUsage
        .where((a) => !MonitoringService.isExcludedApp(a.packageName, a.appName))
        .toList();
    list.sort((a, b) {
      final cmpToday = b.usageMinutesToday.compareTo(a.usageMinutesToday);
      if (cmpToday != 0) return cmpToday;
      return b.usageMinutesWeekly.compareTo(a.usageMinutesWeekly);
    });
    return list.take(4).toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadChildData(String childId, {bool silent = false}) async {
    if (!silent) _setLoading(true);
    _errorMessage = null;
    try {
      final results = await Future.wait([
        _monitoringService.getLatestLocation(childId),
        _monitoringService.getInstalledApps(childId),
        _monitoringService.getRestrictions(childId),
        _monitoringService.getNotifications(childId),
        _monitoringService.getLocationHistory(childId),
        _monitoringService.getAppUsageData(childId),
      ]);

      _currentLocation = results[0] as LocationModel?;
      _installedApps = results[1] as List<AppInfoModel>;
      _restrictions = results[2] as RestrictionModel?;
      _notifications = results[3] as List<NotificationModel>;
      _locationHistory = results[4] as List<LocationModel>;

      final payload = results[5] as Map<String, dynamic>;
      if (payload.isNotEmpty) {
        if (payload['totalMinutesToday'] != null) {
          _backendTotalMinutesToday = (payload['totalMinutesToday'] as num).toInt();
        }
        if (payload['totalMinutesWeekly'] != null) {
          _backendTotalMinutesWeekly = (payload['totalMinutesWeekly'] as num).toInt();
        }
        if (payload['totalMinutesMonthly'] != null) {
          _backendTotalMinutesMonthly = (payload['totalMinutesMonthly'] as num).toInt();
        }
        if (payload['weeklyBreakdown'] != null && payload['weeklyBreakdown']['values'] is List) {
          _backendWeeklyBreakdown = (payload['weeklyBreakdown']['values'] as List)
              .map((v) => (v as num).toDouble())
              .toList();
        }
        if (payload['monthlyBreakdown'] != null && payload['monthlyBreakdown']['values'] is List) {
          _backendMonthlyBreakdown = (payload['monthlyBreakdown']['values'] as List)
              .map((v) => (v as num).toDouble())
              .toList();
        }
        if (payload['usage'] != null && payload['usage'] is List) {
          _appUsage = (payload['usage'] as List)
              .map((item) => AppUsageModel.fromMap(item as Map<String, dynamic>))
              .where((item) => !MonitoringService.isExcludedApp(item.packageName, item.appName))
              .toList();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (!silent) _setLoading(false);
      notifyListeners();
    }
  }

  Future<List<LocationModel>> fetchLocationHistory(String childId, {int limit = 50}) async {
    try {
      final history = await _monitoringService.getLocationHistory(childId, limit: limit);
      _locationHistory = history;
      notifyListeners();
      return history;
    } catch (_) {
      return [];
    }
  }

  Future<LocationModel?> refreshLocationOnly(String childId) async {
    try {
      final loc = await _monitoringService.getLatestLocation(childId);
      if (loc != null) {
        _currentLocation = loc;
        notifyListeners();
        return loc;
      }
    } catch (_) {}
    return null;
  }

  Future<LocationModel?> syncRealDeviceLocation(String childId) async {
    try {
      final result = await _parentGpsChannel.invokeMethod<Map<dynamic, dynamic>>('getRealLocation');
      if (result != null) {
        final lat = result['latitude'] as double?;
        final lng = result['longitude'] as double?;
        final addr = (result['address'] as String?) ?? 'Real GPS Location';
        final acc = (result['accuracy'] as double?) ?? 5.0;

        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          final newLoc = LocationModel(
            childId: childId,
            latitude: lat,
            longitude: lng,
            address: addr,
            accuracy: acc,
            speed: 0,
            batteryAtLocation: 85,
            timestamp: DateTime.now(),
          );

          _currentLocation = newLoc;
          notifyListeners();

          // Also push to backend so server database holds it
          await _monitoringService.sendLocation(
            childId: childId,
            latitude: lat,
            longitude: lng,
            address: addr,
            batteryLevel: 85,
          );

          return newLoc;
        }
      }
    } catch (e) {
      debugPrint('Real GPS error: $e');
    }
    return null;
  }

  Future<void> syncRealDeviceApps(String childId) async {
    try {
      final rawApps = await _parentAppsChannel.invokeListMethod<Map<dynamic, dynamic>>('getInstalledApps');
      if (rawApps != null && rawApps.isNotEmpty) {
        final formattedApps = rawApps.map((a) => {
          'packageName': a['packageName']?.toString() ?? '',
          'appName': a['appName']?.toString() ?? '',
          'versionName': a['versionName']?.toString() ?? '1.0',
          'icon': a['icon']?.toString() ?? '',
        }).toList();

        await _monitoringService.syncInstalledApps(childId: childId, apps: formattedApps);
        final freshApps = await _monitoringService.getInstalledApps(childId, forceRefresh: true);
        if (freshApps.isNotEmpty) {
          _installedApps = freshApps;
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Real Apps sync error: $e');
    }
  }

  Future<void> toggleAppBlock(String childId, String packageName, bool isBlocked) async {
    await _monitoringService.toggleAppBlockStatus(
      childId: childId,
      packageName: packageName,
      isBlocked: isBlocked,
    );
    final index = _installedApps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      _installedApps[index] = _installedApps[index].copyWith(isBlocked: isBlocked);
      notifyListeners();
    }
  }

  Future<void> approveApp(String childId, String packageName) async {
    await _monitoringService.approveAppInstallation(
      childId: childId,
      packageName: packageName,
    );
    final index = _installedApps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      _installedApps[index] = _installedApps[index].copyWith(
        isParentApproved: true,
        isNewlyInstalled: false,
        isBlocked: false,
      );
      notifyListeners();
    }
  }

  Future<void> rejectApp(String childId, String packageName) async {
    await _monitoringService.rejectAppInstallation(
      childId: childId,
      packageName: packageName,
    );
    final index = _installedApps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      _installedApps[index] = _installedApps[index].copyWith(
        isParentApproved: false,
        isNewlyInstalled: false,
        isBlocked: true,
      );
      notifyListeners();
    }
  }

  Future<void> openEmergencyDialer(String number) async {
    try {
      await _emergencyChannel.invokeMethod('openDialer', {'number': number});
    } catch (e) {
      debugPrint('Emergency dialer error: $e');
    }
  }

  Future<void> openEmergencyNavigation(double lat, double lng, String label) async {
    try {
      await _emergencyChannel.invokeMethod('openNavigation', {
        'latitude': lat,
        'longitude': lng,
        'label': label,
      });
    } catch (e) {
      debugPrint('Emergency navigation error: $e');
    }
  }

  Future<void> playEmergencySiren() async {
    try {
      await _emergencyChannel.invokeMethod('playSiren');
      await _emergencyChannel.invokeMethod('vibrateAlert');
    } catch (e) {
      debugPrint('Emergency siren error: $e');
    }
  }

  Future<void> stopEmergencySiren() async {
    try {
      await _emergencyChannel.invokeMethod('stopSiren');
    } catch (e) {
      debugPrint('Emergency stop siren error: $e');
    }
  }

  Future<void> dismissEmergencyAlert(String id) async {
    await stopEmergencySiren();
    await markNotificationAsRead(id);
  }

  Future<void> markNotificationAsRead(String id) async {
    await _monitoringService.markNotificationAsRead(id);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    await _monitoringService.markAllNotificationsAsRead();
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
}

