import 'package:fitness/utils/image_url.dart';
import 'package:intl/intl.dart';

class MemberNextWorkoutModel {
  final String bookingId;
  final String fitnessClassId;
  final String availabilitySlotId;
  final String bookingStatus;
  final String paymentStatus;
  final MemberWorkoutClass workoutClass;
  final MemberWorkoutTrainer trainer;
  final MemberWorkoutLocationTime locationTime;
  final String? totalAmount;
  final String? confirmedAt;

  const MemberNextWorkoutModel({
    required this.bookingId,
    required this.fitnessClassId,
    required this.availabilitySlotId,
    required this.bookingStatus,
    required this.paymentStatus,
    required this.workoutClass,
    required this.trainer,
    required this.locationTime,
    this.totalAmount,
    this.confirmedAt,
  });

  factory MemberNextWorkoutModel.fromJson(Map<String, dynamic> json) {
    return MemberNextWorkoutModel(
      bookingId:
          _readString(json, const ['bookingId', 'booking_id', 'id']) ?? '',
      fitnessClassId:
          _readString(json, const ['fitnessClassId', 'fitness_class_id']) ?? '',
      availabilitySlotId:
          _readString(json, const [
            'availabilitySlotId',
            'availability_slot_id',
          ]) ??
          '',
      bookingStatus:
          (_readString(json, const ['bookingStatus', 'booking_status']) ?? '')
              .toUpperCase(),
      paymentStatus:
          (_readString(json, const ['paymentStatus', 'payment_status']) ?? '')
              .toUpperCase(),
      workoutClass: MemberWorkoutClass.fromJson(
        _object(json['class']) ?? const <String, dynamic>{},
      ),
      trainer: MemberWorkoutTrainer.fromJson(
        _object(json['trainer']) ?? const <String, dynamic>{},
      ),
      locationTime: MemberWorkoutLocationTime.fromJson(
        _object(json['locationTime']) ??
            _object(json['location_time']) ??
            const <String, dynamic>{},
      ),
      totalAmount: _readString(json, const ['totalAmount', 'total_amount']),
      confirmedAt: _readString(json, const ['confirmedAt', 'confirmed_at']),
    );
  }

  String get title => workoutClass.name.isEmpty ? 'Workout' : workoutClass.name;

  String get subtitle {
    final parts = [
      workoutClass.sessionPlanTypeDisplay,
      workoutClass.sessionFormatDisplay,
    ].where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? 'Workout Session' : parts.join(' - ');
  }

  String get displayDate => locationTime.displayDate;

  String get compactDate => locationTime.compactDate;

  String get displayTime => locationTime.displayStartTime;

  String get durationLabel {
    final minutes = workoutClass.durationMinutes;
    if (minutes == null || minutes <= 0) return '';
    return '${minutes}min';
  }

  String get priceLabel {
    final amount = totalAmount;
    if (amount == null || amount.isEmpty) return 'Booked workout';
    return '\$$amount total';
  }
}

class MemberWorkoutClass {
  final String id;
  final String name;
  final String? classType;
  final String? sessionPlanType;
  final int? durationMinutes;
  final String? sessionFormat;

  const MemberWorkoutClass({
    required this.id,
    required this.name,
    this.classType,
    this.sessionPlanType,
    this.durationMinutes,
    this.sessionFormat,
  });

  factory MemberWorkoutClass.fromJson(Map<String, dynamic> json) {
    return MemberWorkoutClass(
      id: _readString(json, const ['id']) ?? '',
      name: _readString(json, const ['name', 'title', 'className']) ?? '',
      classType: _readString(json, const ['classType', 'class_type']),
      sessionPlanType: _readString(json, const [
        'sessionPlanType',
        'session_plan_type',
      ]),
      durationMinutes: _readInt(json, const [
        'durationMinutes',
        'duration_minutes',
      ]),
      sessionFormat: _readString(json, const [
        'sessionFormat',
        'session_format',
      ]),
    );
  }

  String get sessionPlanTypeDisplay => _titleFromEnum(sessionPlanType);

  String get sessionFormatDisplay => _titleFromEnum(sessionFormat);
}

class MemberWorkoutTrainer {
  final String id;
  final String name;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? classesTaught;
  final double? averageRating;
  final int? reviewCount;
  final int? distanceMeters;
  final String? locationLabel;

  const MemberWorkoutTrainer({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.phoneNumber,
    this.classesTaught,
    this.averageRating,
    this.reviewCount,
    this.distanceMeters,
    this.locationLabel,
  });

  factory MemberWorkoutTrainer.fromJson(Map<String, dynamic> json) {
    return MemberWorkoutTrainer(
      id: _readString(json, const ['id']) ?? '',
      name:
          _readString(json, const ['name', 'fullName', 'full_name']) ??
          'Trainer',
      profileImageUrl: normalizeImageUrl(
        _readString(json, const [
          'profileImageUrl',
          'profile_image_url',
          'imageUrl',
          'image_url',
          'avatarUrl',
          'avatar_url',
        ]),
      ),
      phoneNumber: _readString(json, const ['phoneNumber', 'phone_number']),
      classesTaught: _readString(json, const [
        'classesTaught',
        'classes_taught',
        'specialty',
        'expertise',
      ]),
      averageRating: _readDouble(json, const [
        'averageRating',
        'average_rating',
        'rating',
      ]),
      reviewCount: _readInt(json, const ['reviewCount', 'review_count']),
      distanceMeters: _readInt(json, const [
        'distanceMeters',
        'distance_meters',
      ]),
      locationLabel: _readString(json, const [
        'locationLabel',
        'location_label',
      ]),
    );
  }

  String? get distanceLabel {
    final meters = distanceMeters;
    if (meters == null) return null;
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(km >= 10 ? 0 : 1)}km';
    }
    return '${meters}m';
  }
}

class MemberWorkoutLocationTime {
  final String? location;
  final String scheduledDate;
  final String startTime;
  final String? endTime;
  final String? startAt;
  final String? endAt;

  const MemberWorkoutLocationTime({
    this.location,
    required this.scheduledDate,
    required this.startTime,
    this.endTime,
    this.startAt,
    this.endAt,
  });

  factory MemberWorkoutLocationTime.fromJson(Map<String, dynamic> json) {
    return MemberWorkoutLocationTime(
      location: _readString(json, const ['location', 'address']),
      scheduledDate:
          _readString(json, const ['scheduledDate', 'scheduled_date']) ?? '',
      startTime: _readString(json, const ['startTime', 'start_time']) ?? '',
      endTime: _readString(json, const ['endTime', 'end_time']),
      startAt: _readString(json, const ['startAt', 'start_at']),
      endAt: _readString(json, const ['endAt', 'end_at']),
    );
  }

  String get displayDate {
    final parsed = DateTime.tryParse(scheduledDate);
    if (parsed == null) return scheduledDate;
    return DateFormat('dd-MM-yyyy').format(parsed);
  }

  String get compactDate => displayDate.isEmpty ? '--' : displayDate;

  String get displayStartTime => _formatTime(startTime);
}

Map<String, dynamic>? _object(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is Map || value is Iterable) continue;

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

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) return null;
  return double.tryParse(value);
}

String _formatTime(String value) {
  if (value.isEmpty) return '--';
  final parts = value.split(':');
  if (parts.length < 2) return value;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return value;

  return DateFormat('hh:mm a').format(DateTime(2026, 1, 1, hour, minute));
}

String _titleFromEnum(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  return value
      .toLowerCase()
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
