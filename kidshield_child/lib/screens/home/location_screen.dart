import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/child_auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final MapController _mapController = MapController();
  double? _lastCenteredLat;
  double? _lastCenteredLng;

  @override
  Widget build(BuildContext context) {
    final location = Provider.of<LocationProvider>(context);
    final auth = Provider.of<ChildAuthProvider>(context);
    final isGirl = auth.currentProfile?.isGirl ?? false;

    final lat = location.latitude;
    final lng = location.longitude;
    final hasValidCoords = lat != 0.0 && lng != 0.0;
    final centerPosition = LatLng(
      hasValidCoords ? lat : 9.9668,
      hasValidCoords ? lng : 78.1357,
    );

    // Auto-center camera if coordinates just arrived or changed noticeably
    if (hasValidCoords &&
        (_lastCenteredLat == null ||
            (_lastCenteredLat! - lat).abs() > 0.0005 ||
            (_lastCenteredLng! - lng).abs() > 0.0005)) {
      _lastCenteredLat = lat;
      _lastCenteredLng = lng;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(centerPosition, 16.0);
        } catch (_) {}
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const CustomAppBar(title: 'Live Location Sharing'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.navyBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. OPENSTREETMAP LIVE MAP CARD (Replaces empty radar graphic)
                Container(
                  width: double.infinity,
                  height: 270.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF09142E),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: AppColors.electricCyan.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricCyan.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21.r),
                    child: Stack(
                      children: [
                        // OpenStreetMap View
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: centerPosition,
                            initialZoom: 16.0,
                            minZoom: 3.0,
                            maxZoom: 18.5,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            // Tile Layer (Standard OpenStreetMap Tiles)
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.kidshield.child',
                              maxZoom: 19,
                            ),

                            // Accuracy Ring
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: centerPosition,
                                  radius: 36,
                                  color: AppColors.electricCyan.withValues(alpha: 0.18),
                                  borderColor: AppColors.electricCyan,
                                  borderStrokeWidth: 1.8,
                                ),
                              ],
                            ),

                            // Child "You Are Here" Marker Pin
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: centerPosition,
                                  width: 120.w,
                                  height: 80.h,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF040A18).withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(10.r),
                                          border: Border.all(color: AppColors.electricCyan, width: 1.2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.35),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'You Are Here',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.electricCyan,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 3.h),
                                      Container(
                                        padding: EdgeInsets.all(2.5.r),
                                        decoration: BoxDecoration(
                                          color: AppColors.electricCyan,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.electricCyan.withValues(alpha: 0.6),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 17.r,
                                          backgroundColor: const Color(0xFF09142E),
                                          backgroundImage: AssetImage(
                                            isGirl
                                                ? 'assets/images/girl_illustration.png'
                                                : 'assets/images/child_illustration.png',
                                          ),
                                          onBackgroundImageError: (_, _) {},
                                          child: Icon(
                                            Icons.person_pin_circle_rounded,
                                            color: AppColors.electricCyan,
                                            size: 20.r,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Top-Right Live Sync Pill: • GPS Active
                        Positioned(
                          top: 12.h,
                          right: 12.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF040A18).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: AppColors.mintGreen.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7.r,
                                  height: 7.r,
                                  decoration: const BoxDecoration(
                                    color: AppColors.mintGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'GPS Active',
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mintGreen,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Floating Map Controls (Recenter + Zoom In/Out)
                        Positioned(
                          right: 12.w,
                          bottom: 14.h,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMapActionButton(
                                icon: Icons.my_location_rounded,
                                iconColor: AppColors.electricCyan,
                                tooltip: 'Recenter GPS',
                                onTap: () {
                                  _mapController.move(centerPosition, 16.5);
                                },
                              ),
                              SizedBox(height: 8.h),
                              _buildMapActionButton(
                                icon: Icons.add_rounded,
                                iconColor: Colors.white,
                                tooltip: 'Zoom In',
                                onTap: () {
                                  final currentZoom = _mapController.camera.zoom;
                                  _mapController.move(
                                    _mapController.camera.center,
                                    (currentZoom + 1).clamp(3.0, 18.5),
                                  );
                                },
                              ),
                              SizedBox(height: 6.h),
                              _buildMapActionButton(
                                icon: Icons.remove_rounded,
                                iconColor: Colors.white,
                                tooltip: 'Zoom Out',
                                onTap: () {
                                  final currentZoom = _mapController.camera.zoom;
                                  _mapController.move(
                                    _mapController.camera.center,
                                    (currentZoom - 1).clamp(3.0, 18.5),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Bottom-Left Attribution
                        Positioned(
                          bottom: 8.h,
                          left: 10.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF040A18).withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '© OpenStreetMap contributors',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // 2. TELEMETRY DETAILS CARD
                Container(
                  padding: EdgeInsets.all(18.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09142E),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.electricCyan.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.location_on_rounded,
                        label: 'Current Address',
                        value: location.address,
                      ),
                      const Divider(color: Color(0xFF1E2D5A), height: 22),
                      _buildInfoRow(
                        icon: Icons.my_location_rounded,
                        label: 'Coordinates',
                        value: '${location.latitude.toStringAsFixed(4)}° N, ${location.longitude.toStringAsFixed(4)}° E',
                      ),
                      const Divider(color: Color(0xFF1E2D5A), height: 22),
                      _buildInfoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Last Synced',
                        value: 'Just now (Continuous Background Sync)',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),

                // 3. LOCATION SHARING CONTROLS (Permanently Locked ON by Parent)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09142E),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.electricCyan.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: AppColors.mintGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.share_location_rounded,
                                color: AppColors.mintGreen,
                                size: 20.r,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Location Sharing with Parent',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Icon(
                                        Icons.lock_rounded,
                                        color: AppColors.mintGreen,
                                        size: 13.r,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Always Active • Protected by Parent',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppColors.mintGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Locked Switch (Permanently ON, cannot be turned off)
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.shield_rounded, color: AppColors.mintGreen, size: 20.r),
                                  SizedBox(width: 10.w),
                                  const Expanded(
                                    child: Text(
                                      'Safety Protected: Location sharing is permanently active and cannot be turned off from the child device.',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF09142E),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                side: const BorderSide(color: AppColors.mintGreen, width: 1.2),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        child: AbsorbPointer(
                          absorbing: true,
                          child: Switch(
                            value: true,
                            onChanged: (_) {},
                            activeTrackColor: AppColors.mintGreen,
                            activeThumbColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // 4. REFRESH LOCATION BUTTON
                CustomButton(
                  text: 'Refresh Current Location',
                  icon: Icons.refresh_rounded,
                  isGlowingCyan: true,
                  height: 48.h,
                  isLoading: location.isSending,
                  onPressed: () async {
                    final activeId = auth.currentProfile?.id;
                    await location.refreshLocation(activeId);
                    if (!context.mounted) return;
                    final hasGps = location.address != 'Acquiring GPS location...' &&
                        !location.address.contains('disabled') &&
                        !location.address.contains('required');
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              hasGps ? Icons.check_circle_rounded : Icons.info_rounded,
                              color: Colors.white,
                              size: 18.r,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                hasGps
                                    ? 'GPS Location updated & synced with Parent Console!'
                                    : location.address,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: hasGps ? AppColors.mintGreen : AppColors.warningOrange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 36.r,
          height: 36.r,
          decoration: BoxDecoration(
            color: const Color(0xFF040A18).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.electricCyan.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 20.r),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.electricCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.electricCyan, size: 18.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
