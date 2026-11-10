import 'package:flutter/material.dart';
import '../models/emergency_alert_model.dart';
import '../services/sos_service.dart';
import '../services/usage_sync_service.dart';

class CompanionProvider extends ChangeNotifier {
  final SosService _sosService = SosService();
  final UsageSyncService _usageService = UsageSyncService();

  // Calculator State
  String _calcDisplay = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  // Safety State
  bool _isSosActive = false;
  bool _isSendingSos = false;

  String get calcDisplay => _calcDisplay;
  bool get isSosActive => _isSosActive;
  bool get isSendingSos => _isSendingSos;

  int get screenTimeMinutesToday => _usageService.screenTimeMinutesToday;
  int get screenTimeMinutesWeekly => _usageService.screenTimeMinutesWeekly;
  int get screenTimeMinutesMonthly => _usageService.screenTimeMinutesMonthly;

  List<Map<String, dynamic>> get todayApps => _usageService.todayApps;
  List<Map<String, dynamic>> get weeklyApps => _usageService.weeklyApps;
  List<Map<String, dynamic>> get monthlyApps => _usageService.monthlyApps;

  Future<void> refreshAppUsage([String? childId]) async {
    await _usageService.fetchRealAppUsageReport();
    notifyListeners();
    if (childId != null && childId.isNotEmpty) {
      await _usageService.syncUsageToParent(childId);
    }
  }

  // Calculator Methods
  void onNumberPress(String number) {
    if (_calcDisplay == '0' || _shouldResetDisplay) {
      _calcDisplay = number;
      _shouldResetDisplay = false;
    } else {
      _calcDisplay += number;
    }
    notifyListeners();
  }

  void onOperatorPress(String op) {
    _firstOperand = double.tryParse(_calcDisplay);
    _operator = op;
    _shouldResetDisplay = true;
    notifyListeners();
  }

  void onCalculate() {
    if (_firstOperand == null || _operator == null) return;
    final secondOperand = double.tryParse(_calcDisplay);
    if (secondOperand == null) return;

    double result = 0;
    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        result = secondOperand != 0 ? _firstOperand! / secondOperand : 0;
        break;
    }

    _calcDisplay = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(2);
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = true;
    notifyListeners();
  }

  void onClear() {
    _calcDisplay = '0';
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = false;
    notifyListeners();
  }

  // Emergency SOS Trigger
  Future<bool> triggerEmergencySos({
    required String childId,
    required String childName,
    required double latitude,
    required double longitude,
    required String address,
    required int batteryLevel,
  }) async {
    _isSendingSos = true;
    notifyListeners();

    final alert = EmergencyAlertModel(
      childId: childId,
      childName: childName,
      latitude: latitude,
      longitude: longitude,
      address: address,
      timestamp: DateTime.now(),
      batteryLevel: batteryLevel,
    );

    final success = await _sosService.sendEmergencyAlert(alert);
    _isSendingSos = false;
    _isSosActive = true;
    notifyListeners();
    return success;
  }

  void dismissSos() {
    _isSosActive = false;
    notifyListeners();
  }
}

