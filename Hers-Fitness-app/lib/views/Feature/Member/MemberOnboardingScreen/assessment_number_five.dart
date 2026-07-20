import 'package:fitness/Helpers/route.dart';
import 'package:fitness/controllers/assessment_controller.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AssessmentAppbar/assessment_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../utils/AppColor/app_colors.dart';

class AssessmentNumberFiveScreen extends StatefulWidget {
  const AssessmentNumberFiveScreen({super.key});

  @override
  State<AssessmentNumberFiveScreen> createState() =>
      _AssessmentNumberFiveScreenState();
}

class _AssessmentNumberFiveScreenState
    extends State<AssessmentNumberFiveScreen> {
  final AssessmentController controller = Get.find<AssessmentController>();
  final TextEditingController textController = TextEditingController();

  void _addTag(String value) {
    String trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      controller.addLimitation(trimmed);
      textController.clear();
    }
  }

  @override
  void dispose() {
    textController.dispose();
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
                  stepText: "5 of 10",
                ),

                SizedBox(height: 40.h),

                Text(
                  "Do you have any physical limitations?",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.twoXL24Medium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 48.h),

                // Tag Input Area
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: AppColors.actionPrimary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            ...controller.limitations.map(
                              (tag) => _buildTag(tag),
                            ),
                            // Input Field inline with tags
                            IntrinsicWidth(
                              child: TextField(
                                controller: textController,
                                style: AppTextStyles.base16Medium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Type here...",
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                  ),
                                ),
                                onSubmitted: _addTag,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 18.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Obx(
                            () => Text(
                              "${controller.limitations.length}/10",
                              style: AppTextStyles.sm14Medium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: "Continue",
                  showArrow: true,
                  onTap: () {
                    Get.toNamed(AppRoutes.assessmentNumberSixScreen);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.actionPrimary,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () => controller.removeLimitation(text),
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
