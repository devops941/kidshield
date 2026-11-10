import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/app_usage_model.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../children/add_child_screen.dart';
import '../location/live_location_screen.dart';
import '../apps/app_usage_screen.dart';
import '../restrictions/parental_restrictions_screen.dart';
import '../profile/profile_screen.dart';
import 'notifications_screen.dart';
import '../../widgets/emergency_alert_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _liveSyncTimer;
  String? _lastLoadedChildId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLiveData(silent: false);
    });

    // Auto-fetch live data from backend every 12 seconds in real-time
    _liveSyncTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) {
        _fetchLiveData(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _liveSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveData({bool silent = false}) async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final monitoringProvider = Provider.of<MonitoringProvider>(context, listen: false);

    if (childProvider.children.isEmpty && authProvider.currentParent != null) {
      await childProvider.loadChildren(authProvider.currentParent!.uid);
    }

    final child = childProvider.selectedChild;
    if (child != null) {
      _lastLoadedChildId = child.id;
      await monitoringProvider.loadChildData(child.id, silent: silent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    final monitoringProvider = Provider.of<MonitoringProvider>(context);

    final selectedChild = childProvider.selectedChild;

    // If selected child changed, immediately load their data
    if (selectedChild != null && selectedChild.id != _lastLoadedChildId) {
      _lastLoadedChildId = selectedChild.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        monitoringProvider.loadChildData(selectedChild.id, silent: true);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FD),
      body: RefreshIndicator(
        onRefresh: () => _fetchLiveData(silent: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Vibrant Curved Gradient Header
              _buildTopHeader(context, monitoringProvider, childProvider),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Child Switcher (if more than 1 child)
                    if (childProvider.children.length > 1) ...[
                      SizedBox(
                        height: 38.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: childProvider.children.length,
                          separatorBuilder: (_, _) => SizedBox(width: 8.w),
                          itemBuilder: (context, index) {
                            final child = childProvider.children[index];
                            final isSel = selectedChild?.id == child.id;
                            return ChoiceChip(
                              label: Text(
                                child.name,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isSel ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              selected: isSel,
                              selectedColor: AppColors.royalBlue,
                              backgroundColor: Colors.white,
                              onSelected: (_) {
                                childProvider.selectChild(child);
                                monitoringProvider.loadChildData(child.id);
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],

                    if (selectedChild == null)
                      _buildNoChildCard(context)
                    else ...[
                      // Hero Active Child Card
                      _buildChildHeroCard(context, selectedChild, monitoringProvider),
                      SizedBox(height: 14.h),

                      // Middle Section: 2 Columns (Live Location & Screen Time) - Perfectly aligned heights
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildLiveLocationCard(context, selectedChild, monitoringProvider),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildScreenTimeCard(context, selectedChild, monitoringProvider),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Second Row: 2 Columns (Most Used Apps & Recent Activities) - Perfectly aligned heights
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildMostUsedAppsCard(context, monitoringProvider),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildRecentActivitiesCard(context, monitoringProvider),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Vibrant Header matching the wireframe with safe area clearance
  Widget _buildTopHeader(
    BuildContext context,
    MonitoringProvider monitoringProvider,
    ChildProvider childProvider,
  ) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: statusBarHeight > 0 ? statusBarHeight + 8.h : 44.h,
        bottom: 20.h,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF021B59),
            Color(0xFF07389B),
            Color(0xFF0B52D4),
            Color(0xFF0284C7),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          // Left: Shield Logo with Boy & Girl Illustration + App Title
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(2.r),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/animated_logo.gif',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/Animated Safe Zone Protection Storyboard.gif',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Image.asset(
                          'assets/images/kidshield_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (c2, e2, s2) => const Icon(
                            Icons.shield_rounded,
                            color: Color(0xFF0B52D4),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'KIDSHIELD ',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Parent',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Monitor • Protect • Keep Safe',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
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
          SizedBox(width: 8.w),

          // Right: SOS Emergency + Notifications Bell Badge + Parent Profile Avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emergency SOS Trigger
              Builder(
                builder: (context) {
                  final hasActiveEmergency = monitoringProvider.hasActiveEmergency;
                  return GestureDetector(
                    onTap: () => _showEmergencyDialog(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: hasActiveEmergency
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFEF4444).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: hasActiveEmergency ? Colors.white : const Color(0xFFF87171),
                          width: hasActiveEmergency ? 1.6 : 1.2,
                        ),
                        boxShadow: hasActiveEmergency
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.7),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: BoxDecoration(
                              color: hasActiveEmergency ? Colors.white : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            hasActiveEmergency ? '🚨 SOS!' : 'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 8.w),

              // Notification Bell
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                    child: Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 19.r,
                      ),
                    ),
                  ),
                  if (monitoringProvider.unreadNotificationsCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: EdgeInsets.all(3.r),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(minWidth: 15.r, minHeight: 15.r),
                        child: Text(
                          '${monitoringProvider.unreadNotificationsCount}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 8.w),

              // Parent Profile Avatar
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF00E5FF), width: 1.8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: Color(0xFF0B52D4),
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 16.r,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Active Child Profile Hero Card
  Widget _buildChildHeroCard(
    BuildContext context,
    dynamic selectedChild,
    MonitoringProvider monitoringProvider,
  ) {
    final loc = monitoringProvider.currentLocation;
    final int liveBattery = (loc != null && loc.batteryAtLocation > 0)
        ? loc.batteryAtLocation
        : (selectedChild.batteryLevel > 0 ? selectedChild.batteryLevel : 85);
    final String lastSeenText;
    if (loc != null) {
      final diff = DateTime.now().difference(loc.timestamp);
      if (diff.inSeconds < 60) {
        lastSeenText = 'Just now';
      } else if (diff.inMinutes < 60) {
        lastSeenText = '${diff.inMinutes}m ago';
      } else {
        lastSeenText = DateFormat('h:mm a').format(loc.timestamp);
      }
    } else {
      lastSeenText = 'Just now';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFCFE2FF), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Child Avatar + Name + Age + Status
          Expanded(
            flex: 11,
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF38BDF8), width: 1.8),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          selectedChild.isGirl
                              ? 'assets/images/girl_illustration.png'
                              : 'assets/images/child_illustration.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              selectedChild.name.isNotEmpty ? selectedChild.name[0] : 'C',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.royalBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        padding: EdgeInsets.all(2.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 7.r),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedChild.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 9.r, color: const Color(0xFF0284C7)),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Age: ${selectedChild.age} Years',
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 8.5.r, color: const Color(0xFF16A34A)),
                            SizedBox(width: 3.w),
                            Text(
                              selectedChild.isPaired ? 'Connected' : 'Pending',
                              style: TextStyle(
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(
            width: 1.2,
            height: 44.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            color: const Color(0xFFE2E8F0),
          ),

          // Right: Smartphone Icon + Model + Battery + Status
          Expanded(
            flex: 10,
            child: Row(
              children: [
                Container(
                  width: 30.r,
                  height: 30.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                  ),
                  child: Icon(
                    Icons.smartphone_rounded,
                    color: const Color(0xFF0284C7),
                    size: 16.r,
                  ),
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selectedChild.deviceName ?? 'Samsung SM-G990E',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(
                            Icons.battery_charging_full_rounded,
                            size: 11.r,
                            color: liveBattery > 20
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFEF4444),
                          ),
                          SizedBox(width: 3.w),
                          FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$liveBattery%',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w800,
                                color: liveBattery > 20
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Container(
                            width: 5.r,
                            height: 5.r,
                            decoration: BoxDecoration(
                              color: selectedChild.isOnline
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                selectedChild.isOnline ? 'Online • $lastSeenText' : 'Offline',
                                style: TextStyle(
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
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
        ],
      ),
    );
  }

  // 3. Live Location Card
  Widget _buildLiveLocationCard(
    BuildContext context,
    dynamic selectedChild,
    MonitoringProvider monitoringProvider,
  ) {
    final loc = monitoringProvider.currentLocation;
    final hasLoc = loc != null && (loc.latitude != 0.0 || loc.longitude != 0.0);
    final addressText = hasLoc && loc.address.isNotEmpty
        ? loc.address
        : 'Tap to view live GPS map';
    final String timeText;
    if (hasLoc) {
      final diff = DateTime.now().difference(loc.timestamp);
      if (diff.inSeconds < 60) {
        timeText = 'Live • Just now';
      } else if (diff.inMinutes < 60) {
        timeText = 'Live • ${diff.inMinutes}m ago';
      } else {
        timeText = 'Live • ${DateFormat('h:mm a').format(loc.timestamp)}';
      }
    } else {
      timeText = 'GPS Ready';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LiveLocationScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFCFE2FF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF051C52), Color(0xFF0C3D9A)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: Colors.white, size: 14.r),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Live Location',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Map',
                          style: TextStyle(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 7.r),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Map Simulation View
            SizedBox(
              height: 125.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vector Map Graphic
                  CustomPaint(
                    size: Size(double.infinity, 125.h),
                    painter: _MiniMapPainter(),
                  ),

                  // Center Pin Marker with Glowing Waves
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 58.r,
                        height: 58.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                        ),
                      ),
                      Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                        ),
                      ),
                      Container(
                        width: 28.r,
                        height: 28.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0284C7),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.5),
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
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom-left timestamp badge
                  Positioned(
                    left: 6.w,
                    right: 6.w,
                    bottom: 6.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 9.r, color: const Color(0xFF0284C7)),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                timeText,
                                style: TextStyle(
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live Address Footer
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
              ),
              child: Row(
                children: [
                  Icon(
                    hasLoc ? Icons.near_me_rounded : Icons.location_searching_rounded,
                    size: 11.r,
                    color: hasLoc ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      addressText,
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Today's Screen Time Card
  Widget _buildScreenTimeCard(
    BuildContext context,
    dynamic selectedChild,
    MonitoringProvider monitoringProvider,
  ) {
    final int totalMins = monitoringProvider.totalScreenTimeMinutesToday;
    final int hours = totalMins ~/ 60;
    final int mins = totalMins % 60;
    final int limitHours = (selectedChild.dailyScreenTimeLimitMinutes / 60).round();
    final double percent = (totalMins / (selectedChild.dailyScreenTimeLimitMinutes > 0 ? selectedChild.dailyScreenTimeLimitMinutes : 180)).clamp(0.0, 1.0);
    final int percentInt = (percent * 100).round();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AppUsageScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFCFE2FF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF051C52), Color(0xFF0C3D9A)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 14.r),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Today's Screen Time",
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ParentalRestrictionsScreen()),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, color: Colors.white, size: 10.r),
                          SizedBox(width: 2.w),
                          Text(
                            'Rules',
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${hours}h ${mins}m',
                                  style: TextStyle(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '/ ${limitHours > 0 ? limitHours : 6}h Limit',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Radial Circular Progress Chart
                        SizedBox(
                          width: 42.r,
                          height: 42.r,
                          child: CustomPaint(
                            painter: _RadialProgressPainter(percentage: percent),
                            child: Center(
                              child: Text(
                                '$percentInt%',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 7-day Bar Chart with real usage data
                    Builder(
                      builder: (context) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final weeklyData = monitoringProvider.weeklyScreenTimeMinutes;
                        final limitMins = selectedChild.dailyScreenTimeLimitMinutes > 0
                            ? selectedChild.dailyScreenTimeLimitMinutes.toDouble()
                            : 180.0;
                        return SizedBox(
                          height: 48.h,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(days.length, (idx) {
                              final mins = idx < weeklyData.length ? weeklyData[idx] : 0.0;
                              final factor = (mins / limitMins).clamp(0.06, 1.0);
                              final isOver = mins > limitMins;
                              return Expanded(
                                child: _buildBar(days[idx], factor, isOver: isOver, hasUsage: mins > 0),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double heightFactor, {bool isOver = false, bool hasUsage = true}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 7.w,
          height: (32.h * heightFactor).clamp(3.h, 32.h),
          decoration: BoxDecoration(
            gradient: !hasUsage
                ? const LinearGradient(
                    colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                  )
                : (isOver
                    ? const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                      )),
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        SizedBox(height: 3.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            day,
            style: TextStyle(
              fontSize: 7.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  // 5. Most Used Apps Card
  Widget _buildMostUsedAppsCard(
    BuildContext context,
    MonitoringProvider monitoringProvider,
  ) {
    // Real app usage data loaded strictly from child phone
    final List<AppUsageModel> realApps = monitoringProvider.topUsedApps;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AppUsageScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFCFE2FF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF051C52), Color(0xFF0C3D9A)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Row(
                children: [
                  Icon(Icons.grid_view_rounded, color: Colors.white, size: 14.r),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Most Used Apps',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'All',
                          style: TextStyle(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 7.r),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal App Badges Row (or clean empty state)
            Expanded(
              child: Center(
                child: realApps.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
                        child: Text(
                          'No apps used today yet',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                        child: Row(
                          children: [
                            for (final app in realApps.take(4))
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildAppIconWidget(app, monitoringProvider),
                                    SizedBox(height: 4.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        app.usageMinutesToday > 0
                                            ? '${app.usageMinutesToday} min'
                                            : '${app.usageMinutesWeekly}m/wk',
                                        style: TextStyle(
                                          fontSize: 8.5.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }

  Widget _buildAppIconWidget(AppUsageModel app, MonitoringProvider monitoringProvider) {
    String iconData = app.icon;
    if (iconData.isEmpty) {
      final matching = monitoringProvider.installedApps
          .where((a) => a.packageName == app.packageName)
          .firstOrNull;
      if (matching != null && matching.icon.isNotEmpty) {
        iconData = matching.icon;
      }
    }

    if (iconData.isNotEmpty) {
      try {
        final bytes = base64Decode(iconData);
        return Container(
          width: 26.r,
          height: 26.r,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: Image.memory(
              bytes,
              width: 26.r,
              height: 26.r,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildVectorAppIcon(app.appName),
            ),
          ),
        );
      } catch (_) {
        return _buildVectorAppIcon(app.appName);
      }
    }
    return _buildVectorAppIcon(app.appName);
  }

  Widget _buildVectorAppIcon(String appName) {
    final lower = appName.toLowerCase();
    if (lower.contains('youtube')) {
      return Container(
        width: 26.r,
        height: 26.r,
        decoration: BoxDecoration(
          color: const Color(0xFFFF0000),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: const Center(
          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
        ),
      );
    } else if (lower.contains('chrome')) {
      return Container(
        width: 26.r,
        height: 26.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEA4335), width: 2),
        ),
        child: Center(
          child: Container(
            width: 10.r,
            height: 10.r,
            decoration: const BoxDecoration(
              color: Color(0xFF4285F4),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else if (lower.contains('whatsapp')) {
      return Container(
        width: 26.r,
        height: 26.r,
        decoration: const BoxDecoration(
          color: Color(0xFF25D366),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 14),
        ),
      );
    } else if (lower.contains('instagram')) {
      return Container(
        width: 26.r,
        height: 26.r,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
          ),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: const Center(
          child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
        ),
      );
    }
    return Container(
      width: 26.r,
      height: 26.r,
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Center(
        child: Text(
          appName.isNotEmpty ? appName[0].toUpperCase() : 'A',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 6. Recent Activities Card
  Widget _buildRecentActivitiesCard(
    BuildContext context,
    MonitoringProvider monitoringProvider,
  ) {
    final notifications = monitoringProvider.notifications;
    final hasRealEvents = notifications.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFCFE2FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF051C52), Color(0xFF0C3D9A)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: Colors.white, size: 14.r),
                SizedBox(width: 4.w),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Activities',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timeline Body
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(7.r),
                child: hasRealEvents
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: notifications.take(3).toList().asMap().entries.map((entry) {
                          final idx = entry.key;
                          final notif = entry.value;
                          final isLast = idx == (notifications.take(3).length - 1);
                          final timeStr = DateFormat('hh:mm a').format(notif.timestamp);

                          IconData iconData = Icons.info_rounded;
                          Color iconColor = const Color(0xFF0284C7);
                          Color iconBg = const Color(0xFFE0F2FE);

                          if (notif.type == NotificationType.sosEmergency) {
                            iconData = Icons.warning_rounded;
                            iconColor = const Color(0xFFEF4444);
                            iconBg = const Color(0xFFFEE2E2);
                          } else if (notif.type == NotificationType.locationDisabled) {
                            iconData = Icons.place_rounded;
                            iconColor = const Color(0xFF16A34A);
                            iconBg = const Color(0xFFDCFCE7);
                          } else if (notif.type == NotificationType.appInstalled) {
                            iconData = Icons.grid_view_rounded;
                            iconColor = const Color(0xFF0284C7);
                            iconBg = const Color(0xFFE0F2FE);
                          } else if (notif.type == NotificationType.screenTimeLimit) {
                            iconData = Icons.access_time_rounded;
                            iconColor = const Color(0xFF2563EB);
                            iconBg = const Color(0xFFDBEAFE);
                          } else if (notif.type == NotificationType.lowBattery) {
                            iconData = Icons.battery_alert_rounded;
                            iconColor = const Color(0xFFF59E0B);
                            iconBg = const Color(0xFFFEF3C7);
                          }

                          return _buildTimelineItem(
                            time: timeStr,
                            icon: iconData,
                            iconColor: iconColor,
                            iconBg: iconBg,
                            title: notif.title,
                            subtext: notif.message,
                            isLast: isLast,
                          );
                        }).toList(),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 24.r, color: const Color(0xFF16A34A)),
                            SizedBox(height: 5.h),
                            Text(
                              'No recent alerts',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Child device is safe and active',
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                color: const Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtext,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          SizedBox(
            width: 44.w,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ),
          ),

          // Icon node with vertical connector
          Column(
            children: [
              Container(
                width: 15.r,
                height: 15.r,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 9.r),
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 14.h,
                  color: const Color(0xFFCBD5E1),
                ),
            ],
          ),
          SizedBox(width: 5.w),

          // Event Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. Upgraded Get Started Dashboard when no child is paired yet
  Widget _buildNoChildCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Onboarding Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFEFF6FF)],
            ),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: const Color(0xFFCFE2FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // 3D KidShield Junior Emblem
              Container(
                width: 82.r,
                height: 82.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(3.r),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/animated_logo.gif',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/Animated Safe Zone Protection Storyboard.gif',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Image.asset(
                        'assets/images/kidshield_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c2, e2, s2) => const Icon(
                          Icons.shield_rounded,
                          size: 48,
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Welcome to KidShield Console',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                'Connect your child\'s phone in 2 simple steps to start real-time GPS tracking, screen time limits, and safety monitoring.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.4,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 16.h),

              // Primary Add Child Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddChildScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: Text(
                    'Add Child Profile & Scan QR',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B52D4),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // 3 Easy Steps Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: const Color(0xFFF59E0B), size: 18.r),
                  SizedBox(width: 6.w),
                  Text(
                    'How to connect in 3 steps',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildSetupStep('1', 'Create Profile', 'Enter your child\'s name, age, and choose boy/girl avatar.'),
              SizedBox(height: 10.h),
              _buildSetupStep('2', 'Open Child App', 'Launch KidShield Junior on the child\'s smartphone.'),
              SizedBox(height: 10.h),
              _buildSetupStep('3', 'Scan QR Code', 'Scan the QR code to pair devices instantly without passwords.'),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Features Showcase 2x2 Grid
        Text(
          'Features available once connected',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFE0F2FE),
                title: 'Live GPS Map',
                desc: 'Real-time street location',
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.access_time_filled_rounded,
                iconColor: const Color(0xFF9333EA),
                iconBg: const Color(0xFFF3E8FF),
                title: 'Screen Time',
                desc: 'Daily limits & bedtimes',
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFDCFCE7),
                title: 'App Shield',
                desc: 'Block addictive apps',
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.emergency_rounded,
                iconColor: const Color(0xFFE11D48),
                iconBg: const Color(0xFFFFE4E6),
                title: '24/7 SOS',
                desc: 'Instant emergency alerts',
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Sync from server footer
        Center(
          child: TextButton.icon(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final childProvider = Provider.of<ChildProvider>(context, listen: false);
              if (authProvider.currentParent != null) {
                childProvider.loadChildren(authProvider.currentParent!.uid);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking server for paired children...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('Already paired? Tap to sync from server'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0284C7),
              textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildSetupStep(String stepNumber, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22.r,
          height: 22.r,
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0284C7),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 18.r)),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    final monitoring = Provider.of<MonitoringProvider>(context, listen: false);
    if (monitoring.hasActiveEmergency) {
      EmergencyAlertModal.show(context, monitoring.activeEmergencyAlert!);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Color(0xFFE11D48), size: 24),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Helpline Services',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Tap any number to dial instantly (24/7)',
                        style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildHelplineRow(context, 'National Emergency Number', '112', Icons.local_police_rounded),
              SizedBox(height: 10.h),
              _buildHelplineRow(context, 'Police Emergency Helpline', '100', Icons.shield_rounded),
              SizedBox(height: 10.h),
              _buildHelplineRow(context, 'Childline India Foundation', '1098', Icons.child_care_rounded),
              SizedBox(height: 10.h),
              _buildHelplineRow(context, 'Women / Child Helpline', '181', Icons.support_agent_rounded),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelplineRow(BuildContext context, String title, String number, IconData icon) {
    final monitoring = Provider.of<MonitoringProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => monitoring.openEmergencyDialer(number),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF0284C7), size: 20.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Toll Free 24/7 • Tap to Call',
                          style: TextStyle(fontSize: 10.sp, color: const Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw stylized map roads and river
class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFEBF3F8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final parkPaint = Paint()..color = const Color(0xFFDCFCE7).withValues(alpha: 0.7);
    canvas.drawRect(Rect.fromLTWH(8, 8, size.width * 0.35, size.height * 0.45), parkPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.65, size.height * 0.55, size.width * 0.3, size.height * 0.4), parkPaint);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.25), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.8), roadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.35, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.8, 0), Offset(size.width * 0.7, size.height), roadPaint);

    final riverPaint = Paint()
      ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.8)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.95);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.75,
      size.width * 0.65,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.15,
      size.width,
      size.height * 0.05,
    );
    canvas.drawPath(path, riverPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter to draw circular radial progress chart
class _RadialProgressPainter extends CustomPainter {
  final double percentage;
  _RadialProgressPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 2.5, bgPaint);

    final fgPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2.5),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialProgressPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
