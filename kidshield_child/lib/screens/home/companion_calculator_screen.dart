import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../widgets/calculator_widget.dart';

class CompanionCalculatorScreen extends StatelessWidget {
  const CompanionCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Calculator Companion'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: const Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: CalculatorWidget(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
