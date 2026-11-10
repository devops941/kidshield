class EmergencyAlertModel {
  final String childId;
  final String childName;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final int batteryLevel;

  EmergencyAlertModel({
    required this.childId,
    required this.childName,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.batteryLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'childName': childName,
      'type': 'sosEmergency',
      'severity': 'critical',
      'title': '🚨 EMERGENCY SOS TRIGGERED!',
      'message': '$childName has activated the Emergency SOS alert. Immediate attention required!',
      'timestamp': timestamp.toIso8601String(),
      'isRead': false,
      'metadata': {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'batteryLevel': batteryLevel,
      },
    };
  }
}

