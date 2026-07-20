import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/CustomAppbar/custom_appbar.dart';
import 'package:fitness/views/Feature/Member/Trainer/widgets/review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class TrainerReviewsScreen extends StatelessWidget {
  const TrainerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final passedReviews = args is Map && args['reviews'] is List
        ? (args['reviews'] as List)
              .whereType<Map>()
              .map<Map<String, String>>(
                (item) => item.map<String, String>(
                  (key, value) =>
                      MapEntry(key.toString(), value?.toString() ?? ''),
                ),
              )
              .toList()
        : null;

    final List<Map<String, String>> reviews =
        passedReviews ??
        [
          {
            "name": "Ethan J. Wang",
            "rating": "4.6",
            "time": "5h ago",
            "text":
                "Training with coach Aisha Khan has boosted my endurance significantly. The tailored cardio workouts keep me motivated every...",
            "image":
                "https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop",
          },
          {
            "name": "Charles D. Xavier",
            "rating": "4.5",
            "time": "3d ago",
            "text":
                "I've been practicing my glutes with coach Seraphina Dubois for the past week, and I feel better! The personalized recommendation...",
            "image":
                "https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop",
          },
          {
            "name": "Lena M. Carter",
            "rating": "4.8",
            "time": "1d ago",
            "text":
                "The yoga sessions with instructor Mateo Rivera have transformed my flexibility and mindset. Highly recommend his calming ap...",
            "image":
                "https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop",
          },
        ];

    return Scaffold(
      backgroundColor: Colors.white,
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
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const CustomAppbar(title: "Reviews"),
                ),
                SizedBox(height: 24.h),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemCount: reviews.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRatingSummary(),
                            SizedBox(height: 32.h),
                            Text(
                              "Recent",
                              style: AppTextStyles.lg18Bold.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                        );
                      }

                      final review = reviews[index - 1];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: ReviewCard(
                          name: review["name"] ?? 'Member',
                          rating: review["rating"] ?? '0.0',
                          timeAgo: review["time"] ?? '',
                          reviewText: review["text"] ?? '',
                          imageUrl: review["image"] ?? '',
                        ),
                      );
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

  Widget _buildRatingSummary() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "4.5",
                  style: AppTextStyles.base16Medium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 56.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "87 Reviews",
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildRatingBar(5, 0.9),
                _buildRatingBar(4, 0.7),
                _buildRatingBar(3, 0.5),
                _buildRatingBar(2, 0.3),
                _buildRatingBar(1, 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, double progress) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text(
            "$star",
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.star, color: const Color(0xFFFFC107), size: 14.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFFFE5E9),
                color: AppColors.actionPrimary,
                minHeight: 8.h,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
