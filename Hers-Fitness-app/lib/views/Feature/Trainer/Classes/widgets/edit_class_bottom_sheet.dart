import 'package:fitness/controllers/my_classes_controller.dart';
import 'package:fitness/utils/AppColor/app_colors.dart';
import 'package:fitness/utils/AppTextStyle/app_text_styles.dart';
import 'package:fitness/views/Base/AppButton/appButton.dart';
import 'package:fitness/views/Base/AppText/appText.dart';
import 'package:fitness/views/Base/CustomTextfield/CustomTextfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fitness/utils/app_snackbar.dart';

class EditClassBottomSheet extends StatefulWidget {
  final int index;
  final Map<String, dynamic> classData;

  const EditClassBottomSheet({
    super.key,
    required this.index,
    required this.classData,
  });

  @override
  State<EditClassBottomSheet> createState() => _EditClassBottomSheetState();
}

class _EditClassBottomSheetState extends State<EditClassBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final MyClassesController controller = Get.find<MyClassesController>();

  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;
  late final TextEditingController _capacityController;

  DateTime? _selectedDateTime;
  String? _selectedType;
  String? _selectedFormat;
  late final String _initialName;
  late final String _initialClassTypeApi;
  late final String _initialSessionFormatApi;
  late final int _initialDuration;
  late final double _initialPrice;
  late final int? _initialCapacity;
  late final DateTime? _initialDateTime;
  late final bool _hasBookings;

  final List<String> _classTypes = ["Online", "In Person"];
  final List<String> _sessionFormats = ["One-to-one", "Group"];

  @override
  void initState() {
    super.initState();
    final classData = widget.classData;
    final slots = _readList(classData, const [
      'availableSlots',
      'available_slots',
      'availabilitySlots',
      'availability_slots',
    ]);
    final firstSlot = slots.isNotEmpty ? _asMap(slots.first) : null;

    _initialName = _readString(classData, const ['name', 'title']) ?? '';
    _initialClassTypeApi =
        _readString(classData, const ['classType', 'class_type']) ?? 'ONLINE';
    _initialSessionFormatApi =
        _readString(classData, const ['sessionFormat', 'session_format']) ??
        'PRIVATE';
    _initialDuration =
        _readInt(classData, const ['durationMinutes', 'duration_minutes']) ??
        _readInt(classData, const ['duration']) ??
        0;
    _initialPrice =
        _readDouble(classData, const ['pricePerMember', 'price_per_member']) ??
        _readDouble(classData, const ['price']) ??
        0;
    _initialCapacity = _readInt(classData, const [
      'capacity',
      'maxMembers',
      'max_members',
    ]);
    _initialDateTime = _slotStartDateTime(firstSlot);
    _hasBookings =
        (_readInt(classData, const [
                  'bookedMemberCount',
                  'booked_member_count',
                ]) ??
                0) >
            0 ||
        _readList(classData, const ['bookedSlots', 'booked_slots']).isNotEmpty;

    _nameController = TextEditingController(text: _initialName);
    _durationController = TextEditingController(
      text: _initialDuration.toString(),
    );
    _priceController = TextEditingController(
      text: _initialPrice.toStringAsFixed(0),
    );
    _capacityController = TextEditingController(
      text: _initialSessionFormatApi.toUpperCase() == "GROUP"
          ? (_initialCapacity ?? 0).toString()
          : "",
    );
    _selectedType = _displayClassType(_initialClassTypeApi);
    _selectedFormat = _displaySessionFormat(_initialSessionFormatApi);
    _selectedDateTime = _initialDateTime;
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
    if (_hasBookings) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.actionPrimary),
          textTheme: Theme.of(context).textTheme.copyWith(
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
        child: child!,
      ),
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay(
              hour: _selectedDateTime!.hour,
              minute: _selectedDateTime!.minute,
            )
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
        child: child!,
      ),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  bool get _isGroupFormat => _selectedFormat == "Group";

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = _buildPayload();
    if (payload == null) return;

    final success = await controller.updateClass(widget.index, payload);
    if (!success || !mounted) return;

    Navigator.pop(context);
  }

  Map<String, dynamic>? _buildPayload() {
    final selectedDateTime = _selectedDateTime;
    final duration = int.tryParse(_durationController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    if (!_hasBookings && selectedDateTime == null) {
      _showValidationError('Please pick a date and time.');
      return null;
    }

    if (_selectedType == null) {
      _showValidationError('Please select a class type.');
      return null;
    }

    if (!_hasBookings && _selectedFormat == null) {
      _showValidationError('Please select a session format.');
      return null;
    }

    if (!_hasBookings && (duration == null || duration <= 0)) {
      _showValidationError('Please enter a valid duration.');
      return null;
    }

    if (!_hasBookings && (price == null || price < 0)) {
      _showValidationError('Please enter a valid price.');
      return null;
    }

    final capacity = !_hasBookings && _isGroupFormat
        ? int.tryParse(_capacityController.text.trim())
        : null;
    if (!_hasBookings &&
        _isGroupFormat &&
        (capacity == null || capacity <= 0)) {
      _showValidationError('Please enter a valid capacity.');
      return null;
    }

    final payload = <String, dynamic>{};
    final name = _nameController.text.trim();
    if (name != _initialName) payload['name'] = name;

    final classType = _apiClassType(_selectedType!);
    if (classType != _initialClassTypeApi) payload['classType'] = classType;

    if (_hasBookings) return payload;

    final validDuration = duration;
    final validPrice = price;
    final selectedFormat = _selectedFormat;
    if (validDuration == null ||
        validPrice == null ||
        selectedDateTime == null ||
        selectedFormat == null) {
      return null;
    }

    if (validDuration != _initialDuration) {
      payload['durationMinutes'] = validDuration;
    }
    if (validPrice != _initialPrice) {
      payload['pricePerMember'] = validPrice;
    }

    final sessionFormat = _apiSessionFormat(selectedFormat);
    if (sessionFormat != _initialSessionFormatApi) {
      payload['sessionFormat'] = sessionFormat;
    }

    if (sessionFormat == 'GROUP') {
      if (capacity != _initialCapacity ||
          sessionFormat != _initialSessionFormatApi) {
        payload['capacity'] = capacity;
      }
    } else if (_initialCapacity != null ||
        sessionFormat != _initialSessionFormatApi) {
      payload['capacity'] = null;
    }

    final endDateTime = selectedDateTime.add(Duration(minutes: validDuration));
    final slot = {
      'date': DateFormat('yyyy-MM-dd').format(selectedDateTime),
      'startTime': DateFormat('HH:mm').format(selectedDateTime),
      'endTime': DateFormat('HH:mm').format(endDateTime),
    };

    if (_slotChanged(slot)) {
      payload['availableSlots'] = [slot];
    }

    return payload;
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

  bool _slotChanged(Map<String, dynamic> slot) {
    final initial = _initialDateTime;
    if (initial == null) return true;

    final initialEnd = initial.add(Duration(minutes: _initialDuration));
    return slot['date'] != DateFormat('yyyy-MM-dd').format(initial) ||
        slot['startTime'] != DateFormat('HH:mm').format(initial) ||
        slot['endTime'] != DateFormat('HH:mm').format(initialEnd);
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          "Edit Class",
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
                    _FieldLabel("Class Name"),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      controller: _nameController,
                      hintText: "E.g. morning Hit",
                      filColor: Colors.white,
                    ),
                    if (_hasBookings) ...[
                      SizedBox(height: 14.h),
                      _LockedClassNotice(),
                    ],
                    SizedBox(height: 20.h),
                    _FieldLabel("Date & Time"),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: _hasBookings ? null : _pickDateTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _fieldFillColor(_hasBookings),
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
                            AppText(
                              _selectedDateTime != null
                                  ? DateFormat(
                                      "d MMM yyyy  hh:mm a",
                                    ).format(_selectedDateTime!)
                                  : "Pick a date & time",
                              style: AppTextStyles.base16Regular.copyWith(
                                color: _selectedDateTime != null
                                    ? AppColors.DarkBlue
                                    : const Color(0xFF454F5B),
                              ),
                            ),
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
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
                                onChanged: (v) =>
                                    setState(() => _selectedType = v),
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
                                enabled: !_hasBookings,
                                filColor: _fieldFillColor(_hasBookings),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _FieldLabel("Per Member (\$)"),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      controller: _priceController,
                      hintText: "00",
                      keyboardType: TextInputType.number,
                      enabled: !_hasBookings,
                      filColor: _fieldFillColor(_hasBookings),
                    ),
                    SizedBox(height: 16.h),
                    _FieldLabel("Session Format"),
                    SizedBox(height: 8.h),
                    _DropdownField(
                      hint: "Choose format",
                      value: _selectedFormat,
                      items: _sessionFormats,
                      enabled: !_hasBookings,
                      onChanged: (v) => setState(() {
                        _selectedFormat = v;
                        if (!_isGroupFormat) _capacityController.clear();
                      }),
                    ),
                    SizedBox(height: 16.h),
                    if (_isGroupFormat) ...[
                      _FieldLabel("Capacity"),
                      SizedBox(height: 8.h),
                      CustomTextField(
                        controller: _capacityController,
                        hintText: "Enter capacity",
                        keyboardType: TextInputType.number,
                        enabled: !_hasBookings,
                        filColor: _fieldFillColor(_hasBookings),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Capacity is required for Group";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.h),
                    ],
                    Obx(
                      () => AppButton(
                        text: "Save Changes",
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

// ─── Shared helpers ────────────────────────────────────────────────────────────

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

class _LockedClassNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.statusWarningSubtle,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.statusWarning.withValues(alpha: 0.2),
        ),
      ),
      child: AppText(
        'This class already has bookings. Schedule, price, capacity, and slots cannot be edited directly. Use reschedule instead.',
        style: AppTextStyles.xs12Medium.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

Color _fieldFillColor(bool disabled) {
  return disabled ? AppColors.bgTertiary : Colors.white;
}

class _DropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
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
      onChanged: enabled ? onChanged : null,
      padding: EdgeInsets.zero,
      decoration: InputDecoration(
        isDense: false,
        filled: true,
        fillColor: _fieldFillColor(!enabled),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14),
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

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

List<dynamic> _readList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) return value;
  }
  return const [];
}

