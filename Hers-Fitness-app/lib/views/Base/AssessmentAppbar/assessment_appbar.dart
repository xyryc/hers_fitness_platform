import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../utils/AppColor/app_colors.dart';

class AssessmentAppbar extends StatelessWidget {
  final String? title;
  final String? stepText;
  final VoidCallback? onTap;

  const AssessmentAppbar({super.key, this.title, this.stepText, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap ?? () => Get.back(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF9F9F9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.actionPrimary,
                  blurRadius: 0,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
        ),

        Expanded(
          child: title != null
              ? Center(
                  child: AppText(
                    title!,
                    style: AppTextStyles.xl20Medium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                )
              : const SizedBox(),
        ),

        stepText != null
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBC3CC),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: AppText(
                  stepText!,
                  style: AppTextStyles.sm14SemiBold.copyWith(
                    color: const Color(0xFFE06F83),
                  ),
                ),
              )
            : SizedBox(width: 48.w),
      ],
    );
  }
}
