import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/child_auth_provider.dart';
import '../../services/location_sync_service.dart';
import '../../services/pairing_service.dart';
import '../../services/permission_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/permission_card.dart';
import 'setup_complete_screen.dart';

class PermissionsGrantScreen extends StatefulWidget {
  const PermissionsGrantScreen({super.key});

  @override
  State<PermissionsGrantScreen> createState() => _PermissionsGrantScreenState();
}

class _PermissionsGrantScreenState extends State<PermissionsGrantScreen> with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();

  bool _isSyncing = false;
  bool _locationGranted = false;
  bool _usageGranted = false;
  bool _notificationsGranted = false;
  bool _batteryOptGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from Android System Settings or OS dialogs, refresh real statuses
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    final perms = await _permissionService.checkAllPermissions();
    if (!mounted) return;
    setState(() {
      _locationGranted = perms['location'] ?? false;
      _usageGranted = perms['usage'] ?? false;
      _notificationsGranted = perms['notification'] ?? false;
      _batteryOptGranted = perms['batteryOptimization'] ?? false;
    });
  }

  void _showSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF071536),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: AppColors.electricCyan.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        title: Text(
          '$permissionName is Enabled',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'To modify or revoke this permission, please visit the Android System Settings page for KidShield Junior.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.sp,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _permissionService.openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLocationToggle(bool val) async {
    if (val && !_locationGranted) {
      await _permissionService.requestLocationPermission();
      // Allow a brief moment for OS dialog, then re-check
      await Future.delayed(const Duration(milliseconds: 600));
      _refreshPermissions();
    } else if (!val && _locationGranted) {
      _showSettingsDialog('Location Sharing');
    }
  }

  Future<void> _handleUsageToggle(bool val) async {
    if (val && !_usageGranted) {
      await _permissionService.requestUsagePermission();
    } else if (!val && _usageGranted) {
      _showSettingsDialog('Usage Access');
    }
  }

  Future<void> _handleNotificationToggle(bool val) async {
    if (val && !_notificationsGranted) {
      await _permissionService.requestNotificationPermission();
      await Future.delayed(const Duration(milliseconds: 600));
      _refreshPermissions();
    } else if (!val && _notificationsGranted) {
      _showSettingsDialog('Notifications');
    }
  }

  Future<void> _handleBatteryToggle(bool val) async {
    if (val && !_batteryOptGranted) {
      await _permissionService.requestBatteryOptimization();
      await Future.delayed(const Duration(milliseconds: 600));
      _refreshPermissions();
    } else if (!val && _batteryOptGranted) {
      _showSettingsDialog('Battery Optimization');
    }
  }

  Future<void> _onContinue() async {
    setState(() => _isSyncing = true);

    // Get active child ID from Provider or local session
    final auth = Provider.of<ChildAuthProvider>(context, listen: false);
    final childId = auth.currentProfile?.id ?? PairingService.staticProfile?.id ?? '';

    if (childId.isNotEmpty) {
      await _permissionService.syncPermissionsWithBackend(childId);
      LocationSyncService().startNativeForegroundService(childId);
    }

    if (!mounted) return;
    setState(() => _isSyncing = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SetupCompleteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const CustomAppBar(title: 'Safety Settings'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.navyBackgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: 12.h),

                        // Card 1: GPS Location Sharing
                        PermissionCard(
                          title: 'GPS Location Sharing',
                          description: _locationGranted
                              ? 'Active • Real-time location enabled for parents.'
                              : 'Tap to allow location access on this device.',
                          assetIcon: 'assets/icons/gps_location.png',
                          icon: Icons.location_on_rounded,
                          isGranted: _locationGranted,
                          onToggle: _handleLocationToggle,
                        ),

                        // Card 2: Android Usage Access
                        PermissionCard(
                          title: 'Android Usage Access',
                          description: _usageGranted
                              ? 'Active • Screen-time and app activity monitored.'
                              : 'Tap to open Android Usage Settings and allow.',
                          assetIcon: 'assets/icons/app_usage.png',
                          icon: Icons.bar_chart_rounded,
                          isGranted: _usageGranted,
                          onToggle: _handleUsageToggle,
                        ),

                        // Card 3: KIDSHIELD Safety Notifications
                        PermissionCard(
                          title: 'Safety Notifications',
                          description: _notificationsGranted
                              ? 'Active • Parent alerts and safety warnings enabled.'
                              : 'Tap to allow notification alerts on this device.',
                          assetIcon: 'assets/icons/safety_protection.png',
                          icon: Icons.shield_rounded,
                          isGranted: _notificationsGranted,
                          onToggle: _handleNotificationToggle,
                        ),

                        // Card 4: Background Keep-Alive / Battery Optimization
                        PermissionCard(
                          title: 'Background Protection',
                          description: _batteryOptGranted
                              ? 'Active • Android battery restrictions disabled.'
                              : 'Recommended • Prevents Android from killing KidShield.',
                          icon: Icons.battery_charging_full_rounded,
                          isGranted: _batteryOptGranted,
                          onToggle: _handleBatteryToggle,
                        ),
                        SizedBox(height: 14.h),

                        // Info Card
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF071536),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.electricCyan.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.electricCyan,
                                size: 18.r,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  'Permissions are controlled by Android. Toggling switches will trigger official system dialogs or open Settings.',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
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

                // Continue Button to Step 5 (Setup Complete)
                CustomButton(
                  text: _isSyncing ? 'Synchronizing...' : 'Continue',
                  icon: _isSyncing ? null : Icons.arrow_forward_rounded,
                  isGlowingCyan: true,
                  height: 48.h,
                  onPressed: _isSyncing ? () {} : _onContinue,
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