String? _readString(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final key in keys) {
    final value = json[key];
    if (value == null || value is Map || value is Iterable) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return null;
}

int? _readInt(Map<String, dynamic>? json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) return null;
  return int.tryParse(value) ?? double.tryParse(value)?.round();
}

double? _readDouble(Map<String, dynamic>? json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) return null;
  return double.tryParse(value);
}

DateTime? _slotStartDateTime(Map<String, dynamic>? slot) {
  if (slot == null) return null;

  final startAt = _readString(slot, const ['startAt', 'start_at']);
  final parsedStartAt = startAt == null ? null : DateTime.tryParse(startAt);
  if (parsedStartAt != null) return parsedStartAt;

  final date = _readString(slot, const ['date', 'scheduledDate']);
  final time = _readString(slot, const ['startTime', 'start_time', 'time']);
  if (date == null || time == null) return null;

  final normalizedTime = time.length == 5 ? '$time:00' : time;
  return DateTime.tryParse('${date}T$normalizedTime');
}

String _displayClassType(String value) {
  switch (value.toUpperCase()) {
    case 'IN_PERSON':
      return 'In Person';
    case 'ONLINE':
      return 'Online';
    default:
      return value;
  }
}

String _displaySessionFormat(String value) {
  switch (value.toUpperCase()) {
    case 'PRIVATE':
      return 'One-to-one';
    case 'GROUP':
      return 'Group';
    default:
      return value;
  }
}
