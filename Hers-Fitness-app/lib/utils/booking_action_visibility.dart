DateTime? getBookingStartAt(dynamic booking) {
  return _absoluteTime(booking, const [
        ['locationTime', 'startAt'],
        ['location_time', 'start_at'],
        ['startAt'],
        ['start_at'],
      ]) ??
      _combinedLocalTime(
        _readString(booking, const [
          'scheduledDate',
          'scheduled_date',
          'date',
          'classDate',
        ]),
        _readString(booking, const [
          'startTime',
          'start_time',
          'time',
          'scheduledStartTime',
        ]),
      );
}

DateTime? getBookingEndAt(dynamic booking) {
  return _absoluteTime(booking, const [
        ['locationTime', 'endAt'],
        ['location_time', 'end_at'],
        ['endAt'],
        ['end_at'],
      ]) ??
      _combinedLocalTime(
        _readString(booking, const [
          'scheduledDate',
          'scheduled_date',
          'date',
          'classDate',
        ]),
        _readString(booking, const ['endTime', 'end_time', 'scheduledEndTime']),
      );
}

bool canShowCheckIn(dynamic booking, String role) {
  final now = DateTime.now();
  final endAt = getBookingEndAt(booking);

  return _normalize(role) == 'MEMBER' &&
      _isPaid(booking) &&
      _isConfirmedOrRescheduled(booking) &&
      endAt != null &&
      now.isBefore(endAt) &&
      !_hasCompleted(booking);
}

bool canEnableCheckIn(dynamic booking, String role) {
  final startAt = getBookingStartAt(booking);
  final endAt = getBookingEndAt(booking);
  final now = DateTime.now();

  return canShowCheckIn(booking, role) &&
      startAt != null &&
      endAt != null &&
      !now.isBefore(startAt.subtract(const Duration(minutes: 30))) &&
      now.isBefore(endAt);
}

bool canShowMemberComplete(dynamic booking) {
  final endAt = getBookingEndAt(booking);

  return _isPaid(booking) &&
      _isConfirmedOrRescheduled(booking) &&
      endAt != null &&
      !DateTime.now().isBefore(endAt) &&
      _isBlank(
        _readString(booking, const [
          'memberCompletedAt',
          'member_completed_at',
        ]),
      ) &&
      _isBlank(_readString(booking, const ['completedAt', 'completed_at']));
}

bool canShowTrainerComplete(dynamic booking) {
  final status = _bookingStatus(booking);
  final endAt = getBookingEndAt(booking);

  return _isPaid(booking) &&
      (status == 'CONFIRMED' ||
          status == 'RESCHEDULED' ||
          status == 'COMPLETED') &&
      endAt != null &&
      !DateTime.now().isBefore(endAt) &&
      !_isBlank(
        _readString(booking, const [
          'memberCompletedAt',
          'member_completed_at',
        ]),
      ) &&
      _isBlank(
        _readString(booking, const [
          'trainerCompletedAt',
          'trainer_completed_at',
        ]),
      ) &&
      _isBlank(_readString(booking, const ['completedAt', 'completed_at']));
}

bool canShowTrainerChecking(dynamic booking, String? currentTrainerUserId) {
  if (!_isPaid(booking)) return false;

  final status = _bookingStatus(booking);
  final endAt = getBookingEndAt(booking);
  final memberCompleted = !_isBlank(
    _readString(booking, const ['memberCompletedAt', 'member_completed_at']),
  );
  final completed = !_isBlank(
    _readString(booking, const ['completedAt', 'completed_at']),
  );

  // Waiting for member to mark complete
  final waitingForCompletion =
      endAt != null &&
      !DateTime.now().isBefore(endAt) &&
      !memberCompleted &&
      (status == 'CONFIRMED' || status == 'RESCHEDULED') &&
      !completed;

  // Waiting for member to approve trainer's reschedule request
  final requesterId = _readString(booking, const [
    'rescheduleRequestedByUserId',
    'reschedule_requested_by_user_id',
  ]);
  final waitingForReschedule =
      (status == 'RESCHEDULE_REQUESTED' || status == 'RESCHEDULE_PENDING') &&
      requesterId != null &&
      requesterId == currentTrainerUserId;

  return waitingForCompletion || waitingForReschedule;
}

