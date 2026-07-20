import 'package:fitness/controllers/trainer/trainer_schedule_controller.dart';
import 'package:fitness/models/trainer_schedule_model.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Feature/Trainer/Schedule/widgets/booking_schedule_card.dart';
import 'package:fitness/views/Feature/Trainer/Schedule/widgets/reschedule_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedIndex = 0;

  // 7-day window: 3 days back, today, 3 days forward
  final List<DateTime> _dates = List.generate(
    14,
    (i) => DateTime.now().add(Duration(days: i)),
  );

  late final TrainerScheduleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<TrainerScheduleController>()
        ? Get.find<TrainerScheduleController>()
        : Get.put(TrainerScheduleController());
  }

  String get _monthYear =>
      DateFormat('MMMM yyyy').format(_dates[_selectedIndex]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.actionPrimary,
                  ),
                );
              }

              final day = _controller.currentDay;
              final isActionLoading = _controller.isActionLoading.value;

              return RefreshIndicator(
                color: AppColors.actionPrimary,
                onRefresh: () => _controller.fetchSchedule(),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 20.h,
                  ),
                  children: [
                    if (day != null) _buildDaySummary(day),
                    if (day != null && day.items.isNotEmpty)
                      ...day.items.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: BookingScheduleCard(
                            item: item,
                            isActionLoading: isActionLoading,
                            onCheckIn: item.actions.canCheckIn
                                ? () => _controller.performCheckIn(
                                    item.booking.id,
                                  )
                                : null,
                            onMarkComplete: item.actions.canMarkComplete
                                ? () => _controller.performMarkComplete(
                                    item.booking.id,
                                  )
                                : null,
                            onAcceptReschedule: item.actions.canAcceptReschedule
                                ? () => _confirmAcceptReschedule(item)
                                : null,
                            onReschedule: item.actions.canReschedule
                                ? () => _openRescheduleSheet(item)
                                : null,
                          ),
                        ),
                      )
                    else
                      _buildEmptyState(),
                    SizedBox(height: 32.h),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        bottom: 12.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.actionPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                ),
                AppText(
                  'Schedule',
                  style: AppTextStyles.xl20Medium.copyWith(color: Colors.white),
                ),
                SizedBox(width: 48.w),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.020),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: AppText(
              _monthYear,
              style: AppTextStyles.base16Medium.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 105.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
              itemCount: _dates.length,
              itemBuilder: (context, index) {
                final date = _dates[index];
                return _buildDateChip(
                  day: DateFormat('EEE').format(date),
                  date: DateFormat('d').format(date),
                  isSelected: index == _selectedIndex,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    _controller.selectDate(_dates[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String day,
    required String date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65.w,
        margin: EdgeInsets.only(right: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : const Color(0xFFE06F83).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(35),
          border: isSelected
              ? Border.all(color: const Color(0xFFE06F83), width: 1)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    spreadRadius: 4,
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              day,
              style: AppTextStyles.xs12Regular.copyWith(
                color: isSelected ? Colors.black87 : Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            AppText(
              date,
              style: AppTextStyles.base16Medium.copyWith(
                color: isSelected ? Colors.black87 : Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFFA6A85)
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySummary(TrainerScheduleDay day) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          _SummaryPill(
            label: 'Total',
            value: day.totalCount,
            color: AppColors.actionPrimary,
          ),
          SizedBox(width: 8.w),
          _SummaryPill(
            label: 'Done',
            value: day.completedCount,
            color: AppColors.statusSuccess,
          ),
          SizedBox(width: 8.w),
          _SummaryPill(
            label: 'Upcoming',
            value: day.upcomingCount,
            color: AppColors.statusInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80.h),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 56,
              color: AppColors.textDisabled,
            ),
            SizedBox(height: 12.h),
            AppText(
              'No bookings for this day',
              style: AppTextStyles.base16Medium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 6.h),
            AppText(
              'Pull down to refresh',
              style: AppTextStyles.sm14Regular.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRescheduleSheet(TrainerScheduleItem item) {
    RescheduleBottomSheet.show(
      context,
      memberName: item.booking.fullName,
      className: item.booking.scheduleClass?.name ?? 'Session',
      onSubmit: (date, time) => _controller.performRequestReschedule(
        item.booking.id,
        scheduledDate: date,
        startTime: time,
      ),
    );
  }

  void _confirmAcceptReschedule(TrainerScheduleItem item) {
    final booking = item.booking;
    final proposedInfo = booking.proposedScheduledDate != null
        ? '${booking.proposedScheduledDate}'
              '${booking.proposedStartTime != null ? ' at ${booking.proposedStartTime}' : ''}'
        : 'the proposed time';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: AppText(
          'Accept Reschedule?',
          style: AppTextStyles.lg18SemiBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: AppText(
          'Accept reschedule for ${booking.fullName} to $proposedInfo?',
          style: AppTextStyles.sm14Regular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: AppText(
              'Cancel',
              style: AppTextStyles.sm14Medium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.performAcceptReschedule(booking.id);
            },
            child: AppText(
              'Accept',
              style: AppTextStyles.sm14SemiBold.copyWith(
                color: AppColors.actionPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          AppText(
            '$label: $value',
            style: AppTextStyles.xs12SemiBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
