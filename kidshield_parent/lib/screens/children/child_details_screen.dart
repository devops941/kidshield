import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/child_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/battery_indicator.dart';
import '../../widgets/status_badge.dart';
import '../restrictions/parental_restrictions_screen.dart';
import 'pair_device_screen.dart';

class ChildDetailsScreen extends StatelessWidget {
  final ChildModel child;

  const ChildDetailsScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final childProvider = Provider.of<ChildProvider>(context);
    final monitoringProvider = Provider.of<MonitoringProvider>(context);

    // Get live updated child instance from provider (to reflect phone edits immediately)
    final currentChild = childProvider.children.firstWhere(
      (c) => c.id == child.id || (c.pairingCode.isNotEmpty && c.pairingCode == child.pairingCode),
      orElse: () => child,
    );

    final loc = monitoringProvider.currentLocation;
    final int liveBattery = (loc != null && loc.batteryAtLocation > 0)
        ? loc.batteryAtLocation
        : (currentChild.batteryLevel > 0 && currentChild.batteryLevel != 100
            ? currentChild.batteryLevel
            : (loc?.batteryAtLocation ?? (currentChild.batteryLevel > 0 ? currentChild.batteryLevel : 85)));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('${currentChild.name}\'s Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PairDeviceScreen(child: currentChild)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child Profile Card
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyDark.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.royalBlue,
                      backgroundImage: AssetImage(
                        currentChild.isGirl
                            ? 'assets/images/girl_illustration.png'
                            : 'assets/images/child_illustration.png',
                      ),
                      onBackgroundImageError: (exception, stackTrace) {},
                      child: currentChild.name.isEmpty
                          ? Text(
                              'C',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentChild.name,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${currentChild.age} Years Old • ${currentChild.deviceName ?? "Android Device"}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              StatusBadge(isOnline: currentChild.isOnline),
                              SizedBox(width: 8.w),
                              BatteryIndicator(
                                percentage: liveBattery,
                                isCharging: currentChild.isCharging,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Permissions Status Section
              Text(
                'Android Permissions & Safety Status',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                ),
              ),
              SizedBox(height: 12.h),

              _buildPermissionTile(
                title: 'GPS Location Permission',
                subtitle: currentChild.locationPermissionEnabled
                    ? 'Active and sharing location with parent console.'
                    : 'Permission disabled. Location updates are paused.',
                isEnabled: currentChild.locationPermissionEnabled,
                icon: Icons.location_on_rounded,
                isDark: isDark,
              ),
              SizedBox(height: 10.h),

              _buildPermissionTile(
                title: 'Android Usage Access',
                subtitle: currentChild.usagePermissionEnabled
                    ? 'Granted transparently by device user.'
                    : 'Access pending. Screen time stats unavailable.',
                isEnabled: currentChild.usagePermissionEnabled,
                icon: Icons.bar_chart_rounded,
                isDark: isDark,
              ),
              SizedBox(height: 10.h),

              _buildPermissionTile(
                title: 'Device Administration / Protection',
                subtitle: currentChild.isPaired
                    ? 'Parent pairing authorized via secure handshake.'
                    : 'Device not yet paired with KidShield Junior.',
                isEnabled: currentChild.isPaired,
                icon: Icons.security_rounded,
                isDark: isDark,
              ),
              SizedBox(height: 24.h),

              // Device Details Card
              Container(
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Pairing Code', currentChild.pairingCode, isDark),
                    const Divider(height: 24),
                    _buildInfoRow('Device Model', currentChild.deviceName ?? 'Android Phone', isDark),
                    const Divider(height: 24),
                    _buildPhoneInfoRow(
                      context: context,
                      child: currentChild,
                      isDark: isDark,
                      monitoring: monitoringProvider,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Last Active',
                      DateFormat('MMM d, h:mm a').format(currentChild.lastActive),
                      isDark,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Daily Limit',
                      '${(currentChild.dailyScreenTimeLimitMinutes / 60).toStringAsFixed(1)} hours',
                      isDark,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Safety Controls & Screen Limits Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ParentalRestrictionsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  label: const Text(
                    'Safety Controls & Bedtime Rules',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Delete / Disconnect Child
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove Child Device?'),
                        content: Text(
                          'Are you sure you want to disconnect ${child.name}? This will stop location tracking and screen time synchronization.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await childProvider.removeChild(child.id);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Remove Device'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  label: const Text('Disconnect & Remove Child', style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isEnabled,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: (isEnabled ? AppColors.success : AppColors.danger).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: isEnabled ? AppColors.success : AppColors.danger,
              size: 22.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInfoRow({
    required BuildContext context,
    required ChildModel child,
    required bool isDark,
    required MonitoringProvider monitoring,
  }) {
    final hasPhone = child.phoneNumber.trim().isNotEmpty;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.navyDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Child Mobile Number',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: textMuted,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                hasPhone ? 'Emergency SOS direct dial' : 'Tap to add emergency number',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: textMuted.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        InkWell(
          onTap: () => _showEditPhoneDialog(context, child),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: hasPhone
                  ? AppColors.royalBlue.withValues(alpha: isDark ? 0.2 : 0.08)
                  : AppColors.royalBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppColors.royalBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_android_rounded,
                  size: 14.r,
                  color: AppColors.royalBlue,
                ),
                SizedBox(width: 6.w),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 120.w),
                  child: Text(
                    hasPhone ? child.phoneNumber : 'Add Number',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: hasPhone ? textPrimary : AppColors.royalBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 5.w),
                Icon(
                  hasPhone ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                  size: 13.r,
                  color: AppColors.royalBlue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditPhoneDialog(BuildContext context, ChildModel targetChild) {
    final phoneController = TextEditingController(text: targetChild.phoneNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        titlePadding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: const Icon(Icons.phone_android_rounded, color: AppColors.royalBlue, size: 20),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                '${targetChild.name}\'s Phone Number',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.navyDark,
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
                'Enter the SIM / mobile number of your child\'s smartphone. This enables 1-tap direct calling during Emergency SOS distress alerts.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  height: 1.35,
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.navyDark,
                ),
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'e.g. +91 98765 43210',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.royalBlue),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            ),
            onPressed: () async {
              final newPhone = phoneController.text.trim();
              Navigator.of(ctx).pop();
              final provider = Provider.of<ChildProvider>(context, listen: false);
              final success = await provider.updateChild(
                targetChild.id,
                phoneNumber: newPhone,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Phone number updated for ${targetChild.name}'
                          : 'Failed to update phone number',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Save Number', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
          ),
        ),
        SizedBox(width: 12.w),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
