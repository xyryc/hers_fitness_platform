import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../utils/AppColor/app_colors.dart';

class CustomAppbar extends StatelessWidget {
  final String? title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showBack;

  const CustomAppbar({
    super.key,
    this.title,
    this.onTap,
    this.trailing,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          GestureDetector(
            onTap: onTap ?? () => Get.back(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF9F9F9),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.actionPrimary, // Crisp solid pink crescent
                    blurRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.05,
                    ), // Soft global depth
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
          )
        else
          SizedBox(width: 48.w),
        if (title != null) ...[
          Expanded(
            child: Center(
              child: AppText(
                title!,
                style: AppTextStyles.xl20Medium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          trailing ?? SizedBox(width: 48.w),
        ] else if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}
