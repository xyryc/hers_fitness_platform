import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrainerChatScreen extends StatelessWidget {
  const TrainerChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 76.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(100.r),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 12.h),
                children: [
                  _GreetingRow(),
                  SizedBox(height: 30.h),
                  const _ChatBubble(
                    text: "I'm interested in building lean\nmuscle.",
                    isMe: true,
                  ),
                  SizedBox(height: 18.h),
                  const _ChatBubble(
                    text: "Great! Let's start with your\ncurrent diet.",
                    isMe: false,
                  ),
                  SizedBox(height: 20.h),
                  const _TimeDivider(time: "11:15 AM"),
                  SizedBox(height: 20.h),
                  const _ChatBubble(
                    text:
                        "I try to eat a balanced diet, but\nI'm not sure if I'm getting enough\nprotein.",
                    isMe: true,
                  ),
                  SizedBox(height: 18.h),
                  const _ChatBubble(
                    text: "Okay, we can definitely work on\nthat.",
                    isMe: false,
                  ),
                ],
              ),
            ),
            const _SearchComposer(),
          ],
        ),
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: const BoxDecoration(
            color: Color(0xFFFEFEFE),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            "Good afternoon Hamed",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.base16Medium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18.sp,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeDivider extends StatelessWidget {
  const _TimeDivider({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFBEBEBE), height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            time,
            style: AppTextStyles.sm14Regular.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
              letterSpacing: 0,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFBEBEBE), height: 1)),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.isMe});

  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isMe ? Colors.black : const Color(0xFFDFDFDF),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _PersonBadge(
              backgroundColor: const Color(0xFFF7F7F7),
              iconColor: const Color(0xFFB8B8B8),
              size: 42.w,
            ),
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.base16Medium.copyWith(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 17.sp,
                height: 1.35,
                letterSpacing: 0,
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 10.w),
            _PersonBadge(
              backgroundColor: AppColors.actionPrimary,
              iconColor: Colors.white.withValues(alpha: 0.9),
              size: 42.w,
            ),
          ],
        ],
      ),
    );
  }
}

class _PersonBadge extends StatelessWidget {
  const _PersonBadge({
    required this.backgroundColor,
    required this.iconColor,
    required this.size,
  });

  final Color backgroundColor;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(Icons.person, color: iconColor, size: 28.sp),
    );
  }
}

class _SearchComposer extends StatelessWidget {
  const _SearchComposer();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, bottomInset + 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: AppTextStyles.base16Regular.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                hintText: "Search supplements...",
                hintStyle: AppTextStyles.base16Regular.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 16.sp,
                  letterSpacing: 0,
                ),
                suffixIcon: Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.textTertiary,
                  size: 24.sp,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 18.w,
                  vertical: 17.h,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: Color(0xFFEFEFEF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 56.w,
            height: 64.h,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Transform.rotate(
              angle: -0.48,
              child: Icon(
                Icons.send_outlined,
                color: Colors.white,
                size: 28.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
