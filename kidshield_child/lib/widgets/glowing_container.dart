import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class GlowingContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool showGlow;

  const GlowingContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 20.0,
    this.borderColor,
    this.backgroundColor,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.electricCyan.withValues(alpha: 0.6);
    final bg = backgroundColor ?? const Color(0xFF09142E);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius.r),
        border: Border.all(
          color: border,
          width: 1.4,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.electricCyan.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

