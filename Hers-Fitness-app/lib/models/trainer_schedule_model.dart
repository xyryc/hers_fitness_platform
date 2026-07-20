class TrainerScheduleResponse {
  final String startDate;
  final String endDate;
  final List<TrainerScheduleDay> days;

  const TrainerScheduleResponse({
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  factory TrainerScheduleResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return TrainerScheduleResponse(
      startDate: data['startDate']?.toString() ?? '',
      endDate: data['endDate']?.toString() ?? '',
      days: (data['days'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TrainerScheduleDay.fromJson)
          .toList(),
    );
  }
}

class TrainerScheduleDay {
  final String date;
  final int totalCount;
  final int completedCount;
  final int upcomingCount;
  final List<TrainerScheduleItem> items;

  const TrainerScheduleDay({
    required this.date,
    required this.totalCount,
    required this.completedCount,
    required this.upcomingCount,
    required this.items,
  });

  factory TrainerScheduleDay.fromJson(Map<String, dynamic> json) {
    return TrainerScheduleDay(
      date: json['date']?.toString() ?? '',
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      upcomingCount: (json['upcomingCount'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TrainerScheduleItem.fromJson)
          .toList(),
    );
  }
}

class TrainerScheduleItem {
  final TrainerScheduleBooking booking;
  final TrainerScheduleActions actions;

  const TrainerScheduleItem({required this.booking, required this.actions});

  factory TrainerScheduleItem.fromJson(Map<String, dynamic> json) {
    return TrainerScheduleItem(
      booking: TrainerScheduleBooking.fromJson(
        json['booking'] as Map<String, dynamic>? ?? {},
      ),
      actions: TrainerScheduleActions.fromJson(
        json['actions'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class TrainerScheduleActions {
  final bool canCheckIn;
  final bool canReschedule;
  final bool canAcceptReschedule;
  final bool canMarkComplete;
  final String label;

  const TrainerScheduleActions({
    required this.canCheckIn,
    required this.canReschedule,
    required this.canAcceptReschedule,
    required this.canMarkComplete,
    required this.label,
  });

  factory TrainerScheduleActions.fromJson(Map<String, dynamic> json) {
    return TrainerScheduleActions(
      canCheckIn: json['canCheckIn'] == true,
      canReschedule: json['canReschedule'] == true,
      canAcceptReschedule: json['canAcceptReschedule'] == true,
      canMarkComplete: json['canMarkComplete'] == true,
      label: json['label']?.toString() ?? '',
    );
  }
}

class TrainerScheduleBooking {
  final String id;
  final String fullName;
  final String scheduledDate;
  final String startTime;
  final String endTime;
  final String? startAt;
  final String? endAt;
  final String bookingStatus;
  final String? paymentStatus;
  final String? location;
  final String? totalAmount;
  final String? memberCheckedInAt;
  final String? trainerCheckedInAt;
  final String? memberCompletedAt;
  final String? trainerCompletedAt;
  final String? completedAt;
  final TrainerScheduleClass? scheduleClass;
  final String? proposedScheduledDate;
  final String? proposedStartTime;
  final String? proposedEndTime;

  const TrainerScheduleBooking({
    required this.id,
    required this.fullName,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    this.startAt,
    this.endAt,
    required this.bookingStatus,
    this.paymentStatus,
    this.location,
    this.totalAmount,
    this.memberCheckedInAt,
    this.trainerCheckedInAt,
    this.memberCompletedAt,
    this.trainerCompletedAt,
    this.completedAt,
    this.scheduleClass,
    this.proposedScheduledDate,
    this.proposedStartTime,
    this.proposedEndTime,
  });

  factory TrainerScheduleBooking.fromJson(Map<String, dynamic> json) {
    final classJson =
        json['class'] ?? json['trainerClass'] ?? json['trainer_class'];
    return TrainerScheduleBooking(
      id: json['id']?.toString() ?? '',
      fullName:
          json['fullName']?.toString() ?? json['memberName']?.toString() ?? '',
      scheduledDate: json['scheduledDate']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      startAt: json['startAt']?.toString(),
      endAt: json['endAt']?.toString(),
      bookingStatus: json['bookingStatus']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString(),
      location: json['location']?.toString(),
      totalAmount: json['totalAmount']?.toString(),
      memberCheckedInAt: json['memberCheckedInAt']?.toString(),
      trainerCheckedInAt: json['trainerCheckedInAt']?.toString(),
      memberCompletedAt: json['memberCompletedAt']?.toString(),
      trainerCompletedAt: json['trainerCompletedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      scheduleClass: classJson is Map<String, dynamic>
          ? TrainerScheduleClass.fromJson(classJson)
          : null,
      proposedScheduledDate: json['proposedScheduledDate']?.toString(),
      proposedStartTime: json['proposedStartTime']?.toString(),
      proposedEndTime: json['proposedEndTime']?.toString(),
    );
  }

  String get displayStartTime => _formatTime(startTime);
  String get displayEndTime => _formatTime(endTime);

  String _formatTime(String time) {
    if (time.isEmpty) return '--:--';
    final upper = time.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) return time;
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return time;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

class TrainerScheduleClass {
  final String name;
  final String? classType;
  final String? sessionFormat;
  final int? durationMinutes;

  const TrainerScheduleClass({
    required this.name,
    this.classType,
    this.sessionFormat,
    this.durationMinutes,
  });

  factory TrainerScheduleClass.fromJson(Map<String, dynamic> json) {
    return TrainerScheduleClass(
      name: json['name']?.toString() ?? '',
      classType: json['classType']?.toString(),
      sessionFormat: json['sessionFormat']?.toString(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
    );
  }
}
