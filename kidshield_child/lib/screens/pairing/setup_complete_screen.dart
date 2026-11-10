import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../home/child_dashboard_screen.dart';

class SetupCompleteScreen extends StatelessWidget {
  const SetupCompleteScreen({super.key});

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
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              children: [
                SizedBox(height: 30.h),

                // Center Success Badge (100% Native Vector Circular Badge with Concentric Rings & Glow)
                Center(
                  child: SizedBox(
                    width: 170.r,
                    height: 170.r,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. Outermost Ambient Glow Aura
                        Container(
                          width: 170.r,
                          height: 170.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.mintGreen.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // 2. Outer Translucent Concentric Ring (Double ring effect from wireframe)
                        Container(
                          width: 136.r,
                          height: 136.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E676).withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.mintGreen.withValues(alpha: 0.55),
                              width: 2.2,
                            ),
                          ),
                        ),

                        // 3. Middle Solid Vibrant Mint Green Circle with Glowing Shadow
                        Container(
                          width: 104.r,
                          height: 104.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00E676),
                                Color(0xFF10B981),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E676).withValues(alpha: 0.55),
                                blurRadius: 26,
                                spreadRadius: 3,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 58.r,
                            ),
                          ),
                        ),

                        // 4. Subtle Twinkling Sparkles matching Wireframe
                        Positioned(
                          top: 14.r,
                          right: 18.r,
                          child: Icon(
                            Icons.auto_awesome,
                            color: AppColors.electricCyan,
                            size: 18.r,
                          ),
                        ),
                        Positioned(
                          bottom: 22.r,
                          left: 14.r,
                          child: Icon(
                            Icons.auto_awesome,
                            color: AppColors.mintGreen,
                            size: 15.r,
                          ),
                        ),
                        Positioned(
                          top: 38.r,
                          left: 10.r,
                          child: Icon(
                            Icons.star_rounded,
                            color: AppColors.electricCyan.withValues(alpha: 0.8),
                            size: 10.r,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32.h),

                // Heading matching wireframe
                Text(
                  'Connected\nwith Parent!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 12.h),

                // Subtitle matching wireframe
                Text(
                  'You are now protected\nwith KIDSHIELD.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 48.h),

                // Button matching wireframe
                CustomButton(
                  text: 'Complete Setup & Open KIDSHIELD',
                  icon: Icons.check_circle_rounded,
                  isGlowingCyan: true,
                  height: 50.h,
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const ChildDashboardScreen()),
                      (route) => false,
                    );
                  },
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
