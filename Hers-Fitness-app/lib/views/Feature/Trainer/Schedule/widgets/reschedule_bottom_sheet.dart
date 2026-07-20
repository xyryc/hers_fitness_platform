import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class RescheduleBottomSheet extends StatefulWidget {
  final String memberName;
  final String className;
  final Future<void> Function(String date, String startTime) onSubmit;

  const RescheduleBottomSheet({
    super.key,
    required this.memberName,
    required this.className,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String memberName,
    required String className,
    required Future<void> Function(String date, String startTime) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RescheduleBottomSheet(
        memberName: memberName,
        className: className,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  bool get _canSubmit => _selectedDate != null && _selectedTime != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.borderPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              AppText(
                'Request Reschedule',
                style: AppTextStyles.xl20SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              AppText(
                '${widget.memberName} · ${widget.className}',
                style: AppTextStyles.sm14Regular.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              SizedBox(height: 24.h),

              // Date field
              AppText(
                'New Date',
                style: AppTextStyles.sm14SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              _PickerField(
                icon: Icons.calendar_today_outlined,
                hint: 'Select a date',
                value: _selectedDate != null
                    ? DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!)
                    : null,
                onTap: _pickDate,
              ),
              SizedBox(height: 16.h),

              // Time field
              AppText(
                'New Start Time',
                style: AppTextStyles.sm14SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              _PickerField(
                icon: Icons.access_time_outlined,
                hint: 'Select a time',
                value: _selectedTime?.format(context),
                onTap: _pickTime,
              ),
              SizedBox(height: 28.h),

              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _canSubmit && !_isSubmitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionPrimary,
                    disabledBackgroundColor: AppColors.actionPrimaryDisabled,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : AppText(
                          'Send Request',
                          style: AppTextStyles.base16SemiBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.actionPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.actionPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final hour = _selectedTime!.hour.toString().padLeft(2, '0');
    final minute = _selectedTime!.minute.toString().padLeft(2, '0');

    try {
      await widget.onSubmit(dateStr, '$hour:$minute');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context);
      }
    }
  }
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  const _PickerField({
    required this.icon,
    required this.hint,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AppColors.actionPrimary : AppColors.borderPrimary,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: hasValue
                  ? AppColors.actionPrimary
                  : AppColors.textTertiary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppText(
                value ?? hint,
                style: AppTextStyles.base16Regular.copyWith(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
