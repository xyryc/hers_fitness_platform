import 'package:fitness/controllers/my_classes_controller.dart';
import 'package:fitness/models/trainer_class_model.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/CustomTextfield/CustomTextfield.dart';
import 'package:fitness/views/Feature/Trainer/Classes/trainer_class_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fitness/utils/app_snackbar.dart';

class CreateClassBottomSheet extends StatefulWidget {
  final TrainerCreateSessionType sessionType;

  const CreateClassBottomSheet({
    super.key,
    this.sessionType = TrainerCreateSessionType.single,
  });

  @override
  State<CreateClassBottomSheet> createState() => _CreateClassBottomSheetState();
}

enum TrainerCreateSessionType {
  monthly('Monthly session'),
  single('Single session');

  const TrainerCreateSessionType(this.label);

  final String label;

  bool get isMonthly => this == TrainerCreateSessionType.monthly;
}

class _AvailabilitySelection {
  final DateTime start;
  final DateTime? end;

  const _AvailabilitySelection({required this.start, this.end});

  int? get durationMinutes => end?.difference(start).inMinutes;
}

class _CreateClassBottomSheetState extends State<CreateClassBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final MyClassesController controller = Get.find<MyClassesController>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  final List<_AvailabilitySelection> _selectedSlots =
      <_AvailabilitySelection>[];
  String? _selectedType;
  String? _selectedFormat;

  final List<String> _classTypes = ["Online", "In Person"];
  final List<String> _sessionFormats = ["One-to-one", "Group"];
  static const int _minimumSlotDuration = 15;
  static const int _slotDurationStep = 15;

  String get _dateTimeLabel => widget.sessionType.isMonthly
      ? "Pick your available time and date"
      : "Pick a time and date";

  String get _dateTimeHint => widget.sessionType.isMonthly
      ? "Select dates & time"
      : "Pick date, start & end time";

  String get _dateTimeValidationMessage => widget.sessionType.isMonthly
      ? "Please pick at least one available time and date."
      : "Please pick a date, start time, and end time.";

  bool get _hasSelectedDateTime => _selectedSlots.isNotEmpty;

  String get _dateTimeFieldText {
    if (widget.sessionType.isMonthly) {
      final generatedSlotCount = _generatedSlotCount;
      if (generatedSlotCount > 0) {
        return "$generatedSlotCount slots will be created";
      }

      return _hasSelectedDateTime
          ? "${_selectedSlots.length} dates selected"
          : _dateTimeHint;
    }

    if (_hasSelectedDateTime) {
      return _formatSlotLabel(_selectedSlots.first);
    }

    return _dateTimeHint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    if (widget.sessionType.isMonthly) {
      await _pickMonthlyAvailability();
      return;
    }

    await _pickSingleDateTime();
  }

  Future<void> _pickSingleDateTime() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final previousDateTime = _selectedSlots.isNotEmpty
        ? _selectedSlots.first.start
        : now;
    final initialDate = previousDateTime.isBefore(firstDate)
        ? firstDate
        : previousDateTime;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.actionPrimary),
          textTheme: Theme.of(context).textTheme.copyWith(
            // Controls the large "Mon, Apr 27" headline in date picker header
            headlineMedium: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            headlineSmall: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (pickedDate == null) return;

    final pickedStartTime = await showTimePicker(
      context: context,
      initialTime: _selectedSlots.isNotEmpty
          ? TimeOfDay.fromDateTime(_selectedSlots.first.start)
          : TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.actionPrimary,
            primaryContainer: AppColors.actionPrimary,
            onPrimaryContainer: Colors.white,
            secondary: AppColors.actionPrimary,
            secondaryContainer: AppColors.actionPrimary,
            onSecondaryContainer: Colors.white,
            surface: Colors.white,
          ),
          textTheme: Theme.of(context).textTheme.copyWith(
            // Controls large hour / minute digits on the clock face
            displayLarge: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w600,
              letterSpacing: -1,
            ),
            // Controls smaller minute scroll numbers
            bodyLarge: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (pickedStartTime == null) return;

    final startDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedStartTime.hour,
      pickedStartTime.minute,
    );

    final previousEndDateTime = _selectedSlots.isNotEmpty
        ? _selectedSlots.first.end
        : null;
    final initialEndDateTime =
        previousEndDateTime ?? startDateTime.add(const Duration(hours: 1));

    final pickedEndTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialEndDateTime),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.actionPrimary,
            primaryContainer: AppColors.actionPrimary,
            onPrimaryContainer: Colors.white,
            secondary: AppColors.actionPrimary,
            secondaryContainer: AppColors.actionPrimary,
            onSecondaryContainer: Colors.white,
            surface: Colors.white,
          ),
          textTheme: Theme.of(context).textTheme.copyWith(
            displayLarge: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w600,
              letterSpacing: -1,
            ),
            bodyLarge: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (pickedEndTime == null) return;

    final endDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedEndTime.hour,
      pickedEndTime.minute,
    );

    final duration = endDateTime.difference(startDateTime).inMinutes;
    if (duration <= 0) {
      _showValidationError('End time must be after start time.');
      return;
    }

    setState(() {
      _selectedSlots
        ..clear()
        ..add(_AvailabilitySelection(start: startDateTime, end: endDateTime));
      _durationController.text = duration.toString();
    });
  }

  Future<void> _pickMonthlyAvailability() async {
    final selectedSlots =
        await showModalBottomSheet<List<_AvailabilitySelection>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              _MonthlyAvailabilityPicker(initialSlots: _selectedSlots),
        );

    if (selectedSlots == null) return;

    setState(() {
      _selectedSlots
        ..clear()
        ..addAll(selectedSlots);
    });
  }

  void _removeSlot(_AvailabilitySelection slot) {
    setState(() => _selectedSlots.remove(slot));
  }

  void _updateSlotDuration(String value) {
    if (_selectedSlots.isEmpty) return;

    if (widget.sessionType.isMonthly) {
      setState(() {});
      return;
    }

    final duration = int.tryParse(value.trim());
    if (duration == null || duration <= 0) {
      setState(() {});
      return;
    }

    final selectedSlot = _selectedSlots.first;
    setState(() {
      _selectedSlots[0] = _AvailabilitySelection(
        start: selectedSlot.start,
        end: selectedSlot.start.add(Duration(minutes: duration)),
      );
    });
  }

  bool get _isGroupFormat => _selectedFormat == "Group";

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final payload = _buildPayload();
    if (payload == null) return;

    final createdClass = await controller.addClass(payload);
    if (createdClass == null || !mounted) return;

    Navigator.pop(context);
    Get.to(() => TrainerClassDetailsScreen(classData: createdClass));
  }

  TrainerClassPayload? _buildPayload() {
    final selectedSlots = List<_AvailabilitySelection>.from(_selectedSlots);
    final duration = int.tryParse(_durationController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    if (selectedSlots.isEmpty) {
      _showValidationError(_dateTimeValidationMessage);
      return null;
    }

    if (_selectedType == null) {
      _showValidationError('Please select a class type.');
      return null;
    }

    if (_selectedFormat == null) {
      _showValidationError('Please select a session format.');
      return null;
    }

    final durationError = _durationValidationMessage(duration, selectedSlots);
    if (durationError != null) {
      _showValidationError(durationError);
      return null;
    }
    final validDuration = duration;
    if (validDuration == null) {
      _showValidationError('Please enter a valid duration.');
      return null;
    }

    if (price == null || price < 0) {
      _showValidationError('Please enter a valid price.');
      return null;
    }

    final capacity = _isGroupFormat
        ? int.tryParse(_capacityController.text.trim())
        : null;
    if (_isGroupFormat && (capacity == null || capacity <= 0)) {
      _showValidationError('Please enter a valid capacity.');
      return null;
    }

    final selectedType = _selectedType;
    final selectedFormat = _selectedFormat;
    if (selectedType == null || selectedFormat == null) {
      _showValidationError('Please complete class details.');
      return null;
    }

    final generatedSlots = widget.sessionType.isMonthly
        ? _generateBookingSlots(selectedSlots, validDuration)
        : selectedSlots;
    if (generatedSlots.isEmpty) {
      _showValidationError('No booking slots could be created.');
      return null;
    }

    if (!widget.sessionType.isMonthly && generatedSlots.length != 1) {
      _showValidationError('Single session must have exactly one slot.');
      return null;
    }

    final availableSlots = <AvailabilitySlotModel>[];
    for (final selectedSlot in generatedSlots) {
      final selectedDateTime = selectedSlot.start;
      final endDateTime = selectedSlot.end;
      if (endDateTime == null) continue;

      availableSlots.add(
        AvailabilitySlotModel(
          date: DateFormat('yyyy-MM-dd').format(selectedDateTime),
          startTime: DateFormat('HH:mm').format(selectedDateTime),
          endTime: DateFormat('HH:mm').format(endDateTime),
        ),
      );
    }

    if (availableSlots.isEmpty) {
      _showValidationError('No booking slots could be created.');
      return null;
    }

    return TrainerClassPayload(
      name: _nameController.text.trim(),
      classType: _apiClassType(selectedType),
      sessionPlanType: _apiSessionPlanType,
      durationMinutes: validDuration,
      pricePerMember: price,
      sessionFormat: _apiSessionFormat(selectedFormat),
      capacity: capacity,
      availableSlots: availableSlots,
    );
  }

  void _showValidationError(String message) {
    showAppSnackbar(
      'Missing information',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _apiClassType(String value) {
    return value.toLowerCase().contains('person') ? 'IN_PERSON' : 'ONLINE';
  }

  String _apiSessionFormat(String value) {
    return value.toLowerCase().contains('group') ? 'GROUP' : 'PRIVATE';
  }

  String get _apiSessionPlanType {
    return widget.sessionType.isMonthly ? 'MONTHLY_SESSION' : 'SINGLE_SESSION';
  }

  String _formatSlotLabel(_AvailabilitySelection slot) {
    final date = DateFormat("d MMM yyyy").format(slot.start);
    final start = DateFormat("hh:mm a").format(slot.start);
    final slotEnd = slot.end;
    final end = slotEnd == null ? null : DateFormat("hh:mm a").format(slotEnd);

    return end == null ? "$date  $start" : "$date  $start - $end";
  }

  int get _generatedSlotCount {
    final duration = int.tryParse(_durationController.text.trim());
    if (_durationValidationMessage(duration, _selectedSlots) != null) {
      return 0;
    }
    final validDuration = duration;
    if (validDuration == null) return 0;

    if (!widget.sessionType.isMonthly) {
      return _selectedSlots.length == 1 ? 1 : 0;
    }

    return _generateBookingSlots(_selectedSlots, validDuration).length;
  }

  String? _durationValidationMessage(
    int? duration,
    List<_AvailabilitySelection> ranges,
  ) {
    if (ranges.isEmpty) return null;

    if (duration == null || duration <= 0) {
      return 'Please enter a valid duration.';
    }

    if (duration < _minimumSlotDuration) {
      return 'Duration must be at least $_minimumSlotDuration minutes.';
    }

    if (duration % _slotDurationStep != 0) {
      return 'Duration must be in $_slotDurationStep minute steps.';
    }

    if (!widget.sessionType.isMonthly && ranges.length != 1) {
      return 'Single session must have exactly one slot.';
    }

    for (final range in ranges) {
      final rangeDuration = range.durationMinutes;
      if (rangeDuration == null || rangeDuration <= 0) {
        return 'Please select a valid start and end time.';
      }

      if (!widget.sessionType.isMonthly) {
        if (rangeDuration != duration) {
          return 'Duration must match selected start and end time.';
        }
        continue;
      }

      if (duration > rangeDuration) {
        return 'Duration cannot be longer than selected available time.';
      }

      if (rangeDuration % duration != 0) {
        return 'Duration must evenly divide selected available time.';
      }
    }

    return null;
  }

  List<_AvailabilitySelection> _generateBookingSlots(
    List<_AvailabilitySelection> ranges,
    int duration,
  ) {
    final generatedSlots = <_AvailabilitySelection>[];

    for (final range in ranges) {
      final rangeEnd = range.end;
      if (rangeEnd == null) continue;

      var slotStart = range.start;
      while (slotStart.isBefore(rangeEnd)) {
        final slotEnd = slotStart.add(Duration(minutes: duration));
        if (slotEnd.isAfter(rangeEnd)) break;

        generatedSlots.add(
          _AvailabilitySelection(start: slotStart, end: slotEnd),
        );
        slotStart = slotEnd;
      }
    }

    return generatedSlots;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          "Create New Class",
                          style: AppTextStyles.base16Medium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),

                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF9F9F9),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.actionPrimary,
                                  blurRadius: 0,
                                  offset: const Offset(0, 3),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Class Name
                    _FieldLabel("Class Name"),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      controller: _nameController,
                      hintText: "E.g. morning Hit",
                      filColor: Colors.white,
                    ),
                    SizedBox(height: 20.h),

                    // Date & Time
                    _FieldLabel(_dateTimeLabel),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AppText(
                                _dateTimeFieldText,
                                style: AppTextStyles.base16Regular.copyWith(
                                  color: _hasSelectedDateTime
                                      ? AppColors.DarkBlue
                                      : const Color(0xFF454F5B),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              widget.sessionType.isMonthly
                                  ? Icons.add_circle_outline_rounded
                                  : Icons.calendar_month_outlined,
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _SelectedDateTimeList(
                      slots: _selectedSlots,
                      isMonthly: widget.sessionType.isMonthly,
                      onRemove: _removeSlot,
                    ),
                    SizedBox(height: 16.h),

                    // Type + Duration row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel("Type"),
                              SizedBox(height: 8.h),
                              _DropdownField(
                                hint: "Select type",
                                value: _selectedType,
                                items: _classTypes,
                                onChanged: (v) {
                                  FocusScope.of(context).unfocus();
                                  setState(() => _selectedType = v);
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel("Duration (min)"),
                              SizedBox(height: 8.h),
                              CustomTextField(
                                controller: _durationController,
                                hintText: "00",
                                keyboardType: TextInputType.number,
                                filColor: Colors.white,
                                enabled: _selectedSlots.isNotEmpty,
                                onChanged: _updateSlotDuration,
                                validator: (value) {
                                  final duration = int.tryParse(
                                    (value ?? '').trim(),
                                  );
                                  return _durationValidationMessage(
                                    duration,
                                    _selectedSlots,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Per Member price
                    _FieldLabel("Per Member (\$)"),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      controller: _priceController,
                      hintText: "00",
                      keyboardType: TextInputType.number,
                      filColor: Colors.white,
                    ),
                    SizedBox(height: 16.h),

                    // Session Format
                    _FieldLabel("Session Format"),
                    SizedBox(height: 8.h),
                    _DropdownField(
                      hint: "Choose format",
                      value: _selectedFormat,
                      items: _sessionFormats,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _selectedFormat = v;
                          // Reset capacity if switching away from group
                          if (!_isGroupFormat) _capacityController.clear();
                        });
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Capacity — only required for Group
                    if (_isGroupFormat) ...[
                      _FieldLabel("Capacity"),
                      SizedBox(height: 8.h),
                      CustomTextField(
                        controller: _capacityController,
                        hintText: "Enter capacity",
                        keyboardType: TextInputType.number,
                        filColor: Colors.white,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Capacity is required for Group";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.h),
                    ],

                    // Publish button
                    Obx(
                      () => AppButton(
                        text: "Publish Class",
                        isLoading: controller.isSaving.value,
                        onTap: controller.isSaving.value ? () {} : _submit,
                      ),
                    ),

                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.030,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      style: AppTextStyles.sm14Medium.copyWith(color: AppColors.textPrimary),
    );
  }
}

class _SelectedDateTimeList extends StatefulWidget {
  final List<_AvailabilitySelection> slots;
  final bool isMonthly;
  final ValueChanged<_AvailabilitySelection> onRemove;

  const _SelectedDateTimeList({
    required this.slots,
    required this.isMonthly,
    required this.onRemove,
  });

  @override
  State<_SelectedDateTimeList> createState() => _SelectedDateTimeListState();
}

class _SelectedDateTimeListState extends State<_SelectedDateTimeList> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isMonthly || widget.slots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              height: 48.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    size: 18.sp,
                    color: AppColors.actionPrimary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "Selected availability (${widget.slots.length})",
                      style: AppTextStyles.sm14Medium.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22.sp,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            SizedBox(height: 10.h),
            ...widget.slots.map((slot) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Container(
                  constraints: BoxConstraints(minHeight: 44.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.borderSecondary),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 18.sp,
                        color: AppColors.actionPrimary,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _slotLabel(slot),
                          style: AppTextStyles.sm14Medium.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.onRemove(slot),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.sp,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _slotLabel(_AvailabilitySelection slot) {
    final date = DateFormat("d MMM yyyy").format(slot.start);
    final start = DateFormat("hh:mm a").format(slot.start);
    final slotEnd = slot.end;
    final end = slotEnd == null ? null : DateFormat("hh:mm a").format(slotEnd);

    return end == null ? "$date  $start" : "$date  $start - $end";
  }
}

class _MonthlyAvailabilityPicker extends StatefulWidget {
  final List<_AvailabilitySelection> initialSlots;

  const _MonthlyAvailabilityPicker({required this.initialSlots});

  @override
  State<_MonthlyAvailabilityPicker> createState() =>
      _MonthlyAvailabilityPickerState();
}

class _MonthlyAvailabilityPickerState
    extends State<_MonthlyAvailabilityPicker> {
  late DateTime _focusedDay;
  late final Set<DateTime> _selectedDates;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDates = widget.initialSlots
        .map((slot) => _dateOnly(slot.start))
        .toSet();

    if (widget.initialSlots.isNotEmpty) {
      final firstSlot = widget.initialSlots.first;
      _startTime = TimeOfDay.fromDateTime(firstSlot.start);
      _endTime = TimeOfDay.fromDateTime(
        firstSlot.end ?? firstSlot.start.add(const Duration(hours: 1)),
      );
    } else {
      _startTime = const TimeOfDay(hour: 7, minute: 0);
      _endTime = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "Select available dates",
                style: AppTextStyles.xl20SemiBold.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 14.h),
              _buildCalendar(),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: _TimeSelectField(
                      label: "Start Time",
                      value: _formatTime(_startTime),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _TimeSelectField(
                      label: "End Time",
                      value: _formatTime(_endTime),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              if (_errorText != null) ...[
                SizedBox(height: 10.h),
                Text(
                  _errorText ?? '',
                  style: AppTextStyles.xs12Medium.copyWith(
                    color: AppColors.statusError,
                    letterSpacing: 0,
                  ),
                ),
              ],
              SizedBox(height: 18.h),
              GestureDetector(
                onTap: _applySelection,
                child: Container(
                  height: 54.h,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.actionSecondary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    "Apply",
                    style: AppTextStyles.base16SemiBold.copyWith(
                      color: Colors.white,
                      letterSpacing: 0,
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

  Widget _buildCalendar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: TableCalendar(
        firstDay: _dateOnly(DateTime.now()),
        lastDay: _dateOnly(DateTime.now().add(const Duration(days: 365))),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => _selectedDates.contains(_dateOnly(day)),
        onDaySelected: (selectedDay, focusedDay) {
          final normalizedDay = _dateOnly(selectedDay);
          setState(() {
            _focusedDay = focusedDay;
            _errorText = null;
            if (_selectedDates.contains(normalizedDay)) {
              _selectedDates.remove(normalizedDay);
            } else {
              _selectedDates.add(normalizedDay);
            }
          });
        },
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
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: AppColors.actionPrimary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.actionPrimary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: AppTextStyles.xs12SemiBold.copyWith(
            color: Colors.white,
            letterSpacing: 0,
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
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.actionPrimary,
            primaryContainer: AppColors.actionPrimary,
            onPrimaryContainer: Colors.white,
            secondary: AppColors.actionPrimary,
            secondaryContainer: AppColors.actionPrimary,
            onSecondaryContainer: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (pickedTime == null) return;

    setState(() {
      _errorText = null;
      if (isStart) {
        _startTime = pickedTime;
      } else {
        _endTime = pickedTime;
      }
    });
  }

  void _applySelection() {
    if (_selectedDates.isEmpty) {
      setState(() => _errorText = "Please select at least one date.");
      return;
    }

    final startMinutes = _minutesOfDay(_startTime);
    final endMinutes = _minutesOfDay(_endTime);
    if (endMinutes <= startMinutes) {
      setState(() => _errorText = "End time must be after start time.");
      return;
    }

    final slots = _selectedDates.map((date) {
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        _startTime.hour,
        _startTime.minute,
      );
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        _endTime.hour,
        _endTime.minute,
      );

      return _AvailabilitySelection(start: start, end: end);
    }).toList()..sort((a, b) => a.start.compareTo(b.start));

    Navigator.pop(context, slots);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int _minutesOfDay(TimeOfDay value) {
    return value.hour * 60 + value.minute;
  }

  String _formatTime(TimeOfDay value) {
    return DateFormat(
      "hh:mm a",
    ).format(DateTime(2026, 1, 1, value.hour, value.minute));
  }
}

class _TimeSelectField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeSelectField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.sm14Medium.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.sm14Medium.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Icon(
                  Icons.schedule_rounded,
                  size: 18.sp,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: false,
      hint: Text(
        hint,
        style: const TextStyle(
          color: Color(0xFF454F5B),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.grey.shade600,
      ),
      style: TextStyle(
        color: AppColors.DarkBlue,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'WorkSans',
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      padding: EdgeInsets.zero,
      decoration: InputDecoration(
        isDense: false,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.actionPrimary, width: 1.5),
        ),
      ),
    );
  }
}
