import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile_model.dart';
import 'api_service.dart';

class PairingService {
  final ApiService _api = ApiService();

  static const String _keyIsPaired = 'is_paired';
  static const String _keyChildProfile = 'saved_child_profile';
  static const String _keyChildId = 'saved_child_id';
  static const String _keyDeviceToken = 'child_device_token';

  static ChildProfileModel? _activeProfile;
  static bool _isPaired = false;

  bool get isDevicePaired => _isPaired && _activeProfile != null;
  ChildProfileModel? get currentProfile => _activeProfile;

  static bool get staticIsPaired => _isPaired && _activeProfile != null;
  static ChildProfileModel? get staticProfile => _activeProfile;

  /// Loads saved pairing session from local device storage upon app startup
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPaired = prefs.getBool(_keyIsPaired) ?? false;
      final profileStr = prefs.getString(_keyChildProfile);
      final savedId = prefs.getString(_keyChildId);

      if (_isPaired && profileStr != null && profileStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(profileStr);
        final id = savedId ?? map['_id'] ?? map['id'] ?? '';
        _activeProfile = ChildProfileModel.fromMap(map, id);
      } else {
        _isPaired = false;
        _activeProfile = null;
      }
    } catch (_) {
      _isPaired = false;
      _activeProfile = null;
    }
  }

  Future<ChildProfileModel?> pairWithCode(String code) async {
    final cleanCode = code.trim().toUpperCase();

    String realDeviceName = 'Android Device';
    try {
      final name = await const MethodChannel('com.kidshield.child/apps').invokeMethod<String>('getDeviceModel');
      if (name != null && name.trim().isNotEmpty) {
        realDeviceName = name.trim();
      }
    } catch (_) {}

    final res = await _api.pairDevice(
      pairingCode: cleanCode,
      deviceName: realDeviceName,
    );

    if (res['success'] == true && res['child'] != null) {
      final c = res['child'] as Map<String, dynamic>;
      final id = (c['_id'] ?? c['id'] ?? '').toString();
      final token = res['deviceToken']?.toString();
      _isPaired = true;
      _activeProfile = ChildProfileModel.fromMap(c, id);

      // Persist to SharedPreferences so it survives app restarts & phone reboots
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsPaired, true);
        await prefs.setString(_keyChildProfile, jsonEncode(c));
        await prefs.setString(_keyChildId, id);
        if (token != null && token.isNotEmpty) {
          await prefs.setString(_keyDeviceToken, token);
        }
      } catch (_) {}

      return _activeProfile;
    }

    final errorMsg = res['message'] ?? 'Invalid pairing code. Device not found.';
    throw Exception(errorMsg);
  }

  Future<void> unpair() async {
    _isPaired = false;
    _activeProfile = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsPaired);
      await prefs.remove(_keyChildProfile);
      await prefs.remove(_keyChildId);
      await prefs.remove(_keyDeviceToken);
    } catch (_) {}
  }
}
