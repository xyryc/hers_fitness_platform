import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../utils/AppTextStyle/app_text_styles.dart';
import '../../../../Base/AppText/appText.dart';

class CustomScheduleCard extends StatelessWidget {
  final String timeText;
  final String ampm;
  final bool isBooked;

  // Booked specific fields
  final String? title;
  final String? duration;
  final bool isCompleted;

  const CustomScheduleCard({
    super.key,
    required this.timeText,
    required this.ampm,
    required this.isBooked,
    this.title,
    this.duration,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBooked) {
      return _buildAvailableCard();
    }
    return _buildBookedCard();
  }

  Widget _buildBookedCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60.w,
            child: Column(
              children: [
                Icon(
                  Icons.access_time_filled,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
                SizedBox(height: 8.h),
                AppText(
                  timeText,
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                AppText(
                  ampm,
                  style: AppTextStyles.sm14Regular.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(
            width: 1,
            height: isCompleted ? 70.h : 110.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            color: Colors.grey.shade300,
          ),

          // Right Content Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title ?? "Scheduled Event",
                  style: AppTextStyles.lg18Regular.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF1E88E5),
                      size: 16,
                    ),
                    SizedBox(width: 8.w),
                    AppText(
                      duration ?? "--",
                      style: AppTextStyles.sm14Regular.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                isCompleted
                    ? Row(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4CAF50),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          AppText(
                            "Completed",
                            style: AppTextStyles.sm14Regular.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        width: double.infinity,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: AppText(
                            "Check In",
                            style: AppTextStyles.base16Medium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildAvailableCard() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time_filled, color: Colors.grey.shade400, size: 24),
          SizedBox(width: 12.w),
          AppText(
            "$timeText$ampm - Available for booking",
            style: AppTextStyles.base16Medium.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
