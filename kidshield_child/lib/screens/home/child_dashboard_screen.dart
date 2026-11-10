import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/child_auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/companion_provider.dart';
import '../../widgets/status_chip.dart';
import 'companion_calculator_screen.dart';
import 'sos_screen.dart';
import 'location_screen.dart';
import 'app_usage_screen.dart';
import 'notifications_screen.dart';
import '../settings/settings_screen.dart';

class ChildDashboardScreen extends StatelessWidget {
  const ChildDashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<ChildAuthProvider>(context);
    final location = Provider.of<LocationProvider>(context);
    final companion = Provider.of<CompanionProvider>(context);

    final child = auth.currentProfile;
    if (child != null && child.id.isNotEmpty && location.activeChildId != child.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        location.setActiveChildId(child.id);
        companion.refreshAppUsage(child.id);
      });
    } else if (companion.screenTimeMinutesToday == 0 && child != null && child.id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        companion.refreshAppUsage(child.id);
      });
    }

    final childName = (child != null && child.name.isNotEmpty) ? child.name : 'Child';
    final initial = childName.isNotEmpty ? childName[0].toUpperCase() : 'C';

    final usedMinutes = companion.screenTimeMinutesToday;
    final limitMinutes = child?.dailyScreenTimeLimitMinutes ?? 180;
    final usedHours = (usedMinutes / 60).floor();
    final usedMinsRemainder = usedMinutes % 60;
    final limitHours = (limitMinutes / 60).toStringAsFixed(1);
    final progress = (usedMinutes / limitMinutes).clamp(0.0, 1.0);
    final remainingMinutes = (limitMinutes - usedMinutes).clamp(0, limitMinutes);
    final remHours = (remainingMinutes / 60).floor();
    final remMins = remainingMinutes % 60;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.navyBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= TOP HEADER PROFILE BAR =================
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09142E),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: AppColors.electricCyan.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricCyan.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar with glowing cyan ring
                      Container(
                        padding: EdgeInsets.all(2.5.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.electricCyan, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.electricCyan.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 20.r,
                          backgroundColor: const Color(0xFF061026),
                          backgroundImage: AssetImage(
                            (child != null && child.isGirl)
                                ? 'assets/images/girl_illustration.png'
                                : 'assets/images/child_illustration.png',
                          ),
                          onBackgroundImageError: (exception, stackTrace) {},
                          child: (child == null)
                              ? Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.electricCyan,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // Greeting & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()}, $childName! 👋',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Container(
                                  width: 7.r,
                                  height: 7.r,
                                  decoration: const BoxDecoration(
                                    color: AppColors.mintGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: Text(
                                    'Connected to Parent Console',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mintGreen,
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

                      // Notification Action
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.notifications_none_rounded, color: AppColors.electricCyan, size: 22.r),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                      ),

                      // Settings Action
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.settings_outlined, color: Colors.white, size: 20.r),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // ================= LIVE TELEMETRY CHIPS ROW =================
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LocationScreen()),
                          );
                        },
                        child: StatusChip(
                          label: location.isSharingEnabled ? 'GPS Active' : 'GPS Paused',
                          isActive: location.isSharingEnabled,
                          icon: Icons.location_on_rounded,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      const StatusChip(
                        label: 'Safety Guard On',
                        isActive: true,
                        icon: Icons.shield_rounded,
                      ),
                      SizedBox(width: 8.w),
                      StatusChip(
                        label: '${location.batteryLevel}% Battery',
                        isActive: location.batteryLevel > 20,
                        icon: Icons.battery_charging_full_rounded,
                      ),
                      SizedBox(width: 8.w),
                      const StatusChip(
                        label: 'Live Synced',
                        isActive: true,
                        icon: Icons.cloud_done_rounded,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // ================= EMERGENCY SOS HIGHLIGHT CARD =================
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    gradient: AppColors.sosGradient,
                    borderRadius: BorderRadius.circular(22.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sosRed.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.sos_rounded, color: Colors.white, size: 26.r),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emergency SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Feel unsafe? Tap to send an instant alert & location to parent.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11.5.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        height: 40.h,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SosScreen()),
                            );
                          },
                          icon: Icon(Icons.warning_amber_rounded, color: AppColors.sosRedDark, size: 18.r),
                          label: Text(
                            'HOLD FOR EMERGENCY SOS',
                            style: TextStyle(
                              color: AppColors.sosRedDark,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // ================= QUICK ACTIONS TILES ROW =================
                Row(
                  children: [
                    _buildQuickActionCard(
                      context: context,
                      title: 'Location',
                      subtitle: 'Live Map',
                      icon: Icons.map_rounded,
                      color: AppColors.electricCyan,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationScreen())),
                    ),
                    SizedBox(width: 10.w),
                    _buildQuickActionCard(
                      context: context,
                      title: 'App Usage',
                      subtitle: 'Screen Time',
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.mintGreen,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppUsageScreen())),
                    ),
                    SizedBox(width: 10.w),
                    _buildQuickActionCard(
                      context: context,
                      title: 'Math Hub',
                      subtitle: 'Calculator',
                      icon: Icons.calculate_rounded,
                      color: const Color(0xFF818CF8),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanionCalculatorScreen())),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // ================= TODAY'S SCREEN TIME CARD =================
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AppUsageScreen()));
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF09142E),
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                        color: AppColors.electricCyan.withValues(alpha: 0.5),
                        width: 1.4,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Screen Time",
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Large Numbers
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${usedHours}h ${usedMinsRemainder}m',
                                style: TextStyle(
                                  fontSize: 30.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: AppColors.electricCyan,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '/ ${limitHours}h parent limit',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8.h,
                            backgroundColor: const Color(0xFF040A18),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress > 0.85 ? AppColors.sosRed : AppColors.electricCyan,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),

                        Text(
                          '⏳ ${remHours}h ${remMins}m remaining today',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // ================= FAMILY ROUTINE & SCHEDULES CARD =================
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09142E),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: AppColors.electricCyan.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Family Routine & Schedules',
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Study Mode Schedule
                      _buildScheduleRow(
                        icon: Icons.menu_book_rounded,
                        title: 'Study & Homework Mode',
                        time: child != null && child.studyTimeStart.isNotEmpty && child.studyTimeEnd.isNotEmpty
                            ? _formatScheduleRange(child.studyTimeStart, child.studyTimeEnd)
                            : 'Not Scheduled',
                        accentColor: AppColors.electricCyan,
                      ),
                      SizedBox(height: 8.h),

                      // Bedtime Schedule
                      _buildScheduleRow(
                        icon: Icons.bedtime_rounded,
                        title: 'Night Bedtime Mode',
                        time: child != null && child.bedtimeStart.isNotEmpty && child.bedtimeEnd.isNotEmpty
                            ? _formatScheduleRange(child.bedtimeStart, child.bedtimeEnd)
                            : 'Not Scheduled',
                        accentColor: const Color(0xFF818CF8),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // ================= DIGITAL SAFETY TIP =================
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF071536),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.mintGreen.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: AppColors.mintGreen, size: 20.r),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Safety Tip: Always verify with your parents before installing new apps or accepting unknown friend requests.',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: AppColors.mintGreen,
                            height: 1.3,
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
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: const Color(0xFF09142E),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24.r),
              SizedBox(height: 6.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _format24to12(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '';
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final int minute = int.parse(parts[1]);
        final String period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour == 0) hour = 12;
        final minStr = minute.toString().padLeft(2, '0');
        return '$hour:$minStr $period';
      }
    } catch (_) {}
    return timeStr;
  }

  String _formatScheduleRange(String? start, String? end) {
    if (start == null || end == null || start.isEmpty || end.isEmpty) {
      return 'Not Scheduled';
    }
    final formattedStart = _format24to12(start);
    final formattedEnd = _format24to12(end);
    return '$formattedStart - $formattedEnd';
  }

  Widget _buildScheduleRow({
    required IconData icon,
    required String title,
    required String time,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF050D22),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 18.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
