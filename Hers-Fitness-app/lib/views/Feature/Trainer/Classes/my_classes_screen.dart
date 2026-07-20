import 'package:fitness/controllers/my_classes_controller.dart';
import 'package:fitness/Helpers/route.dart';
import 'package:fitness/models/trainer_availability_model.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/CustomAppbar/custom_appbar.dart';
import 'package:fitness/views/Feature/Trainer/Classes/widgets/class_card.dart';
import 'package:fitness/views/Feature/Trainer/Classes/widgets/class_type_bottom_sheet.dart';
import 'package:fitness/views/Feature/Trainer/Classes/widgets/delete_class_dialog.dart';
import 'package:fitness/views/Feature/Trainer/Classes/widgets/edit_class_bottom_sheet.dart';
import 'package:fitness/views/Feature/Trainer/Classes/trainer_class_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MyClassesScreen extends StatelessWidget {
  MyClassesScreen({super.key});

  final MyClassesController controller = Get.isRegistered<MyClassesController>()
      ? Get.find<MyClassesController>()
      : Get.put(MyClassesController());

  void _openCreateSheet(BuildContext context) {
    showCreateClassFlow(context);
  }

  Future<void> _openEditSheet(
    BuildContext context,
    int index,
    Map<String, dynamic> cls,
  ) async {
    final details = await controller.getClassDetails(index);
    if (details == null || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditClassBottomSheet(index: index, classData: details),
    );
  }

  void _openDeleteDialog(BuildContext context, int index) async {
    final confirmed = await showDeleteClassDialog(context);
    if (confirmed == true) {
      await controller.deleteClass(index);
    }
  }

  void _openClassDetails(Map<String, dynamic> cls) {
    Get.to(() => TrainerClassDetailsScreen(classData: cls));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.offAllNamed(AppRoutes.trainerBottomNavScreen);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Stack(
          children: [
            _buildTopGradient(context),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: CustomAppbar(
                      title: "My Classes",
                      onTap: () =>
                          Get.offAllNamed(AppRoutes.trainerBottomNavScreen),
                      trailing: _buildAddButton(context),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildSectionSwitcher(),
                  Expanded(
                    child: Obx(() {
                      switch (controller.selectedSection.value) {
                        case MyClassesSection.availability:
                          return _buildAvailabilityView();
                        case MyClassesSection.history:
                          return _buildHistoryList();
                        case MyClassesSection.classes:
                          return _buildClassesList(context);
                      }
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCreateSheet(context),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Icon(Icons.add, size: 24.sp, color: Colors.black),
      ),
    );
  }

  Widget _buildSectionSwitcher() {
    return Obx(() {
      final selectedSection = controller.selectedSection.value;

      return Container(
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: Row(
          children: [
            _SwitcherOption(
              label: 'Classes',
              isSelected: selectedSection == MyClassesSection.classes,
              onTap: () => controller.setSection(MyClassesSection.classes),
            ),
            SizedBox(width: 4.w),
            _SwitcherOption(
              label: 'Availability',
              isSelected: selectedSection == MyClassesSection.availability,
              onTap: () => controller.setSection(MyClassesSection.availability),
            ),
            SizedBox(width: 4.w),
            _SwitcherOption(
              label: 'History',
              isSelected: selectedSection == MyClassesSection.history,
              onTap: () => controller.setSection(MyClassesSection.history),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHistoryList() {
    return Obx(() {
      if (controller.isHistoryLoading.value &&
          controller.completedClasses.isEmpty) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.actionPrimary),
        );
      }

      return RefreshIndicator(
        color: AppColors.actionPrimary,
        onRefresh: () => controller.fetchClassHistory(showError: true),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          itemCount: controller.completedClasses.isEmpty
              ? 2
              : controller.completedClasses.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: AppText(
                  "Past Classes",
                  style: AppTextStyles.base16SemiBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }
            if (controller.completedClasses.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(top: 80.h),
                child: Center(
                  child: AppText(
                    "No completed classes yet",
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            final cls = controller.completedClasses[index - 1];
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Stack(
                children: [
                  ClassCard(
                    className: cls["title"],
                    time: cls["time"],
                    durationMin: cls["duration"],
                    pricePerMember: cls["price"],
                    maxMembers: cls["maxMembers"],
                    classType: cls["classType"],
                    sessionFormat: cls["sessionFormat"],
                    // History cards are read-only — no edit/delete
                    onTap: () => _openClassDetails(cls),
                  ),
                  // COMPLETED badge overlay
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: AppText(
                        "Completed",
                        style: AppTextStyles.xs12Regular.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildClassesList(BuildContext context) {
    if (controller.isLoading.value && controller.classes.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.actionPrimary),
      );
    }

    return RefreshIndicator(
      color: AppColors.actionPrimary,
      onRefresh: () => controller.fetchClasses(showError: true),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        itemCount: controller.classes.isEmpty
            ? 2
            : controller.classes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: AppText(
                "All Schedules",
                style: AppTextStyles.base16SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }
          if (controller.classes.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: 80.h),
              child: Center(
                child: AppText(
                  "No classes published yet",
                  style: AppTextStyles.sm14Medium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          final classIndex = index - 1;
          final cls = controller.classes[classIndex];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: ClassCard(
              className: cls["title"],
              time: cls["time"],
              durationMin: cls["duration"],
              pricePerMember: cls["price"],
              maxMembers: cls["maxMembers"],
              classType: cls["classType"],
              sessionFormat: cls["sessionFormat"],
              onTap: () => _openClassDetails(cls),
              onEdit: () => _openEditSheet(context, classIndex, cls),
              onDelete: () => _openDeleteDialog(context, classIndex),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailabilityView() {
    if (controller.isAvailabilityLoading.value &&
        controller.availability.value == null) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.actionPrimary),
      );
    }

    return RefreshIndicator(
      color: AppColors.actionPrimary,
      onRefresh: () => controller.fetchAvailability(showError: true),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        children: [
          _AvailabilityCalendar(controller: controller),
          if (controller.isAvailabilityLoading.value) ...[
            SizedBox(height: 18.h),
            Center(
              child: SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.actionPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwitcherOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SwitcherOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.actionPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(13.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.actionPrimary.withValues(alpha: 0.34),
                      blurRadius: 0,
                      offset: Offset(0, 3.h),
                    ),
                  ]
                : null,
          ),
          child: AppText(
            label,
            style: AppTextStyles.base16Medium.copyWith(
              color: isSelected
                  ? AppColors.textInverse
                  : AppColors.textSecondary,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityCalendar extends StatelessWidget {
  final MyClassesController controller;

  const _AvailabilityCalendar({required this.controller});

  static const _weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  Widget build(BuildContext context) {
    final month = controller.focusedMonth.value;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final totalCells = firstWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  DateFormat('MMMM yyyy').format(month),
                  style: AppTextStyles.xl20SemiBold.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _MonthButton(
                icon: Icons.chevron_left_rounded,
                onTap: controller.previousMonth,
              ),
              SizedBox(width: 8.w),
              _MonthButton(
                icon: Icons.chevron_right_rounded,
                onTap: controller.nextMonth,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: _weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: AppText(
                    day,
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 10.h),
          ...List.generate(rowCount, (rowIndex) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex == rowCount - 1 ? 0 : 9.h,
              ),
              child: Row(
                children: List.generate(7, (columnIndex) {
                  final cellIndex = rowIndex * 7 + columnIndex;
                  final dayNumber = cellIndex - firstWeekday + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox.shrink());
                  }

                  return Expanded(
                    child: _CalendarDayCell(
                      day: dayNumber,
                      availability: controller.availabilityForDay(dayNumber),
                    ),
                  );
                }),
              ),
            );
          }),
          SizedBox(height: 22.h),
          Row(
            children: [
              const _LegendItem(label: 'Booked', color: Color(0xFF19AD55)),
              const Spacer(),
              _LegendItem(label: 'Available', color: AppColors.actionPrimary),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 30.sp, color: AppColors.textPrimary),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final TrainerAvailabilityDay? availability;

  const _CalendarDayCell({required this.day, required this.availability});

  @override
  Widget build(BuildContext context) {
    final isBooked = availability?.hasBookedSlot == true;
    final isAvailable = availability?.hasAvailableSlot == true;
    final highlightColor = isBooked
        ? const Color(0xFF19AD55)
        : isAvailable
        ? AppColors.actionPrimary
        : null;

    return Center(
      child: Container(
        width: 36.w,
        height: 30.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlightColor,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: AppText(
          day.toString(),
          style: AppTextStyles.base16Medium.copyWith(
            color: highlightColor == null
                ? AppColors.textPrimary
                : AppColors.textInverse,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9.w,
          height: 9.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        AppText(
          label,
          style: AppTextStyles.xs12Regular.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
