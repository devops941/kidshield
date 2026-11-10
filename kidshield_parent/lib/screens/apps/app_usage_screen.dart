import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/app_usage_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../services/monitoring_service.dart';
import '../../widgets/usage_chart.dart';
import '../../widgets/empty_state.dart';

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({super.key});

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 0; // 0: Today, 1: This Week, 2: This Month

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(silent: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData({bool silent = false}) async {
    final child = context.read<ChildProvider>().selectedChild;
    if (child != null) {
      await context.read<MonitoringProvider>().loadChildData(child.id, silent: silent);
    }
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
        color: AppColors.royalBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Center(
        child: Text(
          appName.isNotEmpty ? appName[0].toUpperCase() : 'A',
          style: TextStyle(
            fontSize: (size * 0.42).sp,
            fontWeight: FontWeight.bold,
            color: AppColors.royalBlue,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final childProvider = Provider.of<ChildProvider>(context);
    final monitoringProvider = Provider.of<MonitoringProvider>(context);

    final selectedChild = childProvider.selectedChild;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('App Activity & Safety'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh real telemetry',
            onPressed: () async {
              await _refreshData(silent: false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Synced latest device activity from child phone'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.royalBlue,
          unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          indicatorColor: AppColors.royalBlue,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
          unselectedLabelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Screen Time'),
            Tab(text: 'Installed Apps'),
          ],
        ),
      ),
      body: selectedChild == null
          ? const EmptyState(
              icon: Icons.person_off_rounded,
              title: 'No Child Selected',
              message: 'Please add or select a child profile to view app activity.',
            )
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () => _refreshData(silent: true),
                  color: AppColors.royalBlue,
                  child: _buildUsageTab(selectedChild, monitoringProvider, isDark),
                ),
                RefreshIndicator(
                  onRefresh: () => _refreshData(silent: true),
                  color: AppColors.royalBlue,
                  child: _buildInstalledAppsTab(selectedChild, monitoringProvider, isDark),
                ),
              ],
            ),
    );
  }

  Widget _buildPeriodPill(int index, String label, bool isDark) {
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.royalBlue
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.royalBlue
                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textPrimaryDark : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageTab(
    dynamic selectedChild,
    MonitoringProvider monitoringProvider,
    bool isDark,
  ) {
    int totalMinutes = 0;
    String periodTitle = 'Total Screen Time Today';
    String limitText = 'Allowed Daily Limit: ${(selectedChild.dailyScreenTimeLimitMinutes / 60).toStringAsFixed(1)} hours';

    List<AppUsageModel> appsList = monitoringProvider.appUsage
        .where((a) => !MonitoringService.isExcludedApp(a.packageName, a.appName))
        .toList();

    List<double> chartValues;
    List<String> chartLabels;
    String chartTitle;
    String chartSubtitle;
    String chartBadge;
    String chartLimitLabel;
    double chartLimitMinutes;

    if (_selectedPeriod == 0) {
      // TODAY
      totalMinutes = monitoringProvider.totalScreenTimeMinutesToday;
      periodTitle = 'Total Screen Time Today';
      limitText = 'Allowed Daily Limit: ${(selectedChild.dailyScreenTimeLimitMinutes / 60).toStringAsFixed(1)} hours';
      chartTitle = "Today's Usage Timeline";
      chartSubtitle = 'Hourly screen time distribution today';
      chartBadge = 'Today';
      chartLabels = const ['6 AM', '9 AM', '12 PM', '3 PM', '6 PM', '9 PM'];
      chartValues = monitoringProvider.todayHourlyMinutes;
      chartLimitMinutes = 0.0;
      chartLimitLabel = '';
      appsList = appsList.where((a) => a.usageMinutesToday > 0).toList();
      appsList.sort((a, b) => b.usageMinutesToday.compareTo(a.usageMinutesToday));
    } else if (_selectedPeriod == 1) {
      // THIS WEEK
      totalMinutes = monitoringProvider.totalScreenTimeMinutesWeekly;
      periodTitle = 'Total Screen Time This Week';
      limitText = 'Weekly Limit: ${((selectedChild.dailyScreenTimeLimitMinutes * 7) / 60).toStringAsFixed(1)} hours';
      chartTitle = 'Daily Screen Time Breakdown';
      chartSubtitle = 'Daily real usage compared with parental daily limit';
      chartBadge = 'Mon - Sun';
      chartLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      chartValues = monitoringProvider.weeklyScreenTimeMinutes;
      chartLimitMinutes = selectedChild.dailyScreenTimeLimitMinutes.toDouble();
      chartLimitLabel = 'Daily Limit ${(chartLimitMinutes / 60).toStringAsFixed(1)}h';
      appsList = appsList.where((a) => a.usageMinutesWeekly > 0).toList();
      appsList.sort((a, b) => b.usageMinutesWeekly.compareTo(a.usageMinutesWeekly));
    } else {
      // THIS MONTH
      totalMinutes = monitoringProvider.totalScreenTimeMinutesMonthly;
      periodTitle = 'Total Screen Time This Month';
      limitText = 'Monthly Active Usage';
      chartTitle = 'Monthly Screen Time Breakdown';
      chartSubtitle = 'Week-by-week screen time distribution this month';
      chartBadge = '4 Weeks';
      chartLabels = const ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      chartValues = monitoringProvider.monthlyWeeksScreenTimeMinutes;
      chartLimitMinutes = (selectedChild.dailyScreenTimeLimitMinutes * 7).toDouble();
      chartLimitLabel = 'Weekly Limit ${(chartLimitMinutes / 60).toStringAsFixed(1)}h';
      appsList = appsList.where((a) => a.usageMinutesMonthly > 0).toList();
      appsList.sort((a, b) => b.usageMinutesMonthly.compareTo(a.usageMinutesMonthly));
    }

    final totalHours = (totalMinutes / 60).floor();
    final remainingMinutes = totalMinutes % 60;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector: Today | This Week | This Month
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPeriodPill(0, 'Today', isDark),
              SizedBox(width: 8.w),
              _buildPeriodPill(1, 'This Week', isDark),
              SizedBox(width: 8.w),
              _buildPeriodPill(2, 'This Month', isDark),
            ],
          ),
          SizedBox(height: 14.h),

          // Total Usage Highlight Card
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodTitle,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '${totalHours}h ${remainingMinutes}m',
                        style: TextStyle(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        limitText,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 32.r),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Dynamic Chart Card (Hourly Today | Daily Week | Weekly Month)
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
                  children: [
                    Expanded(
                      child: Text(
                        chartTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        chartBadge,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  chartSubtitle,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 18.h),
                UsageChart(
                  labels: chartLabels,
                  values: chartValues,
                  customLimitMinutes: chartLimitMinutes,
                  limitLabel: chartLimitLabel,
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),

          // All Apps Usage Breakdown Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'App-wise Breakdown',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                ),
              ),
              Text(
                '${appsList.length} applications',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          if (appsList.isEmpty)
            Container(
              padding: EdgeInsets.all(24.r),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Text(
                'No app usage recorded for this period yet',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appsList.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final app = appsList[index];

                int displayMins = app.usageMinutesToday;
                String timeBadgeText;
                if (_selectedPeriod == 0) {
                  final h = displayMins ~/ 60;
                  final m = displayMins % 60;
                  timeBadgeText = h > 0 ? (m > 0 ? '${h}h ${m}m today' : '${h}h today') : '${m}m today';
                } else if (_selectedPeriod == 1) {
                  displayMins = app.usageMinutesWeekly;
                  final h = displayMins ~/ 60;
                  final m = displayMins % 60;
                  timeBadgeText = h > 0 ? '${h}h ${m}m/wk' : '${m}m/wk';
                } else {
                  displayMins = app.usageMinutesMonthly;
                  final h = displayMins ~/ 60;
                  final m = displayMins % 60;
                  timeBadgeText = h > 0 ? '${h}h ${m}m/mo' : '${m}m/mo';
                }

                final category = _getCategory(app.packageName, app.appName);
                final sharePercent = totalMinutes > 0 ? ((displayMins / totalMinutes) * 100).round() : 0;
                
                String subtitleLeft;
                if (_selectedPeriod == 0) {
                  subtitleLeft = app.launchCountToday > 0
                      ? '$category • ${app.launchCountToday} launches'
                      : (sharePercent > 0 ? '$category • $sharePercent% of usage' : '$category • Active today');
                } else if (_selectedPeriod == 1) {
                  subtitleLeft = sharePercent > 0 ? '$category • $sharePercent% of week' : '$category • Weekly active';
                } else {
                  subtitleLeft = sharePercent > 0 ? '$category • $sharePercent% of month' : '$category • Monthly active';
                }

                return Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildAppIcon(app.icon, app.appName, size: 42),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    app.appName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    timeBadgeText,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.royalBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subtitleLeft,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  app.isRestricted
                                      ? 'Restricted'
                                      : DateFormat('h:mm a').format(app.lastUsed),
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: app.isRestricted
                                        ? AppColors.danger
                                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildInstalledAppsTab(
    dynamic selectedChild,
    MonitoringProvider monitoringProvider,
    bool isDark,
  ) {
    final installedApps = monitoringProvider.installedApps;
    // Only show newly installed apps that actually require parent approval
    final pendingApprovalApps = installedApps.where((a) => a.isNewlyInstalled && !a.isParentApproved).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Newly Installed Apps Needing Attention Card (Only for genuine new installations)
          if (pendingApprovalApps.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notification_important_rounded, color: const Color(0xFFB45309), size: 20.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'New App Install Requests (${pendingApprovalApps.length})',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'These new apps are blocked on your child\'s phone until you approve them.',
                    style: TextStyle(fontSize: 11.sp, color: const Color(0xFF78350F)),
                  ),
                  SizedBox(height: 10.h),
                  ...pendingApprovalApps.map((app) {
                    return Container(
                      margin: EdgeInsets.only(top: 8.h),
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildAppIcon(app.icon, app.appName, size: 36),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${_getCategory(app.packageName, app.appName)} • Newly Installed',
                                  style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6.w),
                          // Reject / Block Button
                          OutlinedButton(
                            onPressed: () async {
                              await monitoringProvider.rejectApp(selectedChild.id, app.packageName);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Disallowed and blocked ${app.appName}')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                            child: Text('Block', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 6.w),
                          // Approve Button
                          ElevatedButton(
                            onPressed: () async {
                              await monitoringProvider.approveApp(selectedChild.id, app.packageName);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Approved ${app.appName} for child use')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                            child: Text('Approve', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Installed Applications (${installedApps.length})',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh Installed Apps',
                onPressed: () => _refreshData(silent: false),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          if (installedApps.isEmpty)
            Container(
              padding: EdgeInsets.all(24.r),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Text(
                'No installed apps synced from device yet.\nEnsure child device is online and permissions are granted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: installedApps.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final app = installedApps[index];

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildAppIcon(app.icon, app.appName, size: 40),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    _getCategory(app.packageName, app.appName),
                                    style: TextStyle(
                                      fontSize: 9.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.royalBlue,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    'v${app.versionName} • Installed ${DateFormat('MMM d, yyyy').format(app.installedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Block / Allow status & toggle
                      InkWell(
                        onTap: () async {
                          final newStatus = !app.isBlocked;
                          await monitoringProvider.toggleAppBlock(selectedChild.id, app.packageName, newStatus);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(newStatus ? 'Blocked ${app.appName}' : 'Unblocked ${app.appName}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: app.isBlocked
                                ? AppColors.danger.withValues(alpha: 0.12)
                                : AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: app.isBlocked ? AppColors.danger : AppColors.success,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                app.isBlocked ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                size: 14.r,
                                color: app.isBlocked ? AppColors.danger : AppColors.success,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                app.isBlocked ? 'Blocked' : 'Allowed',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: app.isBlocked ? AppColors.danger : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
