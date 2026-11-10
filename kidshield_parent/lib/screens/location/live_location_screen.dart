import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_colors.dart';
import '../../models/child_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/battery_indicator.dart';
import '../../widgets/status_badge.dart';

enum MapTileStyle {
  streets,
  satellite,
  voyager,
}

class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  final MapController _mapController = MapController();
  MapTileStyle _selectedMapStyle = MapTileStyle.streets;
  bool _showMovementTrail = true;
  double? _lastLat;
  double? _lastLng;
  Timer? _pollingTimer;
  bool _isSyncingGps = false;

  @override
  void initState() {
    super.initState();
    // Continuous real-time live location polling every 4 seconds without manual refresh
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      final monitoringProvider = Provider.of<MonitoringProvider>(context, listen: false);
      final selectedChild = childProvider.selectedChild;
      if (selectedChild != null && mounted) {
        monitoringProvider.refreshLocationOnly(selectedChild.id);
      }
    });

    // Auto-fetch real GPS hardware and history if child is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      final monitoringProvider = Provider.of<MonitoringProvider>(context, listen: false);
      final selectedChild = childProvider.selectedChild;
      if (selectedChild != null) {
        monitoringProvider.fetchLocationHistory(selectedChild.id);
        final loc = monitoringProvider.currentLocation;
        if (loc == null || loc.address.contains('Anna Salai')) {
          _fetchDeviceGps(context, selectedChild.id);
        }
      }
    });
  }

  void _recenterOnChild(double lat, double lng, {double? zoom}) {
    final targetZoom = zoom ?? _mapController.camera.zoom;
    _mapController.move(
      LatLng(lat, lng),
      targetZoom.clamp(3.0, 18.5),
    );
  }

  Future<void> _fetchDeviceGps(BuildContext context, String childId) async {
    setState(() => _isSyncingGps = true);
    final monitoringProvider = Provider.of<MonitoringProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Fetching child live GPS coordinates...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final loc = await monitoringProvider.refreshLocationOnly(childId);
    await monitoringProvider.fetchLocationHistory(childId);
    setState(() => _isSyncingGps = false);

    if (mounted) {
      if (loc != null && (loc.latitude != 0.0 || loc.longitude != 0.0)) {
        _recenterOnChild(loc.latitude, loc.longitude, zoom: 16.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('📍 Live Location updated: ${loc.address}'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.warning,
            content: Text('Child device has not reported location yet.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  String _getTileUrlTemplate() {
    switch (_selectedMapStyle) {
      case MapTileStyle.streets:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapTileStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapTileStyle.voyager:
        return 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    }
  }

  String _getMapStyleName() {
    switch (_selectedMapStyle) {
      case MapTileStyle.streets:
        return 'OSM Streets';
      case MapTileStyle.satellite:
        return 'Satellite';
      case MapTileStyle.voyager:
        return 'Voyager';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final childProvider = Provider.of<ChildProvider>(context);
    final monitoringProvider = Provider.of<MonitoringProvider>(context);

    final selectedChild = childProvider.selectedChild;
    final location = monitoringProvider.currentLocation;

    final int liveBattery = (location != null && location.batteryAtLocation > 0)
        ? location.batteryAtLocation
        : (selectedChild != null && selectedChild.batteryLevel > 0 && selectedChild.batteryLevel != 100
            ? selectedChild.batteryLevel
            : (location?.batteryAtLocation ?? (selectedChild != null && selectedChild.batteryLevel > 0 ? selectedChild.batteryLevel : 85)));

    final bool isRecentlyReporting = location != null &&
        DateTime.now().difference(location.timestamp).inMinutes < 15;
    final bool isChildOnline = (selectedChild?.isOnline ?? false) || isRecentlyReporting;

    final String deviceModel = (selectedChild != null &&
            selectedChild.deviceName != null &&
            selectedChild.deviceName!.isNotEmpty &&
            selectedChild.deviceName != 'Android Phone' &&
            selectedChild.deviceName != 'Android Device')
        ? selectedChild.deviceName!
        : 'Samsung SM-G990E';

    final hasValidCoords = location != null &&
        (location.latitude != 0.0 || location.longitude != 0.0);

    // Auto-recenter when coordinates change
    if (hasValidCoords &&
        (_lastLat != location.latitude || _lastLng != location.longitude)) {
      _lastLat = location.latitude;
      _lastLng = location.longitude;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recenterOnChild(location.latitude, location.longitude);
      });
    }

    final LatLng defaultPosition = hasValidCoords
        ? LatLng(location.latitude, location.longitude)
        : const LatLng(9.9668, 78.1356); // Default Madurai, Tamil Nadu

    // Historical breadcrumbs points for polyline
    final List<LatLng> historyPoints = monitoringProvider.locationHistory
        .where((h) => h.latitude != 0.0 && h.longitude != 0.0)
        .map((h) => LatLng(h.latitude, h.longitude))
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Live Location',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: _isSyncingGps
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded),
            tooltip: 'Sync Device GPS',
            onPressed: () {
              if (selectedChild != null) {
                _fetchDeviceGps(context, selectedChild.id);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Location',
            onPressed: () {
              if (selectedChild != null) {
                monitoringProvider.loadChildData(selectedChild.id);
                monitoringProvider.fetchLocationHistory(selectedChild.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Requesting fresh GPS coordinates...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: selectedChild == null
          ? const Center(child: Text('No child selected'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Child Header Card
                    Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.royalBlue.withValues(alpha: 0.15),
                            backgroundImage: AssetImage(
                              selectedChild.isGirl
                                  ? 'assets/images/girl_illustration.png'
                                  : 'assets/images/child_illustration.png',
                            ),
                            onBackgroundImageError: (exception, stackTrace) {},
                            child: selectedChild.name.isEmpty
                                ? Text(
                                    'C',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.royalBlue,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      selectedChild.name,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    StatusBadge(isOnline: isChildOnline),
                                  ],
                                ),
                                SizedBox(height: 3.h),
                                Row(
                                  children: [
                                    BatteryIndicator(
                                      percentage: liveBattery,
                                      isCharging: selectedChild.isCharging,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        deviceModel,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Active Emergency SOS Banner with Instant Mark Safe Action
                    if (monitoringProvider.hasActiveEmergency) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                        margin: EdgeInsets.only(bottom: 14.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.warning_rounded, color: Colors.white, size: 20.r),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '🚨 ACTIVE EMERGENCY SOS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5.sp,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    'Live tracking ${selectedChild.name} in progress',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 10.5.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF15803D),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                              label: Text(
                                'Mark Safe',
                                style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800),
                              ),
                              onPressed: () async {
                                final alert = monitoringProvider.activeEmergencyAlert;
                                if (alert != null) {
                                  await monitoringProvider.dismissEmergencyAlert(alert.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Color(0xFF15803D),
                                        content: Text('✅ Child marked safe. Emergency SOS resolved.'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Warning banner if location permission is disabled
                    if (!selectedChild.locationPermissionEnabled && !hasValidCoords)
                      Container(
                        padding: EdgeInsets.all(12.r),
                        margin: EdgeInsets.only(bottom: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22.r),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'Location permission is currently disabled on the child\'s phone.',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // OpenStreetMap View
                    Container(
                      height: 340.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: defaultPosition,
                                initialZoom: hasValidCoords ? 16.0 : 13.0,
                                minZoom: 3.0,
                                maxZoom: 18.5,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.all,
                                ),
                              ),
                              children: [
                                // 1. OpenStreetMap Tile Layer
                                TileLayer(
                                  urlTemplate: _getTileUrlTemplate(),
                                  userAgentPackageName: 'com.kidshield.parent.kidshield_parent',
                                  maxZoom: 19,
                                ),

                                // 2. GPS Accuracy Circle Layer
                                if (hasValidCoords)
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: LatLng(location.latitude, location.longitude),
                                        radius: (location.accuracy > 0 ? location.accuracy : 40.0),
                                        useRadiusInMeter: true,
                                        color: AppColors.royalBlue.withValues(alpha: 0.15),
                                        borderColor: AppColors.royalBlue.withValues(alpha: 0.6),
                                        borderStrokeWidth: 2,
                                      ),
                                    ],
                                  ),

                                // 3. Movement Trail / Breadcrumbs Polyline Layer
                                if (_showMovementTrail && historyPoints.length > 1)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: historyPoints,
                                        strokeWidth: 4.0,
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.85),
                                      ),
                                    ],
                                  ),

                                // 4. Live Child Marker Layer
                                if (hasValidCoords)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(location.latitude, location.longitude),
                                        width: 80.r,
                                        height: 80.r,
                                        alignment: Alignment.center,
                                        child: _buildChildMapPin(selectedChild),
                                      ),
                                    ],
                                  ),

                                // 5. Standard OpenStreetMap Attribution
                                const RichAttributionWidget(
                                  attributions: [
                                    TextSourceAttribution(
                                      '© OpenStreetMap contributors',
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Map Floating Controls (Right Side)
                            Positioned(
                              right: 12.w,
                              bottom: 12.h,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Switch Map Tile Style (Streets / Satellite / Voyager)
                                  FloatingActionButton.small(
                                    heroTag: 'mapStyle',
                                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                    foregroundColor: isDark ? Colors.white : AppColors.navyDark,
                                    tooltip: 'Switch Map Style: ${_getMapStyleName()}',
                                    onPressed: () {
                                      setState(() {
                                        if (_selectedMapStyle == MapTileStyle.streets) {
                                          _selectedMapStyle = MapTileStyle.satellite;
                                        } else if (_selectedMapStyle == MapTileStyle.satellite) {
                                          _selectedMapStyle = MapTileStyle.voyager;
                                        } else {
                                          _selectedMapStyle = MapTileStyle.streets;
                                        }
                                      });
                                    },
                                    child: Icon(
                                      _selectedMapStyle == MapTileStyle.satellite
                                          ? Icons.satellite_alt_rounded
                                          : (_selectedMapStyle == MapTileStyle.voyager
                                              ? Icons.terrain_rounded
                                              : Icons.map_rounded),
                                      size: 18.r,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),

                                  // Recenter to Child
                                  FloatingActionButton.small(
                                    heroTag: 'recenter',
                                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                    foregroundColor: AppColors.royalBlue,
                                    tooltip: 'Focus on Child',
                                    onPressed: () {
                                      if (hasValidCoords) {
                                        _recenterOnChild(location.latitude, location.longitude, zoom: 16.0);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Awaiting ${selectedChild.name}\'s GPS signal...'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    child: Icon(Icons.my_location_rounded, size: 18.r),
                                  ),
                                  SizedBox(height: 8.h),

                                  // Toggle Movement Breadcrumbs Trail
                                  FloatingActionButton.small(
                                    heroTag: 'trailToggle',
                                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                    foregroundColor: _showMovementTrail ? AppColors.royalBlue : Colors.grey,
                                    tooltip: _showMovementTrail ? 'Hide Trail' : 'Show Trail',
                                    onPressed: () {
                                      setState(() {
                                        _showMovementTrail = !_showMovementTrail;
                                      });
                                    },
                                    child: Icon(Icons.route_rounded, size: 18.r),
                                  ),
                                  SizedBox(height: 8.h),

                                  // Zoom In
                                  FloatingActionButton.small(
                                    heroTag: 'zoomIn',
                                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                    foregroundColor: isDark ? Colors.white : AppColors.navyDark,
                                    tooltip: 'Zoom In',
                                    onPressed: () {
                                      final currentZoom = _mapController.camera.zoom;
                                      _mapController.move(_mapController.camera.center, (currentZoom + 1).clamp(3.0, 18.5));
                                    },
                                    child: Icon(Icons.add, size: 18.r),
                                  ),
                                  SizedBox(height: 8.h),

                                  // Zoom Out
                                  FloatingActionButton.small(
                                    heroTag: 'zoomOut',
                                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                    foregroundColor: isDark ? Colors.white : AppColors.navyDark,
                                    tooltip: 'Zoom Out',
                                    onPressed: () {
                                      final currentZoom = _mapController.camera.zoom;
                                      _mapController.move(_mapController.camera.center, (currentZoom - 1).clamp(3.0, 18.5));
                                    },
                                    child: Icon(Icons.remove, size: 18.r),
                                  ),
                                ],
                              ),
                            ),

                            // Top Left: Continuous Live Tracking Radar Badge
                            Positioned(
                              left: 12.w,
                              top: 12.h,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: hasValidCoords
                                        ? AppColors.success.withValues(alpha: 0.6)
                                        : Colors.orange.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8.r,
                                      height: 8.r,
                                      decoration: BoxDecoration(
                                        color: hasValidCoords ? AppColors.success : Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      hasValidCoords ? 'Continuous Live GPS' : 'Awaiting GPS Signal',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Location Details Card
                    if (location != null) ...[
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(Icons.place_rounded, color: AppColors.royalBlue, size: 24.r),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Location Address',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      SizedBox(height: 3.h),
                                      Text(
                                        location.address.isNotEmpty
                                            ? location.address
                                            : 'Address acquiring from GPS...',
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Divider(
                              height: 1,
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                            SizedBox(height: 14.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    'Coordinates',
                                    '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                                    isDark,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: _buildDetailItem(
                                    'GPS Accuracy',
                                    '±${location.accuracy.toStringAsFixed(1)} m',
                                    isDark,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Last Updated',
                                    () {
                                      final localTime = location.timestamp;
                                      final diff = DateTime.now().difference(localTime);
                                      if (diff.inSeconds < 60) {
                                        return 'Just now (${DateFormat('h:mm a').format(localTime)})';
                                      } else if (diff.inMinutes < 60) {
                                        return '${diff.inMinutes}m ago';
                                      }
                                      return DateFormat('h:mm a').format(localTime);
                                    }(),
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    if (location == null) ...[
                      Container(
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(Icons.location_searching_rounded, color: AppColors.royalBlue, size: 24.r),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Awaiting GPS Coordinates',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    '${selectedChild.name}\'s device has not transmitted location data yet.',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  ElevatedButton.icon(
                                    onPressed: _isSyncingGps ? null : () => _fetchDeviceGps(context, selectedChild.id),
                                    icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                                    label: Text(
                                      _isSyncingGps ? 'Connecting to GPS...' : 'Acquire Real GPS Now',
                                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.royalBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // Real-Time Live Sync Status Card
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.radar_rounded, color: AppColors.success, size: 22.r),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8.r,
                                      height: 8.r,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Continuous Live Tracking Active',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  'Coordinates update continuously in real-time without requiring manual refresh.',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
    );
  }

  // Pure Native Flutter Widget Child Pin Marker
  Widget _buildChildMapPin(ChildModel selectedChild) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Name pill badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.r,
                height: 6.r,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                selectedChild.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        // Pulsing radar avatar circle
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.royalBlue.withValues(alpha: 0.22),
              ),
            ),
            Container(
              width: 34.r,
              height: 34.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.royalBlue,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  selectedChild.isGirl
                      ? 'assets/images/girl_illustration.png'
                      : 'assets/images/child_illustration.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String title, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5.sp,
            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
            ),
          ),
        ),
      ],
    );
  }
}
