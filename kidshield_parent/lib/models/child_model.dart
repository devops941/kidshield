class ChildModel {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String? photoUrl;
  final String pairingCode;
  final bool isPaired;
  final bool isOnline;
  final int batteryLevel;
  final bool isCharging;
  final DateTime lastActive;
  final bool locationPermissionEnabled;
  final bool usagePermissionEnabled;
  final String? deviceName;
  final int dailyScreenTimeLimitMinutes;
  final String? bedtimeStart;
  final String? bedtimeEnd;
  final String? studyTimeStart;
  final String? studyTimeEnd;
  final bool restrictionsActive;
  final String gender;
  final String phoneNumber;

  bool get isGirl => gender.toLowerCase() == 'girl';

  ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    this.photoUrl,
    this.phoneNumber = '',
    required this.pairingCode,
    this.isPaired = false,
    this.isOnline = false,
    this.batteryLevel = 100,
    this.isCharging = false,
    required this.lastActive,
    this.locationPermissionEnabled = false,
    this.usagePermissionEnabled = false,
    this.deviceName,
    this.dailyScreenTimeLimitMinutes = 180,
    this.bedtimeStart = '21:30',
    this.bedtimeEnd = '06:30',
    this.studyTimeStart = '16:00',
    this.studyTimeEnd = '18:00',
    this.restrictionsActive = true,
    this.gender = 'boy',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'age': age,
      'photoUrl': photoUrl,
      'pairingCode': pairingCode,
      'isPaired': isPaired,
      'isOnline': isOnline,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'lastActive': lastActive.toIso8601String(),
      'locationPermissionEnabled': locationPermissionEnabled,
      'usagePermissionEnabled': usagePermissionEnabled,
      'deviceName': deviceName,
      'dailyScreenTimeLimitMinutes': dailyScreenTimeLimitMinutes,
      'bedtimeStart': bedtimeStart,
      'bedtimeEnd': bedtimeEnd,
      'studyTimeStart': studyTimeStart,
      'studyTimeEnd': studyTimeEnd,
      'restrictionsActive': restrictionsActive,
      'gender': gender,
      'phoneNumber': phoneNumber,
    };
  }

  static String guessGender(String name) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) return 'boy';
    final girlIndicators = [
      'josvika', 'ananya', 'diya', 'pooja', 'priya', 'kavya', 'sneha', 'riya',
      'divya', 'meera', 'isha', 'aadhya', 'swetha', 'deepa', 'lakshmi', 'nisha',
      'shree', 'sri', 'ammu', 'paapa', 'girl', 'dhiya', 'keerthi', 'harini',
      'nithya', 'pavithra', 'sandhya', 'varsha', 'meena', 'rani', 'devi'
    ];
    for (final g in girlIndicators) {
      if (lower.contains(g)) return 'girl';
    }
    if (lower.endsWith('ka') || lower.endsWith('itha') || lower.endsWith('shree') || lower.endsWith('priya')) {
      return 'girl';
    }
    return 'boy';
  }

  factory ChildModel.fromMap(Map<String, dynamic> map, String id) {
    final parsedName = (map['name'] ?? '').toString();
    final rawGender = (map['gender'] ?? '').toString().toLowerCase().trim();
    final resolvedGender = rawGender.isNotEmpty
        ? (rawGender == 'girl' ? 'girl' : 'boy')
        : guessGender(parsedName);

    return ChildModel(
      id: id.isNotEmpty ? id : (map['_id'] ?? map['id'] ?? '').toString(),
      parentId: (map['parentId'] ?? '').toString(),
      name: parsedName,
      age: map['age'] is int ? map['age'] as int : int.tryParse(map['age']?.toString() ?? '10') ?? 10,
      photoUrl: map['photoUrl']?.toString(),
      pairingCode: (map['pairingCode'] ?? '').toString(),
      isPaired: map['isPaired'] == true,
      isOnline: map['isOnline'] == true,
      batteryLevel: map['batteryLevel'] is int
          ? map['batteryLevel'] as int
          : int.tryParse(map['batteryLevel']?.toString() ?? '100') ?? 100,
      isCharging: map['isCharging'] == true,
      lastActive: map['lastActive'] != null
          ? (DateTime.tryParse(map['lastActive'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      locationPermissionEnabled: map['locationPermissionEnabled'] == true,
      usagePermissionEnabled: map['usagePermissionEnabled'] == true,
      deviceName: map['deviceName']?.toString(),
      dailyScreenTimeLimitMinutes: map['dailyScreenTimeLimitMinutes'] is int
          ? map['dailyScreenTimeLimitMinutes'] as int
          : int.tryParse(map['dailyScreenTimeLimitMinutes']?.toString() ?? '180') ?? 180,
      bedtimeStart: map['bedtimeStart']?.toString() ?? '21:30',
      bedtimeEnd: map['bedtimeEnd']?.toString() ?? '06:30',
      studyTimeStart: map['studyTimeStart']?.toString() ?? '16:00',
      studyTimeEnd: map['studyTimeEnd']?.toString() ?? '18:00',
      restrictionsActive: map['restrictionsActive'] ?? true,
      gender: resolvedGender,
      phoneNumber: (map['phoneNumber'] ?? '').toString(),
    );
  }

  ChildModel copyWith({
    String? name,
    int? age,
    String? photoUrl,
    String? phoneNumber,
    String? pairingCode,
    bool? isPaired,
    bool? isOnline,
    int? batteryLevel,
    bool? isCharging,
    DateTime? lastActive,
    bool? locationPermissionEnabled,
    bool? usagePermissionEnabled,
    String? deviceName,
    int? dailyScreenTimeLimitMinutes,
    String? bedtimeStart,
    String? bedtimeEnd,
    String? studyTimeStart,
    String? studyTimeEnd,
    bool? restrictionsActive,
    String? gender,
  }) {
    return ChildModel(
      id: id,
      parentId: parentId,
      name: name ?? this.name,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pairingCode: pairingCode ?? this.pairingCode,
      isPaired: isPaired ?? this.isPaired,
      isOnline: isOnline ?? this.isOnline,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      lastActive: lastActive ?? this.lastActive,
      locationPermissionEnabled: locationPermissionEnabled ?? this.locationPermissionEnabled,
      usagePermissionEnabled: usagePermissionEnabled ?? this.usagePermissionEnabled,
      deviceName: deviceName ?? this.deviceName,
      dailyScreenTimeLimitMinutes: dailyScreenTimeLimitMinutes ?? this.dailyScreenTimeLimitMinutes,
      bedtimeStart: bedtimeStart ?? this.bedtimeStart,
      bedtimeEnd: bedtimeEnd ?? this.bedtimeEnd,
      studyTimeStart: studyTimeStart ?? this.studyTimeStart,
      studyTimeEnd: studyTimeEnd ?? this.studyTimeEnd,
      restrictionsActive: restrictionsActive ?? this.restrictionsActive,
      gender: gender ?? this.gender,
    );
  }
}

