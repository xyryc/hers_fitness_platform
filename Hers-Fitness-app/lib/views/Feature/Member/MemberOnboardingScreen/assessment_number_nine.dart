import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/assessment_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AssessmentAppbar/assessment_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class AssessmentNumberNineScreen extends StatelessWidget {
  AssessmentNumberNineScreen({super.key});

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

                const AssessmentAppbar(title: "Assessment", stepText: "9 of 9"),

                SizedBox(height: 40.h),

                Text(
                  "What's Your Calorie Goal per day?",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.twoXL24Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 48.h),

                // Kcal/Joule Toggle
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUnitButton(
                          "Kcal",
                          controller.calorieUnit.value == "Kcal",
                        ),
                        _buildUnitButton(
                          "Joule's",
                          controller.calorieUnit.value == "Joule's",
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 60.h),

                // Calorie Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Obx(
                      () => Text(
                        controller.calorieGoal.value
                            .toString()
                            .replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]},',
                            ),
                        style: AppTextStyles.sixXL36Bold.copyWith(
                          fontSize: 80.sp,
                          color: AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 4.w,
                      height: 60.h,
                      color: AppColors.actionPrimary,
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                Text(
                  "calories daily",
                  style: AppTextStyles.xl20Medium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: 60.h),

                // Plus/Minus Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepButton(
                      icon: Icons.remove,
                      onTap: () {
                        if (controller.calorieGoal.value > 150) {
                          controller.setCalorieGoal(
                            controller.calorieGoal.value - 50,
                          );
                        }
                      },
                    ),
                    SizedBox(width: 32.w),
                    _buildStepButton(
                      icon: Icons.add,
                      isPrimary: true,
                      onTap: () {
                        if (controller.calorieGoal.value < 10000) {
                          controller.setCalorieGoal(
                            controller.calorieGoal.value + 50,
                          );
                        }
                      },
                    ),
                  ],
                ),

                const Spacer(),

                Padding(
                  padding: EdgeInsets.only(bottom: 50.h),
                  child: AppButton(
                    text: "Continue",
                    showArrow: true,
                    onTap: () {
                      Get.toNamed(AppRoutes.assessmentNumberTenScreen);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.setCalorieUnit(label),
      child: Container(
        width: 150.w,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.actionPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.base16Medium.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112.w,
        height: 64.h,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.actionPrimary : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(20.r),
          border: isPrimary
              ? Border.all(color: AppColors.actionPrimary)
              : Border.all(color: Color(0xFFE0E0E0)),
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.textSecondary,
          size: 32.sp,
        ),
      ),
    );
  }
}
