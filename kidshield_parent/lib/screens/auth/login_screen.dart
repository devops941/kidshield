import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../home/main_navigation_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed. Please check credentials.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF3F7FD),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Compact Logo & Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46.w,
                        height: 46.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E64D8).withValues(alpha: 0.16),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/parent_app_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/kidshield_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Icon(
                              Icons.shield_rounded,
                              color: const Color(0xFF1E64D8),
                              size: 26.r,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KIDSHIELD',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: const Color(0xFF0B256C),
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'CHILD SAFETY & PROTECTION',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: const Color(0xFF1E64D8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Compact, Sleek Card Container
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                        color: const Color(0xFF1E64D8),
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E64D8).withValues(alpha: isDark ? 0.35 : 0.20),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: const Color(0xFF1565C0).withValues(alpha: isDark ? 0.25 : 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Title
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0B256C),
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Sign in to protect and guide your child safely.',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 14.h),

                          // Email Input
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'Enter your email',
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!val.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12.h),

                          // Password Input
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 8.h),

                          // Remember Me & Forgot Password Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 18.w,
                                    height: 18.h,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: const Color(0xFF1E64D8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberMe = val ?? true;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: isDark
                                          ? AppColors.textMutedDark
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E64D8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),

                          // Action Button
                          Center(
                            child: SizedBox(
                              width: 200.w,
                              height: 38.h,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1565C0),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: const Color(0xFF1565C0).withValues(alpha: 0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: authProvider.isLoading
                                    ? SizedBox(
                                        width: 18.r,
                                        height: 18.r,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
