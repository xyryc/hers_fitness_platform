import 'package:intl/intl.dart';

class MemberMonthlyActivityModel {
  final int year;
  final int totalCompletedSessions;
  final int maxMonthlyCompletedSessions;
  final List<MemberMonthlyActivityItem> months;

  const MemberMonthlyActivityModel({
    required this.year,
    required this.totalCompletedSessions,
    required this.maxMonthlyCompletedSessions,
    required this.months,
  });

  factory MemberMonthlyActivityModel.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    return MemberMonthlyActivityModel(
      year: _readInt(data, const ['year']) ?? DateTime.now().year,
      totalCompletedSessions:
          _readInt(data, const ['totalCompletedSessions']) ?? 0,
      maxMonthlyCompletedSessions:
          _readInt(data, const ['maxMonthlyCompletedSessions']) ?? 0,
      months: _readList(data, const ['months'])
          .map(
            (item) => MemberMonthlyActivityItem.fromJson(_object(item) ?? {}),
          )
          .toList(),
    );
  }

  static MemberMonthlyActivityModel empty(int year) {
    return MemberMonthlyActivityModel(
      year: year,
      totalCompletedSessions: 0,
      maxMonthlyCompletedSessions: 0,
      months: List.generate(12, (index) {
        final date = DateTime(year, index + 1);
        return MemberMonthlyActivityItem(
          month: index + 1,
          label: DateFormat('MMMM').format(date),
          shortLabel: DateFormat('MMM').format(date).substring(0, 1),
          completedSessions: 0,
          activityPercentage: 0,
        );
      }),
    );
  }
}

class MemberMonthlyActivityItem {
  final int month;
  final String label;
  final String shortLabel;
  final int completedSessions;
  final int activityPercentage;

  const MemberMonthlyActivityItem({
    required this.month,
    required this.label,
    required this.shortLabel,
    required this.completedSessions,
    required this.activityPercentage,
  });

  factory MemberMonthlyActivityItem.fromJson(Map<String, dynamic> json) {
    final month = _readInt(json, const ['month']) ?? 1;
    return MemberMonthlyActivityItem(
      month: month,
      label:
          _readString(json, const ['label']) ??
          DateFormat('MMMM').format(DateTime(2026, month)),
      shortLabel:
          _readString(json, const ['shortLabel', 'short_label']) ??
          DateFormat('MMM').format(DateTime(2026, month)).substring(0, 1),
      completedSessions: _readInt(json, const ['completedSessions']) ?? 0,
      activityPercentage: _readInt(json, const ['activityPercentage']) ?? 0,
    );
  }
}

class MemberWeeklyActivityModel {
  final String weekStart;
  final String weekEnd;
  final int totalCompletedSessions;
  final int maxDailyCompletedSessions;
  final List<MemberWeeklyActivityItem> days;

  const MemberWeeklyActivityModel({
    required this.weekStart,
    required this.weekEnd,
    required this.totalCompletedSessions,
    required this.maxDailyCompletedSessions,
    required this.days,
  });

  factory MemberWeeklyActivityModel.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    return MemberWeeklyActivityModel(
      weekStart: _readString(data, const ['weekStart', 'week_start']) ?? '',
      weekEnd: _readString(data, const ['weekEnd', 'week_end']) ?? '',
      totalCompletedSessions:
          _readInt(data, const ['totalCompletedSessions']) ?? 0,
      maxDailyCompletedSessions:
          _readInt(data, const ['maxDailyCompletedSessions']) ?? 0,
      days: _readList(data, const ['days'])
          .map((item) => MemberWeeklyActivityItem.fromJson(_object(item) ?? {}))
          .toList(),
    );
  }

  static MemberWeeklyActivityModel empty([DateTime? selectedDate]) {
    final date = selectedDate ?? DateTime.now();
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final days = List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      return MemberWeeklyActivityItem(
        date: DateFormat('yyyy-MM-dd').format(day),
        dayOfWeek: index + 1,
        label: DateFormat('EEEE').format(day),
        shortLabel: DateFormat('E').format(day).substring(0, 1),
        completedSessions: 0,
        activityPercentage: 0,
      );
    });

    return MemberWeeklyActivityModel(
      weekStart: days.first.date,
      weekEnd: days.last.date,
      totalCompletedSessions: 0,
      maxDailyCompletedSessions: 0,
      days: days,
    );
  }
}

class MemberWeeklyActivityItem {
  final String date;
  final int dayOfWeek;
  final String label;
  final String shortLabel;
  final int completedSessions;
  final int activityPercentage;

  const MemberWeeklyActivityItem({
    required this.date,
    required this.dayOfWeek,
    required this.label,
    required this.shortLabel,
    required this.completedSessions,
    required this.activityPercentage,
  });

