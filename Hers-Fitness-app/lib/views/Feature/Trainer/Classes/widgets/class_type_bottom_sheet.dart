import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'create_class_bottom_sheet.dart';

Future<void> showCreateClassFlow(BuildContext context) async {
  final selectedSessionType =
      await showModalBottomSheet<TrainerCreateSessionType>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ClassTypeBottomSheet(),
      );

  if (selectedSessionType == null || !context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CreateClassBottomSheet(sessionType: selectedSessionType),
  );
}

class ClassTypeBottomSheet extends StatefulWidget {
  const ClassTypeBottomSheet({super.key});

  @override
  State<ClassTypeBottomSheet> createState() => _ClassTypeBottomSheetState();
}

class _ClassTypeBottomSheetState extends State<ClassTypeBottomSheet> {
  TrainerCreateSessionType _selectedType = TrainerCreateSessionType.monthly;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 64.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              Text(
                "Select Class Type",
                style: AppTextStyles.xl20SemiBold.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 28.h),
              _SessionTypeTile(
                title: TrainerCreateSessionType.monthly.label,
                isSelected: _selectedType == TrainerCreateSessionType.monthly,
                onTap: () => setState(
                  () => _selectedType = TrainerCreateSessionType.monthly,
                ),
              ),
              SizedBox(height: 12.h),
              _SessionTypeTile(
                title: TrainerCreateSessionType.single.label,
                isSelected: _selectedType == TrainerCreateSessionType.single,
                onTap: () => setState(
                  () => _selectedType = TrainerCreateSessionType.single,
                ),
              ),
              SizedBox(height: 32.h),
              GestureDetector(
                onTap: () => Navigator.pop(context, _selectedType),
                child: Container(
                  height: 56.h,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.actionSecondary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Select",
                        style: AppTextStyles.base16SemiBold.copyWith(
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTypeTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionTypeTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 84.h,
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppColors.actionPrimary : Colors.transparent,
            width: 1.4.w,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.actionPrimary.withValues(alpha: 0.18),
                blurRadius: 0,
                spreadRadius: 3.r,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Text(
          title,
          style: AppTextStyles.xl20SemiBold.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
