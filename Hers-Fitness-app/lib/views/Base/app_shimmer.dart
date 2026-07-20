import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
        ),
      ),
    );
  }
}

class TrainerCardShimmer extends StatelessWidget {
  const TrainerCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Shimmer
          AppShimmer(width: 52.r, height: 52.r, borderRadius: 26),
          SizedBox(width: 10.w),
          // Content Shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppShimmer(width: 150, height: 16),
                SizedBox(height: 8.h),
                const AppShimmer(width: 100, height: 14),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    AppShimmer(width: 80.w, height: 14.h),
                    SizedBox(width: 12.w),
                    AppShimmer(width: 60.w, height: 14.h),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
