import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/child_auth_provider.dart';
import 'pairing/welcome_screen.dart';
import 'home/child_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final auth = Provider.of<ChildAuthProvider>(context, listen: false);
      if (auth.isPaired) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChildDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // KidShield App Logo
            Image.asset(
              'assets/images/logo.png',
              width: 120.r,
              height: 120.r,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 90.w,
                height: 90.h,
                decoration: BoxDecoration(
                  gradient: AppColors.childGradient,
                  borderRadius: BorderRadius.circular(26.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyanAccent.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shield_rounded,
                  size: 50.r,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'KIDSHIELD',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.softGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.mintGreen.withValues(alpha: 0.4)),
              ),
              child: Text(
                'JUNIOR COMPANION',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.mintGreen,
                ),
              ),
            ),
            SizedBox(height: 40.h),
            SizedBox(
              width: 24.r,
              height: 24.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.mintGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
