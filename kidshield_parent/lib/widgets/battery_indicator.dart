import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class BatteryIndicator extends StatelessWidget {
  final int percentage;
  final bool isCharging;
  final bool showLabel;

  const BatteryIndicator({
    super.key,
    required this.percentage,
    this.isCharging = false,
    this.showLabel = true,
  });

  Color get _color {
    if (percentage > 40) return AppColors.success;
    if (percentage > 20) return AppColors.warning;
    return AppColors.danger;
  }

  IconData get _icon {
    if (isCharging) return Icons.battery_charging_full_rounded;
    if (percentage > 85) return Icons.battery_full_rounded;
    if (percentage > 60) return Icons.battery_6_bar_rounded;
    if (percentage > 40) return Icons.battery_4_bar_rounded;
    if (percentage > 20) return Icons.battery_2_bar_rounded;
    if (percentage > 10) return Icons.battery_1_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 16.r),
          if (showLabel) ...[
            SizedBox(width: 4.w),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
