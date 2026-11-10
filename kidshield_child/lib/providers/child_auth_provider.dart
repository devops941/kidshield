import 'package:flutter/material.dart';
import '../models/child_profile_model.dart';
import '../services/pairing_service.dart';

class ChildAuthProvider extends ChangeNotifier {
  final PairingService _pairingService = PairingService();

  ChildProfileModel? _currentProfile;
  bool _isPaired = false;
  bool _isLoading = false;
  String? _errorMessage;

  ChildProfileModel? get currentProfile => _currentProfile;
  bool get isPaired => _isPaired;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ChildAuthProvider() {
    _init();
  }

  void _init() {
    _isPaired = _pairingService.isDevicePaired;
    _currentProfile = _pairingService.currentProfile;
  }

  Future<bool> pairWithCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _pairingService.pairWithCode(code);
      if (profile != null) {
        _currentProfile = profile;
        _isPaired = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid pairing code or device not found.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> unpair() async {
    await _pairingService.unpair();
    _isPaired = false;
    _currentProfile = null;
    notifyListeners();
  }
}

