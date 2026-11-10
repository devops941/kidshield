import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parent_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  static const String _keyToken = 'jwt_token';
  static const String _keyUser = 'saved_parent_user';

  static ParentModel? _currentParentModel;
  static bool _isLoggedIn = false;

  bool get isAuthenticated => _isLoggedIn && _currentParentModel != null;

  Future<ParentModel?> getCurrentParent() async {
    if (_isLoggedIn && _currentParentModel != null) {
      return _currentParentModel;
    }

    // Attempt restoring saved session from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final userStr = prefs.getString(_keyUser);

      if (token != null && token.isNotEmpty && userStr != null && userStr.isNotEmpty) {
        final Map<String, dynamic> u = jsonDecode(userStr);
        final id = u['uid'] ?? u['id'] ?? u['_id'] ?? '';
        _currentParentModel = ParentModel.fromMap(u, id);
        _isLoggedIn = true;
        _api.setToken(token);
        return _currentParentModel;
      }
    } catch (_) {}

    return null;
  }

  Future<ParentModel> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _api.login(
      email: email.trim(),
      password: password,
    );

    if (res['success'] == true && res['user'] != null) {
      final u = res['user'];
      final token = res['token'] ?? '';
      final uid = (u['id'] ?? u['_id'] ?? 'parent_1').toString();

      _currentParentModel = ParentModel(
        uid: uid,
        email: u['email'] ?? email.trim(),
        fullName: u['fullName'] ?? 'Parent',
        phoneNumber: u['phoneNumber'],
        createdAt: u['createdAt'] != null
            ? DateTime.tryParse(u['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
      _isLoggedIn = true;
      _api.setToken(token);

      // Persist to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, token);
        await prefs.setString(_keyUser, jsonEncode(_currentParentModel!.toMap()));
      } catch (_) {}

      return _currentParentModel!;
    }

    final errorMsg = res['message'] ?? 'Invalid email or password';
    throw Exception(errorMsg);
  }

  Future<ParentModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    final res = await _api.register(
      fullName: fullName.trim(),
      email: email.trim(),
      password: password,
      phoneNumber: phoneNumber?.trim(),
    );

    if (res['success'] == true && res['user'] != null) {
      final u = res['user'];
      final token = res['token'] ?? '';
      final uid = (u['id'] ?? u['_id'] ?? 'parent_new').toString();

      _currentParentModel = ParentModel(
        uid: uid,
        email: u['email'] ?? email.trim(),
        fullName: u['fullName'] ?? fullName.trim(),
        phoneNumber: u['phoneNumber'] ?? phoneNumber?.trim(),
        createdAt: u['createdAt'] != null
            ? DateTime.tryParse(u['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
      _isLoggedIn = true;
      _api.setToken(token);

      // Persist to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, token);
        await prefs.setString(_keyUser, jsonEncode(_currentParentModel!.toMap()));
      } catch (_) {}

      return _currentParentModel!;
    }

    final errorMsg = res['message'] ?? 'Registration failed. Please try again.';
    throw Exception(errorMsg);
  }

  Future<String> sendPasswordReset(String email) async {
    final res = await _api.forgotPassword(email);
    if (res['success'] == true) {
      return res['message'] ?? 'Password reset code sent to your email';
    }
    final errorMsg = res['message'] ?? 'Failed to send password reset code';
    throw Exception(errorMsg);
  }

  Future<bool> verifyResetOtp(String email, String otp) async {
    final res = await _api.verifyResetOtp(email, otp);
    if (res['success'] == true) {
      return true;
    }
    final errorMsg = res['message'] ?? 'Invalid or expired verification code';
    throw Exception(errorMsg);
  }

  Future<ParentModel> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await _api.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );

    if (res['success'] == true && res['user'] != null) {
      final u = res['user'];
      final token = res['token'] ?? '';
      final uid = (u['id'] ?? u['_id'] ?? 'parent_1').toString();

      _currentParentModel = ParentModel(
        uid: uid,
        email: u['email'] ?? email.trim(),
        fullName: u['fullName'] ?? 'Parent',
        phoneNumber: u['phoneNumber'],
        createdAt: u['createdAt'] != null
            ? DateTime.tryParse(u['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
      _isLoggedIn = true;
      _api.setToken(token);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, token);
        await prefs.setString(_keyUser, jsonEncode(_currentParentModel!.toMap()));
      } catch (_) {}

      return _currentParentModel!;
    }

    final errorMsg = res['message'] ?? 'Password reset failed';
    throw Exception(errorMsg);
  }

  Future<void> signOut() async {
    _isLoggedIn = false;
    _currentParentModel = null;
    _api.setToken('');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (_) {}
  }
}
