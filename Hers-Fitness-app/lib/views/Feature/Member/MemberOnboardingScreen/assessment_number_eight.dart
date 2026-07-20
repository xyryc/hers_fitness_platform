import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/assessment_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AssessmentAppbar/assessment_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class AssessmentNumberEightScreen extends StatelessWidget {
  AssessmentNumberEightScreen({super.key});

  final AssessmentController controller = Get.find<AssessmentController>();

  final List<String> supplementOptions = [
    "Whey",
    "Protein",
    "Vitamin D",
    "Magnesium",
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

          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.045,
                    ),
                    const AssessmentAppbar(
                      title: "Assessment",
                      stepText: "8 of 10",
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Main Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32.r),
                      topRight: Radius.circular(32.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: EdgeInsets.only(top: 12.h),
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.borderPrimary,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      Text(
                        "Supplements",
                        style: AppTextStyles.xl20Bold.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Please specify your supplement.",
                        style: AppTextStyles.base16Medium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Search Bar
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search supplements...",
                            hintStyle: AppTextStyles.base16Medium.copyWith(
                              color: const Color(0xFF9EA3AE),
                            ),
                            border: InputBorder.none,
                            suffixIcon: Icon(
                              Icons.search,
                              color: Colors.black,
                              size: 28.sp,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // List of Supplements
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          itemCount: supplementOptions.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            String item = supplementOptions[index];
                            return Obx(() {
                              bool isSelected = controller.selectedSupplements
                                  .contains(item);
                              return GestureDetector(
                                onTap: () => controller.toggleSupplement(item),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.actionPrimary
                                        : AppColors.bgTertiary,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 0,
                                          )
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  AppColors.borderFocusEffect,
                                              blurRadius: 0,
                                              spreadRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item,
                                        style: AppTextStyles.base16Medium
                                            .copyWith(
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                            ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        size: 24.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                      ),

                      // Selected Chips
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 16.h,
                        ),
                        child: Row(
                          children: [
                            Text(
                              "Selected",
                              style: AppTextStyles.sm14Medium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Obx(
                                () => Wrap(
                                  spacing: 8.w,
                                  children: controller.selectedSupplements
                                      .map((item) => _buildChip(item))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Apply Button
                      Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 50.h),
                        child: AppButton(
                          text: "Apply",
                          showArrow: false,
                          onTap: () {
                            Get.toNamed(AppRoutes.assessmentNumberNineScreen);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.xs12Medium.copyWith(
              color: AppColors.actionPrimary,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () => controller.toggleSupplement(label),
            child: Icon(
              Icons.close,
              size: 14.sp,
              color: AppColors.actionPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
