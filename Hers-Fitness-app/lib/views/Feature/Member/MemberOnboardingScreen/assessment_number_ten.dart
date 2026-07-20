import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/assessment_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AssessmentAppbar/assessment_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class AssessmentNumberTenScreen extends StatelessWidget {
  AssessmentNumberTenScreen({super.key});

  final AssessmentController controller = Get.find<AssessmentController>();

  final List<Map<String, dynamic>> sleepOptions = [
    {
      "label": "Excellent",
      "range": ">8 hours",
      "icon": Icons.sentiment_very_satisfied_outlined,
    },
    {
      "label": "Great",
      "range": "7-8 hours",
      "icon": Icons.sentiment_satisfied_alt_outlined,
    },
    {
      "label": "Normal",
      "range": "6-7 hours",
      "icon": Icons.sentiment_neutral_outlined,
    },
    {
      "label": "Bad",
      "range": "3-4 hours",
      "icon": Icons.sentiment_dissatisfied_outlined,
    },
    {
      "label": "Insomniac",
      "range": "<2 hours",
      "icon": Icons.sentiment_very_dissatisfied_outlined,
    },
  ];

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
                  stepText: "10 of 10",
                ),

                SizedBox(height: 40.h),

                Text(
                  "What's your sleep quality like?",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.twoXL24Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 48.h),

                // Sleep Options List
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: sleepOptions.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      return Obx(() {
                        bool isSelected =
                            controller.selectedSleepIndex.value == index;
                        return GestureDetector(
                          onTap: () => controller.setSleepQuality(index),
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.actionPrimary
                                  : AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(22.r),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 0)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.borderFocusEffect,
                                        blurRadius: 0,
                                        spreadRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  sleepOptions[index]["icon"],
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textDisabled,
                                  size: 40.sp,
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Text(
                                    sleepOptions[index]["label"],
                                    style: AppTextStyles.lg18Medium.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16.sp,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : AppColors.textDisabled,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      sleepOptions[index]["range"],
                                      style: AppTextStyles.sm14Medium.copyWith(
                                        color: isSelected
                                            ? Colors.white.withValues(
                                                alpha: 0.8,
                                              )
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(bottom: 50.h),
                  child: Obx(
                    () => AppButton(
                      text: "Continue",
                      showArrow: !controller.isSubmitting.value,
                      isLoading: controller.isSubmitting.value,
                      onTap: controller.isSubmitting.value
                          ? () {}
                          : () async {
                              final success = await controller
                                  .submitAssessment();
                              if (!success) return;

                              Get.offAllNamed(AppRoutes.memberBottomNavScreen);
                            },
                    ),
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
