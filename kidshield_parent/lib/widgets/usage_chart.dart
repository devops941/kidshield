import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';

class UsageChart extends StatelessWidget {
  final int dailyLimitMinutes;
  final List<double>? values;
  final List<String>? labels;
  final String? limitLabel;
  final double? customLimitMinutes;
  final List<double>? weeklyMinutes; // fallback

  const UsageChart({
    super.key,
    this.dailyLimitMinutes = 180,
    this.values,
    this.labels,
    this.limitLabel,
    this.customLimitMinutes,
    this.weeklyMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final xLabels = labels ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final usageData = values ?? weeklyMinutes ?? List<double>.filled(xLabels.length, 0.0);
    final maxVal = usageData.fold<double>(0.0, (m, v) => v > m ? v : m);
    final limit = customLimitMinutes ?? (dailyLimitMinutes > 0 ? dailyLimitMinutes.toDouble() : 180.0);
    final highest = maxVal > limit ? maxVal : limit;

    // Clean ceiling in whole hours
    final totalHoursCeil = ((highest * 1.15) / 60).ceil().clamp(3, 200);
    final effectiveMaxY = totalHoursCeil * 60.0;
    final interval = (totalHoursCeil <= 5) ? 60.0 : ((totalHoursCeil / 4).ceil() * 60.0);

    final displayLimitLabel = limitLabel ?? 'Limit ${(limit / 60).toStringAsFixed(1)}h';
    final rodWidth = xLabels.length <= 4 ? 22.w : (xLabels.length <= 6 ? 16.w : 14.w);

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: 0,
          maxY: effectiveMaxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final idx = group.x.toInt();
                final labelName = idx >= 0 && idx < xLabels.length ? xLabels[idx] : '';
                final hours = (rod.toY / 60).floor();
                final mins = (rod.toY % 60).toInt();
                return BarTooltipItem(
                  '$labelName\n${hours}h ${mins}m',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < xLabels.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        xLabels[index],
                        style: TextStyle(
                          fontSize: xLabels.length <= 4 ? 12.sp : 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval > 0 ? interval : 60,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value > effectiveMaxY) return const SizedBox.shrink();
                  final hours = (value / 60).round();
                  return Text(
                    '${hours}h',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              strokeWidth: 1,
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: limit,
                color: Colors.redAccent.withValues(alpha: 0.75),
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: EdgeInsets.only(right: 6.w, bottom: 2.h),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                  labelResolver: (_) => displayLimitLabel,
                ),
              ),
            ],
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(xLabels.length, (index) {
            final val = index < usageData.length ? usageData[index] : 0.0;
            final isOverLimit = val > limit;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: isOverLimit ? AppColors.danger : AppColors.royalBlue,
                  gradient: LinearGradient(
                    colors: isOverLimit
                        ? [AppColors.danger, const Color(0xFFF87171)]
                        : [AppColors.royalBlue, AppColors.cyanAccent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: rodWidth,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: effectiveMaxY,
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
