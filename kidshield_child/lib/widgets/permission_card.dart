import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class PermissionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final String? assetIcon;
  final bool isGranted;
  final ValueChanged<bool> onToggle;

  const PermissionCard({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.assetIcon,
    required this.isGranted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF09142E),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isGranted
              ? AppColors.electricCyan.withValues(alpha: 0.75)
              : AppColors.electricCyan.withValues(alpha: 0.3),
          width: 1.4,
        ),
        boxShadow: isGranted
            ? [
                BoxShadow(
                  color: AppColors.electricCyan.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // High-Visibility Glowing Icon Container
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00F0FF).withValues(alpha: 0.18),
                  const Color(0xFF0369A1).withValues(alpha: 0.28),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppColors.electricCyan.withValues(alpha: 0.6),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricCyan.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      color: AppColors.electricCyan,
                      size: 26.r,
                    )
                  : (assetIcon != null
                      ? Image.asset(assetIcon!, width: 28.r, height: 28.r)
                      : Icon(
                          Icons.shield_rounded,
                          color: AppColors.electricCyan,
                          size: 26.r,
                        )),
            ),
          ),
          SizedBox(width: 14.w),

          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Mint Green Switch Toggle
          Transform.scale(
            scale: 0.88,
            child: Switch(
              value: isGranted,
              onChanged: onToggle,
              activeTrackColor: AppColors.mintGreen,
              activeThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF1E293B),
              inactiveThumbColor: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
