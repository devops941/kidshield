import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/child_auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/companion_provider.dart';
import '../../widgets/custom_button.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  static const MethodChannel _gpsChannel = MethodChannel('com.kidshield.child/gps');
  bool _sent = false;

  Future<void> _sendSos() async {
    final auth = Provider.of<ChildAuthProvider>(context, listen: false);
    final location = Provider.of<LocationProvider>(context, listen: false);
    final companion = Provider.of<CompanionProvider>(context, listen: false);

    final child = auth.currentProfile;
    HapticFeedback.heavyImpact();

    // Refresh location right before dispatching
    if (child != null) {
      try {
        await location.refreshLocation(child.id);
      } catch (_) {}
    }

    await companion.triggerEmergencySos(
      childId: child?.id ?? '',
      childName: child?.name ?? 'Child',
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.address,
      batteryLevel: location.batteryLevel,
    );

    HapticFeedback.heavyImpact();

    if (mounted) {
      setState(() {
        _sent = true;
      });
    }
  }

  void _callNumber(String number) {
    HapticFeedback.selectionClick();
    _gpsChannel.invokeMethod('openDialer', {'number': number});
  }

  @override
  Widget build(BuildContext context) {
    final companion = Provider.of<CompanionProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: _sent
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: AppColors.softGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 72.r,
                          color: AppColors.softGreen,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'SOS Alert Dispatched!',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Your live GPS location and an emergency alert have been transmitted to your parent\'s phone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                      ),
                      SizedBox(height: 32.h),

                      // Emergency helplines card
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          children: [
                            _buildHelplineRow('National Emergency', '112'),
                            const Divider(color: AppColors.borderDark, height: 16),
                            _buildHelplineRow('Police Helpline', '100'),
                            const Divider(color: AppColors.borderDark, height: 16),
                            _buildHelplineRow('Childline Support', '1098'),
                            const Divider(color: AppColors.borderDark, height: 16),
                            _buildHelplineRow('Women & Child Helpline', '181'),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      CustomButton(
                        text: 'Return to Safety Dashboard',
                        color: AppColors.primaryBlue,
                        onPressed: () {
                          companion.dismissSos();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110.w,
                      height: 110.h,
                      decoration: BoxDecoration(
                        color: AppColors.sosRed.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.sosRed, width: 3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.warning_rounded,
                          size: 60.r,
                          color: AppColors.sosRed,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Activate Emergency SOS?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'This will immediately alert your parents with your exact coordinates and high-priority notification sound.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5.sp, color: Colors.white70),
                    ),
                    SizedBox(height: 20.h),

                    // Silent Hardware Pocket Trigger Tip
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.power_settings_new_rounded, color: const Color(0xFFF59E0B), size: 20.r),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Silent Trigger: Press Power Button 4 times consecutively to send SOS silently without unlocking screen.',
                              style: TextStyle(fontSize: 11.5.sp, color: Colors.white70, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),

                    CustomButton(
                      text: 'SEND EMERGENCY ALERT NOW',
                      isLoading: companion.isSendingSos,
                      color: AppColors.sosRed,
                      icon: Icons.emergency_rounded,
                      onPressed: _sendSos,
                    ),
                    SizedBox(height: 14.h),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel & Return', style: TextStyle(color: Colors.white60)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHelplineRow(String label, String number) {
    return InkWell(
      onTap: () => _callNumber(number),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.softGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.softGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_in_talk_rounded, color: AppColors.softGreen, size: 14.r),
                  SizedBox(width: 6.w),
                  Text(
                    number,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
