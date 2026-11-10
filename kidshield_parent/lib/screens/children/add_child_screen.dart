import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'pair_device_screen.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _age = 10;
  int _screenTimeHours = 3;
  String _gender = 'boy';
  TimeOfDay _bedtimeStart = const TimeOfDay(hour: 21, minute: 30);
  TimeOfDay _bedtimeEnd = const TimeOfDay(hour: 6, minute: 30);
  bool _bedtimeEnabled = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('h:mm a').format(dt);
  }

  String _timeOfDayTo24h(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _selectTime(bool isStart) async {
    final initial = isStart ? _bedtimeStart : _bedtimeEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _bedtimeStart = picked;
        } else {
          _bedtimeEnd = picked;
        }
      });
    }
  }

  Future<void> _handleCreateChild() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    final parentId = authProvider.currentParent?.uid;
    if (parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first to create a child profile.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final newChild = await childProvider.addChild(
      parentId: parentId,
      name: _nameController.text.trim(),
      age: _age,
      gender: _gender,
      phoneNumber: _phoneController.text.trim(),
      dailyLimitMinutes: _screenTimeHours * 60,
      bedtimeStart: _bedtimeEnabled ? _timeOfDayTo24h(_bedtimeStart) : '21:30',
      bedtimeEnd: _bedtimeEnabled ? _timeOfDayTo24h(_bedtimeEnd) : '06:30',
    );

    if (!mounted) return;

    if (newChild != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PairDeviceScreen(child: newChild),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(childProvider.errorMessage ?? 'Failed to create child profile'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final childProvider = Provider.of<ChildProvider>(context);

    final primaryBg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF4F7FD);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19.r,
            color: textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Child Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Avatar & Gender Selection Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with animated glow ring
                      Container(
                        width: 96.r,
                        height: 96.r,
                        decoration: BoxDecoration(
                          color: _gender == 'girl'
                              ? const Color(0xFFFDF2F8)
                              : const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _gender == 'girl'
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF2563EB),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_gender == 'girl'
                                      ? const Color(0xFFEC4899)
                                      : const Color(0xFF2563EB))
                                  .withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            _gender == 'girl'
                                ? 'assets/images/girl_illustration.png'
                                : 'assets/images/child_illustration.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.face_rounded,
                              size: 56.r,
                              color: _gender == 'girl'
                                  ? const Color(0xFFEC4899)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Gender Segmented Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGenderOption(
                            label: 'Boy',
                            icon: Icons.boy_rounded,
                            isSelected: _gender == 'boy',
                            activeColor: const Color(0xFF2563EB),
                            onTap: () => setState(() => _gender = 'boy'),
                            isDark: isDark,
                          ),
                          SizedBox(width: 14.w),
                          _buildGenderOption(
                            label: 'Girl',
                            icon: Icons.girl_rounded,
                            isSelected: _gender == 'girl',
                            activeColor: const Color(0xFFEC4899),
                            onTap: () => setState(() => _gender = 'girl'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Child's Full Name Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: CustomTextField(
                    controller: _nameController,
                    label: "Child's Full Name",
                    hint: 'Enter child name',
                    prefixIcon: Icons.badge_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Please enter child's name";
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 14.h),

                // Child's Mobile Number Card (for Emergency SOS Calls)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _phoneController,
                        label: "Child's Mobile Number (Optional)",
                        hint: 'e.g. +91 98765 43210',
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.sos_rounded, size: 14.r, color: AppColors.danger),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              'Directly dials your child\'s phone when you tap "Call Child" in Emergency SOS alerts.',
                              style: TextStyle(fontSize: 11.5.sp, color: textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Age Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cake_outlined,
                                size: 18.r,
                                color: const Color(0xFF2563EB),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "Child's Age",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '$_age years old',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5.h,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.r),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 18.r),
                        ),
                        child: Slider(
                          value: _age.toDouble(),
                          min: 4,
                          max: 18,
                          divisions: 14,
                          activeColor: const Color(0xFF2563EB),
                          inactiveColor: borderColor,
                          label: '$_age yrs',
                          onChanged: (val) => setState(() => _age = val.round()),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '4 yrs',
                              style: TextStyle(fontSize: 11.sp, color: textMuted),
                            ),
                            Text(
                              '18 yrs',
                              style: TextStyle(fontSize: 11.sp, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Daily Screen Time Limit Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timelapse_rounded,
                                  size: 18.r,
                                  color: const Color(0xFF06B6D4),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    'Daily Screen Time Limit',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '$_screenTimeHours hrs / day',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0891B2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5.h,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.r),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 18.r),
                        ),
                        child: Slider(
                          value: _screenTimeHours.toDouble(),
                          min: 1,
                          max: 8,
                          divisions: 7,
                          activeColor: const Color(0xFF0891B2),
                          inactiveColor: borderColor,
                          label: '$_screenTimeHours hrs',
                          onChanged: (val) => setState(() => _screenTimeHours = val.round()),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1 hr',
                              style: TextStyle(fontSize: 11.sp, color: textMuted),
                            ),
                            Text(
                              '8 hrs',
                              style: TextStyle(fontSize: 11.sp, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Bedtime Schedule Card (Added directly into Child Creation)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.bedtime_rounded,
                                    size: 18.r,
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    'Bedtime Schedule',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _bedtimeEnabled,
                            activeThumbColor: const Color(0xFF6366F1),
                            onChanged: (val) => setState(() => _bedtimeEnabled = val),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Restricts non-emergency app usage during sleep hours to ensure healthy rest.',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: textMuted,
                        ),
                      ),
                      if (_bedtimeEnabled) ...[
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(true),
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bedtime Starts',
                                        style: TextStyle(fontSize: 10.5.sp, color: textMuted),
                                      ),
                                      SizedBox(height: 4.h),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTimeOfDay(_bedtimeStart),
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                              color: textPrimary,
                                            ),
                                          ),
                                          Icon(Icons.access_time_rounded, size: 14.r, color: const Color(0xFF6366F1)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(false),
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bedtime Ends',
                                        style: TextStyle(fontSize: 10.5.sp, color: textMuted),
                                      ),
                                      SizedBox(height: 4.h),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTimeOfDay(_bedtimeEnd),
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                              color: textPrimary,
                                            ),
                                          ),
                                          Icon(Icons.wb_sunny_rounded, size: 14.r, color: Colors.amber),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Responsive, Overflow-Proof Submit Button
                CustomButton(
                  text: 'Generate Pairing Code & Continue',
                  isLoading: childProvider.isLoading,
                  icon: Icons.qr_code_2_rounded,
                  onPressed: _handleCreateChild,
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: 1.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19.r,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.check_circle_rounded,
                size: 14.r,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
