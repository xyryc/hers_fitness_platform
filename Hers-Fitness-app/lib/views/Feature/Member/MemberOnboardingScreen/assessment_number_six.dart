import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/assessment_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AssessmentAppbar/assessment_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class AssessmentNumberSixScreen extends StatelessWidget {
  AssessmentNumberSixScreen({super.key});

  final AssessmentController controller = Get.find<AssessmentController>();

  final List<Map<String, dynamic>> dietOptions = [
    {"title": "Plant Based", "subtitle": "Vegan", "icon": Icons.eco_outlined},
    {
      "title": "Carbo Diet",
      "subtitle": "Bread, etc",
      "icon": Icons.bakery_dining_outlined,
    },
    {
      "title": "Specialized",
      "subtitle": "Paleo, keto, etc",
      "icon": Icons.restaurant_outlined,
    },
    {
      "title": "Traditional",
      "subtitle": "Fruit diet",
      "icon": Icons.apple_outlined,
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
                  stepText: "6 of 10",
                ),

                SizedBox(height: 40.h),

                Text(
                  "Do you have a specific diet preference?",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.twoXL24Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 32.h),

                // Grid of Diet Options
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: dietOptions.length,
                    itemBuilder: (context, index) {
                      return Obx(() {
                        bool isSelected =
                            controller.selectedDietIndex.value == index;
                        return _buildDietCard(
                          title: dietOptions[index]["title"],
                          subtitle: dietOptions[index]["subtitle"],
                          icon: dietOptions[index]["icon"],
                          isSelected: isSelected,
                          onTap: () => controller.setDietPreference(index),
                        );
                      });
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: AppButton(
                    text: "Continue",
                    showArrow: true,
                    onTap: () {
                      Get.toNamed(AppRoutes.assessmentNumberSevenScreen);
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

  Widget _buildDietCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.actionPrimary : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.actionPrimary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.actionPrimary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.lg18Bold.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: AppTextStyles.sm14Medium.copyWith(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.iconSecondary.withValues(alpha: 0.5),
                size: 32.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
