import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Feature/Trainer/Home/widgets/attendee_details_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ClassDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> classData;

  const ClassDetailsBottomSheet({super.key, required this.classData});

  // Sample attendee data
  static const List<Map<String, dynamic>> _sampleAttendees = [
    {
      "name": "Seraphina Dubois",
      "class": "Yoga Flow",
      "series": "5 Series Workout",
      "age": 22,
      "weight": 54,
      "diet": "Keto Diet",
      "phone": "(225) 555-0118",
    },
    {
      "name": "Eleanor Pera",
      "class": "Yoga Flow",
      "series": "5 Series Workout",
      "age": 24,
      "weight": 60,
      "diet": "Vegan Diet",
      "phone": "(225) 555-0119",
    },
    {
      "name": "Juliette Fox",
      "class": "Yoga Flow",
      "series": "5 Series Workout",
      "age": 21,
      "weight": 52,
      "diet": "Carbo Diet",
      "phone": "(225) 555-0120",
    },
    {
      "name": "Luna Lovegood",
      "class": "Yoga Flow",
      "series": "5 Series Workout",
      "age": 23,
      "weight": 56,
      "diet": "Paleo Diet",
      "phone": "(225) 555-0121",
    },
  ];

  void _showAttendeeDetails(
    BuildContext context,
    Map<String, dynamic> attendee,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttendeeDetailsBottomSheet(attendee: attendee),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isGroup =
        classData["sessionFormat"]?.toString().toLowerCase() == "group";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                "Class Details",
                style: AppTextStyles.base16SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
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
                    child: Icon(Icons.close, size: 20, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          if (isGroup)
            // ── Group Class: Attendee List ──────────────────────────
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _sampleAttendees.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final attendee = _sampleAttendees[index];
                  return GestureDetector(
                    onTap: () => _showAttendeeDetails(context, attendee),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.network(
                              "https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop",
                              width: 56.w,
                              height: 56.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  attendee["name"]!,
                                  style: AppTextStyles.base16SemiBold.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  "${attendee["class"]} • ${attendee["series"]}",
                                  style: AppTextStyles.xs12Regular.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else ...[
            // ── One-to-one Class: Full Attendee Profile ─────────────
            Builder(
              builder: (context) {
                final attendee = _sampleAttendees.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.network(
                              "https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop",
                              width: 64.w,
                              height: 64.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  attendee["name"]!,
                                  style: AppTextStyles.base16SemiBold.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  "${attendee["class"]} • ${attendee["series"]}",
                                  style: AppTextStyles.xs12Regular.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.calendar_month_rounded,
                            iconColor: const Color(0xFFF7869A),
                            value: "${attendee["age"]} yr",
                            label: "Current Age",
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.monitor_weight_outlined,
                            iconColor: const Color(0xFF16A34A),
                            value: "${attendee["weight"]} kg",
                            label: "Current weight",
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.local_dining_outlined,
                            iconColor: const Color(0xFF0284C7),
                            value: attendee["diet"]!,
                            label: "specific diet",
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Location & Time
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 8.w),
                              AppText(
                                "Location & Time",
                                style: AppTextStyles.sm14Medium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Padding(
                            padding: EdgeInsets.only(left: 28.w),
                            child: AppText(
                              "578 Boolean Ave, New York, NY, Turing St",
                              style: AppTextStyles.xs12Regular.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Padding(
                            padding: EdgeInsets.only(left: 28.w),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 16,
                                  color: const Color(0xFF0284C7),
                                ),
                                SizedBox(width: 4.w),
                                AppText(
                                  "10-04-2026",
                                  style: AppTextStyles.xs12Regular.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Icon(
                                  Icons.access_time_filled,
                                  size: 16,
                                  color: const Color(0xFF0284C7),
                                ),
                                SizedBox(width: 4.w),
                                AppText(
                                  "11:00 AM",
                                  style: AppTextStyles.xs12Regular.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Phone Number
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 8.w),
                              AppText(
                                "Phone Number",
                                style: AppTextStyles.sm14Medium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          AppText(
                            attendee["phone"]!,
                            style: AppTextStyles.xs12Regular.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 20, color: AppColors.actionPrimary),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              label,
              style: AppTextStyles.xs12Regular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppText(
              value,
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          SizedBox(height: 8.h),
          AppText(
            value,
            style: AppTextStyles.sm14SemiBold.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          AppText(
            label,
            style: AppTextStyles.xs12Regular.copyWith(
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
