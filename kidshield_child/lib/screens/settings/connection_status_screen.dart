import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/child_auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/custom_button.dart';
import '../pairing/enter_pairing_code_screen.dart';

class ConnectionStatusScreen extends StatelessWidget {
  const ConnectionStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<ChildAuthProvider>(context);
    final location = Provider.of<LocationProvider>(context);

    final child = auth.currentProfile;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Safety & Connection Status'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Info Card
              Container(
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    _buildRow('Child Profile', child?.name ?? 'Child User', isDark),
                    const Divider(height: 24),
                    _buildRow('Pairing Code', child?.pairingCode ?? 'KS-7821', isDark),
                    const Divider(height: 24),
                    _buildRow('Parent Account', 'Active & Linked', isDark),
                    const Divider(height: 24),
                    _buildRow('Battery Level', '${location.batteryLevel}%', isDark),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              Text(
                'Safety Controls & Permissions',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              SizedBox(height: 12.h),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Location Sharing',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      subtitle: const Text('Shares live GPS location with your parent'),
                      secondary: const Icon(Icons.location_on_rounded, color: AppColors.primaryBlue),
                      value: location.isSharingEnabled,
                      activeThumbColor: AppColors.softGreen,
                      onChanged: (val) {
                        location.toggleLocationSharing(val, child?.id ?? '');
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.bar_chart_rounded, color: AppColors.primaryBlue),
                      title: Text(
                        'Screen Time Access',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      subtitle: const Text('Permitted via Android Usage Access'),
                      trailing: Icon(Icons.check_circle_rounded, color: AppColors.softGreen, size: 20.r),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.security_rounded, color: AppColors.primaryBlue),
                      title: Text(
                        'Device Administration',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      subtitle: const Text('Parental control protection enabled'),
                      trailing: Icon(Icons.check_circle_rounded, color: AppColors.softGreen, size: 20.r),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Transmit Ping Button
              CustomButton(
                text: 'Send Live Location Ping',
                isLoading: location.isSending,
                icon: Icons.satellite_alt_rounded,
                onPressed: () async {
                  await location.updateLocation(child?.id ?? '');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Updated GPS coordinates transmitted to parent console!'),
                        backgroundColor: AppColors.softGreen,
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 14.h),

              // Unpair button
              CustomButton(
                text: 'Disconnect / Unpair Device',
                isOutlined: true,
                color: AppColors.sosRed,
                icon: Icons.phonelink_erase_rounded,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Unpair Device?'),
                      content: const Text(
                        'Are you sure you want to disconnect this device from your parent? This will pause location and safety sharing.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.sosRed),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            auth.unpair();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const EnterPairingCodeScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text('Unpair'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
