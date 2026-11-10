class AppInfoModel {
  final String packageName;
  final String appName;
  final String versionName;
  final DateTime installedAt;
  final bool isBlocked;
  final String ageRating;
  final bool isNewlyInstalled;
  final bool isParentApproved;
  final String icon;

  AppInfoModel({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.installedAt,
    this.isBlocked = false,
    this.ageRating = 'Everyone',
    this.isNewlyInstalled = false,
    this.isParentApproved = true,
    this.icon = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'versionName': versionName,
      'installedAt': installedAt.toIso8601String(),
      'isBlocked': isBlocked,
      'ageRating': ageRating,
      'isNewlyInstalled': isNewlyInstalled,
      'isParentApproved': isParentApproved,
      'icon': icon,
    };
  }

  factory AppInfoModel.fromMap(Map<String, dynamic> map) {
    return AppInfoModel(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      versionName: map['versionName'] ?? '1.0',
      installedAt: map['installedAt'] != null
          ? (DateTime.tryParse(map['installedAt'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      isBlocked: map['isBlocked'] ?? false,
      ageRating: map['ageRating'] ?? 'Everyone',
      isNewlyInstalled: map['isNewlyInstalled'] ?? false,
      isParentApproved: map['isParentApproved'] ?? true,
      icon: map['icon'] ?? '',
    );
  }

  AppInfoModel copyWith({
    bool? isBlocked,
    bool? isParentApproved,
    bool? isNewlyInstalled,
    String? icon,
  }) {
    return AppInfoModel(
      packageName: packageName,
      appName: appName,
      versionName: versionName,
      installedAt: installedAt,
      isBlocked: isBlocked ?? this.isBlocked,
      ageRating: ageRating,
      isNewlyInstalled: isNewlyInstalled ?? this.isNewlyInstalled,
      isParentApproved: isParentApproved ?? this.isParentApproved,
      icon: icon ?? this.icon,
    );
  }
}
