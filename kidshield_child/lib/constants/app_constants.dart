class AppConstants {
  static const String appName = 'KidShield Junior';
  static const String appTagline = 'Smart Safety & Family Companion';
  static const String appVersion = '1.0.0';

  // Firestore Collections matching Parent App
  static const String colParents = 'parents';
  static const String colChildren = 'children';
  static const String colLocations = 'locations';
  static const String colAppUsage = 'app_usage';
  static const String colInstalledApps = 'installed_apps';
  static const String colRestrictions = 'restrictions';
  static const String colNotifications = 'notifications';
  static const String colPairingCodes = 'pairing_codes';

  // Local storage keys
  static const String keyIsPaired = 'is_device_paired';
  static const String keyChildId = 'saved_child_id';
  static const String keyParentId = 'saved_parent_id';
  static const String keyChildName = 'saved_child_name';
}

