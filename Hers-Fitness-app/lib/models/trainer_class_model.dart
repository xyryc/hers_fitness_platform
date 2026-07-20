class AvailabilitySlotModel {
  final String? id;
  final String date;
  final String startTime;
  final String endTime;

  const AvailabilitySlotModel({
    this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory AvailabilitySlotModel.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlotModel(
      id: _readString(json, const [
        'id',
        'availabilitySlotId',
        'availability_slot_id',
      ]),
      date: _readString(json, const ['date', 'slotDate', 'slot_date']) ?? '',
      startTime:
          _readString(json, const ['startTime', 'start_time', 'time']) ?? '',
      endTime: _readString(json, const ['endTime', 'end_time']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'startTime': startTime, 'endTime': endTime};
  }

  DateTime? get startDateTime {
    if (date.isEmpty || startTime.isEmpty) return null;

    final normalizedTime = startTime.length == 5 ? '$startTime:00' : startTime;
    return DateTime.tryParse('${date}T$normalizedTime');
  }

  String get displayDate {
    final dateTime = startDateTime;
    if (dateTime == null) return date;

    return '${_twoDigits(dateTime.day)}-${_twoDigits(dateTime.month)}-${dateTime.year}';
  }

  String get displayStartTime => _formatTime(startTime);

  static String _formatTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;

    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${_twoDigits(minute)} $suffix';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class TrainerClassPayload {
  final String name;
  final String classType;
  final String? sessionPlanType;
  final int durationMinutes;
  final double pricePerMember;
  final String sessionFormat;
  final int? capacity;
  final List<AvailabilitySlotModel> availableSlots;

  const TrainerClassPayload({
    required this.name,
    required this.classType,
    this.sessionPlanType,
    required this.durationMinutes,
    required this.pricePerMember,
    required this.sessionFormat,
    this.capacity,
    required this.availableSlots,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name,
      'classType': classType,
      'durationMinutes': durationMinutes,
      'pricePerMember': pricePerMember,
      'sessionFormat': sessionFormat,
      'availableSlots': availableSlots.map((slot) => slot.toJson()).toList(),
    };

    final planType = sessionPlanType;
    if (planType != null) {
      data['sessionPlanType'] = planType;
    }

    final classCapacity = capacity;
    if (classCapacity != null) {
      data['capacity'] = classCapacity;
    }

    return data;
  }
}

class TrainerClassModel {
  final String? id;
  final String name;
  final String classType;
  final int durationMinutes;
  final double pricePerMember;
  final String sessionFormat;
  final int capacity;
  final List<AvailabilitySlotModel> availableSlots;
  final String? imageUrl;

  /// 'ACTIVE' | 'COMPLETED' — returned by the API when includeCompleted=true
  final String status;

  const TrainerClassModel({
    this.id,
    required this.name,
    required this.classType,
    required this.durationMinutes,
    required this.pricePerMember,
    required this.sessionFormat,
    required this.capacity,
    required this.availableSlots,
    this.imageUrl,
    this.status = 'ACTIVE',
  });

  factory TrainerClassModel.fromJson(Map<String, dynamic> json) {
    final slots = _readList(json, const [
      'availableSlots',
      'available_slots',
      'availabilitySlots',
      'availability_slots',
      'slots',
    ]);

    return TrainerClassModel(
      id: _readString(json, const ['id', 'classId', 'class_id', 'serviceId']),
      name: _readString(json, const ['name', 'title']) ?? 'Untitled Class',
      classType:
          _readString(json, const ['classType', 'class_type', 'type']) ??
          'ONLINE',
      durationMinutes:
          _readInt(json, const ['durationMinutes', 'duration_minutes']) ??
          _readInt(json, const ['duration']) ??
          0,
      pricePerMember:
          _readDouble(json, const ['pricePerMember', 'price_per_member']) ??
          _readDouble(json, const ['price']) ??
          0,
      sessionFormat:
          _readString(json, const ['sessionFormat', 'session_format']) ??
          'PRIVATE',
      capacity:
          _readInt(json, const ['capacity', 'maxMembers', 'max_members']) ?? 1,
      availableSlots: slots
          .whereType<Map<String, dynamic>>()
          .map(AvailabilitySlotModel.fromJson)
          .toList(),
      imageUrl: _readString(json, const [
        'imageUrl',
        'image_url',
        'trainerImageUrl',
        'trainer_image_url',
      ]),
      status: _readString(json, const ['status']) ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toUiMap() {
    final firstSlot = availableSlots.isEmpty ? null : availableSlots.first;

    return {
      'id': id,
      'title': name,
      'name': name,
      'time': firstSlot?.displayStartTime ?? 'N/A',
      'date': firstSlot?.displayDate ?? '',
      'startDateTime': firstSlot?.startDateTime,
      'duration': durationMinutes,
      'price': pricePerMember,
      'maxMembers': capacity,
      'classType': displayClassType,
      'sessionFormat': displaySessionFormat,
      'apiClassType': classType,
      'apiSessionFormat': sessionFormat,
      'availableSlots': availableSlots.map((slot) => slot.toJson()).toList(),
      'series': displaySessionFormat,
      'imageUrl': imageUrl ?? '',
      'status': status,
    };
  }

  String get displayClassType {
    switch (classType.toUpperCase()) {
      case 'IN_PERSON':
        return 'In Person';
      case 'ONLINE':
        return 'Online';
      default:
        return classType;
    }
  }

  String get displaySessionFormat {
    switch (sessionFormat.toUpperCase()) {
      case 'PRIVATE':
        return 'One-to-one';
      case 'GROUP':
        return 'Group';
      default:
        return sessionFormat;
    }
  }
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;

    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }

  return null;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) return null;

  return int.tryParse(value) ?? double.tryParse(value)?.round();
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) return null;

  return double.tryParse(value);
}

List<dynamic> _readList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) return value;
  }

  return const [];
}
