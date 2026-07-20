import 'package:fitness/models/trainer_schedule_model.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingScheduleCard extends StatelessWidget {
  final TrainerScheduleItem item;
  final VoidCallback? onCheckIn;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onAcceptReschedule;
  final VoidCallback? onReschedule;
  final bool isActionLoading;

  const BookingScheduleCard({
    super.key,
    required this.item,
    this.onCheckIn,
    this.onMarkComplete,
    this.onAcceptReschedule,
    this.onReschedule,
    this.isActionLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final booking = item.booking;
    final actions = item.actions;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSecondary, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimeBlock(booking: booking),
          Container(
            width: 1,
            height: 130.h,
            margin: EdgeInsets.symmetric(horizontal: 14.w),
            color: AppColors.borderPrimary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _BookingInfo(booking: booking)),
                    SizedBox(width: 8.w),
                    _StatusChip(label: actions.label),
                  ],
                ),
                SizedBox(height: 12.h),
                _ActionButtons(
                  actions: actions,
                  isActionLoading: isActionLoading,
                  onCheckIn: onCheckIn,
                  onMarkComplete: onMarkComplete,
                  onAcceptReschedule: onAcceptReschedule,
                  onReschedule: onReschedule,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final TrainerScheduleBooking booking;

  const _TimeBlock({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time_filled,
            color: AppColors.actionPrimary,
            size: 22,
          ),
          SizedBox(height: 6.h),
          AppText(
            booking.displayStartTime,
            style: AppTextStyles.xs12Medium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          AppText(
            '—',
            style: AppTextStyles.xs12Regular.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: 2.h),
          AppText(
            booking.displayEndTime,
            style: AppTextStyles.xs12Medium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (booking.scheduleClass?.durationMinutes != null) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppText(
                '${booking.scheduleClass!.durationMinutes}m',
                style: AppTextStyles.xxs9Medium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingInfo extends StatelessWidget {
  final TrainerScheduleBooking booking;

  const _BookingInfo({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          booking.fullName,
          style: AppTextStyles.base16SemiBold.copyWith(
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        AppText(
          booking.scheduleClass?.name ?? 'Session',
          style: AppTextStyles.sm14Regular.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (booking.location != null && booking.location!.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: AppText(
                  booking.location!,
                  style: AppTextStyles.xs12Regular.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = _chipColors(label);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        label,
        style: AppTextStyles.xxs9SemiBold.copyWith(
          color: colors.$2,
          letterSpacing: 0,
        ),
      ),
    );
  }

  (Color, Color) _chipColors(String label) {
    switch (label.toLowerCase()) {
      case 'upcoming':
        return (AppColors.bgTertiaryGrey, AppColors.textSecondary);
      case 'in progress':
        return (const Color(0xFFE3F2FD), AppColors.statusInfo);
      case 'check in':
        return (const Color(0xFFFFF3E0), AppColors.statusWarning);
      case 'mark as complete':
        return (AppColors.statusSuccessSubtle, AppColors.statusSuccess);
      case 'reschedule pending':
        return (AppColors.statusWarningSubtle, AppColors.statusWarning);
      case 'accept reschedule':
        return (AppColors.statusWarningSubtle, AppColors.statusWarning);
      case 'completed':
        return (AppColors.statusSuccessSubtle, AppColors.statusSuccess);
      default:
        return (AppColors.bgTertiaryGrey, AppColors.textTertiary);
    }
  }
}

class _ActionButtons extends StatelessWidget {
  final TrainerScheduleActions actions;
  final bool isActionLoading;
  final VoidCallback? onCheckIn;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onAcceptReschedule;
  final VoidCallback? onReschedule;

  const _ActionButtons({
    required this.actions,
    required this.isActionLoading,
    this.onCheckIn,
    this.onMarkComplete,
    this.onAcceptReschedule,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (actions.canCheckIn) {
      buttons.add(
        _ActionButton(
          label: 'Check In',
          color: AppColors.statusWarning,
          background: const Color(0xFFFFF3E0),
          icon: Icons.login_rounded,
          onTap: isActionLoading ? null : onCheckIn,
          isLoading: isActionLoading,
        ),
      );
    }

    if (actions.canMarkComplete) {
      buttons.add(
        _ActionButton(
          label: 'Mark Complete',
          color: Colors.white,
          background: AppColors.actionSecondary,
          icon: Icons.check_circle_outline,
          onTap: isActionLoading ? null : onMarkComplete,
          isLoading: isActionLoading,
        ),
      );
    }

    if (actions.canAcceptReschedule) {
      buttons.add(
        _ActionButton(
          label: 'Accept Reschedule',
          color: AppColors.statusWarning,
          background: AppColors.statusWarningSubtle,
          icon: Icons.event_available_outlined,
          onTap: isActionLoading ? null : onAcceptReschedule,
          isLoading: isActionLoading,
        ),
      );
    }

    // Show Reschedule only when no higher-priority action is visible
    if (actions.canReschedule &&
        !actions.canCheckIn &&
        !actions.canMarkComplete &&
        !actions.canAcceptReschedule) {
      buttons.add(
        _ActionButton(
          label: 'Reschedule',
          color: AppColors.textSecondary,
          background: AppColors.bgTertiaryGrey,
          icon: Icons.schedule,
          onTap: isActionLoading ? null : onReschedule,
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8.w, runSpacing: 6.h, children: buttons);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon, size: 14, color: color),
            SizedBox(width: 6.w),
            AppText(
              label,
              style: AppTextStyles.xs12SemiBold.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
