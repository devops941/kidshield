class AppUsageModel {
  final String packageName;
  final String appName;
  final String category;
  final int usageMinutesToday;
  final int usageMinutesWeekly;
  final int usageMinutesMonthly;
  final int launchCountToday;
  final DateTime lastUsed;
  final bool isRestricted;
  final String icon;

  AppUsageModel({
    required this.packageName,
    required this.appName,
    required this.category,
    required this.usageMinutesToday,
    required this.usageMinutesWeekly,
    this.usageMinutesMonthly = 0,
    required this.launchCountToday,
    required this.lastUsed,
    this.isRestricted = false,
    this.icon = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'category': category,
      'usageMinutesToday': usageMinutesToday,
      'usageMinutesWeekly': usageMinutesWeekly,
      'usageMinutesMonthly': usageMinutesMonthly,
      'launchCountToday': launchCountToday,
      'lastUsed': lastUsed.toIso8601String(),
      'isRestricted': isRestricted,
      'icon': icon,
    };
  }

  factory AppUsageModel.fromMap(Map<String, dynamic> map) {
    return AppUsageModel(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      category: map['category'] ?? 'General',
      usageMinutesToday: map['usageMinutesToday'] ?? 0,
      usageMinutesWeekly: map['usageMinutesWeekly'] ?? 0,
      usageMinutesMonthly: map['usageMinutesMonthly'] ?? 0,
      launchCountToday: map['launchCountToday'] ?? 0,
      lastUsed: map['lastUsed'] != null
          ? (DateTime.tryParse(map['lastUsed'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      isRestricted: map['isRestricted'] ?? false,
      icon: map['icon'] ?? '',
    );
  }
}