  factory MemberWeeklyActivityItem.fromJson(Map<String, dynamic> json) {
    return MemberWeeklyActivityItem(
      date: _readString(json, const ['date']) ?? '',
      dayOfWeek: _readInt(json, const ['dayOfWeek', 'day_of_week']) ?? 1,
      label: _readString(json, const ['label']) ?? '',
      shortLabel: _readString(json, const ['shortLabel', 'short_label']) ?? '',
      completedSessions: _readInt(json, const ['completedSessions']) ?? 0,
      activityPercentage: _readInt(json, const ['activityPercentage']) ?? 0,
    );
  }
}

class MemberYearlyActivityModel {
  final int totalCompletedSessions;
  final int maxYearlyCompletedSessions;
  final List<MemberYearlyActivityItem> years;

  const MemberYearlyActivityModel({
    required this.totalCompletedSessions,
    required this.maxYearlyCompletedSessions,
    required this.years,
  });

  factory MemberYearlyActivityModel.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    return MemberYearlyActivityModel(
      totalCompletedSessions:
          _readInt(data, const ['totalCompletedSessions']) ?? 0,
      maxYearlyCompletedSessions:
          _readInt(data, const ['maxYearlyCompletedSessions']) ?? 0,
      years: _readList(data, const ['years'])
          .map((item) => MemberYearlyActivityItem.fromJson(_object(item) ?? {}))
          .toList(),
    );
  }

  static MemberYearlyActivityModel empty() {
    final currentYear = DateTime.now().year;
    return MemberYearlyActivityModel(
      totalCompletedSessions: 0,
      maxYearlyCompletedSessions: 0,
      years: [
        MemberYearlyActivityItem(
          year: currentYear - 2,
          completedSessions: 0,
          activityPercentage: 0,
        ),
        MemberYearlyActivityItem(
          year: currentYear - 1,
          completedSessions: 0,
          activityPercentage: 0,
        ),
        MemberYearlyActivityItem(
          year: currentYear,
          completedSessions: 0,
          activityPercentage: 0,
        ),
      ],
    );
  }
}

class MemberYearlyActivityItem {
  final int year;
  final int completedSessions;
  final int activityPercentage;

  const MemberYearlyActivityItem({
    required this.year,
    required this.completedSessions,
    required this.activityPercentage,
  });

  factory MemberYearlyActivityItem.fromJson(Map<String, dynamic> json) {
    return MemberYearlyActivityItem(
      year: _readInt(json, const ['year']) ?? DateTime.now().year,
      completedSessions: _readInt(json, const ['completedSessions']) ?? 0,
      activityPercentage: _readInt(json, const ['activityPercentage']) ?? 0,
    );
  }
}

// ── Daily Activity (Monthly tab) ─────────────────────────────────────────────

class MemberDailyActivityModel {
  final int month;
  final int year;
  final int totalCompletedSessions;
  final List<MemberDailyActivityItem> days;

  const MemberDailyActivityModel({
    required this.month,
    required this.year,
    required this.totalCompletedSessions,
    required this.days,
  });

  factory MemberDailyActivityModel.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    return MemberDailyActivityModel(
      month: _readInt(data, const ['month']) ?? DateTime.now().month,
      year: _readInt(data, const ['year']) ?? DateTime.now().year,
      totalCompletedSessions:
          _readInt(data, const ['totalCompletedSessions']) ?? 0,
      days: _readList(data, const ['days'])
          .map((item) => MemberDailyActivityItem.fromJson(_object(item) ?? {}))
          .toList(),
    );
  }

  static MemberDailyActivityModel empty(int month, int year) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return MemberDailyActivityModel(
      month: month,
      year: year,
      totalCompletedSessions: 0,
      days: List.generate(
        daysInMonth,
        (index) => MemberDailyActivityItem(
          date:
              '${year.toString().padLeft(4, '0')}-'
              '${month.toString().padLeft(2, '0')}-'
              '${(index + 1).toString().padLeft(2, '0')}',
          day: index + 1,
          completedSessions: 0,
          activityPercentage: 0,
        ),
      ),
    );
  }
}

class MemberDailyActivityItem {
  final String date;
  final int day;
  final int completedSessions;
  final int activityPercentage;

  const MemberDailyActivityItem({
    required this.date,
    required this.day,
    required this.completedSessions,
    required this.activityPercentage,
  });

  factory MemberDailyActivityItem.fromJson(Map<String, dynamic> json) {
    return MemberDailyActivityItem(
      date: _readString(json, const ['date']) ?? '',
      day: _readInt(json, const ['day']) ?? 1,
      completedSessions: _readInt(json, const ['completedSessions']) ?? 0,
      activityPercentage: _readInt(json, const ['activityPercentage']) ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic>? _object(dynamic value) {
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
