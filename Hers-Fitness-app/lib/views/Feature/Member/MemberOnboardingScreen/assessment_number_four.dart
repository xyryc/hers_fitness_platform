import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/assessment_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AssessmentAppbar/assessment_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class AssessmentNumberFourScreen extends StatelessWidget {
  AssessmentNumberFourScreen({super.key});

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
                  stepText: "4 of 10",
                ),

                SizedBox(height: 40.h),

                Text(
                  "Do you have previous fitness experience?",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.twoXL24Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 32.h),

                // Dumbbell Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(32.r),
                  child: Image.asset(
                    'assets/images/dumbbells.png',
                    width: double.infinity,
                    height: 330.h,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 32),

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
                        isSelected: false,
                        onTap: () {
                          controller.setExperience(false);
                          Get.toNamed(AppRoutes.assessmentNumberFiveScreen);
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
                        isSelected: true,
                        onTap: () {
                          controller.setExperience(true);
                          Get.toNamed(AppRoutes.assessmentNumberFiveScreen);
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
    required bool isSelected,
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
