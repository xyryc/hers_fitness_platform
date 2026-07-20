import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppIcons/app_icons.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ClassCard extends StatelessWidget {
  final String className;
  final String time;
  final int durationMin;
  final double pricePerMember;
  final int maxMembers;
  final String? classType;
  final String sessionFormat;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ClassCard({
    super.key,
    required this.className,
    required this.time,
    required this.durationMin,
    required this.pricePerMember,
    required this.maxMembers,
    required this.sessionFormat,
    this.classType,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    bool isGroup = sessionFormat.toLowerCase() == "group";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + action buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        className,
                        style: AppTextStyles.xl20SemiBold.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 22,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: 8.w),
                          AppText(
                            "$time ($durationMin m)",
                            style: AppTextStyles.base16Regular.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _ActionButton(svgPath: AppIcons.edit, onTap: onEdit),
                SizedBox(width: 12.w),
                _ActionButton(svgPath: AppIcons.delete, onTap: onDelete),
              ],
            ),
            SizedBox(height: 20.h),

            // Info Container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      label: "Class type",
                      value: classType ?? "N/A",
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _InfoChip(
                      label: "Per Member",
                      value: "\$${pricePerMember.toStringAsFixed(0)}",
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _InfoChip(
                      label: isGroup ? "Max Member" : "Session Format",
                      value: isGroup ? "$maxMembers" : sessionFormat,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40.h,
      color: Colors.grey.shade200,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String svgPath;
  final VoidCallback? onTap;

  const _ActionButton({required this.svgPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52.w,
        height: 52.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          color: const Color(0xFFF9F9F9),
          boxShadow: [
            BoxShadow(
              color: AppColors.actionPrimary.withValues(alpha: 0.4),
              blurRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            svgPath,
            width: 24.w,
            height: 24.w,
            colorFilter: const ColorFilter.mode(
              Colors.black87,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          style: AppTextStyles.xs12Regular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 6.h),
        AppText(
          value,
          style: AppTextStyles.sm14Medium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
