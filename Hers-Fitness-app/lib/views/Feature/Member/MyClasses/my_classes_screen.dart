import 'package:fitness/controllers/member/my_classes_controller.dart';
import 'package:fitness/models/trainer_review_model.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/CustomAppbar/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../Helpers/route.dart';

class MemberMyClassesScreen extends StatelessWidget {
  MemberMyClassesScreen({super.key});

  final MyClassesController controller = Get.put(MyClassesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          _buildTopGradient(context),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: CustomAppbar(
                    title: "My Classes",
                    showBack: false,
                    onTap: () =>
                        Get.offAllNamed(AppRoutes.memberBottomNavScreen),
                  ),
                ),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.only(left: 16.w),
                  child: _buildFilters(),
                ),
                SizedBox(height: 18.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'All Schedules',
                    style: AppTextStyles.sm14SemiBold.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: Obx(() {
                    final schedules = controller.filteredSchedules;

                    if (controller.isLoading.value && schedules.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.actionPrimary,
                        ),
                      );
                    }

                    if (schedules.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      color: AppColors.actionPrimary,
                      onRefresh: () =>
                          controller.fetchBookings(showError: true),
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 40.h),
                        itemCount: schedules.length,
                        separatorBuilder: (_, __) => SizedBox(height: 16.h),
                        itemBuilder: (context, index) {
                          final schedule = schedules[index];
                          final bookingId = schedule['id']?.toString() ?? '';
                          final trainerUserId =
                              schedule['trainerUserId']?.toString() ?? '';
                          final existingReview =
                              schedule['existingReview'] as TrainerReviewModel?;

                          return _ClassScheduleCard(
                            schedule: schedule,
                            isSubmitting: controller.isSubmitting.value,
                            onFeedback: () => _showFeedbackDialog(
                              context,
                              bookingId: bookingId,
                              trainerUserId: trainerUserId,
                              existingReview: existingReview,
                            ),
                            onCheckIn: () => controller.checkIn(bookingId),
                            onComplete: () =>
                                controller.completeBooking(bookingId),
                            onAccept: () =>
                                controller.acceptReschedule(bookingId),
                            onReschedule: () =>
                                _showRescheduleModal(context, bookingId),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGradient(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).padding.top + 250.h,
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFDADF).withValues(alpha: 0.9),
                    const Color(0xFFFFECEE).withValues(alpha: 0.8),
                    const Color(0xFFFFF7F5).withValues(alpha: 0.58),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.46, 0.78, 1],
                ),
              ),
            ),
            Positioned(
              left: -78.w,
              top: -38.h,
              width: 220.w,
              height: 220.w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFBECB).withValues(alpha: 0.5),
                      const Color(0xFFFFDDE4).withValues(alpha: 0.26),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -76.w,
              top: -26.h,
              width: 230.w,
              height: 230.w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFC1CF).withValues(alpha: 0.45),
                      const Color(0xFFFFE1E7).withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: controller.filters.map((filter) {
          return Obx(() {
            final isSelected = controller.selectedFilter.value == filter;

            return GestureDetector(
              onTap: () => controller.setFilter(filter),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 38.h,
                margin: EdgeInsets.only(right: 10.w),
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.actionPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.actionPrimary
                        : AppColors.borderPrimary,
                  ),
                ),
                child: Text(
                  filter,
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No classes found for this filter',
        style: AppTextStyles.sm14Medium.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0,
        ),
      ),
    );
  }

  void _showFeedbackDialog(
    BuildContext context, {
    required String bookingId,
    required String trainerUserId,
    TrainerReviewModel? existingReview,
  }) {
    showDialog(
      context: context,
      builder: (_) => _TrainerReviewDialog(
        controller: controller,
        bookingId: bookingId,
        trainerUserId: trainerUserId,
        existingReview: existingReview,
      ),
    );
  }

  void _showRescheduleModal(BuildContext context, String bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(44.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 56.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderPrimary,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reschedule Booking',
                      style: AppTextStyles.xl20Medium.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.actionPrimary.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 12.r,
                              offset: Offset(0, 4.h),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 24.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Divider(color: AppColors.borderSecondary, height: 1.h),
                SizedBox(height: 24.h),
                _FieldLabel(text: 'New Date'),
                SizedBox(height: 10.h),
                Obx(
                  () => _ModalField(
                    value: controller.selectedRescheduleDate.value,
                    placeholder: 'mm/dd/yyyy',
                    icon: Icons.calendar_month_outlined,
                    onTap: () => _pickDate(context),
                  ),
                ),
                SizedBox(height: 20.h),
                _FieldLabel(text: 'New Time'),
                SizedBox(height: 10.h),
                Obx(
                  () => _ModalField(
                    value: controller.selectedRescheduleTime.value,
                    placeholder: 'hh:mm a',
                    icon: Icons.access_time_rounded,
                    onTap: () => _pickTime(context),
                  ),
                ),
                SizedBox(height: 32.h),
                _SheetPrimaryButton(
                  label: 'Confirm Reschedule',
                  onTap: () {
                    Get.back();
                    controller.requestReschedule(bookingId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.actionPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      controller.updateRescheduleDate(
        DateFormat('MM/dd/yyyy').format(pickedDate),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.actionPrimary,
            primaryContainer: AppColors.actionPrimary,
            onPrimaryContainer: Colors.white,
            secondary: AppColors.actionPrimary,
            secondaryContainer: AppColors.actionPrimary,
            onSecondaryContainer: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      controller.updateRescheduleTime(DateFormat('hh:mm a').format(dateTime));
    }
  }
}

class _TrainerReviewDialog extends StatefulWidget {
  final MyClassesController controller;
  final String bookingId;
  final String trainerUserId;
  final TrainerReviewModel? existingReview;

  const _TrainerReviewDialog({
    required this.controller,
    required this.bookingId,
    required this.trainerUserId,
    this.existingReview,
  });

  @override
  State<_TrainerReviewDialog> createState() => _TrainerReviewDialogState();
}

class _TrainerReviewDialogState extends State<_TrainerReviewDialog> {
  static const int _maxCommentLength = 120;

  late final TextEditingController _commentController;
  late int _rating;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
    _rating = widget.existingReview?.rating.toInt() ?? 5;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (_rating < 1 || _rating > 5) {
      setState(() => _errorMessage = 'Please select a rating.');
      return;
    }
    if (comment.isEmpty) {
      setState(() => _errorMessage = 'Please write a short review.');
      return;
    }

    setState(() => _errorMessage = '');
    final posted = await widget.controller.submitTrainerReview(
      bookingId: widget.bookingId,
      trainerUserId: widget.trainerUserId,
      rating: _rating,
      comment: comment,
    );
    if (posted && mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your workout?',
              style: AppTextStyles.xl20SemiBold.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Help us make your fitness journey even better.',
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final value = index + 1;
                final selected = value <= _rating;

                return GestureDetector(
                  onTap: () => setState(() => _rating = value),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    selected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: selected
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD1D5DB),
                    size: 48.sp,
                  ),
                );
              }),
            ),
            SizedBox(height: 24.h),
            Container(
              height: 120.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _commentController,
                maxLength: _maxCommentLength,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Write here...',
                  hintStyle: AppTextStyles.base16Medium.copyWith(
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                style: AppTextStyles.base16Medium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_commentController.text.length} / $_maxCommentLength',
                style: AppTextStyles.sm14Medium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                _errorMessage,
                style: AppTextStyles.xs12Regular.copyWith(
                  color: AppColors.statusError,
                  letterSpacing: 0,
                ),
              ),
            ],
            SizedBox(height: 24.h),
            Obx(
              () => _SheetPrimaryButton(
                label: 'Post',
                isLoading: widget.controller.isSubmittingReview.value,
                onTap: widget.controller.isSubmittingReview.value
                    ? null
                    : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final bool isSubmitting;
  final VoidCallback onFeedback;
  final VoidCallback onCheckIn;
  final VoidCallback onComplete;
  final VoidCallback onAccept;
  final VoidCallback onReschedule;

  const _ClassScheduleCard({
    required this.schedule,
    required this.isSubmitting,
    required this.onFeedback,
    required this.onCheckIn,
    required this.onComplete,
    required this.onAccept,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final status = schedule['status']?.toString() ?? 'Upcoming';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule['title']?.toString() ?? 'Class',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.base16SemiBold.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'With ${schedule['trainer'] ?? 'Trainer'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sm14Regular.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusIndicator(status: status),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderSecondary),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_month_outlined,
                  text: schedule['date']?.toString() ?? '',
                ),
                SizedBox(height: 12.h),
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  text: schedule['time']?.toString() ?? '',
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          _CardActions(
            schedule: schedule,
            isSubmitting: isSubmitting,
            onFeedback: onFeedback,
            onCheckIn: onCheckIn,
            onComplete: onComplete,
            onAccept: onAccept,
            onReschedule: onReschedule,
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'Completed') {
      return Text(
        'Completed',
        style: AppTextStyles.sm14SemiBold.copyWith(
          color: const Color(0xFF22C55E),
          letterSpacing: 0,
        ),
      );
    }

    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        color: const Color(0xFFFFB6C1).withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.priority_high_rounded,
          size: 14.sp,
          color: AppColors.actionPrimary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.actionPrimary),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardActions extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final bool isSubmitting;
  final VoidCallback onFeedback;
  final VoidCallback onCheckIn;
  final VoidCallback onComplete;
  final VoidCallback onAccept;
  final VoidCallback onReschedule;

  const _CardActions({
    required this.schedule,
    required this.isSubmitting,
    required this.onFeedback,
    required this.onCheckIn,
    required this.onComplete,
    required this.onAccept,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final showReschedule = schedule['showReschedule'] == true;
    final showMarkAsComplete = schedule['showMarkAsComplete'] == true;
    final showChecking = schedule['showChecking'] == true;
    final showAcceptReschedule = schedule['showAcceptReschedule'] == true;
    final showReview = schedule['showReview'] == true;
    final showEditReview = schedule['showEditReview'] == true;
    final showCheckIn = schedule['showCheckIn'] == true;
    final checkInEnabled = schedule['showCheckInEnabled'] == true;

    if (showReview || showEditReview) {
      return _CardButton(
        label: showEditReview ? 'Edit Review' : 'Review',
        backgroundColor: AppColors.actionSecondary,
        foregroundColor: Colors.white,
        onTap: onFeedback,
      );
    }

    if (showAcceptReschedule) {
      return _CardButton(
        label: 'Accept New Time',
        backgroundColor: AppColors.actionSecondary,
        foregroundColor: Colors.white,
        isLoading: isSubmitting,
        onTap: isSubmitting ? null : onAccept,
      );
    }

    if (showChecking) {
      return _CardButton(
        label: 'Checking...',
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textSecondary,
        bordered: true,
      );
    }

    if (showCheckIn) {
      return _CardButton(
        label: 'Check In',
        backgroundColor: checkInEnabled
            ? AppColors.actionSecondary
            : AppColors.actionSecondary.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
        isLoading: isSubmitting,
        onTap: (checkInEnabled && !isSubmitting) ? onCheckIn : null,
      );
    }

    if (showReschedule && showMarkAsComplete) {
      // Should not happen based on logic but handled for safety
      return _CardButton(
        label: 'Mark as complete',
        backgroundColor: AppColors.actionSecondary,
        foregroundColor: Colors.white,
        isLoading: isSubmitting,
        onTap: isSubmitting ? null : onComplete,
      );
    }

    if (showMarkAsComplete) {
      return _CardButton(
        label: 'Mark as complete',
        backgroundColor: AppColors.actionSecondary,
        foregroundColor: Colors.white,
        isLoading: isSubmitting,
        onTap: isSubmitting ? null : onComplete,
      );
    }

    if (showReschedule) {
      return Row(
        children: [
          Expanded(
            child: _CardButton(
              label: 'Cancel',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              bordered: true,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _CardButton(
              label: 'Reschedule',
              backgroundColor: AppColors.actionSecondary,
              foregroundColor: Colors.white,
              isLoading: isSubmitting,
              onTap: isSubmitting ? null : onReschedule,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool bordered;
  final bool isLoading;
  final VoidCallback? onTap;

  const _CardButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.bordered = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          border: bordered ? Border.all(color: AppColors.borderPrimary) : null,
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sm14SemiBold.copyWith(
                  color: foregroundColor,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.base16Medium.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
    );
  }
}

class _ModalField extends StatelessWidget {
  final String value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;

  const _ModalField({
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue =
        value.contains('/') ||
        (value.contains(':') && !value.toLowerCase().contains('email'));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sm14Medium.copyWith(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  letterSpacing: 0,
                ),
              ),
            ),
            Icon(icon, color: Colors.black, size: 22.sp),
          ],
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SheetPrimaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.actionSecondary,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.base16SemiBold.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }
}
