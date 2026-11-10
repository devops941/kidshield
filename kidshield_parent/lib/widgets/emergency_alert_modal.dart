import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/child_model.dart';
import '../models/notification_model.dart';
import '../providers/child_provider.dart';
import '../providers/monitoring_provider.dart';
import '../screens/location/live_location_screen.dart';

class EmergencyAlertModal extends StatefulWidget {
  final NotificationModel alert;

  const EmergencyAlertModal({super.key, required this.alert});

  static Future<void> show(BuildContext context, NotificationModel alert) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (context) => EmergencyAlertModal(alert: alert),
    );
  }

  @override
  State<EmergencyAlertModal> createState() => _EmergencyAlertModalState();
}

class _EmergencyAlertModalState extends State<EmergencyAlertModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final MapController _miniMapController = MapController();
  bool _isSirenPlaying = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-play emergency siren sound & vibration on parent phone
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final monitoring = Provider.of<MonitoringProvider>(context, listen: false);
      monitoring.playEmergencySiren();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleSiren(MonitoringProvider monitoring) {
    setState(() {
      _isSirenPlaying = !_isSirenPlaying;
    });
    if (_isSirenPlaying) {
      monitoring.playEmergencySiren();
    } else {
      monitoring.stopEmergencySiren();
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitoring = Provider.of<MonitoringProvider>(context);
    final childProvider = Provider.of<ChildProvider>(context);
    final selectedChild = childProvider.selectedChild;

    // Resolve matching child for phone number
    ChildModel? targetChild;
    for (final c in childProvider.children) {
      if ((widget.alert.childId.isNotEmpty && c.id == widget.alert.childId) ||
          (widget.alert.childName.isNotEmpty && c.name.toLowerCase() == widget.alert.childName.toLowerCase())) {
        targetChild = c;
        break;
      }
    }
    targetChild ??= selectedChild;

    final String childPhone = targetChild?.phoneNumber.trim() ?? '';

    final meta = widget.alert.metadata ?? {};
    final double lat = double.tryParse(meta['latitude']?.toString() ?? '') ??
        monitoring.currentLocation?.latitude ??
        13.0827;
    final double lng = double.tryParse(meta['longitude']?.toString() ?? '') ??
        monitoring.currentLocation?.longitude ??
        80.2707;
    final String address = meta['address']?.toString() ??
        monitoring.currentLocation?.address ??
        'Location coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    final int batteryLevel = int.tryParse(meta['batteryLevel']?.toString() ?? '') ??
        monitoring.currentLocation?.batteryAtLocation ??
        85;
    final String childName = widget.alert.childName.isNotEmpty
        ? widget.alert.childName
        : (selectedChild?.name ?? 'Child');
    final String timeFormatted = DateFormat('hh:mm:ss a, dd MMM yyyy')
        .format(widget.alert.timestamp);

    final LatLng childCoord = LatLng(lat, lng);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0510),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Flashing Emergency Banner
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 12.h, left: 16.w, right: 16.w),
                padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.5 * _pulseAnimation.value),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 22.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          'EMERGENCY SOS DISTRESS ALERT!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Child Info Card
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C0E1E),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar with animated red danger ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 58.r,
                              height: 58.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                              ),
                            ),
                            Container(
                              width: 50.r,
                              height: 50.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFEF4444),
                                  width: 2.2,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  selectedChild?.gender == 'girl'
                                      ? 'assets/images/girl_avatar.png'
                                      : 'assets/images/mithran_avatar.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30.r,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                childName,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Triggered: $timeFormatted',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: const Color(0xFFFCA5A5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(color: const Color(0xFF22C55E)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          batteryLevel < 20
                                              ? Icons.battery_alert_rounded
                                              : Icons.battery_std_rounded,
                                          size: 13.r,
                                          color: batteryLevel < 20
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF22C55E),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Battery $batteryLevel%',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  GestureDetector(
                                    onTap: () => _toggleSiren(monitoring),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                      decoration: BoxDecoration(
                                        color: _isSirenPlaying
                                            ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                                            : const Color(0xFF475569).withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8.r),
                                        border: Border.all(
                                          color: _isSirenPlaying
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _isSirenPlaying
                                                ? Icons.volume_up_rounded
                                                : Icons.volume_off_rounded,
                                            size: 13.r,
                                            color: _isSirenPlaying
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFF94A3B8),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            _isSirenPlaying ? 'Siren ON' : 'Muted',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
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

                  SizedBox(height: 12.h),

                  // Exact Location Address Banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1428),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: const Color(0xFF00E5FF),
                            size: 20.r,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distress Coordinates & Address',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                address,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // Mini OpenStreetMap Preview with pulsing marker
                  Container(
                    height: 170.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _miniMapController,
                            options: MapOptions(
                              initialCenter: childCoord,
                              initialZoom: 16.0,
                              minZoom: 4.0,
                              maxZoom: 19.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.kidshield.parent.kidshield_parent',
                              ),
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: childCoord,
                                    radius: 38.r,
                                    useRadiusInMeter: false,
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                                    borderColor: const Color(0xFFEF4444),
                                    borderStrokeWidth: 2,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: childCoord,
                                    width: 44.r,
                                    height: 44.r,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          selectedChild?.gender == 'girl'
                                              ? 'assets/images/girl_avatar.png'
                                              : 'assets/images/mithran_avatar.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Open in Full Map Button Overlay
                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: GestureDetector(
                              onTap: () {
                                monitoring.stopEmergencySiren();
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LiveLocationScreen()),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(color: const Color(0xFF00E5FF)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fullscreen_rounded, color: const Color(0xFF00E5FF), size: 16.r),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Full Map',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Section Title: Immediate Emergency Actions
                  Text(
                    '⚡ IMMEDIATE EMERGENCY ACTIONS',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFCA5A5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Grid of 4 Direct Call Buttons
                  Row(
                    children: [
                      // 1. Call Child
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.phone_rounded,
                          title: 'Call $childName',
                          subtitle: childPhone.isNotEmpty ? childPhone : 'Direct Call',
                          color: const Color(0xFF0284C7),
                          onTap: () {
                            if (childPhone.isNotEmpty) {
                              monitoring.openEmergencyDialer(childPhone);
                            } else {
                              _showPromptDialChild(context, targetChild, childName, monitoring, childProvider);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 10.w),

                      // 2. Call 112 (National Emergency)
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.emergency_rounded,
                          title: 'Call 112',
                          subtitle: 'National Helpline',
                          color: const Color(0xFFDC2626),
                          isUrgent: true,
                          onTap: () => monitoring.openEmergencyDialer('112'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  Row(
                    children: [
                      // 3. Call 1098 Childline
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.child_care_rounded,
                          title: 'Call 1098',
                          subtitle: 'Childline Support',
                          color: const Color(0xFF7C3AED),
                          onTap: () => monitoring.openEmergencyDialer('1098'),
                        ),
                      ),
                      SizedBox(width: 10.w),

                      // 4. Call 100 Police
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.local_police_rounded,
                          title: 'Call 100',
                          subtitle: 'Police Patrol',
                          color: const Color(0xFF059669),
                          onTap: () => monitoring.openEmergencyDialer('100'),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // Turn-by-Turn Navigation Button (Google Maps / Maps app)
                  GestureDetector(
                    onTap: () => monitoring.openEmergencyNavigation(
                      lat,
                      lng,
                      '$childName Distress Location',
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_rounded, color: Colors.white, size: 22.r),
                          SizedBox(width: 8.w),
                          Text(
                            'TURN-BY-TURN NAVIGATION IN MAPS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Acknowledge & Mark Safe Button
                  GestureDetector(
                    onTap: () async {
                      await monitoring.dismissEmergencyAlert(widget.alert.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 22.r),
                          SizedBox(width: 8.w),
                          Text(
                            'ACKNOWLEDGE & MARK CHILD SAFE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isUrgent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: color.withValues(alpha: isUrgent ? 0.9 : 0.4),
            width: isUrgent ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18.r),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPromptDialChild(
    BuildContext context,
    ChildModel? targetChild,
    String childName,
    MonitoringProvider monitoring,
    ChildProvider childProvider,
  ) {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        titlePadding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: const Icon(Icons.phone_rounded, color: Color(0xFF38BDF8), size: 20),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Call $childName',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No phone number configured for $childName. Enter mobile number to dial immediately:',
                style: TextStyle(
                  color: const Color(0xFFCBD5E1),
                  fontSize: 12.sp,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'e.g. +91 98765 43210',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.dialpad_rounded, color: Color(0xFF38BDF8)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () {
              final number = phoneCtrl.text.trim();
              if (number.isNotEmpty) {
                Navigator.of(ctx).pop();
                if (targetChild != null) {
                  childProvider.updateChild(targetChild.id, phoneNumber: number);
                }
                monitoring.openEmergencyDialer(number);
              }
            },
            child: const Text('Save & Call', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
