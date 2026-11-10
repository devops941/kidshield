import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import 'scan_qr_screen.dart';
import 'enter_pairing_code_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.navyBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
            child: Column(
              children: [
                SizedBox(height: 10.h),

                // Top Logo & Brand
                Image.asset(
                  'assets/images/kidshield_logo.png',
                  height: 75.h,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF09142E),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.electricCyan, width: 2),
                    ),
                    child: Icon(Icons.shield_rounded, color: AppColors.electricCyan, size: 40.r),
                  ),
                ),
                SizedBox(height: 8.h),

                // "KIDSHIELD Junior" Header
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                    children: const [
                      TextSpan(text: 'KIDSHIELD '),
                      TextSpan(
                        text: 'Junior',
                        style: TextStyle(color: AppColors.electricCyan),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),

                // Slogan
                Text(
                  'Stay Safe • Learn Smart',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),

                SizedBox(height: 20.h),

                // Center Hero Artwork (The new high-definition illustration)
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: 340.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: AppColors.electricCyan.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricCyan.withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.asset(
                        'assets/images/child_illustration.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF09142E),
                          child: Icon(
                            Icons.sentiment_very_satisfied_rounded,
                            color: AppColors.electricCyan,
                            size: 80.r,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // Invitation Description
                Text(
                  'Your parent has invited you\nto connect with their account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),

                SizedBox(height: 24.h),

                // Button 1: Glowing Cyan Scan Parent QR
                CustomButton(
                  text: 'Scan Parent QR',
                  icon: Icons.qr_code_scanner_rounded,
                  isGlowingCyan: true,
                  height: 48.h,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
                    );
                  },
                ),
                SizedBox(height: 12.h),

                // Button 2: Navy Pill with Cyan Border Enter Pairing Code
                CustomButton(
                  text: 'Enter Pairing Code',
                  icon: Icons.dialpad_rounded,
                  isOutlined: true,
                  height: 48.h,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EnterPairingCodeScreen()),
                    );
                  },
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
