import 'package:flutter/foundation.dart';

class FirebaseService {
  static const bool _isFirebaseInitialized = true;

  static bool get isInitialized => _isFirebaseInitialized;

  static Future<void> initialize() async {
    debugPrint('[KidShield Junior] REST API Backend Mode initialized.');
  }
}
