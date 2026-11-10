class ChildProfileModel {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String pairingCode;
  final bool isPaired;
  final int batteryLevel;
  final bool isCharging;
  final bool locationPermissionEnabled;
  final bool usagePermissionEnabled;
  final int dailyScreenTimeLimitMinutes;
  final String bedtimeStart;
  final String bedtimeEnd;
  final String studyTimeStart;
  final String studyTimeEnd;
  final bool restrictionsActive;
  final String gender;

  bool get isGirl => gender.toLowerCase() == 'girl';

  ChildProfileModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    required this.pairingCode,
    this.isPaired = true,
    this.batteryLevel = 90,
    this.isCharging = false,
    this.locationPermissionEnabled = true,
    this.usagePermissionEnabled = true,
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
      'pairingCode': pairingCode,
      'isPaired': isPaired,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'locationPermissionEnabled': locationPermissionEnabled,
      'usagePermissionEnabled': usagePermissionEnabled,
      'dailyScreenTimeLimitMinutes': dailyScreenTimeLimitMinutes,
      'bedtimeStart': bedtimeStart,
      'bedtimeEnd': bedtimeEnd,
      'studyTimeStart': studyTimeStart,
      'studyTimeEnd': studyTimeEnd,
      'restrictionsActive': restrictionsActive,
      'gender': gender,
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

  factory ChildProfileModel.fromMap(Map<String, dynamic> map, String id) {
    final parsedName = map['name'] ?? 'Child';
    final rawGender = (map['gender'] ?? '').toString().toLowerCase().trim();
    final resolvedGender = rawGender.isNotEmpty
        ? (rawGender == 'girl' ? 'girl' : 'boy')
        : guessGender(parsedName.toString());

    return ChildProfileModel(
      id: id,
      parentId: map['parentId'] ?? '',
      name: parsedName,
      age: map['age'] is int ? map['age'] : int.tryParse(map['age']?.toString() ?? '10') ?? 10,
      pairingCode: map['pairingCode'] ?? '',
      isPaired: map['isPaired'] ?? true,
      batteryLevel: map['batteryLevel'] ?? 90,
      isCharging: map['isCharging'] ?? false,
      locationPermissionEnabled: map['locationPermissionEnabled'] ?? true,
      usagePermissionEnabled: map['usagePermissionEnabled'] ?? true,
      dailyScreenTimeLimitMinutes: map['dailyScreenTimeLimitMinutes'] ?? 180,
      bedtimeStart: map['bedtimeStart'] ?? '21:30',
      bedtimeEnd: map['bedtimeEnd'] ?? '06:30',
      studyTimeStart: map['studyTimeStart'] ?? '16:00',
      studyTimeEnd: map['studyTimeEnd'] ?? '18:00',
      restrictionsActive: map['restrictionsActive'] ?? true,
      gender: resolvedGender,
    );
  }

  ChildProfileModel copyWith({
    bool? isPaired,
    int? batteryLevel,
    bool? isCharging,
    bool? locationPermissionEnabled,
    bool? usagePermissionEnabled,
    int? dailyScreenTimeLimitMinutes,
    String? bedtimeStart,
    String? bedtimeEnd,
    String? studyTimeStart,
    String? studyTimeEnd,
    bool? restrictionsActive,
    String? gender,
  }) {
    return ChildProfileModel(
      id: id,
      parentId: parentId,
      name: name,
      age: age,
      pairingCode: pairingCode,
      isPaired: isPaired ?? this.isPaired,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      locationPermissionEnabled: locationPermissionEnabled ?? this.locationPermissionEnabled,
      usagePermissionEnabled: usagePermissionEnabled ?? this.usagePermissionEnabled,
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

