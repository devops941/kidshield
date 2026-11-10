import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final String? assetIcon;
  final Color? color;
  final bool isOutlined;
  final bool isGlowingCyan;
  final double? height;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.assetIcon,
    this.color,
    this.isOutlined = false,
    this.isGlowingCyan = false,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 48.h;

    // 1. Dark Navy Button with Glowing Cyan Border (Wireframe "Enter Pairing Code" style)
    if (isOutlined) {
      return Container(
        height: effectiveHeight,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF09142E),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.electricCyan.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.electricCyan.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (assetIcon != null) ...[
                        Image.asset(assetIcon!, width: 20.r, height: 20.r),
                        SizedBox(width: 8.w),
                      ] else if (icon != null) ...[
                        Icon(icon, size: 20.r, color: AppColors.electricCyan),
                        SizedBox(width: 8.w),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 2. Glowing Cyan Gradient Button (Wireframe Primary Action style)
    return Container(
      height: effectiveHeight,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        gradient: isGlowingCyan || color == null
            ? AppColors.cyanGlowButtonGradient
            : null,
        color: color,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricCyan.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22.r,
                    height: 22.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textDarkNavy),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (assetIcon != null) ...[
                            Image.asset(assetIcon!, width: 20.r, height: 20.r),
                            SizedBox(width: 8.w),
                          ] else if (icon != null) ...[
                            Icon(icon, size: 20.r, color: AppColors.textDarkNavy),
                            SizedBox(width: 8.w),
                          ],
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDarkNavy,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
