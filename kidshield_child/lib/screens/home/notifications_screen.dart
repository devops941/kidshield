import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/child_auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    final auth = Provider.of<ChildAuthProvider>(context, listen: false);
    final childId = auth.currentProfile?.id ?? '';
    if (childId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final list = await _apiService.getChildNotifications(childId);
      if (mounted) {
        setState(() {
          _notices = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const CustomAppBar(title: 'Safety Alerts & Notices'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.navyBackgroundGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.electricCyan,
            backgroundColor: const Color(0xFF09142E),
            onRefresh: _loadNotices,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.electricCyan),
                  )
                : _notices.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        itemCount: _notices.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final item = _notices[index];
                          final type = item['type']?.toString() ?? 'general';
                          final title = item['title']?.toString() ?? 'Parent Notice';
                          final message = item['message']?.toString() ?? '';
                          final timeStr = _formatTimestamp(item['timestamp'] ?? item['createdAt']);

                          Color accentColor = AppColors.electricCyan;
                          IconData iconData = Icons.notifications_rounded;

                          if (type == 'appApproved') {
                            accentColor = const Color(0xFF10B981); // Emerald Green
                            iconData = Icons.check_circle_rounded;
                          } else if (type == 'appRejected') {
                            accentColor = const Color(0xFFEF4444); // Red
                            iconData = Icons.block_rounded;
                          } else if (type == 'screenTimeLimit') {
                            accentColor = const Color(0xFFF59E0B); // Amber
                            iconData = Icons.hourglass_top_rounded;
                          }

                          return Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFF09142E),
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Icon(iconData, color: accentColor, size: 22.r),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 13.5.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (timeStr.isNotEmpty)
                                            Text(
                                              timeStr,
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        message,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: const Color(0xFFCBD5E1),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 100.h, horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF09142E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.electricCyan.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 44.r,
                  color: AppColors.electricCyan,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'No Notifications Yet',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Parent app approvals, restrictions, and safety updates will appear here in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
