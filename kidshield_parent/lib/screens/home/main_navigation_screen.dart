import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/emergency_alert_modal.dart';
import 'dashboard_screen.dart';
import '../apps/app_usage_screen.dart';
import '../location/live_location_screen.dart';
import 'notifications_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  Timer? _emergencyPollingTimer;
  String? _displayedAlertId;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AppUsageScreen(),
    LiveLocationScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      final monitoringProvider = Provider.of<MonitoringProvider>(context, listen: false);
      if (authProvider.currentParent != null) {
        await childProvider.loadChildren(authProvider.currentParent!.uid);
      }
      if (childProvider.selectedChild != null) {
        await monitoringProvider.loadChildData(childProvider.selectedChild!.id);
      }
    });

    // Auto-poll notifications every 12 seconds to instantly detect Child SOS
    _emergencyPollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      final monitoringProvider = Provider.of<MonitoringProvider>(context, listen: false);
      final child = childProvider.selectedChild;
      if (child != null && mounted) {
        monitoringProvider.loadChildData(child.id, silent: true);
      }
    });
  }

  @override
  void dispose() {
    _emergencyPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitoringProvider = Provider.of<MonitoringProvider>(context);
    final unreadCount = monitoringProvider.unreadNotificationsCount;

    // Detect Active Child SOS Emergency Alert
    final activeAlert = monitoringProvider.activeEmergencyAlert;
    if (activeAlert != null && _displayedAlertId != activeAlert.id) {
      _displayedAlertId = activeAlert.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          EmergencyAlertModal.show(context, activeAlert).then((_) {
            _displayedAlertId = null;
          });
        }
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF060D24),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Dashboard', isGlow: true),
                _buildNavItem(1, Icons.bar_chart_rounded, 'Reports'),
                _buildNavItem(2, Icons.location_on_rounded, 'Location', isGlow: true),
                _buildNavItem(3, Icons.notifications_rounded, 'Notifications', badgeCount: unreadCount > 0 ? unreadCount : null),
                _buildNavItem(4, Icons.more_horiz_rounded, 'More'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isGlow = false, int? badgeCount}) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 21.r,
                  color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: EdgeInsets.all(2.5.r),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 14.r, minHeight: 14.r),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 3.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8),
                ),
                maxLines: 1,
              ),
            ),
            SizedBox(height: 2.h),
            if (isSelected)
              Container(
                width: 14.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  borderRadius: BorderRadius.circular(2.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                      blurRadius: 4,
                    ),
                  ],
                ),
              )
            else
              SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
