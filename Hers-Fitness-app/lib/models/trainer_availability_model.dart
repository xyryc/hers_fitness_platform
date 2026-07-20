class TrainerAvailabilityResponse {
  final String trainerUserId;
  final String month;
  final String startDate;
  final String endDate;
  final List<TrainerAvailabilityDay> days;

  const TrainerAvailabilityResponse({
    required this.trainerUserId,
    required this.month,
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  factory TrainerAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    final data =
        _object(json['availability']) ??
        _object(json['trainerAvailability']) ??
        _object(json['trainer_availability']) ??
        _object(json['data']) ??
        json;
    final days = _list(data, const ['days']);

    return TrainerAvailabilityResponse(
      trainerUserId:
          _readString(data, const ['trainerUserId', 'trainer_user_id']) ?? '',
      month: _readString(data, const ['month']) ?? '',
      startDate: _readString(data, const ['startDate', 'start_date']) ?? '',
      endDate: _readString(data, const ['endDate', 'end_date']) ?? '',
      days: days
          .map(_object)
          .whereType<Map<String, dynamic>>()
          .map(TrainerAvailabilityDay.fromJson)
          .toList(),
    );
  }
}

class TrainerAvailabilityDay {
  final String date;
  final int day;
  final String status;
  final bool isAvailable;
  final int availableSlotCount;
  final int bookedSlotCount;
  final List<Map<String, dynamic>> slots;

  const TrainerAvailabilityDay({
    required this.date,
    required this.day,
    required this.status,
    required this.isAvailable,
    required this.availableSlotCount,
    required this.bookedSlotCount,
    required this.slots,
  });

  factory TrainerAvailabilityDay.fromJson(Map<String, dynamic> json) {
    final slots = _list(json, const ['slots']);

    return TrainerAvailabilityDay(
      date: _readString(json, const ['date']) ?? '',
      day: _readInt(json, const ['day']) ?? 0,
      status: _readString(json, const ['status']) ?? '',
      isAvailable: _readBool(json, const ['isAvailable', 'is_available']),
      availableSlotCount:
          _readInt(json, const [
            'availableSlotCount',
            'available_slot_count',
          ]) ??
          0,
      bookedSlotCount:
          _readInt(json, const ['bookedSlotCount', 'booked_slot_count']) ?? 0,
      slots: slots.map(_object).whereType<Map<String, dynamic>>().toList(),
    );
  }

  bool get hasBookedSlot =>
      status.toUpperCase() == 'BOOKED' || bookedSlotCount > 0;

  bool get hasAvailableSlot =>
      status.toUpperCase() == 'AVAILABLE' ||
      isAvailable ||
      availableSlotCount > 0;
}

Map<String, dynamic>? _object(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

List<dynamic> _list(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) return value;
  }
  return const [];
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null || value is Map || value is Iterable) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return null;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) return null;
  return int.tryParse(value) ?? double.tryParse(value)?.round();
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys)?.toLowerCase();
  return value == 'true' || value == '1' || value == 'yes';
}
