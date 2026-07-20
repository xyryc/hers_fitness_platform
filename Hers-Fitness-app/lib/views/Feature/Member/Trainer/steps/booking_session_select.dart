import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../../controllers/member/book_trainer_controller.dart';
import '../../../../../utils/AppColor/app_colors.dart';
import '../../../../../utils/AppTextStyle/app_text_styles.dart';
import '../widgets/booking_trainer_summary.dart';

class BookingSessionSelect extends StatelessWidget {
  final BookTrainerController controller;

  const BookingSessionSelect({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 116.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookingTrainerSummary(controller: controller),
          SizedBox(height: 24.h),

          Text(
            '1. Select Class Type',
            style: AppTextStyles.base16SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12.h),
          _ClassTypePicker(controller: controller),
          SizedBox(height: 24.h),

          Text(
            '2. Choose your Class',
            style: AppTextStyles.base16SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12.h),
          _ClassSelector(controller: controller),
          SizedBox(height: 24.h),

          Obx(() {
            if (controller.isLoadingClasses.value &&
                controller.selectedClassSlots.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(
                    color: AppColors.actionPrimary,
                  ),
                ),
              );
            }

            if (controller.selectedClass == null) {
              return _emptyState(
                controller.classesErrorMessage.value.isNotEmpty
                    ? controller.classesErrorMessage.value
                    : 'No classes available for this type.',
                isError: controller.classesErrorMessage.value.isNotEmpty,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  height: 48.h,
                  color: AppColors.borderPrimary.withValues(alpha: 0.5),
                ),
                Text(
                  '3. Pick a Date & Time',
                  style: AppTextStyles.base16SemiBold.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                if (controller.isMonthlySelection) ...[
                  SizedBox(height: 16.h),
                  _CalendarView(controller: controller),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      _legendItem(const Color(0xFF22C55E), 'Booked'),
                      SizedBox(width: 24.w),
                      _legendItem(AppColors.actionPrimary, 'Available'),
                    ],
                  ),
                ] else ...[
                  SizedBox(height: 16.h),
                  _SingleSessionDateInfo(controller: controller),
                ],

                SizedBox(height: 32.h),
                if (controller.isMonthlySelection) ...[
                  _SelectedMonthlySlots(controller: controller),
                  SizedBox(height: 18.h),
                ],
                _TimeSlotsGrid(controller: controller),

                SizedBox(height: 32.h),
                _ReminderSwitch(controller: controller),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          text,
          style: AppTextStyles.xs12Regular.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message, {bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isError
              ? AppColors.statusError.withValues(alpha: 0.3)
              : AppColors.borderPrimary,
        ),
      ),
      child: Text(
        message,
        style: AppTextStyles.sm14Medium.copyWith(
          color: isError ? AppColors.statusError : AppColors.textSecondary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SingleSessionDateInfo extends StatelessWidget {
  final BookTrainerController controller;
  const _SingleSessionDateInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    final slots = controller.selectedClassSlots;
    if (slots.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available,
            color: AppColors.actionPrimary,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Text(
            slots.first.displayDate,
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderSwitch extends StatelessWidget {
  final BookTrainerController controller;
  const _ReminderSwitch({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: AppColors.actionPrimary,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Set reminder',
                style: AppTextStyles.sm14Medium.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          Obx(
            () => Switch.adaptive(
              value: controller.isReminderEnabled.value,
              onChanged: (value) => controller.isReminderEnabled.value = value,
              activeThumbColor: AppColors.actionPrimary,
              activeTrackColor: AppColors.actionPrimary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassTypePicker extends StatelessWidget {
  final BookTrainerController controller;

  const _ClassTypePicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: Offset(0, 48.h),
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      onSelected: controller.setClassType,
      itemBuilder: (_) => controller.classTypes
          .map(
            (type) => PopupMenuItem<String>(
              value: type,
              height: 42.h,
              child: Text(
                type == 'IN_PERSON' ? 'In person session' : 'Online session',
                style: AppTextStyles.sm14Medium.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 52.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.borderPrimary, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Obx(
              () => Icon(
                controller.selectedClassType.value == 'IN_PERSON'
                    ? Icons.location_on_outlined
                    : Icons.videocam_outlined,
                size: 20.sp,
                color: AppColors.actionPrimary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Obx(
                () => Text(
                  controller.selectedClassType.value == 'IN_PERSON'
                      ? 'In person session'
                      : 'Online session',
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 22.sp,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassSelector extends StatelessWidget {
  final BookTrainerController controller;

  const _ClassSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final classes = controller.filteredClasses;

      if (classes.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: List.generate(classes.length, (index) {
          final item = classes[index];
          final selected = controller.selectedClassIndex.value == index;

          return GestureDetector(
            onTap: () => controller.setClassIndex(index),
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.actionPrimary.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: selected
                      ? AppColors.actionPrimary
                      : AppColors.borderPrimary,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTextStyles.base16SemiBold.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${_planLabel(item.sessionPlanType)} • ${item.availableSlots.where((slot) => slot.isBookable).length} times available',
                          style: AppTextStyles.xs12Medium.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.actionPrimary,
                    )
                  else
                    const Icon(
                      Icons.radio_button_off,
                      color: AppColors.borderPrimary,
                    ),
                ],
              ),
            ),
          );
        }),
      );
    });
  }

  String _planLabel(String? value) {
    final text = (value ?? '').toUpperCase();
    if (text.contains('MONTH')) return 'Monthly';
    return 'Single Session';
  }
}

class _CalendarView extends StatelessWidget {
  final BookTrainerController controller;

  const _CalendarView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final focusedDate = controller.focusedDate.value;

      final selectedSlotDates = controller.selectedSlots
          .map((s) {
            final d = DateTime.tryParse(s.date);
            return d != null ? DateTime(d.year, d.month, d.day) : null;
          })
          .whereType<DateTime>()
          .toSet();

      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.borderPrimary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDate,
          selectedDayPredicate: (day) {
            final dateOnly = DateTime(day.year, day.month, day.day);
            final viewedDate = controller.selectedDate.value;
            final viewedDateOnly = DateTime(
              viewedDate.year,
              viewedDate.month,
              viewedDate.day,
            );
            return selectedSlotDates.contains(dateOnly) ||
                dateOnly == viewedDateOnly;
          },
          onDaySelected: (selectedDay, focusedDay) {
            controller.selectDate(selectedDay, focusedDay);
          },
          onPageChanged: (focusedDay) {
            controller.focusedDate.value = focusedDay;
          },
          rowHeight: 48.h,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: AppTextStyles.base16SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              size: 24.sp,
              color: AppColors.textPrimary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              size: 24.sp,
              color: AppColors.textPrimary,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: AppTextStyles.xs12Medium.copyWith(
              color: AppColors.textTertiary,
            ),
            weekendStyle: AppTextStyles.xs12Medium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: AppColors.actionPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            selectedBuilder: (context, day, focusedDay) {
              return _dateBubble(day.day, Colors.black, Colors.white);
            },
            defaultBuilder: (context, day, focusedDay) {
              final dateOnly = DateTime(day.year, day.month, day.day);
              if (selectedSlotDates.contains(dateOnly)) {
                return _dateBubble(day.day, Colors.black, Colors.white);
              }
              if (controller.hasBookedSlot(day)) {
                return _dateBubble(
                  day.day,
                  const Color(0xFF22C55E),
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
        width: 34.w,
        height: 34.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(
          '$day',
          style: AppTextStyles.sm14Medium.copyWith(
            color: foreground,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _TimeSlotsGrid extends StatelessWidget {
  final BookTrainerController controller;

  const _TimeSlotsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedDate = controller.isMonthlySelection
          ? controller.selectedMonthlyDate.value
          : controller.selectedDate.value;

      if (selectedDate == null) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderPrimary),
          ),
          child: Text(
            'Select a date to see available times.',
            textAlign: TextAlign.center,
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0,
            ),
          ),
        );
      }

      final formattedDate = DateFormat('MMMM dd').format(selectedDate);

      // Get ALL slots for the date (including unbookable ones)
      final slots = controller.selectedClassSlots.where((slot) {
        final d = DateTime.tryParse(slot.date);
        return d != null &&
            d.year == selectedDate.year &&
            d.month == selectedDate.month &&
            d.day == selectedDate.day;
      }).toList();

      if (slots.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Time for $formattedDate',
              style: AppTextStyles.sm14SemiBold.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    color: AppColors.textTertiary,
                    size: 32.sp,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'No slots available for this date.',
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Try picking another day from the calendar.',
                    style: AppTextStyles.xs12Regular.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Time for $formattedDate',
            style: AppTextStyles.sm14SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
              childAspectRatio: 3.2,
            ),
            itemCount: slots.length,
            itemBuilder: (_, index) {
              final slot = slots[index];
              final isSelected = controller.selectedSlotIds.contains(slot.id);
              final isBookable = slot.isBookable;

              return GestureDetector(
                onTap: () => controller.selectSlot(slot),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !isBookable
                        ? AppColors.textDisabled
                        : isSelected
                        ? Colors.black
                        : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: !isBookable
                          ? AppColors.textDisabled
                          : isSelected
                          ? Colors.black
                          : AppColors.borderPrimary,
                    ),
                  ),
                  child: Text(
                    _slotLabel(slot),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.xs12SemiBold.copyWith(
                      color: !isBookable || isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  String _slotLabel(dynamic slot) {
    final endTime = slot.displayEndTime?.toString() ?? '';
    if (endTime.isEmpty) return slot.displayTime;
    return '${slot.displayTime} - $endTime';
  }
}

class _SelectedMonthlySlots extends StatelessWidget {
  final BookTrainerController controller;

  const _SelectedMonthlySlots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final slots = controller.selectedSlots;
      if (slots.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Times',
            style: AppTextStyles.sm14SemiBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: slots.map((slot) {
              return GestureDetector(
                onTap: () => controller.selectSlot(slot),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${_slotDateLabel(slot.date)} • ${_slotLabel(slot)}',
                        style: AppTextStyles.xs12SemiBold.copyWith(
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }

  String _slotLabel(dynamic slot) {
    final endTime = slot.displayEndTime?.toString() ?? '';
    if (endTime.isEmpty) return slot.displayTime;
    return '${slot.displayTime} - $endTime';
  }

  String _slotDateLabel(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return DateFormat('MMM d').format(parsed);
  }
}
