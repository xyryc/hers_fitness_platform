import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'AppColor/app_colors.dart';
import 'AppTextStyle/app_text_styles.dart';

void showPushNotification(
  String title,
  String message, {
  VoidCallback? onTap,
  Duration duration = const Duration(seconds: 4),
}) {
  Get.rawSnackbar(
    snackPosition: SnackPosition.TOP,
    duration: duration,
    onTap: onTap != null ? (_) => onTap() : null,
    backgroundColor: Colors.transparent,
    barBlur: 0,
    overlayBlur: 0,
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: EdgeInsets.zero,
    messageText: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.actionPrimary.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Icon / Notification Icon
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage("assets/images/welcomeLogo.png"),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.base16SemiBold.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "now",
                      style: AppTextStyles.xxs9Regular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.sm14Regular.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Dismiss Handle Indicator (Simple line)
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.actionPrimary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    ),
  );
}

void showAppSnackbar(
  String title,
  String message, {
  Color? colorText,
  Duration? duration = const Duration(seconds: 3),
  bool instantInit = true,
  SnackPosition? snackPosition,
  Widget? titleText,
  Widget? messageText,
  Widget? icon,
  bool? shouldIconPulse,
  double? maxWidth,
  EdgeInsets? margin,
  EdgeInsets? padding,
  double? borderRadius,
  Color? borderColor,
  double? borderWidth,
  Color? backgroundColor,
  Color? leftBarIndicatorColor,
  List<BoxShadow>? boxShadows,
  Gradient? backgroundGradient,
  TextButton? mainButton,
  OnTap? onTap,
  bool? isDismissible,
  bool? showProgressIndicator,
  DismissDirection? dismissDirection,
  AnimationController? progressIndicatorController,
  Color? progressIndicatorBackgroundColor,
  Animation<Color>? progressIndicatorValueColor,
  SnackStyle? snackStyle,
  Curve? forwardAnimationCurve,
  Curve? reverseAnimationCurve,
  Duration? animationDuration,
  double? barBlur,
  double? overlayBlur,
  SnackbarStatusCallback? snackbarStatus,
  Color? overlayColor,
  Form? userInputForm,
}) {
  final safeTitle = _safeSnackbarText(title, maxLength: 80);
  final safeMessage = _safeSnackbarText(message);
  final resolvedDuration = duration ?? const Duration(seconds: 3);
  final resolvedTextColor = colorText ?? AppColors.textInverse;
  final resolvedBackground = backgroundColor ?? AppColors.actionSecondary;
  final resolvedRadius = borderRadius ?? 12;
  final resolvedMargin = margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 16);
  final position = snackPosition ?? SnackPosition.BOTTOM;

  Get.closeCurrentSnackbar();

  if (position == SnackPosition.TOP || userInputForm != null) {
    _showTopGetSnackbar(
      titleText: titleText,
      messageText: messageText,
      title: safeTitle,
      message: safeMessage,
      textColor: resolvedTextColor,
      backgroundColor: resolvedBackground,
      duration: resolvedDuration,
      instantInit: instantInit,
      icon: icon,
      shouldIconPulse: shouldIconPulse,
      maxWidth: maxWidth,
      margin: margin,
      padding: padding,
      borderRadius: resolvedRadius,
      borderColor: borderColor,
      borderWidth: borderWidth,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      isDismissible: isDismissible,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle,
      forwardAnimationCurve: forwardAnimationCurve,
      reverseAnimationCurve: reverseAnimationCurve,
      animationDuration: animationDuration,
      barBlur: barBlur,
      overlayBlur: overlayBlur,
      snackbarStatus: snackbarStatus,
      overlayColor: overlayColor,
      userInputForm: userInputForm,
    );
    return;
  }

  final context = Get.context ?? Get.overlayContext;
  final messenger = context == null ? null : ScaffoldMessenger.maybeOf(context);

  if (messenger == null) {
    _showTopGetSnackbar(
      titleText: titleText,
      messageText: messageText,
      title: safeTitle,
      message: safeMessage,
      textColor: resolvedTextColor,
      backgroundColor: resolvedBackground,
      duration: resolvedDuration,
      instantInit: instantInit,
      icon: icon,
      shouldIconPulse: shouldIconPulse,
      maxWidth: maxWidth,
      margin: margin,
      padding: padding,
      borderRadius: resolvedRadius,
      borderColor: borderColor,
      borderWidth: borderWidth,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      isDismissible: isDismissible,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle,
      forwardAnimationCurve: forwardAnimationCurve,
      reverseAnimationCurve: reverseAnimationCurve,
      animationDuration: animationDuration,
      barBlur: barBlur,
      overlayBlur: overlayBlur,
      snackbarStatus: snackbarStatus,
      overlayColor: overlayColor,
      userInputForm: userInputForm,
    );
    return;
  }

  final snackBar = SnackBar(
    duration: resolvedDuration,
    behavior: SnackBarBehavior.floating,
    backgroundColor: resolvedBackground,
    margin: resolvedMargin,
    padding:
        padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(resolvedRadius),
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor, width: borderWidth ?? 1),
    ),
    content: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          IconTheme(
            data: IconThemeData(color: resolvedTextColor),
            child: icon,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _boundedText(
                titleText,
                fallback: safeTitle,
                style: AppTextStyles.sm14SemiBold.copyWith(
                  color: resolvedTextColor,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              _boundedText(
                messageText,
                fallback: safeMessage,
                style: AppTextStyles.sm14Regular.copyWith(
                  color: resolvedTextColor.withValues(alpha: 0.9),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        if (mainButton != null) ...[const SizedBox(width: 8), mainButton],
      ],
    ),
  );

  try {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  } catch (_) {
    _showTopGetSnackbar(
      titleText: titleText,
      messageText: messageText,
      title: safeTitle,
      message: safeMessage,
      textColor: resolvedTextColor,
      backgroundColor: resolvedBackground,
      duration: resolvedDuration,
      instantInit: instantInit,
      icon: icon,
      shouldIconPulse: shouldIconPulse,
      maxWidth: maxWidth,
      margin: margin,
      padding: padding,
      borderRadius: resolvedRadius,
      borderColor: borderColor,
      borderWidth: borderWidth,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      isDismissible: isDismissible,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle,
      forwardAnimationCurve: forwardAnimationCurve,
      reverseAnimationCurve: reverseAnimationCurve,
      animationDuration: animationDuration,
      barBlur: barBlur,
      overlayBlur: overlayBlur,
      snackbarStatus: snackbarStatus,
      overlayColor: overlayColor,
      userInputForm: userInputForm,
    );
  }
}

void _showTopGetSnackbar({
  required Widget? titleText,
  required Widget? messageText,
  required String title,
  required String message,
  required Color textColor,
  required Color backgroundColor,
  required Duration duration,
  required bool instantInit,
  required double borderRadius,
  Widget? icon,
  bool? shouldIconPulse,
  double? maxWidth,
  EdgeInsets? margin,
  EdgeInsets? padding,
  Color? borderColor,
  double? borderWidth,
  Color? leftBarIndicatorColor,
  List<BoxShadow>? boxShadows,
  Gradient? backgroundGradient,
  TextButton? mainButton,
  OnTap? onTap,
  bool? isDismissible,
  DismissDirection? dismissDirection,
  bool? showProgressIndicator,
  AnimationController? progressIndicatorController,
  Color? progressIndicatorBackgroundColor,
  Animation<Color>? progressIndicatorValueColor,
  SnackStyle? snackStyle,
  Curve? forwardAnimationCurve,
  Curve? reverseAnimationCurve,
  Duration? animationDuration,
  double? barBlur,
  double? overlayBlur,
  SnackbarStatusCallback? snackbarStatus,
  Color? overlayColor,
  Form? userInputForm,
}) {
  Get.rawSnackbar(
    titleText: _boundedText(
      titleText,
      fallback: title,
      style: AppTextStyles.sm14SemiBold.copyWith(color: textColor),
      maxLines: 1,
    ),
    messageText: _boundedText(
      messageText,
      fallback: message,
      style: AppTextStyles.sm14Regular.copyWith(
        color: textColor.withValues(alpha: 0.9),
      ),
      maxLines: 3,
    ),
    snackPosition: SnackPosition.TOP,
    backgroundColor: backgroundColor,
    borderRadius: borderRadius,
    margin: margin ?? const EdgeInsets.all(16),
    padding: padding ?? const EdgeInsets.all(16),
    duration: duration,
    instantInit: instantInit,
    icon: icon,
    shouldIconPulse: shouldIconPulse ?? true,
    maxWidth: maxWidth,
    borderColor: borderColor,
    borderWidth: borderWidth ?? 1,
    leftBarIndicatorColor: leftBarIndicatorColor,
    boxShadows: boxShadows,
    backgroundGradient: backgroundGradient,
    mainButton: mainButton,
    onTap: onTap,
    isDismissible: isDismissible ?? true,
    dismissDirection: dismissDirection ?? DismissDirection.up,
    showProgressIndicator: showProgressIndicator ?? false,
    progressIndicatorController: progressIndicatorController,
    progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
    progressIndicatorValueColor: progressIndicatorValueColor,
    snackStyle: snackStyle ?? SnackStyle.FLOATING,
    forwardAnimationCurve: forwardAnimationCurve ?? Curves.easeOutCirc,
    reverseAnimationCurve: reverseAnimationCurve ?? Curves.easeOutCirc,
    animationDuration: animationDuration ?? const Duration(milliseconds: 350),
    barBlur: barBlur ?? 0,
    overlayBlur: overlayBlur ?? 0,
    snackbarStatus: snackbarStatus,
    overlayColor: overlayColor,
    userInputForm: userInputForm,
  );
}

Widget _boundedText(
  Widget? customText, {
  required String fallback,
  required TextStyle style,
  required int maxLines,
}) {
  if (customText != null) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 64),
      child: ClipRect(child: customText),
    );
  }

  return Text(
    fallback,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: style,
  );
}

String _safeSnackbarText(String value, {int maxLength = 260}) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxLength) return normalized;
  return '${normalized.substring(0, maxLength).trimRight()}...';
}
