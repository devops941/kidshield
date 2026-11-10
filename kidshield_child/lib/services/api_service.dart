import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static String _customBaseUrl = '';
  static void setBaseUrl(String url) => _customBaseUrl = url;

  // For Android real phone on same Wi-Fi, use PC IP 192.168.1.9. For Web/Chrome use localhost.
  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.9:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // 1. PAIR DEVICE
  Future<Map<String, dynamic>> pairDevice({
    required String pairingCode,
    String? deviceName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/children/pair'),
        headers: _headers,
        body: jsonEncode({
          'pairingCode': pairingCode.trim().toUpperCase(),
          'deviceName': deviceName ?? 'Android Device',
        }),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Connection timed out. Check Wi-Fi and server.'
        };
      }
      return {'success': false, 'message': 'Cannot reach backend server ($baseUrl)'};
    }
  }

  // 2. SEND LIVE GPS LOCATION
  Future<bool> sendLocation({
    required String childId,
    required double latitude,
    required double longitude,
    required String address,
    required int batteryLevel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/locations'),
        headers: _headers,
        body: jsonEncode({
          'childId': childId,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'batteryLevel': batteryLevel,
        }),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 3. TRIGGER EMERGENCY SOS
  Future<bool> triggerEmergencySos({
    required String childId,
    required double latitude,
    required double longitude,
    required String address,
    required int batteryLevel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sos/trigger'),
        headers: _headers,
        body: jsonEncode({
          'childId': childId,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'batteryLevel': batteryLevel,
        }),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // 4. SYNC APP USAGE
  Future<bool> syncAppUsage({
    required String childId,
    required List<Map<String, dynamic>> usageData,
    String? date,
    String? timezone,
    int? totalMinutesToday,
  }) async {
    try {
      final body = <String, dynamic>{
        'childId': childId,
        'usageData': usageData,
      };
      if (date != null && date.isNotEmpty) body['date'] = date;
      if (timezone != null && timezone.isNotEmpty) body['timezone'] = timezone;
      if (totalMinutesToday != null) body['totalMinutesToday'] = totalMinutesToday;

      final response = await http.post(
        Uri.parse('$baseUrl/app-usage/sync'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // 5. SYNC INSTALLED APPS
  Future<bool> syncInstalledApps({
    required String childId,
    required List<Map<String, dynamic>> apps,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app-usage/installed/sync'),
        headers: _headers,
        body: jsonEncode({
          'childId': childId,
          'apps': apps,
        }),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 6. GET RESTRICTIONS
  Future<Map<String, dynamic>?> getRestrictions(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restrictions/$childId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['restrictions'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // 7. SYNC CHILD PERMISSION STATUS
  Future<bool> updateChildPermissions({
    required String childId,
    required bool locationPermissionEnabled,
    required bool usagePermissionEnabled,
    required bool notificationPermissionEnabled,
    int? batteryLevel,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/children/$childId/permissions'),
        headers: _headers,
        body: jsonEncode({
          'locationPermissionEnabled': locationPermissionEnabled,
          'usagePermissionEnabled': usagePermissionEnabled,
          'notificationPermissionEnabled': notificationPermissionEnabled,
          if (batteryLevel != null) 'batteryLevel': batteryLevel,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 8. GET NOTICES FOR CHILD
  Future<List<Map<String, dynamic>>> getChildNotifications(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/child/$childId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['notifications'] as List?;
        if (list != null) {
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