bool canShowTrainerAcceptReschedule(
  dynamic booking,
  String? currentTrainerUserId,
) {
  if (!_isPaid(booking)) return false;

  final status = _bookingStatus(booking);
  final requesterId = _readString(booking, const [
    'rescheduleRequestedByUserId',
    'reschedule_requested_by_user_id',
  ]);

  return (status == 'RESCHEDULE_REQUESTED' || status == 'RESCHEDULE_PENDING') &&
      requesterId != null &&
      requesterId != currentTrainerUserId;
}

bool canShowTrainerWaitingForMember(dynamic booking) {
  final endAt = getBookingEndAt(booking);

  return _isPaid(booking) &&
      _isConfirmedOrRescheduled(booking) &&
      endAt != null &&
      !DateTime.now().isBefore(endAt) &&
      _isBlank(
        _readString(booking, const [
          'memberCompletedAt',
          'member_completed_at',
        ]),
      ) &&
      _isBlank(_readString(booking, const ['completedAt', 'completed_at']));
}

bool canShowReschedule(dynamic booking, String role) {
  final normalizedRole = _normalize(role);
  final startAt = getBookingStartAt(booking);

  return (normalizedRole == 'MEMBER' || normalizedRole == 'TRAINER') &&
      _isPaid(booking) &&
      _isConfirmedOrRescheduled(booking) &&
      startAt != null &&
      DateTime.now().isBefore(startAt) &&
      _isBlank(_readString(booking, const ['completedAt', 'completed_at'])) &&
      !_isReschedulePending(booking);
}

bool isReschedulePending(dynamic booking) => _isReschedulePending(booking);

DateTime? _absoluteTime(dynamic booking, List<List<String>> paths) {
  for (final path in paths) {
    final value = _readPath(booking, path);
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _combinedLocalTime(String? date, String? time) {
  if (_isBlank(date) || _isBlank(time)) return null;
  final normalizedTime = time!.length == 5 ? '$time:00' : time;
  return DateTime.tryParse('${date!.trim()}T${normalizedTime.trim()}');
}

bool _isPaid(dynamic booking) {
  return _normalize(
        _readString(booking, const ['paymentStatus', 'payment_status']),
      ) ==
      'PAID';
}

bool _isConfirmedOrRescheduled(dynamic booking) {
  final status = _bookingStatus(booking);
  return status == 'CONFIRMED' || status == 'RESCHEDULED';
}

bool _isReschedulePending(dynamic booking) {
  final status = _bookingStatus(booking);
  return status == 'RESCHEDULE_REQUESTED' ||
      status == 'RESCHEDULE_PENDING' ||
      status == 'PENDING_RESCHEDULE';
}

bool _hasCompleted(dynamic booking) {
  return !_isBlank(
        _readString(booking, const [
          'memberCompletedAt',
          'member_completed_at',
        ]),
      ) ||
      !_isBlank(
        _readString(booking, const [
          'trainerCompletedAt',
          'trainer_completed_at',
        ]),
      ) ||
      !_isBlank(_readString(booking, const ['completedAt', 'completed_at']));
}

String _bookingStatus(dynamic booking) {
  return _normalize(
        _readString(booking, const [
          'bookingStatus',
          'booking_status',
          'status',
        ]),
      ) ??
      '';
}

String? _readPath(dynamic source, List<String> path) {
  dynamic current = source;
  for (final key in path) {
    if (current == null) return null;
    if (current is Map) {
      current = current[key];
      continue;
    }
    return null;
  }

  if (current == null || current is Map || current is Iterable) return null;
  final text = current.toString().trim();
  return _isBlank(text) ? null : text;
}

String? _readString(dynamic source, List<String> keys) {
  for (final key in keys) {
    final value = _readValue(source, key);
    if (value == null || value is Map || value is Iterable) continue;

    final text = value.toString().trim();
    if (!_isBlank(text)) return text;
  }
  return null;
}

dynamic _readValue(dynamic source, String key) {
  if (source == null) return null;
  if (source is Map) return source[key];
  return null;
}

String? _normalize(String? value) {
  if (value == null) return null;
  return value.trim().toUpperCase();
}

bool _isBlank(String? value) {
  if (value == null) return true;
  final text = value.trim();
  return text.isEmpty || text.toLowerCase() == 'null';
}
