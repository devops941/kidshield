import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/child_auth_provider.dart';
import '../../providers/companion_provider.dart';
import '../../widgets/custom_app_bar.dart';

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({super.key});

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
  int _selectedTab = 0; // 0: Today, 1: Week, 2: Month
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<ChildAuthProvider>(context, listen: false);
    final companion = Provider.of<CompanionProvider>(context, listen: false);
    await companion.refreshAppUsage(auth.currentProfile?.id);
    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildAppIcon(String iconBase64, String appName, {double size = 42}) {
    if (iconBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(iconBase64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.memory(
            bytes,
            width: size.r,
            height: size.r,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(appName, size),
          ),
        );
      } catch (_) {}
    }
    return _buildFallbackIcon(appName, size);
  }

  Widget _buildFallbackIcon(String appName, double size) {
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        color: AppColors.electricCyan.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.electricCyan.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          appName.isNotEmpty ? appName[0].toUpperCase() : 'A',
          style: TextStyle(
            fontSize: (size * 0.42).sp,
            fontWeight: FontWeight.bold,
            color: AppColors.electricCyan,
          ),
        ),
      ),
    );
  }

  String _getCategory(String packageName, String appName) {
    final p = packageName.toLowerCase();
    final n = appName.toLowerCase();
    if (p.contains('shop') || n.contains('shop') || p.contains('amazon') || p.contains('flipkart')) return 'Shopping';
    if (p.contains('youtube') || p.contains('netflix') || p.contains('prime') || p.contains('hotstar') || p.contains('spotify') || p.contains('music')) return 'Entertainment';
    if (p.contains('whatsapp') || p.contains('instagram') || p.contains('facebook') || p.contains('telegram') || p.contains('twitter') || p.contains('social')) return 'Social';
    if (p.contains('chrome') || p.contains('browser') || p.contains('firefox') || p.contains('opera')) return 'Browser';
    if (p.contains('tutor') || n.contains('tutor') || p.contains('study') || p.contains('school') || p.contains('learn')) return 'Education';
    if (p.contains('game') || n.contains('game') || p.contains('play') || p.contains('freefire') || p.contains('pubg')) return 'Games';
    if (p.contains('camera') || p.contains('gallery') || p.contains('photo')) return 'Photos & Media';
    if (p.contains('sec.android') || p.contains('samsung') || p.contains('system') || p.contains('setting')) return 'System Utility';
    if (p.contains('kidshield')) return 'KidShield Safe App';
    return 'Utility';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<ChildAuthProvider>(context);
    final companion = Provider.of<CompanionProvider>(context);
    final child = auth.currentProfile;

    // Calculate metrics based on selected Tab
    int usedMinutes = companion.screenTimeMinutesToday;
    int limitMinutes = child?.dailyScreenTimeLimitMinutes ?? 180;
    String periodTitle = "Today's Screen Time";
    String minuteKey = 'usageMinutesToday';
    List<Map<String, dynamic>> activeApps = companion.todayApps;

    if (_selectedTab == 1) {
      usedMinutes = companion.screenTimeMinutesWeekly;
      limitMinutes = (child?.dailyScreenTimeLimitMinutes ?? 180) * 7;
      periodTitle = "This Week's Screen Time";
      minuteKey = 'usageMinutesWeekly';
      activeApps = companion.weeklyApps;
    } else if (_selectedTab == 2) {
      usedMinutes = companion.screenTimeMinutesMonthly;
      limitMinutes = (child?.dailyScreenTimeLimitMinutes ?? 180) * 30;
      periodTitle = "This Month's Screen Time";
      minuteKey = 'usageMinutesMonthly';
      activeApps = companion.monthlyApps;
    }

    final hours = (usedMinutes / 60).floor();
    final mins = usedMinutes % 60;
    final progress = limitMinutes > 0 ? (usedMinutes / limitMinutes).clamp(0.0, 1.0) : 0.0;
    final limitHours = (limitMinutes / 60).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const CustomAppBar(title: 'App Usage & Screen Time'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.navyBackgroundGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.electricCyan,
            backgroundColor: const Color(0xFF09142E),
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Switcher (Today / Week / Month)
                  Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07122C),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.electricCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(0, 'Today'),
                        _buildTabButton(1, 'This Week'),
                        _buildTabButton(2, 'This Month'),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Hero Screen Time Card
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF09142E),
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                        color: AppColors.electricCyan.withValues(alpha: 0.5),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                periodTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: progress > 0.85
                                    ? AppColors.sosRed.withValues(alpha: 0.15)
                                    : AppColors.mintGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: progress > 0.85
                                      ? AppColors.sosRed.withValues(alpha: 0.4)
                                      : AppColors.mintGreen.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                progress > 0.85 ? 'High Usage' : 'Healthy Pace',
                                style: TextStyle(
                                  color: progress > 0.85 ? AppColors.sosRed : AppColors.mintGreen,
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Large Numbers - Responsive & Overflow-proof
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${hours}h ${mins}m',
                                style: TextStyle(
                                  fontSize: 30.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: AppColors.electricCyan,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '/ ${limitHours}h limit',
                                style: TextStyle(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10.h,
                            backgroundColor: const Color(0xFF040A18),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress > 0.85 ? AppColors.sosRed : AppColors.electricCyan,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),

                        Text(
                          'Live telemetry fetched directly from this Android device.',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22.h),

                  // Section Title: Apps List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTab == 0
                            ? 'Top Apps Used Today'
                            : (_selectedTab == 1 ? 'Top Apps This Week' : 'Top Apps This Month'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '${activeApps.length} Apps',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.electricCyan,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // App Usage List or Empty State
                  if (_isLoading) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.h),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.electricCyan),
                      ),
                    ),
                  ] else if (activeApps.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFF09142E),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: AppColors.electricCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.hourglass_empty_rounded,
                            color: AppColors.electricCyan,
                            size: 38.r,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'No App Usage Recorded',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'App usage metrics will appear here once device apps are launched and used.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...activeApps.map((app) {
                      final appMinutes = (app[minuteKey] as int?) ?? 0;
                      final appHours = (appMinutes / 60).floor();
                      final appMinsRemainder = appMinutes % 60;
                      final timeStr = appHours > 0
                          ? '${appHours}h ${appMinsRemainder}m'
                          : '$appMinsRemainder min';

                      return Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF09142E),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: AppColors.electricCyan.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildAppIcon(app['icon']?.toString() ?? '', app['appName']?.toString() ?? '', size: 40),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app['appName']?.toString() ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    _getCategory(app['packageName']?.toString() ?? '', app['appName']?.toString() ?? ''),
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.electricCyan,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.electricCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.textDarkNavy : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
