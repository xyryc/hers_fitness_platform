import 'package:flutter/material.dart';
import '../AppText/appText.dart';

class OrDivider extends StatelessWidget {
  final String text;
  final Color? lineColor; // ✅ Make nullable
  final Color? textColor; // ✅ Make nullable
  final double thickness;
  final double fontSize;
  final FontWeight fontWeight;
  final double horizontalMargin;

  const OrDivider({
    super.key,
    this.text = "OR Sign up with",
    this.lineColor, // ✅ No default value
    this.textColor, // ✅ No default value
    this.thickness = 1.0,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.horizontalMargin = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Auto-determine colors based on theme if not provided
    final finalLineColor =
        lineColor ?? (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    final finalTextColor =
        textColor ?? (isDark ? Colors.white : Colors.black54);

    return Row(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.only(right: horizontalMargin),
            height: thickness,
            color: finalLineColor,
          ),
        ),
        AppText(
          text,
          fontSize: fontSize,
          color: finalTextColor,
          fontWeight: fontWeight,
          textAlign: TextAlign.center,
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(left: horizontalMargin),
            height: thickness,
            color: finalLineColor,
          ),
        ),
      ],
    );
  }
}
