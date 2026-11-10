import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/child_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/battery_indicator.dart';
import '../../widgets/status_badge.dart';
import '../auth/login_screen.dart';
import '../children/add_child_screen.dart';
import '../children/child_details_screen.dart';
import '../children/pair_device_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRefreshing = false;
  bool _sirenEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      if (authProvider.currentParent != null) {
        await childProvider.loadChildren(authProvider.currentParent!.uid);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8.w),
            Expanded(child: Text('$label copied to clipboard!')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final childProvider = Provider.of<ChildProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final monitoringProvider = Provider.of<MonitoringProvider>(context, listen: false);

    final parent = authProvider.currentParent;

    // Deduplicate children by unique ID or pairing code to guarantee no duplicate cards
    final uniqueChildrenMap = <String, ChildModel>{};
    for (final c in childProvider.children) {
      final key = c.pairingCode.isNotEmpty ? c.pairingCode : (c.id.isNotEmpty ? c.id : c.name);
      if (!uniqueChildrenMap.containsKey(key)) {
        uniqueChildrenMap[key] = c;
      }
    }
    final displayChildren = uniqueChildrenMap.values.toList();

    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.navyDark;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        title: Text(
          'Parent Profile & Settings',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Profile Data',
            icon: _isRefreshing
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.royalBlue),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.royalBlue),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.royalBlue,
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PARENT HERO PROFILE CARD
                _buildParentHeroCard(parent, isDark),
                SizedBox(height: 24.h),

                // 2. MONITORED FAMILY SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Family Profiles',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${displayChildren.length}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.royalBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        backgroundColor: AppColors.royalBlue.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddChildScreen()),
                        );
                      },
                      icon: Icon(Icons.person_add_alt_1_rounded, size: 16.r, color: AppColors.royalBlue),
                      label: Text(
                        'Add Child',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.royalBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Child Cards (Deduplicated)
                if (displayChildren.isEmpty)
                  _buildNoChildrenCard(isDark)
                else
                  ...displayChildren.map((child) => _buildChildCard(context, child, isDark, cardColor, borderColor, textPrimary, textMuted)),

                SizedBox(height: 24.h),

                // 3. SAFETY & MONITORING CONTROLS
                _buildSectionTitle('Safety & Emergency Controls', textPrimary),
                SizedBox(height: 10.h),
                _buildSettingsCard(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                      secondary: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_active_rounded, color: AppColors.danger, size: 20.r),
                      ),
                      title: Text(
                        'Emergency Distress Siren',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      subtitle: Text(
                        'Sound high-pitch siren on SOS alerts',
                        style: TextStyle(fontSize: 12.sp, color: textMuted),
                      ),
                      value: _sirenEnabled,
                      activeColor: AppColors.danger,
                      onChanged: (val) {
                        setState(() => _sirenEnabled = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? '🚨 Emergency siren enabled.' : 'Siren muted for SOS alerts.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildDivider(borderColor),
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                      leading: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.gps_fixed_rounded, color: AppColors.cyanAccent, size: 20.r),
                      ),
                      title: Text(
                        'Real-time GPS Tracking',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      subtitle: Text(
                        'High-precision live tracking via OpenStreetMap',
                        style: TextStyle(fontSize: 12.sp, color: textMuted),
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // 4. PREFERENCES & DISPLAY
                _buildSectionTitle('Preferences & Display', textPrimary),
                SizedBox(height: 10.h),
                _buildSettingsCard(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                      secondary: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: AppColors.royalBlue,
                          size: 20.r,
                        ),
                      ),
                      title: Text(
                        'Dark Theme',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      subtitle: Text(
                        'Switch between light and dark modes',
                        style: TextStyle(fontSize: 12.sp, color: textMuted),
                      ),
                      value: isDark,
                      activeColor: AppColors.royalBlue,
                      onChanged: (val) {
                        themeProvider.toggleTheme();
                      },
                    ),
                    _buildDivider(borderColor),
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                      leading: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.language_rounded, color: Colors.purple, size: 20.r),
                      ),
                      title: Text(
                        'Console Language',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      subtitle: Text(
                        'English (India)',
                        style: TextStyle(fontSize: 12.sp, color: textMuted),
                      ),
                      trailing: Text(
                        'EN',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // 5. 24/7 EMERGENCY HELPLINES (DIRECT DIAL)
                _buildSectionTitle('24/7 Emergency Helplines', textPrimary),
                SizedBox(height: 10.h),
                _buildSettingsCard(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  children: [
                    _buildHelplineTile(
                      icon: Icons.emergency_rounded,
                      color: const Color(0xFFDC2626),
                      number: '112',
                      title: 'National Emergency Helpline',
                      subtitle: 'Direct emergency response dispatch',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () => monitoringProvider.openEmergencyDialer('112'),
                    ),
                    _buildDivider(borderColor),
                    _buildHelplineTile(
                      icon: Icons.support_agent_rounded,
                      color: const Color(0xFF7C3AED),
                      number: '1098',
                      title: 'Childline Support Helpline',
                      subtitle: '24/7 child safety & rescue helpline',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () => monitoringProvider.openEmergencyDialer('1098'),
                    ),
                    _buildDivider(borderColor),
                    _buildHelplineTile(
                      icon: Icons.local_police_rounded,
                      color: const Color(0xFF0284C7),
                      number: '100',
                      title: 'Police Control Room',
                      subtitle: 'Direct local police station assistance',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () => monitoringProvider.openEmergencyDialer('100'),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // 6. SECURITY & LEGAL COMPLIANCE
                _buildSectionTitle('Privacy, Security & Legal', textPrimary),
                SizedBox(height: 10.h),
                _buildSettingsCard(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                      leading: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.policy_outlined, color: AppColors.royalBlue, size: 20.r),
                      ),
                      title: Text(
                        'Android Transparency Policy',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      subtitle: Text(
                        'Complies with Google Play Parental Control policies',
                        style: TextStyle(fontSize: 12.sp, color: textMuted),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14.r, color: textMuted),
                      onTap: () => _showTransparencyDialog(context),
                    ),
                    _buildDivider(borderColor),
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                      leading: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shield_outlined, color: AppColors.success, size: 20.r),
                      ),
                      title: Text(
                        'Telemetry Encryption',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      subtitle: Text(
                        'End-to-end encrypted telemetry partition',
                        style: TextStyle(fontSize: 12.sp, color: textMuted),
                      ),
                      trailing: Icon(Icons.check_circle_rounded, size: 16.r, color: AppColors.success),
                    ),
                    _buildDivider(borderColor),
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                      leading: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondaryLight.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.info_outline_rounded, color: AppColors.royalBlue, size: 20.r),
                      ),
                      title: Text(
                        'System & Version Info',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      subtitle: Text(
                        '${AppConstants.appName} v${AppConstants.appVersion} (Stable Production)',
                        style: TextStyle(fontSize: 12.sp, color: textMuted),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),

                // 7. SIGN OUT BUTTON
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: () => _confirmSignOut(context, authProvider),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: AppColors.danger),
                            SizedBox(width: 8.w),
                            Text(
                              'Sign Out of Account',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildParentHeroCard(dynamic parent, bool isDark) {
    final fullName = parent?.fullName ?? 'Parent';
    final email = parent?.email ?? 'parent@kidshield.app';
    final phone = parent?.phoneNumber ?? 'Not provided';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P';

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with initial and verified badge
              Stack(
                children: [
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.royalBlue.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(3.r),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 12.r, color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16.w),

              // Name, Role Chip, and Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fullName,
                            style: TextStyle(
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.cyanAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'GUARDIAN',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cyanAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.mail_outline_rounded, size: 13.r, color: Colors.white70),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (phone.isNotEmpty && phone != 'Not provided') ...[
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 13.r, color: AppColors.cyanAccent),
                          SizedBox(width: 5.w),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyanAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Bottom Bar inside Hero Card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Account Active & Monitored',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'ID: ...${(parent?.uid ?? '').length > 6 ? (parent?.uid ?? '').substring((parent?.uid ?? '').length - 6) : 'PARENT'}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white54,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(
    BuildContext context,
    ChildModel child,
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
  ) {
    final monitoringProvider = Provider.of<MonitoringProvider>(context, listen: false);
    final loc = monitoringProvider.currentLocation;
    final int liveBattery = (loc != null && loc.batteryAtLocation > 0)
        ? loc.batteryAtLocation
        : (child.batteryLevel > 0 && child.batteryLevel != 100
            ? child.batteryLevel
            : (loc?.batteryAtLocation ?? (child.batteryLevel > 0 ? child.batteryLevel : 85)));

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChildDetailsScreen(child: child),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                Row(
                  children: [
                    // Child Avatar with Online Status
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 26.r,
                          backgroundColor: AppColors.royalBlue.withValues(alpha: 0.12),
                          backgroundImage: AssetImage(
                            child.isGirl
                                ? 'assets/images/girl_illustration.png'
                                : 'assets/images/child_illustration.png',
                          ),
                          onBackgroundImageError: (_, _) {},
                          child: child.name.isEmpty
                              ? Text(
                                  'C',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.royalBlue,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14.r,
                            height: 14.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: child.isOnline ? AppColors.success : AppColors.textMutedDark,
                              border: Border.all(color: cardColor, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 14.w),

                    // Child Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  child.name,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              StatusBadge(isOnline: child.isOnline),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            '${child.age} yrs old • ${child.gender.toUpperCase()}${child.phoneNumber.isNotEmpty ? " • ${child.phoneNumber}" : ""}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(Icons.phone_android_rounded, size: 13.r, color: textMuted),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  child.deviceName ?? 'Child Device',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              BatteryIndicator(
                                percentage: liveBattery,
                                isCharging: child.isCharging,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Icon(Icons.arrow_forward_ios_rounded, size: 16.r, color: textMuted),
                  ],
                ),
                SizedBox(height: 12.h),

                // Pairing Code Copy Chip & QR Shortcut
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.key_rounded, size: 14.r, color: AppColors.royalBlue),
                      SizedBox(width: 5.w),
                      Text(
                        'Code: ',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      Text(
                        child.pairingCode,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.royalBlue,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _copyToClipboard(child.pairingCode, 'Pairing code ${child.pairingCode}'),
                        borderRadius: BorderRadius.circular(6.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 13.r, color: AppColors.royalBlue),
                              SizedBox(width: 3.w),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.royalBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PairDeviceScreen(child: child),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                          child: Icon(Icons.qr_code_rounded, size: 16.r, color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoChildrenCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.family_restroom_rounded, size: 48.r, color: AppColors.royalBlue.withValues(alpha: 0.5)),
          SizedBox(height: 12.h),
          Text(
            'No Child Profiles Connected',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Add your child to start real-time monitoring and safety protections.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textPrimary) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildSettingsCard({
    required Color cardColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(height: 1, thickness: 1, color: borderColor);
  }

  Widget _buildHelplineTile({
    required IconData icon,
    required Color color,
    required String number,
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20.r),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.5.sp, color: textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              number,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: color),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.phone_rounded, size: 14.r, color: color),
          ],
        ),
      ),
      onTap: onTap,
    );
  }

  void _showTransparencyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppColors.royalBlue, size: 22),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'KidShield Safety Policy',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KidShield operates with complete transparency in compliance with Google Play and Android Parental Control guidelines:',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12.h),
              _buildPolicyBullet(
                title: 'Explicit Consent',
                desc: 'All child monitoring features require device owner installation and transparent permission grant on the child device.',
                textColor: textMuted,
                bulletColor: AppColors.royalBlue,
              ),
              SizedBox(height: 10.h),
              _buildPolicyBullet(
                title: 'No Invisible Spyware',
                desc: 'The KidShield Junior app maintains an ongoing, transparent persistent notification whenever safety monitoring or location tracking is active.',
                textColor: textMuted,
                bulletColor: AppColors.royalBlue,
              ),
              SizedBox(height: 10.h),
              _buildPolicyBullet(
                title: 'Platform APIs',
                desc: 'Screen time limits and restrictions use official Android Device Administration APIs without invasive rooting or hidden processes.',
                textColor: textMuted,
                bulletColor: AppColors.royalBlue,
              ),
              SizedBox(height: 10.h),
              _buildPolicyBullet(
                title: 'Private Data Vault',
                desc: 'All child telemetry is end-to-end encrypted and strictly partitioned to your authenticated parent account.',
                textColor: textMuted,
                bulletColor: AppColors.royalBlue,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyBullet({
    required String title,
    required String desc,
    required Color textColor,
    required Color bulletColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 5.h, right: 8.w),
          child: Container(
            width: 6.r,
            height: 6.r,
            decoration: BoxDecoration(
              color: bulletColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12.5.sp, height: 1.4, color: textColor),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Text('Sign Out', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to sign out of KidShield Parent? Live emergency alerts will be paused on this phone until you sign back in.',
          style: TextStyle(color: textMuted, fontSize: 13.5.sp, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
