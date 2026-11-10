enum NotificationType {
  appInstalled,
  screenTimeLimit,
  locationDisabled,
  deviceOffline,
  lowBattery,
  deviceDisconnected,
  sosEmergency,
  settingsChanged,
  general,
}

enum NotificationSeverity {
  info,
  warning,
  critical,
}

class NotificationModel {
  final String id;
  final String childId;
  final String childName;
  final NotificationType type;
  final NotificationSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'childName': childName,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      childId: map['childId'] ?? '',
      childName: map['childName'] ?? 'Child',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      severity: NotificationSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => NotificationSeverity.info,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? (DateTime.tryParse(map['timestamp'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      metadata: map['metadata'],
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      childId: childId,
      childName: childName,
      type: type,
      severity: severity,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata,
    );
  }
}

