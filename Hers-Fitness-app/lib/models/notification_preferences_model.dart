class NotificationPreferencesModel {
  // ── Role discriminator ─────────────────────────────────────────────────────
  /// 'MEMBER' | 'TRAINER' — drives which toggle list is shown.
  /// Defaults to 'MEMBER' as a safe fallback per spec.
  final String role;

  // ── Trainer-only fields ────────────────────────────────────────────────────
  final bool newBooking;
  final bool classCheckIn;
  final bool paymentReceived;

  // ── Member-only fields ─────────────────────────────────────────────────────
  final bool bookingConfirmation;
  final bool bookingCancellation;
  final bool paymentConfirmation;
  final bool trainerMessage;

  // ── Shared fields ──────────────────────────────────────────────────────────
  final bool classReminder;
  final bool systemAnnouncements;
  final bool emailNotifications;
  final bool pushNotifications;

  const NotificationPreferencesModel({
    this.role = 'MEMBER',
    // trainer
    this.newBooking = true,
    this.classCheckIn = true,
    this.paymentReceived = true,
    // member
    this.bookingConfirmation = true,
    this.bookingCancellation = true,
    this.paymentConfirmation = true,
    this.trainerMessage = true,
    // shared
    this.classReminder = true,
    this.systemAnnouncements = false,
    this.emailNotifications = true,
    this.pushNotifications = true,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    // Normalise role: accept 'MEMBER', 'member', 'TRAINER', 'trainer'.
    // Default to 'MEMBER' if absent or unrecognised.
    final rawRole = (data['role']?.toString() ?? '').toUpperCase();
    final role = (rawRole == 'TRAINER') ? 'TRAINER' : 'MEMBER';

    return NotificationPreferencesModel(
      role: role,
      // trainer
      newBooking: _bool(data['newBooking'], defaultValue: true),
      classCheckIn: _bool(data['classCheckIn'], defaultValue: true),
      paymentReceived: _bool(data['paymentReceived'], defaultValue: true),
      // member
      bookingConfirmation: _bool(
        data['bookingConfirmation'],
        defaultValue: true,
      ),
      bookingCancellation: _bool(
        data['bookingCancellation'],
        defaultValue: true,
      ),
      paymentConfirmation: _bool(
        data['paymentConfirmation'],
        defaultValue: true,
      ),
      trainerMessage: _bool(data['trainerMessage'], defaultValue: true),
      // shared
      classReminder: _bool(data['classReminder'], defaultValue: true),
      systemAnnouncements: _bool(
        data['systemAnnouncements'],
        defaultValue: false,
      ),
      emailNotifications: _bool(data['emailNotifications'], defaultValue: true),
      pushNotifications: _bool(data['pushNotifications'], defaultValue: true),
    );
  }

  NotificationPreferencesModel copyWith({
    String? role,
    // trainer
    bool? newBooking,
    bool? classCheckIn,
    bool? paymentReceived,
    // member
    bool? bookingConfirmation,
    bool? bookingCancellation,
    bool? paymentConfirmation,
    bool? trainerMessage,
    // shared
    bool? classReminder,
    bool? systemAnnouncements,
    bool? emailNotifications,
    bool? pushNotifications,
  }) {
    return NotificationPreferencesModel(
      role: role ?? this.role,
      newBooking: newBooking ?? this.newBooking,
      classCheckIn: classCheckIn ?? this.classCheckIn,
      paymentReceived: paymentReceived ?? this.paymentReceived,
      bookingConfirmation: bookingConfirmation ?? this.bookingConfirmation,
      bookingCancellation: bookingCancellation ?? this.bookingCancellation,
      paymentConfirmation: paymentConfirmation ?? this.paymentConfirmation,
      trainerMessage: trainerMessage ?? this.trainerMessage,
      classReminder: classReminder ?? this.classReminder,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'newBooking': newBooking,
    'classCheckIn': classCheckIn,
    'paymentReceived': paymentReceived,
    'bookingConfirmation': bookingConfirmation,
    'bookingCancellation': bookingCancellation,
    'paymentConfirmation': paymentConfirmation,
    'trainerMessage': trainerMessage,
    'classReminder': classReminder,
    'systemAnnouncements': systemAnnouncements,
    'emailNotifications': emailNotifications,
    'pushNotifications': pushNotifications,
  };

  static bool _bool(dynamic v, {bool defaultValue = false}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return defaultValue;
  }
}
