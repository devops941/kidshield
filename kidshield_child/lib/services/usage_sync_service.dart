import 'dart:async';
import 'package:flutter/services.dart';
import 'api_service.dart';

class UsageSyncService {
  static final UsageSyncService _instance = UsageSyncService._internal();
  factory UsageSyncService() => _instance;
  UsageSyncService._internal();

  static const MethodChannel _appsChannel = MethodChannel('com.kidshield.child/apps');
  final ApiService _api = ApiService();

  int _screenTimeMinutesToday = 0;
  int _screenTimeMinutesWeekly = 0;
  int _screenTimeMinutesMonthly = 0;
  String _date = '';
  String _timezone = 'Asia/Kolkata';

  List<Map<String, dynamic>> _todayApps = [];
  List<Map<String, dynamic>> _weeklyApps = [];
  List<Map<String, dynamic>> _monthlyApps = [];

  int get screenTimeMinutesToday => _screenTimeMinutesToday;
  int get screenTimeMinutesWeekly => _screenTimeMinutesWeekly;
  int get screenTimeMinutesMonthly => _screenTimeMinutesMonthly;
  String get date => _date;
  String get timezone => _timezone;

  List<Map<String, dynamic>> get todayApps => _todayApps;
  List<Map<String, dynamic>> get weeklyApps => _weeklyApps;
  List<Map<String, dynamic>> get monthlyApps => _monthlyApps;

  Future<bool> checkPermission() async {
    try {
      final res = await _appsChannel.invokeMethod<bool>('checkUsagePermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _appsChannel.invokeMethod('requestUsagePermission');
    } catch (_) {}
  }

  /// Queries Android UsageStatsManager directly and updates local cache
  Future<Map<String, dynamic>?> fetchRealAppUsageReport() async {
    try {
      final usageRes = await _appsChannel.invokeMethod<Map<dynamic, dynamic>>('getRealAppUsage');
      if (usageRes != null) {
        _screenTimeMinutesToday = (usageRes['totalMinutesToday'] as int?) ?? 0;
        _screenTimeMinutesWeekly = (usageRes['totalMinutesWeekly'] as int?) ?? 0;
        _screenTimeMinutesMonthly = (usageRes['totalMinutesMonthly'] as int?) ?? 0;
        _date = usageRes['date']?.toString() ?? '';
        _timezone = usageRes['timezone']?.toString() ?? 'Asia/Kolkata';

        _todayApps = (usageRes['todayApps'] as List?)?.cast<Map<dynamic, dynamic>>().map((item) => {
          'packageName': item['packageName']?.toString() ?? '',
          'appName': item['appName']?.toString() ?? '',
          'category': item['category']?.toString() ?? 'General',
          'icon': item['icon']?.toString() ?? '',
          'usageMinutesToday': item['usageMinutesToday'] as int? ?? 0,
          'usageMinutesWeekly': item['usageMinutesWeekly'] as int? ?? 0,
          'usageMinutesMonthly': item['usageMinutesMonthly'] as int? ?? 0,
        }).toList() ?? [];

        _weeklyApps = (usageRes['weeklyApps'] as List?)?.cast<Map<dynamic, dynamic>>().map((item) => {
          'packageName': item['packageName']?.toString() ?? '',
          'appName': item['appName']?.toString() ?? '',
          'category': item['category']?.toString() ?? 'General',
          'icon': item['icon']?.toString() ?? '',
          'usageMinutesToday': item['usageMinutesToday'] as int? ?? 0,
          'usageMinutesWeekly': item['usageMinutesWeekly'] as int? ?? 0,
          'usageMinutesMonthly': item['usageMinutesMonthly'] as int? ?? 0,
        }).toList() ?? [];

        _monthlyApps = (usageRes['monthlyApps'] as List?)?.cast<Map<dynamic, dynamic>>().map((item) => {
          'packageName': item['packageName']?.toString() ?? '',
          'appName': item['appName']?.toString() ?? '',
          'category': item['category']?.toString() ?? 'General',
          'icon': item['icon']?.toString() ?? '',
          'usageMinutesToday': item['usageMinutesToday'] as int? ?? 0,
          'usageMinutesWeekly': item['usageMinutesWeekly'] as int? ?? 0,
          'usageMinutesMonthly': item['usageMinutesMonthly'] as int? ?? 0,
        }).toList() ?? [];

        return {
          'totalMinutesToday': _screenTimeMinutesToday,
          'totalMinutesWeekly': _screenTimeMinutesWeekly,
          'totalMinutesMonthly': _screenTimeMinutesMonthly,
          'todayApps': _todayApps,
          'weeklyApps': _weeklyApps,
          'monthlyApps': _monthlyApps,
        };
      }
    } catch (_) {}
    return null;
  }

  Future<void> syncUsageToParent(String childId) async {
    if (childId.isEmpty) return;

    try {
      // 1. Fetch real installed apps with icons from device package manager
      final apps = await _appsChannel.invokeListMethod<Map<dynamic, dynamic>>('getInstalledApps');
      if (apps != null && apps.isNotEmpty) {
        final formattedApps = apps.map((a) => {
          'packageName': a['packageName']?.toString() ?? '',
          'appName': a['appName']?.toString() ?? '',
          'versionName': a['versionName']?.toString() ?? '1.0',
          'icon': a['icon']?.toString() ?? '',
        }).toList();

        await _api.syncInstalledApps(
          childId: childId,
          apps: formattedApps,
        );
      }

      // 2. Fetch real app usage stats and foreground screen time across today, week, and month
      await fetchRealAppUsageReport();

      if (_todayApps.isNotEmpty || _weeklyApps.isNotEmpty || _monthlyApps.isNotEmpty) {
        // Collect combined unique list of apps to sync to parent backend
        final combinedMap = <String, Map<String, dynamic>>{};
        for (final app in [..._monthlyApps, ..._weeklyApps, ..._todayApps]) {
          final pkg = app['packageName'] as String;
          combinedMap[pkg] = app;
        }

        await _api.syncAppUsage(
          childId: childId,
          usageData: combinedMap.values.toList(),
          date: _date.isNotEmpty ? _date : null,
          timezone: _timezone,
          totalMinutesToday: _screenTimeMinutesToday,
        );
      }
    } catch (_) {}
  }
}
