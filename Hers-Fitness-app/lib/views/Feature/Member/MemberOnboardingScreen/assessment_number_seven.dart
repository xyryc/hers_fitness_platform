import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/assessment_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AssessmentAppbar/assessment_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class AssessmentNumberSevenScreen extends StatelessWidget {
  AssessmentNumberSevenScreen({super.key});

  final AssessmentController controller = Get.find<AssessmentController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.0, -1.0),
                radius: 2.5,
                colors: [
                  const Color(0xFFFFA6B4).withValues(alpha: 0.5),
                  const Color(0xFFFFE0B9).withValues(alpha: 0.25),
                  Colors.white,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.045),

                const AssessmentAppbar(
                  title: "Assessment",
                  stepText: "7 of 10",
                ),

                SizedBox(height: 40.h),

                Text(
                  "Are you taking any supplements?",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.twoXL24Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 48.h),

                // Supplements Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(50.r),
                  child: Image.asset(
                    'assets/images/supplements.png',
                    width: double.infinity,
                    height: 330.h,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 32),

                // Yes/No Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceButton(
                        text: "No",
                        icon: Icons.close,
                        backgroundColor: Colors.grey,
                        textColor: AppColors.textPrimary,
                        iconColor: AppColors.textPrimary,
                        onTap: () {
                          controller.setTakingSupplements(false);
                          Get.toNamed(AppRoutes.assessmentNumberNineScreen);
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildChoiceButton(
                        text: "Yes",
                        icon: Icons.check,
                        backgroundColor: AppColors.actionSecondary,
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        onTap: () {
                          controller.setTakingSupplements(true);
                          Get.toNamed(AppRoutes.assessmentNumberEightScreen);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton({
    required String text,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: AppTextStyles.base16Medium.copyWith(color: textColor),
            ),
            SizedBox(width: 8.w),
            Icon(icon, color: iconColor, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
