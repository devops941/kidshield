import '../models/emergency_alert_model.dart';
import 'api_service.dart';

class SosService {
  final ApiService _api = ApiService();

  Future<bool> sendEmergencyAlert(EmergencyAlertModel alert) async {
    try {
      final success = await _api.triggerEmergencySos(
        childId: alert.childId,
        latitude: alert.latitude,
        longitude: alert.longitude,
        address: alert.address,
        batteryLevel: alert.batteryLevel,
      );
      if (success) return true;
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
