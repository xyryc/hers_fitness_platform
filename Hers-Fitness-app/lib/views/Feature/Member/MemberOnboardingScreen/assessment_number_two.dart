import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/assessment_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AssessmentAppbar/assessment_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class AssessmentNumberTwoScreen extends StatefulWidget {
  const AssessmentNumberTwoScreen({super.key});

  @override
  State<AssessmentNumberTwoScreen> createState() =>
      _AssessmentNumberTwoScreenState();
}

class _AssessmentNumberTwoScreenState extends State<AssessmentNumberTwoScreen> {
  final AssessmentController controller = Get.find<AssessmentController>();
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    // Use a consistent itemWidth for both the listener and the UI
    double itemWidth = 15.w;
    double initialWeight = controller.weight.value;
    double initialOffset = (initialWeight - 20) / 0.2 * itemWidth;

    scrollController = ScrollController(initialScrollOffset: initialOffset);

    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      double offset = scrollController.offset;
      // Correct for any negative offset or bounce
      if (offset < 0) offset = 0;

      int index = (offset / itemWidth).round();
      double newVal = 20 + (index * 0.2);

      // Update weight in controller
      controller.setWeight(
        double.parse(newVal.clamp(20, 300).toStringAsFixed(1)),
      );
    });

    // Ensure the controller matches the initial scroll position exactly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.setWeight(initialWeight);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

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
                  stepText: "2 of 10",
                ),

                SizedBox(height: 40.h),

                Text(
                  "What is your weight?",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.twoXL24Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 48.h),

                // kg/lbs Toggle
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
                          "kg",
                          controller.weightUnit.value == "kg",
                        ),
                        _buildUnitButton(
                          "lbs",
                          controller.weightUnit.value == "lbs",
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 48.h),

                // Weight Display
                Obx(
                  () => RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: controller.weight.value.toStringAsFixed(1),
                          style: AppTextStyles.sixXL36Bold.copyWith(
                            fontSize: 64.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: controller.weightUnit.value,
                          style: AppTextStyles.xl20Medium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 48.h),

                // Ruler / Scale Picker
                SizedBox(
                  height: 120.h,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double centerX = constraints.maxWidth / 2;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: centerX - 7.5.w,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: 1401, // (300 - 20) / 0.2 + 1
                            itemBuilder: (context, index) {
                              bool isInteger = index % 5 == 0;
                              int currentWeight = 20 + (index ~/ 5);
                              bool isEven = currentWeight % 2 == 0;
                              bool shouldLabel = isInteger && !isEven;

                              return SizedBox(
                                width: 15.w,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          width: isInteger ? 2.5.w : 2.w,
                                          height: isInteger ? 50.h : 25.h,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF9EA3AE),
                                            borderRadius: BorderRadius.circular(
                                              2.r,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 24.h,
                                      child: shouldLabel
                                          ? Text(
                                              currentWeight.toString(),
                                              textAlign: TextAlign.center,
                                              softWrap: false,
                                              overflow: TextOverflow.visible,
                                              style: AppTextStyles.base16Medium
                                                  .copyWith(
                                                    color: const Color(
                                                      0xFF676C75,
                                                    ),
                                                  ),
                                            )
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Center Indicator
                          Positioned(
                            top: 0,
                            child: Container(
                              width: 16.w,
                              height: 95.h,
                              decoration: BoxDecoration(
                                color: AppColors.actionPrimary,
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.actionPrimary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: EdgeInsets.only(bottom: 45.h),
                  child: AppButton(
                    text: "Continue",
                    showArrow: true,
                    onTap: () {
                      Get.toNamed(AppRoutes.assessmentNumberThreeScreen);
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
      onTap: () => controller.setWeightUnit(label),
      child: Container(
        width: 80.w,
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
}
