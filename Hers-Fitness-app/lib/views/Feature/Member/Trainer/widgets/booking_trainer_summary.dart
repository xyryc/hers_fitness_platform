import 'package:fitness/controllers/member/book_trainer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../utils/AppColor/app_colors.dart';
import '../../../../../utils/AppTextStyle/app_text_styles.dart';

class BookingTrainerSummary extends StatelessWidget {
  final BookTrainerController controller;
  final bool showChevron;
  final EdgeInsetsGeometry? margin;

  const BookingTrainerSummary({
    super.key,
    required this.controller,
    this.showChevron = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.network(
              controller.trainerImageUrl,
              width: 76.w,
              height: 76.w,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 76.w,
                height: 76.w,
                color: AppColors.bgTertiary,
                child: Icon(
                  Icons.person,
                  size: 30.sp,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.trainerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.base16SemiBold.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: const Color(0xFFFACC15),
                      size: 20.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      controller.trainerRating.toStringAsFixed(1),
                      style: AppTextStyles.sm14Medium.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        '•',
                        style: AppTextStyles.sm14Medium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.groups_rounded,
                      color: AppColors.actionPrimary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '21 Clients',
                      style: AppTextStyles.sm14Regular.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showChevron)
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
              size: 28.sp,
            ),
        ],
      ),
    );
  }
}
