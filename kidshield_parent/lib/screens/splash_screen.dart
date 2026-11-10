import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home/main_navigation_screen.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Show animated GIF logo for 4 seconds before navigating
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background soft subtle top tint
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.4,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF4F8FD),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          // Main Center Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Safe Zone Protection GIF Logo
                          Container(
                            width: 170.r,
                            height: 170.r,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E64D8).withValues(alpha: 0.18),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32.r),
                              child: Image.asset(
                                'assets/images/animated_logo.gif',
                                width: 170.r,
                                height: 170.r,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  'assets/images/Animated Safe Zone Protection Storyboard.gif',
                                  width: 170.r,
                                  height: 170.r,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 130.w,
                                    height: 130.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F5FD),
                                      borderRadius: BorderRadius.circular(30.r),
                                      border: Border.all(
                                        color: const Color(0xFF1E64D8),
                                        width: 3,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.shield_outlined,
                                      size: 70.r,
                                      color: const Color(0xFF1E64D8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // App Name
                          Text(
                            'KIDSHIELD',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0B256C),
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 6.h),

                          // Subtitle
                          Text(
                            "Your Child's Safety, Our Priority",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E64D8),
                              height: 1.35,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 42.h),

                          // Circular Loading Indicator
                          SizedBox(
                            width: 38.r,
                            height: 38.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2185F5)),
                              backgroundColor: Color(0xFFE2EAF8),
                            ),
                          ),

                          // Spacer for bottom waves clearance
                          SizedBox(height: size.height * 0.12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Layered Curved Waves (matching the reference design)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.20,
            child: const CustomPaint(
              painter: WaveBottomPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveBottomPainter extends CustomPainter {
  const WaveBottomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1 (Back, Light Sky Blue)
    final path1 = Path();
    path1.moveTo(0, h * 0.35);
    path1.cubicTo(
      w * 0.25, h * 0.10,
      w * 0.70, h * 0.55,
      w, h * 0.25,
    );
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF81D4FA),
          Color(0xFF4FC3F7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path1, paint1);

    // Layer 2 (Middle, Vibrant Ocean Blue)
    final path2 = Path();
    path2.moveTo(0, h * 0.50);
    path2.cubicTo(
      w * 0.30, h * 0.75,
      w * 0.65, h * 0.25,
      w, h * 0.45,
    );
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF29B6F6),
          Color(0xFF0288D1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, paint2);

    // Layer 3 (Front, Deep Royal Blue)
    final path3 = Path();
    path3.moveTo(0, h * 0.68);
    path3.cubicTo(
      w * 0.35, h * 0.50,
      w * 0.70, h * 0.80,
      w, h * 0.60,
    );
    path3.lineTo(w, h);
    path3.lineTo(0, h);
    path3.close();

    final paint3 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0288D1),
          Color(0xFF01579B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
