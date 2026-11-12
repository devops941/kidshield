import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static String _customBaseUrl = '';
  static void setBaseUrl(String url) => _customBaseUrl = url;

  // Production Render Cloud Backend API
  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;
    return 'https://kidshield-1jvi.onrender.com/api';
  }

  String? _jwtToken;

  void setToken(String token) {
    _jwtToken = token;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_jwtToken != null) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

  // 1. AUTH
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? fcmToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'fcmToken': fcmToken,
        }),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['token'] != null) {
        setToken(data['token']);
      }
      return data;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Connection timed out. Please check your network and backend server.'
        };
      }
      return {
        'success': false,
        'message': 'Cannot reach backend server ($baseUrl). Please check Wi-Fi connection.'
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'fcmToken': fcmToken,
        }),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        setToken(data['token']);
      }
      return data;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Connection timed out. Please check your network and backend server.'
        };
      }
      return {
        'success': false,
        'message': 'Cannot reach backend server ($baseUrl). Please check Wi-Fi connection.'
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: _headers,
        body: jsonEncode({'email': email.trim()}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyResetOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-otp'),
        headers: _headers,
        body: jsonEncode({'email': email.trim(), 'otp': otp.trim()}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        setToken(data['token']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 2. CHILDREN
  Future<List<dynamic>> getChildren() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/children'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      return data['children'] ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addChild({
    required String name,
    required int age,
    String gender = 'boy',
    String? phoneNumber,
    int dailyLimitMinutes = 180,
    String bedtimeStart = '21:30',
    String bedtimeEnd = '06:30',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/children'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'age': age,
          'gender': gender,
          if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
          'dailyScreenTimeLimitMinutes': dailyLimitMinutes,
          'bedtimeStart': bedtimeStart,
          'bedtimeEnd': bedtimeEnd,
        }),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Connection timed out while adding child. Please check network.'
        };
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateChild(
    String childId, {
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    int? dailyLimitMinutes,
    String? bedtimeStart,
    String? bedtimeEnd,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (age != null) body['age'] = age;
      if (gender != null) body['gender'] = gender;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (dailyLimitMinutes != null) body['dailyScreenTimeLimitMinutes'] = dailyLimitMinutes;
      if (bedtimeStart != null) body['bedtimeStart'] = bedtimeStart;
      if (bedtimeEnd != null) body['bedtimeEnd'] = bedtimeEnd;

      final response = await http.put(
        Uri.parse('$baseUrl/children/$childId'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> removeChild(String childId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/children/$childId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> regeneratePairingCode(String childId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/children/$childId/regenerate-code'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> unpairDevice(String childId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/children/$childId/unpair'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 3. LOCATIONS
  Future<Map<String, dynamic>?> getLatestLocation(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/$childId/latest'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['location'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getLocationHistory(String childId, {int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/$childId/history?limit=$limit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['history'] as List?;
        if (list != null) {
          return list.map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendLocation({
    required String childId,
    required double latitude,
    required double longitude,
    required String address,
    int batteryLevel = 85,
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
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // 4. APP USAGE
  Future<Map<String, dynamic>> getAppUsage(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/app-usage/$childId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (_) {
      return {};
    }
  }

  Future<List<dynamic>> getDailyActivityHistory(String childId, {int limit = 14}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/app-usage/$childId/daily-history?limit=$limit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      return data['records'] ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getInstalledApps(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/app-usage/installed/$childId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      return data['apps'] ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> syncAppUsage({
    required String childId,
    required List<Map<String, dynamic>> usageData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app-usage/sync'),
        headers: _headers,
        body: jsonEncode({
          'childId': childId,
          'usageData': usageData,
        }),
      ).timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

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

  Future<void> toggleAppBlock(String childId, String packageName, bool isBlocked) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/app-usage/installed/$childId/block'),
        headers: _headers,
        body: jsonEncode({'packageName': packageName, 'isBlocked': isBlocked}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<bool> approveApp(String childId, String packageName) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/app-usage/installed/$childId/approve'),
        headers: _headers,
        body: jsonEncode({'packageName': packageName}),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectApp(String childId, String packageName) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/app-usage/installed/$childId/reject'),
        headers: _headers,
        body: jsonEncode({'packageName': packageName}),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 5. RESTRICTIONS
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

  Future<void> updateRestrictions(String childId, Map<String, dynamic> restrictions) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/restrictions/$childId'),
        headers: _headers,
        body: jsonEncode(restrictions),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  // 6. NOTIFICATIONS
  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      return data['notifications'] ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }
}
