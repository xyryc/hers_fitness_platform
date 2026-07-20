import 'package:flutter_svg/flutter_svg.dart';
import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/assessment_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AssessmentAppbar/assessment_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class AssessmentNumberOneScreen extends StatelessWidget {
  AssessmentNumberOneScreen({super.key});

  final AssessmentController controller = Get.put(AssessmentController());

  final List<Map<String, dynamic>> goals = [
    {"label": "I wanna lose weight", "icon": "assets/icons/loseWeightIcon.svg"},
    {"label": "I wanna get bulks", "icon": "assets/icons/bulksIcon.svg"},
    {
      "label": "I wanna gain endurance",
      "icon": "assets/icons/enduranceIcon.svg",
    },
    {
      "label": "Just trying out the app! 👍",
      "icon": "assets/icons/tryingOutIcon.svg",
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.045),

                const AssessmentAppbar(
                  title: "Assessment",
                  stepText: "1 of 10",
                ),

                SizedBox(height: 40.h),

                Center(
                  child: Text(
                    "What's your fitness goal ?",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.twoXL24Medium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),

                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: goals.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      return Obx(() {
                        bool isSelected =
                            controller.selectedGoalIndex.value == index;
                        return GestureDetector(
                          onTap: () => controller.setGoal(index),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 18.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.actionPrimary
                                  : AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.actionPrimary.withValues(
                                        alpha: .25,
                                      ),
                              ),
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
                                SvgPicture.asset(
                                  goals[index]["icon"],
                                  colorFilter: ColorFilter.mode(
                                    isSelected
                                        ? Colors.white
                                        : Color(0xFF676C75),
                                    BlendMode.srcIn,
                                  ),
                                  width: 24.w,
                                  height: 24.w,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    goals[index]["label"],
                                    style: AppTextStyles.base16Medium.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 20.w,
                                  height: 20.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 10.w,
                                            height: 10.w,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                      : null,
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
                  padding: EdgeInsets.only(bottom: 45.h),
                  child: AppButton(
                    text: "Continue",
                    showArrow: true,
                    onTap: () {
                      Get.toNamed(AppRoutes.assessmentNumberTwoScreen);
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
