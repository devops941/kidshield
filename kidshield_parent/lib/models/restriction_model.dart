class RestrictionModel {
  final int dailyScreenTimeMinutes;
  final String bedtimeStart;
  final String bedtimeEnd;
  final String studyTimeStart;
  final String studyTimeEnd;
  final List<String> blockedPackageNames;
  final bool isDailyLimitEnabled;
  final bool isBedtimeEnabled;
  final bool isStudyTimeEnabled;

  RestrictionModel({
    this.dailyScreenTimeMinutes = 180,
    this.bedtimeStart = '21:30',
    this.bedtimeEnd = '06:30',
    this.studyTimeStart = '16:00',
    this.studyTimeEnd = '18:00',
    this.blockedPackageNames = const [],
    this.isDailyLimitEnabled = true,
    this.isBedtimeEnabled = true,
    this.isStudyTimeEnabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'dailyScreenTimeMinutes': dailyScreenTimeMinutes,
      'bedtimeStart': bedtimeStart,
      'bedtimeEnd': bedtimeEnd,
      'studyTimeStart': studyTimeStart,
      'studyTimeEnd': studyTimeEnd,
      'blockedPackageNames': blockedPackageNames,
      'isDailyLimitEnabled': isDailyLimitEnabled,
      'isBedtimeEnabled': isBedtimeEnabled,
      'isStudyTimeEnabled': isStudyTimeEnabled,
    };
  }

  factory RestrictionModel.fromMap(Map<String, dynamic> map) {
    return RestrictionModel(
      dailyScreenTimeMinutes: map['dailyScreenTimeMinutes'] ?? 180,
      bedtimeStart: map['bedtimeStart'] ?? '21:30',
      bedtimeEnd: map['bedtimeEnd'] ?? '06:30',
      studyTimeStart: map['studyTimeStart'] ?? '16:00',
      studyTimeEnd: map['studyTimeEnd'] ?? '18:00',
      blockedPackageNames: List<String>.from(map['blockedPackageNames'] ?? []),
      isDailyLimitEnabled: map['isDailyLimitEnabled'] ?? true,
      isBedtimeEnabled: map['isBedtimeEnabled'] ?? true,
      isStudyTimeEnabled: map['isStudyTimeEnabled'] ?? false,
    );
  }

  RestrictionModel copyWith({
    int? dailyScreenTimeMinutes,
    String? bedtimeStart,
    String? bedtimeEnd,
    String? studyTimeStart,
    String? studyTimeEnd,
    List<String>? blockedPackageNames,
    bool? isDailyLimitEnabled,
    bool? isBedtimeEnabled,
    bool? isStudyTimeEnabled,
  }) {
    return RestrictionModel(
      dailyScreenTimeMinutes: dailyScreenTimeMinutes ?? this.dailyScreenTimeMinutes,
      bedtimeStart: bedtimeStart ?? this.bedtimeStart,
      bedtimeEnd: bedtimeEnd ?? this.bedtimeEnd,
      studyTimeStart: studyTimeStart ?? this.studyTimeStart,
      studyTimeEnd: studyTimeEnd ?? this.studyTimeEnd,
      blockedPackageNames: blockedPackageNames ?? this.blockedPackageNames,
      isDailyLimitEnabled: isDailyLimitEnabled ?? this.isDailyLimitEnabled,
      isBedtimeEnabled: isBedtimeEnabled ?? this.isBedtimeEnabled,
      isStudyTimeEnabled: isStudyTimeEnabled ?? this.isStudyTimeEnabled,
    );
  }
}

