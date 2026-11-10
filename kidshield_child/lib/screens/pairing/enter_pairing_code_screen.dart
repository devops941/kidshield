import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/child_auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import 'permissions_grant_screen.dart';

class EnterPairingCodeScreen extends StatefulWidget {
  const EnterPairingCodeScreen({super.key});

  @override
  State<EnterPairingCodeScreen> createState() => _EnterPairingCodeScreenState();
}

class _EnterPairingCodeScreenState extends State<EnterPairingCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String _errorMessage = '';

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _fullCode => _controllers.map((c) => c.text.trim().toUpperCase()).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      // If user pasted a full code like KS3683 or KS-3683
      final clean = value.replaceAll('-', '').toUpperCase();
      if (clean.length > 1) {
        for (int i = 0; i < 6 && i < clean.length; i++) {
          _controllers[i].text = clean[i];
        }
        _focusNodes[clean.length.clamp(0, 5)].requestFocus();
        return;
      }

      _controllers[index].text = value.toUpperCase();
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    setState(() => _errorMessage = '');
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      final clean = data.text!.replaceAll('-', '').trim().toUpperCase();
      for (int i = 0; i < 6 && i < clean.length; i++) {
        _controllers[i].text = clean[i];
      }
      setState(() => _errorMessage = '');
    }
  }

  Future<void> _handlePair() async {
    final code = _fullCode;
    if (code.length < 5) {
      setState(() => _errorMessage = 'Please enter the full pairing code');
      return;
    }

    // Format code: If starts with KS without dash, or KS-XXXX
    final formattedCode = code.startsWith('KS') && !code.contains('-') && code.length >= 6
        ? 'KS-${code.substring(2)}'
        : code;

    final auth = Provider.of<ChildAuthProvider>(context, listen: false);
    final success = await auth.pairWithCode(formattedCode);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionsGrantScreen()),
      );
    } else {
      setState(() {
        _errorMessage = auth.errorMessage ?? 'Invalid pairing code. Please check your parent app.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<ChildAuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const CustomAppBar(title: 'Enter Pairing Code'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.navyBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 12.h),

                // Illustration matching wireframe (Phone with shield pointing to mother)
                Center(
                  child: Image.asset(
                    'assets/images/parent_child_illustration.png',
                    height: 70.h,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF09142E),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.electricCyan, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_android_rounded, color: AppColors.mintGreen, size: 28.r),
                          SizedBox(width: 8.w),
                          Icon(Icons.arrow_forward_rounded, color: AppColors.electricCyan, size: 20.r),
                          SizedBox(width: 8.w),
                          Icon(Icons.person_rounded, color: Colors.amberAccent, size: 28.r),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // Heading / Prompt
                Text(
                  'Enter the 6-digit code\nfrom your parent\'s app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 28.h),

                // 6 Rounded PIN Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    final hasText = _controllers[i].text.isNotEmpty;
                    return Container(
                      width: 44.w,
                      height: 54.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1E45),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: hasText
                              ? AppColors.electricCyan
                              : AppColors.electricCyan.withValues(alpha: 0.3),
                          width: hasText ? 1.8 : 1.2,
                        ),
                        boxShadow: hasText
                            ? [
                                BoxShadow(
                                  color: AppColors.electricCyan.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          keyboardType: TextInputType.text,
                          maxLength: 1,
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) => _onDigitChanged(i, val),
                        ),
                      ),
                    );
                  }),
                ),

                // Paste button helper
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _handlePaste,
                    icon: Icon(Icons.content_paste_rounded, size: 14.r, color: AppColors.electricCyan),
                    label: Text(
                      'Paste Code',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.electricCyan,
                      ),
                    ),
                  ),
                ),

                if (_errorMessage.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sosRed,
                    ),
                  ),
                ],

                SizedBox(height: 36.h),

                // Button: Glowing Cyan Connect to Parent
                CustomButton(
                  text: 'Connect to Parent',
                  icon: Icons.link_rounded,
                  isGlowingCyan: true,
                  isLoading: auth.isLoading,
                  height: 48.h,
                  onPressed: _handlePair,
                ),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
