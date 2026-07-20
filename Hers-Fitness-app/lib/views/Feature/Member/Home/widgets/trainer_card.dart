import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrainerCard extends StatelessWidget {
  final String name;
  final String expertise;
  final double rating;
  final String price;
  final String imageUrl;
  final String? distance;
  final int? reviewCount;
  final VoidCallback? onTap;

  const TrainerCard({
    super.key,
    required this.name,
    required this.expertise,
    required this.rating,
    required this.price,
    required this.imageUrl,
    this.distance,
    this.reviewCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Color(0xFFE4E4E7), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Container(
                padding: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderSecondary,
                    width: 1,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24.r,
                  backgroundImage: NetworkImage(imageUrl),
                ),
              ),
              SizedBox(width: 10.w),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.monitor_heart_outlined,
                          size: 18.sp,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            expertise,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (distance != null) ...[
                          SizedBox(width: 8.w),
                          Container(
                            width: 4.w,
                            height: 4.w,
                            decoration: const BoxDecoration(
                              color: AppColors.borderPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.location_on,
                            size: 18.sp,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            distance!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          double starValue = index + 1;
                          if (rating >= starValue) {
                            return Icon(
                              Icons.star,
                              size: 16.sp,
                              color: Colors.orange,
                            );
                          } else if (rating >= starValue - 0.5) {
                            return Icon(
                              Icons.star_half,
                              size: 16.sp,
                              color: Colors.orange,
                            );
                          } else {
                            return Icon(
                              Icons.star_border,
                              size: 16.sp,
                              color: Colors.orange,
                            );
                          }
                        }),
                        SizedBox(width: 8.w),
                        Text(
                          "$rating",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (reviewCount != null) ...[
                          SizedBox(width: 4.w),
                          Text(
                            "($reviewCount)",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        const Icon(
                          Icons.language,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(width: 6.w),
                        const Text(
                          "Available Remotely",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
