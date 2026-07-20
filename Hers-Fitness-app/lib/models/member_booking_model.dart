import 'package:fitness/utils/booking_action_visibility.dart';
import 'package:intl/intl.dart';

class MemberBookingModel {
  final String id;
  final String title;
  final String? trainerUserId;
  final String trainerName;
  final String scheduledDate;
  final String startTime;
  final String? endTime;
  final String bookingStatus;
  final String paymentStatus;
  final String? startAt;
  final String? endAt;
  final String? classType;
  final String? sessionFormat;
  final String? rescheduleRequestedByUserId;
  final String? proposedScheduledDate;
  final String? proposedStartTime;
  final String? memberCompletedAt;
  final String? trainerCompletedAt;
  final String? completedAt;
  final String? totalAmount;
  final String? classStatus;

  const MemberBookingModel({
    required this.id,
    required this.title,
    this.trainerUserId,
    required this.trainerName,
    required this.scheduledDate,
    required this.startTime,
    this.endTime,
    required this.bookingStatus,
    required this.paymentStatus,
    this.startAt,
    this.endAt,
    this.classType,
    this.sessionFormat,
    this.rescheduleRequestedByUserId,
    this.proposedScheduledDate,
    this.proposedStartTime,
    this.memberCompletedAt,
    this.trainerCompletedAt,
    this.completedAt,
    this.totalAmount,
    this.classStatus,
  });

  factory MemberBookingModel.fromJson(Map<String, dynamic> json) {
    final trainer =
        _object(json['trainer']) ??
        _object(json['trainerUser']) ??
        _object(json['trainer_user']) ??
        _object(json['coach']) ??
        const <String, dynamic>{};
    final klass =
        _object(json['class']) ??
        _object(json['trainerClass']) ??
        _object(json['trainer_class']) ??
        _object(json['service']) ??
        const <String, dynamic>{};

    return MemberBookingModel(
      id: _readString(json, const ['id', 'bookingId', 'booking_id']) ?? '',
      title:
          _readString(klass, const ['title', 'name', 'className']) ??
          _readString(json, const ['title', 'className', 'class_name']) ??
          'Back Workout',
      trainerUserId:
          _readString(json, const [
            'trainerUserId',
            'trainer_user_id',
            'trainerId',
            'trainer_id',
          ]) ??
          _readString(trainer, const [
            'userId',
            'user_id',
            'trainerUserId',
            'trainer_user_id',
            'id',
          ]) ??
          '',
      trainerName:
          _displayName(trainer) ??
          _readString(json, const ['trainerName', 'trainer_name']) ??
          'Trainer',
      scheduledDate:
          _readString(json, const [
            'scheduledDate',
            'scheduled_date',
            'date',
            'classDate',
          ]) ??
          '',
      startTime:
          _readString(json, const [
            'startTime',
            'start_time',
            'time',
            'scheduledStartTime',
          ]) ??
          '',
      endTime: _readString(json, const [
        'endTime',
        'end_time',
        'scheduledEndTime',
      ]),
      bookingStatus:
          (_readString(json, const [
                    'bookingStatus',
                    'booking_status',
                    'status',
                  ]) ??
                  'CONFIRMED')
              .toUpperCase(),
      paymentStatus:
          (_readString(json, const ['paymentStatus', 'payment_status']) ?? '')
              .toUpperCase(),
      startAt:
          _readString(json, const ['startAt', 'start_at']) ??
          _readString(
            _object(json['locationTime']) ?? const <String, dynamic>{},
            const ['startAt', 'start_at'],
          ) ??
          _readString(
            _object(json['location_time']) ?? const <String, dynamic>{},
            const ['startAt', 'start_at'],
          ),
      endAt:
          _readString(json, const ['endAt', 'end_at']) ??
          _readString(
            _object(json['locationTime']) ?? const <String, dynamic>{},
            const ['endAt', 'end_at'],
          ) ??
          _readString(
            _object(json['location_time']) ?? const <String, dynamic>{},
            const ['startAt', 'start_at'],
          ),
      classType:
          _readString(json, const ['classType', 'class_type']) ??
          _readString(klass, const ['classType', 'class_type']),
      sessionFormat:
          _readString(json, const ['sessionFormat', 'session_format']) ??
          _readString(klass, const ['sessionFormat', 'session_format']),
      rescheduleRequestedByUserId: _readString(json, const [
        'rescheduleRequestedByUserId',
        'reschedule_requested_by_user_id',
      ]),
      proposedScheduledDate: _readString(json, const [
        'proposedScheduledDate',
        'proposed_scheduled_date',
      ]),
      proposedStartTime: _readString(json, const [
        'proposedStartTime',
        'proposed_start_time',
      ]),
      memberCompletedAt: _readString(json, const [
        'memberCompletedAt',
        'member_completed_at',
      ]),
      trainerCompletedAt: _readString(json, const [
        'trainerCompletedAt',
        'trainer_completed_at',
      ]),
      completedAt: _readString(json, const ['completedAt', 'completed_at']),
      totalAmount: _readString(json, const ['totalAmount', 'total_amount']),
      classStatus: _readString(klass, const [
        'status',
        'classStatus',
        'class_status',
      ]),
    );
  }

