import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../../controllers/member/book_trainer_controller.dart';
import '../../../../../utils/AppColor/app_colors.dart';
import '../../../../../utils/AppTextStyle/app_text_styles.dart';
import '../widgets/booking_trainer_summary.dart';

class BookingDateTime extends StatelessWidget {
  final BookTrainerController controller;

  const BookingDateTime({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 116.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookingTrainerSummary(controller: controller),
          SizedBox(height: 18.h),
          Text(
            'Select Date',
            style: AppTextStyles.sm14SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 10.h),
          _buildCalendar(),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildLegend(AppColors.statusSuccess, 'Booked'),
              const Spacer(),
              _buildLegend(AppColors.actionPrimary, 'Available'),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set reminder',
                style: AppTextStyles.sm14SemiBold.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0,
                ),
              ),
              Obx(
                () => Switch.adaptive(
                  value: controller.isReminderEnabled.value,
                  onChanged: (value) =>
                      controller.isReminderEnabled.value = value,
                  activeThumbColor: AppColors.actionPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Time',
                style: AppTextStyles.sm14SemiBold.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0,
                ),
              ),
              _buildAmPmToggle(),
            ],
          ),
          SizedBox(height: 12.h),
          _buildTimeSlots(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Obx(() {
      final focusedDate = controller.focusedDate.value;
      final selectedDate = controller.selectedDate.value;

      return Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDate,
          selectedDayPredicate: (day) => isSameDay(selectedDate, day),
          onDaySelected: (selectedDay, focusedDay) {
            controller.selectDate(selectedDay, focusedDay);
          },
          rowHeight: 36.h,
          daysOfWeekHeight: 24.h,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: false,
            titleTextStyle: AppTextStyles.sm14SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
              size: 22.sp,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
              size: 22.sp,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: AppTextStyles.xxs9Medium.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0,
            ),
            weekendStyle: AppTextStyles.xxs9Medium.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: AppColors.actionPrimary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppColors.actionSecondary,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: AppTextStyles.xs12Medium.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
            weekendTextStyle: AppTextStyles.xs12Medium.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            selectedBuilder: (context, day, focusedDay) {
              return _dateBubble(
                day.day,
                AppColors.actionSecondary,
                AppColors.textInverse,
              );
            },
            defaultBuilder: (context, day, focusedDay) {
              if (controller.hasSelectedSlot(day)) {
                return _dateBubble(
                  day.day,
                  AppColors.actionSecondary,
                  AppColors.textInverse,
                );
              }
              if (controller.hasBookedSlot(day)) {
                return _dateBubble(
                  day.day,
                  AppColors.statusSuccess,
                  Colors.white,
                );
              }
              if (controller.hasAvailableSlot(day)) {
                return _dateBubble(
                  day.day,
                  AppColors.actionPrimary,
                  Colors.white,
                );
              }
              return null;
            },
          ),
        ),
      );
    });
  }

  Widget _dateBubble(int day, Color background, Color foreground) {
    return Center(
      child: Container(
        width: 30.w,
        height: 30.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(
          '$day',
          style: AppTextStyles.xs12Medium.copyWith(
            color: foreground,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 7.w,
          height: 7.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Text(
          text,
          style: AppTextStyles.xxs9Medium.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildAmPmToggle() {
    return Obx(() {
      final selectedPeriod = controller.selectedPeriod.value;

      return Container(
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Row(
          children: [
            _buildToggleItem('AM', selectedPeriod),
            _buildToggleItem('PM', selectedPeriod),
          ],
        ),
      );
    });
  }

  Widget _buildToggleItem(String label, String selectedPeriod) {
    final isSelected = selectedPeriod == label;
    return GestureDetector(
      onTap: () => controller.setPeriod(label),
      child: Container(
        width: 52.w,
        height: 28.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.actionPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Text(
          label,
          style: AppTextStyles.xxs9Medium.copyWith(
            color: isSelected ? AppColors.textInverse : AppColors.textTertiary,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Obx(() {
      final slots = controller.availableSlots;
      final filteredSlots = controller.filteredSlots;

      if (slots.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 18.h),
          child: Text(
            controller.isLoadingClasses.value
                ? 'Loading available slots...'
                : 'No available slots for this class.',
            style: AppTextStyles.xs12Medium.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0,
            ),
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8.h,
          crossAxisSpacing: 8.w,
          childAspectRatio: 2.45,
        ),
        itemCount: slots.length,
        itemBuilder: (_, index) {
          final time = slots[index];
          final slot = filteredSlots[index];
          final isSelected = slot.id == controller.selectedSlot?.id;
          final isBookable = slot.isBookable;

          return GestureDetector(
            onTap: () => controller.setTimeSlot(index),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: !isBookable
                    ? AppColors.textDisabled
                    : isSelected
                    ? AppColors.actionSecondary
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                time,
                style: AppTextStyles.xxs9Medium.copyWith(
                  color: !isBookable || isSelected
                      ? AppColors.textInverse
                      : AppColors.textPrimary,
                  letterSpacing: 0,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
