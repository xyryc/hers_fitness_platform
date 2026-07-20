import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/assessment_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AssessmentAppbar/assessment_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class AssessmentNumberThreeScreen extends StatelessWidget {
  AssessmentNumberThreeScreen({super.key});

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
                  stepText: "3 of 10",
                ),

                SizedBox(height: 40.h),

                Text(
                  "What is your age?",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.twoXL24Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 48.h),

                // Age Picker
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Selected Background
                      Container(
                        width: 250.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          color: AppColors.actionPrimary,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      ListWheelScrollView.useDelegate(
                        itemExtent: 80.h,
                        perspective: 0.005,
                        diameterRatio: 1.5,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          controller.setAge(index + 10);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 90, // Up to age 100
                          builder: (context, index) {
                            int ageValue = index + 10;
                            return Obx(() {
                              bool isSelected =
                                  controller.age.value == ageValue;
                              return Center(
                                child: Text(
                                  ageValue.toString(),
                                  style: AppTextStyles.sixXL36Bold.copyWith(
                                    fontSize: 48.sp,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textDisabled,
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(bottom: 45.h),
                  child: AppButton(
                    text: "Continue",
                    showArrow: true,
                    onTap: () {
                      Get.toNamed(AppRoutes.assessmentNumberFourScreen);
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
}
