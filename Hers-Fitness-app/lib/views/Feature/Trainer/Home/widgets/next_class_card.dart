import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NextClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final VoidCallback onTap;
  final String? imageUrl;

  const NextClassCard({
    super.key,
    required this.classData,
    required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.r),
          color: const Color(0xFF2C2C2C),
          image: (imageUrl != null && imageUrl!.isNotEmpty)
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.15),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.r),
            gradient: LinearAlignment(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.6),
              ],
            ).toLinearGradient(),
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row (Date & Duration) ──────────────────────
              Row(
                children: [
                  _Badge(
                    icon: Icons.calendar_month_rounded,
                    text: classData["date"] ?? "10-04-2026",
                  ),
                  SizedBox(width: 12.w),
                  _Badge(
                    icon: Icons.access_time_filled,
                    text: "${classData["duration"] ?? 30}min",
                  ),
                ],
              ),
              const Spacer(),

              // ── Bottom Section ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          classData["title"] ?? "Yoga Flow",
                          style: AppTextStyles.xl20SemiBold.copyWith(
                            color: Colors.white,
                            fontSize: 26.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        AppText(
                          classData["series"] ?? "5 Series Workout",
                          style: AppTextStyles.sm14Medium.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Pink Action Button ──────────────────────────
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: AppColors.actionPrimary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Badge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: Colors.white),
          SizedBox(width: 6.w),
          AppText(
            text,
            style: AppTextStyles.xs12Regular.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Helper extension for LinearAlignment if needed, but I'll use standard LinearGradient
extension on LinearAlignment {
  LinearGradient toLinearGradient() =>
      LinearGradient(begin: begin, end: end, colors: colors);
}

class LinearAlignment {
  final Alignment begin;
  final Alignment end;
  final List<Color> colors;
  LinearAlignment({
    required this.begin,
    required this.end,
    required this.colors,
  });
}
