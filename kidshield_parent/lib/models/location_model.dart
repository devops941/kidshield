class LocationModel {
  final String childId;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final double accuracy;
  final double speed;
  final bool isOffline;
  final int batteryAtLocation;

  LocationModel({
    required this.childId,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    this.accuracy = 5.0,
    this.speed = 0.0,
    this.isOffline = false,
    this.batteryAtLocation = 100,
  });

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'speed': speed,
      'isOffline': isOffline,
      'batteryAtLocation': batteryAtLocation,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      childId: map['childId'] ?? '',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
      address: map['address'] ?? 'Unknown location',
      timestamp: map['timestamp'] != null
          ? (DateTime.tryParse(map['timestamp'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      accuracy: (map['accuracy'] is num) ? (map['accuracy'] as num).toDouble() : 5.0,
      speed: (map['speed'] is num) ? (map['speed'] as num).toDouble() : 0.0,
      isOffline: map['isOffline'] ?? false,
      batteryAtLocation: map['batteryAtLocation'] ?? 100,
    );
  }
}

