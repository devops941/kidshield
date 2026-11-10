import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/companion_provider.dart';

class CalculatorWidget extends StatelessWidget {
  const CalculatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final companion = Provider.of<CompanionProvider>(context);

    final buttons = [
      ['C', '±', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '=', ''],
    ];

    return Column(
      children: [
        // Calculator Display
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(24.r),
          ),
          alignment: Alignment.centerRight,
          child: Text(
            companion.calcDisplay,
            style: TextStyle(
              fontSize: 42.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // Keypad Grid
        Column(
          children: buttons.map((row) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: row.map((btn) {
                  if (btn.isEmpty) {
                    return const Expanded(child: SizedBox());
                  }

                  final isOperator = ['÷', '×', '-', '+', '='].contains(btn);
                  final isAction = ['C', '±', '%'].contains(btn);

                  Color btnColor;
                  Color textColor;

                  if (btn == '=') {
                    btnColor = AppColors.softGreen;
                    textColor = Colors.white;
                  } else if (isOperator) {
                    btnColor = AppColors.primaryBlue;
                    textColor = Colors.white;
                  } else if (isAction) {
                    btnColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
                    textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
                  } else {
                    btnColor = isDark ? AppColors.surfaceDark : Colors.white;
                    textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
                  }

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.r),
                      child: InkWell(
                        onTap: () {
                          if (btn == 'C') {
                            companion.onClear();
                          } else if (btn == '=') {
                            companion.onCalculate();
                          } else if (isOperator) {
                            companion.onOperatorPress(btn);
                          } else if (btn == '±' || btn == '%') {
                            // no-op or simple
                          } else {
                            companion.onNumberPress(btn);
                          }
                        },
                        borderRadius: BorderRadius.circular(18.r),
                        child: Container(
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: btnColor,
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              btn,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
