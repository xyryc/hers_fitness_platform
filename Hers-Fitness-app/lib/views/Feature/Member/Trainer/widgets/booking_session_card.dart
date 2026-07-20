import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../utils/AppColor/app_colors.dart';
import '../../../../../utils/AppTextStyle/app_text_styles.dart';

class BookingSessionCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String location;
  final String classType;
  final String sessionFormat;
  final String price;
  final bool isSelected;
  final VoidCallback? onTap;

  const BookingSessionCard({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.classType,
    required this.sessionFormat,
    required this.price,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected
                ? AppColors.actionPrimary
                : AppColors.borderSecondary,
            width: isSelected ? 1.5.w : 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.base16SemiBold.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                _iconLabel(Icons.calendar_month_outlined, date),
                SizedBox(width: 24.w),
                _iconLabel(Icons.access_time_rounded, time),
              ],
            ),
            SizedBox(height: 12.h),
            _iconLabel(Icons.location_on_rounded, location),
            SizedBox(height: 16.h),
            Divider(color: AppColors.borderSecondary, height: 1.h),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailItem('Class typ', classType),
                _detailItem('Session Format', sessionFormat),
                _detailItem('Per Member', price),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconLabel(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18.sp, color: AppColors.textTertiary),
        SizedBox(width: 8.w),
        Text(
          text,
          style: AppTextStyles.sm14Medium.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.xs12Regular.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.sm14SemiBold.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
