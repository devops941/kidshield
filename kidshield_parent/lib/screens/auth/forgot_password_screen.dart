import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../home/main_navigation_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 1 = Enter Email, 2 = Enter OTP & New Password, 3 = Success
  int _step = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Step 1: Send OTP to parent email via Gmail SMTP
  Future<void> _handleSendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final success = await authProvider.sendPasswordReset(email);

    if (!mounted) return;

    if (success) {
      setState(() {
        _step = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A 6-digit verification code has been sent to $email'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to send reset code. Please try again.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    }
  }

  // Step 2: Verify OTP & Save New Password
  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _passwordController.text;

    final success = await authProvider.resetPasswordWithOtp(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _step = 3;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to reset password. Please check the code.'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.r,
            color: isDark ? Colors.white : const Color(0xFF0B256C),
          ),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 390.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E64D8).withValues(alpha: 0.16),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(4.r),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/animated_logo.gif',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.shield_rounded,
                              color: const Color(0xFF1E64D8),
                              size: 24.r,
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
                            'PARENT ACCOUNT RECOVERY',
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
                  SizedBox(height: 16.h),

                  // Main Card
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
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
                    child: _buildCurrentStep(isDark, authProvider),
                  ),
                  SizedBox(height: 16.h),

                  // Back to Sign In Link
                  if (_step != 3)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Remember your password? ',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Sign In',
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

  Widget _buildCurrentStep(bool isDark, AuthProvider authProvider) {
    switch (_step) {
      case 2:
        return _buildStep2OtpAndNewPassword(isDark, authProvider);
      case 3:
        return _buildStep3Success(isDark);
      case 1:
      default:
        return _buildStep1EnterEmail(isDark, authProvider);
    }
  }

  // STEP 1: Enter Email
  Widget _buildStep1EnterEmail(bool isDark, AuthProvider authProvider) {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E64D8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF1E64D8), size: 22),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0B256C),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Enter your registered email address. We will send a secure 6-digit verification code to your Gmail inbox.',
            style: TextStyle(
              fontSize: 12.5.sp,
              color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          SizedBox(height: 18.h),
          CustomTextField(
            controller: _emailController,
            label: 'Registered Email',
            hint: 'name@example.com',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!val.contains('@') || !val.contains('.')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: 20.h),
          Center(
            child: SizedBox(
              width: 220.w,
              height: 42.h,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleSendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF1565C0).withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: authProvider.isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 16),
                          SizedBox(width: 8.w),
                          Text(
                            'Send Reset Code',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Enter OTP & New Password
  Widget _buildStep2OtpAndNewPassword(bool isDark, AuthProvider authProvider) {
    return Form(
      key: _resetFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF059669), size: 22),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Verify & Set Password',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0B256C),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B),
                height: 1.35,
              ),
              children: [
                const TextSpan(text: 'Enter the 6-digit code sent to '),
                TextSpan(
                  text: _emailController.text.trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E64D8)),
                ),
                const TextSpan(text: ' and choose your new password.'),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // 6-Digit OTP Field
          CustomTextField(
            controller: _otpController,
            label: '6-Digit Verification Code',
            hint: 'e.g. 849201',
            prefixIcon: Icons.pin_rounded,
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter the 6-digit code';
              }
              if (val.trim().length != 6) {
                return 'Code must be exactly 6 digits';
              }
              return null;
            },
          ),
          SizedBox(height: 12.h),

          // New Password Field
          CustomTextField(
            controller: _passwordController,
            label: 'New Password',
            hint: 'At least 6 characters',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter a new password';
              }
              if (val.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 12.h),

          // Confirm Password Field
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            hint: 'Re-enter your new password',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please confirm your new password';
              }
              if (val != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          SizedBox(height: 8.h),

          // Resend Code Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: authProvider.isLoading ? null : _handleSendOtp,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Resend Code', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E64D8),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          SizedBox(height: 14.h),

          Center(
            child: SizedBox(
              width: 240.w,
              height: 42.h,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: authProvider.isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 18),
                          SizedBox(width: 8.w),
                          Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Success Screen
  Widget _buildStep3Success(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64.r,
          height: 64.r,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_rounded,
            size: 38,
            color: Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Password Reset Complete!',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0B256C),
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          'Your password has been securely updated. A confirmation email has also been delivered to ${_emailController.text.trim()}.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        SizedBox(height: 24.h),
        SizedBox(
          width: 220.w,
          height: 42.h,
          child: ElevatedButton(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isAuthenticated) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                  (route) => false,
                );
              } else {
                Navigator.of(context).pop(); // Back to Login
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Sign In with New Password',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
