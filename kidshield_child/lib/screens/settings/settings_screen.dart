import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/child_auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../pairing/welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<ChildAuthProvider>(context);
    final child = auth.currentProfile;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const CustomAppBar(title: 'KidShield Settings'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.navyBackgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            children: [
              // Connection Status Card
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF09142E),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.electricCyan.withValues(alpha: 0.5),
                    width: 1.4,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield_rounded, color: AppColors.mintGreen, size: 28.r),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child?.name ?? 'Child Device',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Paired Code: ${child?.pairingCode ?? "KS-XXXX"}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.electricCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.mintGreen.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Connected',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mintGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Permissions Section
              _buildSectionHeader('Device Permissions'),
              _buildSettingTile(
                icon: Icons.location_on_rounded,
                title: 'Location Permission',
                subtitle: 'Always Allow (Continuous GPS sync)',
                trailing: Icon(Icons.check_circle_rounded, color: AppColors.mintGreen, size: 20.r),
              ),
              _buildSettingTile(
                icon: Icons.bar_chart_rounded,
                title: 'Android Usage Access',
                subtitle: 'Active (Daily screen time tracking)',
                trailing: Icon(Icons.check_circle_rounded, color: AppColors.mintGreen, size: 20.r),
              ),
              _buildSettingTile(
                icon: Icons.notifications_active_rounded,
                title: 'Safety Notifications',
                subtitle: 'Active (Important alerts from parents)',
                trailing: Icon(Icons.check_circle_rounded, color: AppColors.mintGreen, size: 20.r),
              ),
              SizedBox(height: 16.h),

              // About & Support Section
              _buildSectionHeader('About & Support'),
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                subtitle: 'KidShield Junior v1.0.0 (Production Build)',
              ),
              _buildSettingTile(
                icon: Icons.lock_outline_rounded,
                title: 'Child Privacy Policy',
                subtitle: 'End-to-end encrypted telemetry with parents',
              ),
              _buildSettingTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Safety Guide',
                subtitle: 'Tips for staying safe online',
              ),
              SizedBox(height: 24.h),

              // Disconnect Device Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF09142E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        title: const Text('Unlink Child Device?', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Unlinking will stop protection and telemetry sharing with the Parent Console until repaired.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final auth = Provider.of<ChildAuthProvider>(context, listen: false);
                              await auth.unpair();
                              if (!context.mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                                (route) => false,
                              );
                            },
                            child: const Text('Unlink', style: TextStyle(color: AppColors.sosRed)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.link_off_rounded, color: AppColors.sosRed),
                  label: const Text('Unlink / Reset Device Connection', style: TextStyle(color: AppColors.sosRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.sosRed, width: 1.4),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.electricCyan,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF09142E),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.electricCyan.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.electricCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.electricCyan, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