  String get category {
    final type = (classType ?? title).toLowerCase();
    if (type.contains('meditation')) return 'Meditation';
    if (type.contains('yoga')) return 'Yoga';
    if (type.contains('cardio')) return 'Cardio';
    if (type.contains('strength') || type.contains('back')) return 'Strength';
    return 'Strength';
  }

  bool get isCompleted => bookingStatus == 'COMPLETED' || completedAt != null;

  bool get isReschedulePending =>
      bookingStatus == 'RESCHEDULE_PENDING' ||
      bookingStatus == 'RESCHEDULE_REQUESTED';

  bool get _isConfirmedOrRescheduled =>
      bookingStatus == 'CONFIRMED' || bookingStatus == 'RESCHEDULED';

  bool get canRequestReschedule {
    return canShowReschedule(_actionSource, 'MEMBER');
  }

  bool get canMarkComplete {
    return canShowMemberComplete(_actionSource);
  }

  bool get isOngoing {
    if (!_isConfirmedOrRescheduled) return false;
    final start = getBookingStartAt(_actionSource);
    final end = getBookingEndAt(_actionSource);
    if (start == null || end == null) return false;
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  bool canAcceptReschedule(String? memberUserId) {
    if (!isReschedulePending) return false;
    final requester = rescheduleRequestedByUserId;
    if (requester == null || requester.isEmpty) return true;
    return memberUserId == null || requester != memberUserId;
  }

  bool isWaitingForTrainer(String? memberUserId) {
    if (!isReschedulePending) return false;
    final requester = rescheduleRequestedByUserId;
    return memberUserId != null && requester == memberUserId;
  }

  Map<String, dynamic> toUiMap({String? memberUserId}) {
    final acceptsTrainerReschedule = canAcceptReschedule(memberUserId);
    final waitingForTrainer = isWaitingForTrainer(memberUserId);

    return {
      'id': id,
      'title': title,
      'trainerUserId': trainerUserId ?? '',
      'trainer': trainerName,
      'date': _displayDate(scheduledDate),
      'time': _displayTime(startTime),
      'status': _displayStatus(memberUserId),
      'bookingStatus': bookingStatus,
      'paymentStatus': paymentStatus,
      'category': category,
      'classType': classType,
      'sessionFormat': sessionFormat,
      'scheduledDate': scheduledDate,
      'startTime': startTime,
      'endTime': endTime,
      'startAt': startAt,
      'endAt': endAt,
      'memberCompletedAt': memberCompletedAt,
      'trainerCompletedAt': trainerCompletedAt,
      'completedAt': completedAt,
      'canShowCheckIn': canShowCheckIn(_actionSource, 'MEMBER'),
      'canEnableCheckIn': canEnableCheckIn(_actionSource, 'MEMBER'),
      'canMarkComplete': canMarkComplete,
      'canRequestReschedule': canRequestReschedule,
      'canAcceptReschedule': acceptsTrainerReschedule,
      'waitingForTrainer': waitingForTrainer,
      'isOngoing': isOngoing,
      'proposedDate': _displayDate(proposedScheduledDate ?? ''),
      'proposedTime': _displayTime(proposedStartTime ?? ''),
      'totalAmount': totalAmount,
    };
  }

  String _displayStatus(String? memberUserId) {
    if (isCompleted) return 'Completed';
    if (canAcceptReschedule(memberUserId)) return 'Reschedule Requested';
    if (isWaitingForTrainer(memberUserId)) return 'Pending';
    if (isOngoing) return 'Ongoing';
    if (canMarkComplete) return 'Ended';
    return 'Upcoming';
  }

  Map<String, dynamic> get _actionSource {
    return {
      'id': id,
      'bookingStatus': bookingStatus,
      'paymentStatus': paymentStatus,
      'scheduledDate': scheduledDate,
      'startTime': startTime,
      'endTime': endTime,
      'startAt': startAt,
      'endAt': endAt,
      'memberCompletedAt': memberCompletedAt,
      'trainerCompletedAt': trainerCompletedAt,
      'completedAt': completedAt,
    };
  }

  static String _displayDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;

    final now = DateTime.now();
    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;
    if (isToday) return 'Today';

    return DateFormat('MMMM d, yyyy').format(date);
  }

  static String _displayTime(String value) {
    if (value.isEmpty) return value;
    final parts = value.split(':');
    if (parts.length < 2) return value;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;

    final date = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(date);
  }

  static Map<String, dynamic>? _object(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  static String? _displayName(Map<String, dynamic> source) {
    final firstName = _readString(source, const ['firstName', 'first_name']);
    final lastName = _readString(source, const ['lastName', 'last_name']);
    final combined = [
      firstName,
      lastName,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');

    return _readString(source, const [
          'name',
          'displayName',
          'display_name',
          'fullName',
          'full_name',
        ]) ??
        (combined.isEmpty ? null : combined);
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is Map || value is Iterable) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }

    return null;
  }
}
