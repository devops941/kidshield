import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/child_model.dart';
import '../../providers/child_provider.dart';
import '../../widgets/custom_button.dart';

class PairDeviceScreen extends StatefulWidget {
  final ChildModel child;

  const PairDeviceScreen({
    super.key,
    required this.child,
  });

  @override
  State<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends State<PairDeviceScreen> {
  late String _currentCode;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _currentCode = widget.child.pairingCode;
  }

  Future<void> _regenerateCode() async {
    setState(() => _isRegenerating = true);
    try {
      final newCode = await context
          .read<ChildProvider>()
          .regeneratePairingCode(widget.child.id);
      if (newCode != null && mounted) {
        setState(() {
          _currentCode = newCode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ New pairing code generated! Valid for 15 minutes.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Short payload makes QR modules large, crisp, and 10x easier to scan phone-to-phone
    final pairingPayload = _currentCode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Pair Child Device'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Connect ${widget.child.name}\'s Device',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Scan this QR code from KidShield Junior on the child\'s phone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                ),
              ),
              SizedBox(height: 24.h),

              // QR Code Card
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: pairingPayload,
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.navyDark,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.navyDark,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentCode,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                              color: AppColors.royalBlue,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          IconButton(
                            icon: Icon(Icons.copy_rounded, size: 20.r, color: AppColors.royalBlue),
                            tooltip: 'Copy Code',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _currentCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pairing code copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, size: 14.sp, color: Colors.orange.shade800),
                        SizedBox(width: 5.w),
                        Text(
                          'Valid for 15 minutes',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    OutlinedButton.icon(
                      onPressed: _isRegenerating ? null : _regenerateCode,
                      icon: _isRegenerating
                          ? SizedBox(
                              width: 14.r,
                              height: 14.r,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(_isRegenerating ? 'Generating...' : 'Regenerate Code'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.royalBlue,
                        side: const BorderSide(color: AppColors.royalBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28.h),

              // Pairing Steps
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to complete pairing:',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _buildStepRow(
                      number: '1',
                      title: 'Download KidShield Junior',
                      desc: 'Open KidShield Junior on your child\'s Android device.',
                      isDark: isDark,
                    ),
                    SizedBox(height: 12.h),
                    _buildStepRow(
                      number: '2',
                      title: 'Scan QR or Enter Code',
                      desc: 'Point the child device camera at this code or enter $_currentCode.',
                      isDark: isDark,
                    ),
                    SizedBox(height: 12.h),
                    _buildStepRow(
                      number: '3',
                      title: 'Grant Permissions',
                      desc: 'Approve transparent Location & Usage permissions as prompted.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              CustomButton(
                text: 'Done & Return to Console',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24.r,
          height: 24.r,
          decoration: const BoxDecoration(
            color: AppColors.royalBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
