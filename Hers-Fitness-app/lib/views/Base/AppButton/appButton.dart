import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../utils/AppColor/app_colors.dart';
import '../Ios_effect/iosTapEffect.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color backgroundColor;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final bool showArrow;

  const AppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.backgroundColor = AppColors.actionSecondary,
    this.height = 52,
    this.borderRadius = 12,
    this.isLoading = false,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return IosTapEffect(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CupertinoActivityIndicator(
                    radius: 12,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),

                    /// 👉 Optional Arrow
                    if (showArrow) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
