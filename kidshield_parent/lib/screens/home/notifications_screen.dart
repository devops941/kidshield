import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Color _getSeverityColor(NotificationSeverity severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return AppColors.danger;
      case NotificationSeverity.warning:
        return AppColors.warning;
      case NotificationSeverity.info:
        return AppColors.info;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appInstalled:
        return Icons.download_for_offline_rounded;
      case NotificationType.screenTimeLimit:
        return Icons.timer_off_rounded;
      case NotificationType.locationDisabled:
        return Icons.location_off_rounded;
      case NotificationType.deviceOffline:
        return Icons.wifi_off_rounded;
      case NotificationType.lowBattery:
        return Icons.battery_alert_rounded;
      case NotificationType.deviceDisconnected:
        return Icons.phonelink_erase_rounded;
      case NotificationType.sosEmergency:
        return Icons.emergency_rounded;
      case NotificationType.settingsChanged:
        return Icons.settings_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monitoringProvider = Provider.of<MonitoringProvider>(context);
    final notifications = monitoringProvider.notifications;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Safety Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                monitoringProvider.markAllNotificationsAsRead();
              },
              icon: Icon(Icons.done_all_rounded, size: 18.r),
              label: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No Notifications',
              message: 'Everything is peaceful. New alerts about your child\'s device will appear here.',
            )
          : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final color = _getSeverityColor(notif.severity);
                final formattedTime = DateFormat('MMM d, h:mm a').format(notif.timestamp);

                final isAppInstallAlert = notif.type == NotificationType.appInstalled ||
                    (notif.metadata != null && notif.metadata!['requiresApproval'] == true) ||
                    notif.title.toLowerCase().contains('new app installed');
                final packageName = notif.metadata?['packageName']?.toString() ??
                    (notif.title.toLowerCase().contains('instagram') || notif.message.toLowerCase().contains('instagram')
                        ? 'com.instagram.android'
                        : '');
                final appName = notif.metadata?['appName']?.toString() ??
                    (notif.title.contains(':')
                        ? notif.title.split(':').last.trim()
                        : 'New App');

                return Dismissible(
                  key: Key(notif.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.w),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    monitoringProvider.markNotificationAsRead(notif.id);
                  },
                  child: InkWell(
                    onTap: () {
                      if (!notif.isRead) {
                        monitoringProvider.markNotificationAsRead(notif.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: notif.isRead
                            ? (isDark ? AppColors.cardDark : AppColors.cardLight)
                            : (isDark
                                ? AppColors.surfaceDark
                                : AppColors.royalBlue.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: notif.isRead
                              ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                              : AppColors.royalBlue.withValues(alpha: 0.3),
                          width: notif.isRead ? 1 : 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(_getTypeIcon(notif.type), color: color, size: 22.r),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      Container(
                                        width: 8.r,
                                        height: 8.r,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.royalBlue,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  notif.message,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                if (isAppInstallAlert && packageName.isNotEmpty) ...[
                                  Container(
                                    margin: EdgeInsets.only(bottom: 8.h),
                                    padding: EdgeInsets.all(10.r),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF59E0B),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.lock_clock_rounded, size: 16.r, color: const Color(0xFFD97706)),
                                            SizedBox(width: 6.w),
                                            Expanded(
                                              child: Text(
                                                'Locked on device • Approval required',
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8.h),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () async {
                                                  await monitoringProvider.rejectApp(notif.childId, packageName);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Disallowed $appName. It remains blocked on child device.'),
                                                        backgroundColor: AppColors.danger,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.danger,
                                                  side: const BorderSide(color: AppColors.danger),
                                                  padding: EdgeInsets.symmetric(vertical: 6.h),
                                                  minimumSize: Size.zero,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                                ),
                                                child: Text('Reject / Block', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  await monitoringProvider.approveApp(notif.childId, packageName);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Approved $appName! Child can now use it.'),
                                                        backgroundColor: AppColors.success,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.success,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(vertical: 6.h),
                                                  minimumSize: Size.zero,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                                ),
                                                child: Text('Approve App', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Child: ${notif.childName}',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.royalBlue,
                                      ),
                                    ),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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
                  ),
                );
              },
            ),
    );
  }
}
