import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/restriction_model.dart';
import '../../providers/child_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';

class ParentalRestrictionsScreen extends StatefulWidget {
  const ParentalRestrictionsScreen({super.key});

  @override
  State<ParentalRestrictionsScreen> createState() => _ParentalRestrictionsScreenState();
}

class _ParentalRestrictionsScreenState extends State<ParentalRestrictionsScreen> {
  int _dailyLimitMinutes = 180;
  bool _isDailyLimitEnabled = true;

  bool _isBedtimeEnabled = true;
  TimeOfDay _bedtimeStart = const TimeOfDay(hour: 21, minute: 30);
  TimeOfDay _bedtimeEnd = const TimeOfDay(hour: 6, minute: 30);

  bool _isStudyTimeEnabled = true;
  TimeOfDay _studyTimeStart = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _studyTimeEnd = const TimeOfDay(hour: 18, minute: 0);

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final child = Provider.of<ChildProvider>(context).selectedChild;
      if (child != null) {
        _dailyLimitMinutes = child.dailyScreenTimeLimitMinutes;
        _initialized = true;
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart, bool isBedtime) async {
    final initial = isBedtime
        ? (isStart ? _bedtimeStart : _bedtimeEnd)
        : (isStart ? _studyTimeStart : _studyTimeEnd);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        if (isBedtime) {
          if (isStart) {
            _bedtimeStart = picked;
          } else {
            _bedtimeEnd = picked;
          }
        } else {
          if (isStart) {
            _studyTimeStart = picked;
          } else {
            _studyTimeEnd = picked;
          }
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _saveSettings() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final selectedChild = childProvider.selectedChild;

    if (selectedChild == null) return;

    final restriction = RestrictionModel(
      dailyScreenTimeMinutes: _dailyLimitMinutes,
      bedtimeStart: '${_bedtimeStart.hour}:${_bedtimeStart.minute.toString().padLeft(2, '0')}',
      bedtimeEnd: '${_bedtimeEnd.hour}:${_bedtimeEnd.minute.toString().padLeft(2, '0')}',
      studyTimeStart: '${_studyTimeStart.hour}:${_studyTimeStart.minute.toString().padLeft(2, '0')}',
      studyTimeEnd: '${_studyTimeEnd.hour}:${_studyTimeEnd.minute.toString().padLeft(2, '0')}',
      isDailyLimitEnabled: _isDailyLimitEnabled,
      isBedtimeEnabled: _isBedtimeEnabled,
      isStudyTimeEnabled: _isStudyTimeEnabled,
    );

    await childProvider.updateRestrictions(restriction);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Safety rules updated & synced with child phone.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final childProvider = Provider.of<ChildProvider>(context);
    final selectedChild = childProvider.selectedChild;

    if (selectedChild == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parental Controls')),
        body: const EmptyState(
          icon: Icons.shield_outlined,
          title: 'No Child Selected',
          message: 'Add or select a child to configure screen time and schedule limits.',
        ),
      );
    }

    final limitHours = (_dailyLimitMinutes / 60).floor();
    final limitMins = _dailyLimitMinutes % 60;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Safety Controls • ${selectedChild.name}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Time Limit Card
              Container(
                padding: EdgeInsets.all(18.r),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(Icons.timer_rounded, color: AppColors.royalBlue, size: 22.r),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  'Daily Screen Limit',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isDailyLimitEnabled,
                          activeThumbColor: AppColors.royalBlue,
                          onChanged: (val) {
                            setState(() {
                              _isDailyLimitEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Allowed Time: ${limitHours}h ${limitMins > 0 ? '${limitMins}m' : ''}',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Slider(
                      value: _dailyLimitMinutes.toDouble(),
                      min: 30,
                      max: 480,
                      divisions: 15,
                      activeColor: AppColors.royalBlue,
                      label: '${limitHours}h ${limitMins}m',
                      onChanged: _isDailyLimitEnabled
                          ? (val) {
                              setState(() {
                                _dailyLimitMinutes = val.round();
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Bedtime Schedule Card
              Container(
                padding: EdgeInsets.all(18.r),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(Icons.bedtime_rounded, color: const Color(0xFF6366F1), size: 22.r),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  'Bedtime Schedule',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isBedtimeEnabled,
                          activeThumbColor: const Color(0xFF6366F1),
                          onChanged: (val) {
                            setState(() {
                              _isBedtimeEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Restricts non-emergency app usage during sleep hours.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _isBedtimeEnabled
                                ? () => _selectTime(context, true, true)
                                : null,
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bedtime Starts', style: TextStyle(fontSize: 11.sp, color: AppColors.textMutedLight)),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _formatTimeOfDay(_bedtimeStart),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: InkWell(
                            onTap: _isBedtimeEnabled
                                ? () => _selectTime(context, false, true)
                                : null,
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bedtime Ends', style: TextStyle(fontSize: 11.sp, color: AppColors.textMutedLight)),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _formatTimeOfDay(_bedtimeEnd),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Study Time Schedule Card
              Container(
                padding: EdgeInsets.all(18.r),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: AppColors.cyanAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(Icons.school_rounded, color: AppColors.cyanAccent, size: 22.r),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  'Study & Homework Hours',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.navyDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isStudyTimeEnabled,
                          activeThumbColor: AppColors.cyanAccent,
                          onChanged: (val) {
                            setState(() {
                              _isStudyTimeEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Focus mode for homework. Only educational apps and phone calls allowed.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _isStudyTimeEnabled
                                ? () => _selectTime(context, true, false)
                                : null,
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Study Starts', style: TextStyle(fontSize: 11.sp, color: AppColors.textMutedLight)),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _formatTimeOfDay(_studyTimeStart),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: InkWell(
                            onTap: _isStudyTimeEnabled
                                ? () => _selectTime(context, false, false)
                                : null,
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Study Ends', style: TextStyle(fontSize: 11.sp, color: AppColors.textMutedLight)),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _formatTimeOfDay(_studyTimeEnd),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Save Changes Button
              CustomButton(
                text: 'Save & Apply Restrictions',
                isLoading: childProvider.isLoading,
                icon: Icons.shield_rounded,
                onPressed: _saveSettings,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
