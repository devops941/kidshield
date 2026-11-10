import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/location_sync_service.dart';
import '../services/usage_sync_service.dart';

class LocationProvider extends ChangeNotifier {
  static const MethodChannel _gpsChannel = MethodChannel('com.kidshield.child/gps');
  final LocationSyncService _syncService = LocationSyncService();
  final UsageSyncService _usageSyncService = UsageSyncService();

  bool _isSharingEnabled = true;
  double _latitude = 13.0827;
  double _longitude = 80.2707;
  String _address = 'Acquiring GPS location...';
  int _batteryLevel = 95;
  bool _isSending = false;
  Timer? _periodicSyncTimer;
  String? _activeChildId;

  bool get isSharingEnabled => _isSharingEnabled;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get address => _address;
  int get batteryLevel => _batteryLevel;
  bool get isSending => _isSending;
  String? get activeChildId => _activeChildId;

  LocationProvider() {
    _startPeriodicTracking();
  }

  void _startPeriodicTracking() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isSharingEnabled && _activeChildId != null && _activeChildId!.isNotEmpty) {
        updateLocation(_activeChildId!);
      }
    });
  }

  void setActiveChildId(String childId) {
    _activeChildId = childId;
    if (_isSharingEnabled && childId.isNotEmpty) {
      updateLocation(childId);
      _syncService.startNativeForegroundService(childId);
    }
  }

  void toggleLocationSharing(bool val, String childId) {
    // Safety enforcement: Location sharing is mandatory and permanently locked ON for child
    _isSharingEnabled = true;
    _syncService.toggleLocationSharing(true);
    _activeChildId = childId;
    _syncService.startNativeForegroundService(childId);
    notifyListeners();
    updateLocation(childId);
  }

  void toggleSharing(bool val, [String? childId]) {
    toggleLocationSharing(true, childId ?? _activeChildId ?? '');
  }

  Future<void> refreshLocation([String? childId]) async {
    await updateLocation(childId ?? _activeChildId ?? '');
  }

  Future<void> updateLocation(String childId) async {
    if (childId.isNotEmpty) {
      _activeChildId = childId;
    }
    _isSending = true;
    notifyListeners();

    try {
      // 0. Ensure location permission is checked and requested
      final bool hasPerm = await _gpsChannel.invokeMethod<bool>('checkPermission') ?? false;
      if (!hasPerm) {
        await _gpsChannel.invokeMethod('requestPermission');
      }

      // 1. Fetch real GPS coordinates directly from device hardware
      final result = await _gpsChannel.invokeMethod<Map<dynamic, dynamic>>('getRealLocation');
      if (result != null) {
        final lat = result['latitude'] as double?;
        final lng = result['longitude'] as double?;
        final addr = result['address'] as String?;

        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          _latitude = lat;
          _longitude = lng;
          if (addr != null && addr.isNotEmpty) {
            _address = addr;
          }
        }
      }

      // 2. Fetch real battery level
      final battery = await const MethodChannel('com.kidshield.child/apps').invokeMethod<int>('getBatteryLevel');
      if (battery != null && battery > 0) {
        _batteryLevel = battery;
      }
    } catch (e) {
      debugPrint('Child GPS fetch error: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('permission_denied') || errStr.contains('permission')) {
        _address = 'Location permission required. Please allow location access.';
      } else if (errStr.contains('location_disabled')) {
        _address = 'Device GPS is turned off. Please enable GPS in settings.';
      }
    }

    if (_activeChildId != null && _activeChildId!.isNotEmpty) {
      await _syncService.sendLocationUpdate(
        childId: _activeChildId!,
        latitude: _latitude,
        longitude: _longitude,
        address: _address,
        batteryLevel: _batteryLevel,
      );

      // Also continuously sync installed apps with real icons and app usage
      unawaited(_usageSyncService.syncUsageToParent(_activeChildId!));
    }

    _isSending = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    super.dispose();
  }
}
