import 'package:intl/intl.dart';

class MemberClassModel {
  final String id;
  final String? trainerUserId;
  final String title;
  final String trainerName;
  final String? classType;
  final String? sessionFormat;
  final String? sessionPlanType;
  final String? location;
  final String? price;
  final List<MemberAvailabilitySlotModel> availableSlots;

  const MemberClassModel({
    required this.id,
    this.trainerUserId,
    required this.title,
    required this.trainerName,
    this.classType,
    this.sessionFormat,
    this.sessionPlanType,
    this.location,
    this.price,
    required this.availableSlots,
  });

  factory MemberClassModel.fromJson(Map<String, dynamic> json) {
    final trainer =
        _object(json['trainer']) ??
        _object(json['trainerUser']) ??
        _object(json['trainer_user']) ??
        const <String, dynamic>{};
    final rawSlots = json['availableSlots'] ?? json['available_slots'] ?? [];
    final nextSlot = _object(json['nextSlot'] ?? json['next_slot']);
    final slots = rawSlots is List ? rawSlots : const <dynamic>[];
    final normalizedSlots = [
      if (nextSlot != null) nextSlot,
      ...slots.whereType<Map>().map(
        (slot) => slot.map((key, value) => MapEntry(key.toString(), value)),
      ),
    ];

    return MemberClassModel(
      id: _readString(json, const ['id', 'classId', 'class_id']) ?? '',
      trainerUserId:
          _readString(json, const ['trainerUserId', 'trainer_user_id']) ??
          _readString(trainer, const ['id', 'userId', 'user_id']),
      title: _readString(json, const ['title', 'name', 'className']) ?? 'Class',
      trainerName:
          _displayName(trainer) ??
          _readString(json, const ['trainerName', 'trainer_name']) ??
          'Trainer',
      classType: _readString(json, const ['classType', 'class_type']),
      sessionFormat: _readString(json, const [
        'sessionFormat',
        'session_format',
      ]),
      sessionPlanType: _readString(json, const [
        'sessionPlanType',
        'session_plan_type',
      ]),
      location: _readString(json, const ['location', 'address']),
      price: _readString(json, const [
        'price',
        'pricePerMember',
        'price_per_member',
        'totalAmount',
        'amount',
      ]),
      availableSlots: () {
        final parsedSlots = normalizedSlots
            .map(MemberAvailabilitySlotModel.fromJson)
            .where((slot) => slot.id.isNotEmpty)
            .toList();

        final plan =
            _readString(json, const [
              'sessionPlanType',
              'session_plan_type',
            ])?.toUpperCase() ??
            '';

        final isMonthly =
            plan == 'MONTHLY_SESSION' ||
            plan == 'MONTHLY' ||
            plan.contains('MONTH');

        if (parsedSlots.isEmpty && isMonthly) {
          final fallbackId =
              _readString(json, const ['id', 'classId', 'class_id']) ??
              'monthly_slot';
          return [
            MemberAvailabilitySlotModel(
              id: fallbackId,
              date: 'Flexible',
              startTime: 'Anytime',
              status: 'AVAILABLE',
            ),
          ];
        }

        return parsedSlots;
      }(),
    );
  }

  Map<String, dynamic> toSessionMap(MemberAvailabilitySlotModel slot) {
    return {
      'id': slot.id,
      'classId': id,
      'title': title,
      'date': slot.displayDate,
      'apiDate': slot.date,
      'time': slot.displayTime,
      'apiTime': slot.startTime,
      'location': location ?? 'Location unavailable',
      'classType': classType ?? 'N/A',
      'format': sessionFormat ?? 'Session',
      'planType': sessionPlanType ?? 'Single',
      'price': price ?? '0.00',
      'status': slot.status ?? 'AVAILABLE',
      'spotsRemaining': slot.spotsRemaining,
      'isBookable': slot.isBookable,
    };
  }

  bool get isSingleSession {
    final value = (sessionPlanType ?? '').trim().toUpperCase();
    return value == 'SINGLE_SESSION' ||
        value == 'SINGLE' ||
        value.contains('SINGLE');
  }

  bool get isMonthlySession {
    final value = (sessionPlanType ?? '').trim().toUpperCase();
    return value == 'MONTHLY_SESSION' ||
        value == 'MONTHLY' ||
        value.contains('MONTH');
  }

  bool matchesClassType(String type) {
    final expected = type.trim().toUpperCase();
    if (expected.isEmpty) return true;
    return (classType ?? '').trim().toUpperCase() == expected;
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

class MemberAvailabilitySlotModel {
  final String id;
  final String date;
  final String startTime;
  final String? endTime;
  final String? status;
  final int? spotsRemaining;

  const MemberAvailabilitySlotModel({
    required this.id,
    required this.date,
    required this.startTime,
    this.endTime,
    this.status,
    this.spotsRemaining,
  });

  factory MemberAvailabilitySlotModel.fromJson(Map<String, dynamic> json) {
    final startAt = MemberClassModel._readString(json, const [
      'startAt',
      'start_at',
      'scheduledAt',
      'scheduled_at',
    ]);
    final parsedStartAt = startAt == null ? null : DateTime.tryParse(startAt);

    return MemberAvailabilitySlotModel(
      id:
          MemberClassModel._readString(json, const [
            'id',
            'slotId',
            'slot_id',
          ]) ??
          '',
      date:
          MemberClassModel._readString(json, const [
            'date',
            'scheduledDate',
            'scheduled_date',
          ]) ??
          (parsedStartAt == null
              ? ''
              : DateFormat('yyyy-MM-dd').format(parsedStartAt)),
      startTime:
          MemberClassModel._readString(json, const [
            'startTime',
            'start_time',
            'time',
          ]) ??
          (parsedStartAt == null
              ? ''
              : DateFormat('HH:mm').format(parsedStartAt)),
      endTime: MemberClassModel._readString(json, const [
        'endTime',
        'end_time',
      ]),
      status: MemberClassModel._readString(json, const ['status']),
      spotsRemaining: _readInt(json, const [
        'spotsRemaining',
        'spots_remaining',
      ]),
    );
  }

  String get displayDate {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return DateFormat('MMMM d, yyyy').format(parsed);
  }

  String get displayTime {
    final parts = startTime.split(':');
    if (parts.length < 2) return startTime;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return startTime;
    return DateFormat('hh:mm a').format(DateTime(2026, 1, 1, hour, minute));
  }

  String get displayEndTime {
    if (endTime == null || endTime!.isEmpty) return '';
    final parts = endTime!.split(':');
    if (parts.length < 2) return endTime!;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return endTime!;
    return DateFormat('hh:mm a').format(DateTime(2026, 1, 1, hour, minute));
  }

  bool get isBookable {
    final normalizedStatus = status?.trim().toUpperCase();
    final hasSpots = spotsRemaining == null || spotsRemaining! > 0;
    final statusAllowsBooking =
        normalizedStatus == null ||
        normalizedStatus.isEmpty ||
        normalizedStatus == 'AVAILABLE' ||
        normalizedStatus == 'ACTIVE';
    return hasSpots && statusAllowsBooking;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    final value = MemberClassModel._readString(json, keys);
    if (value == null) return null;
    return int.tryParse(value) ?? double.tryParse(value)?.round();
  }
}

class BookingHoldModel {
  final String? id;
  final String? bookingId;
  final String? paymentId;
  final String className;
  final String trainerName;
  final List<MemberAvailabilitySlotModel> selectedSlots;
  final String perMemberPrice;
  final String subtotal;
  final String discount;
  final String tax;
  final String totalAmount;
  final DateTime? reservedUntil;

  const BookingHoldModel({
    this.id,
    this.bookingId,
    this.paymentId,
    this.className = 'Class',
    this.trainerName = 'Trainer',
    this.selectedSlots = const [],
    this.perMemberPrice = '0.00',
    this.subtotal = '0.00',
    this.discount = '0.00',
    this.tax = '0.00',
    required this.totalAmount,
    this.reservedUntil,
  });

  factory BookingHoldModel.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final booking = _object(data['booking']) ?? const <String, dynamic>{};
    final payment =
        _object(data['bookingPayment']) ??
        _object(data['booking_payment']) ??
        _object(data['pendingBookingPayment']) ??
        _object(data['pending_booking_payment']) ??
        _object(data['pendingPayment']) ??
        _object(data['pending_payment']) ??
        _object(booking['bookingPayment']) ??
        _object(booking['booking_payment']) ??
        _object(booking['pendingBookingPayment']) ??
        _object(booking['pending_booking_payment']) ??
        _object(data['payment']) ??
        _object(booking['payment']) ??
        const <String, dynamic>{};
    final summary = _object(data['summary']) ?? data;
    final rawSlots =
        summary['selectedSlots'] ??
        summary['selected_slots'] ??
        data['selectedSlots'] ??
        data['selected_slots'] ??
        const [];
    final slots = rawSlots is List
        ? rawSlots
              .whereType<Map>()
              .map(
                (slot) => MemberAvailabilitySlotModel.fromJson(
                  slot.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .where((slot) => slot.id.isNotEmpty || slot.date.isNotEmpty)
              .toList()
        : const <MemberAvailabilitySlotModel>[];

    return BookingHoldModel(
      id: _readString(data, const ['id', 'holdId', 'hold_id']),
      bookingId: _readString(data, const ['bookingId', 'booking_id']),
      paymentId:
          _readString(payment, const [
            'bookingPaymentId',
            'booking_payment_id',
            'paymentId',
            'payment_id',
            'id',
          ]) ??
          _readString(data, const [
            'bookingPaymentId',
            'booking_payment_id',
            'paymentId',
            'payment_id',
          ]) ??
          _readString(booking, const [
            'bookingPaymentId',
            'booking_payment_id',
            'paymentId',
            'payment_id',
          ]),
      className:
          _readString(summary, const [
            'className',
            'class_name',
            'title',
            'name',
          ]) ??
          'Class',
      trainerName:
          _readString(summary, const ['trainerName', 'trainer_name']) ??
          'Trainer',
      selectedSlots: slots,
      perMemberPrice:
          _readString(summary, const [
            'perMemberPrice',
            'per_member_price',
            'price',
          ]) ??
          '0.00',
      subtotal:
          _readString(summary, const ['subtotal', 'subTotal', 'sub_total']) ??
          '0.00',
      discount:
          _readString(summary, const [
            'discount',
            'discountAmount',
            'discount_amount',
          ]) ??
          '0.00',
      tax:
          _readString(summary, const ['tax', 'taxAmount', 'tax_amount']) ??
          '0.00',
      totalAmount:
          _readString(payment, const [
            'totalAmount',
            'total_amount',
            'amount',
          ]) ??
          _readString(summary, const [
            'total',
            'totalAmount',
            'total_amount',
          ]) ??
          _readString(data, const ['total', 'totalAmount', 'total_amount']) ??
          '0.00',
      reservedUntil: DateTime.tryParse(
        _readString(data, const ['reservedUntil', 'reserved_until']) ?? '',
      ),
    );
  }

  static Map<String, dynamic>? _object(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
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

class StripePaymentIntentModel {
  final String paymentId;
  final String paymentIntentId;
  final String clientSecret;
  final String publishableKey;
  final int amount;
  final String currency;

  const StripePaymentIntentModel({
    required this.paymentId,
    required this.paymentIntentId,
    required this.clientSecret,
    required this.publishableKey,
    required this.amount,
    required this.currency,
  });

  factory StripePaymentIntentModel.fromJson(Map<String, dynamic> json) {
    final data = BookingHoldModel._object(json['data']) ?? json;
    final intent =
        BookingHoldModel._object(data['paymentIntent']) ??
        BookingHoldModel._object(data['payment_intent']) ??
        data;
    return StripePaymentIntentModel(
      paymentId:
          BookingHoldModel._readString(data, const [
            'paymentId',
            'payment_id',
            'bookingPaymentId',
            'booking_payment_id',
          ]) ??
          BookingHoldModel._readString(intent, const [
            'paymentId',
            'payment_id',
            'bookingPaymentId',
            'booking_payment_id',
          ]) ??
          '',
      paymentIntentId:
          BookingHoldModel._readString(data, const [
            'paymentIntentId',
            'payment_intent_id',
          ]) ??
          BookingHoldModel._readString(intent, const [
            'paymentIntentId',
            'payment_intent_id',
            'id',
          ]) ??
          '',
      clientSecret:
          BookingHoldModel._readString(data, const [
            'clientSecret',
            'client_secret',
          ]) ??
          BookingHoldModel._readString(intent, const [
            'clientSecret',
            'client_secret',
          ]) ??
          '',
      publishableKey:
          BookingHoldModel._readString(data, const [
            'publishableKey',
            'publishable_key',
          ]) ??
          BookingHoldModel._readString(intent, const [
            'publishableKey',
            'publishable_key',
          ]) ??
          '',
      amount:
          int.tryParse(
            BookingHoldModel._readString(data, const ['amount']) ??
                BookingHoldModel._readString(intent, const ['amount']) ??
                '',
          ) ??
          0,
      currency:
          BookingHoldModel._readString(data, const ['currency']) ??
          BookingHoldModel._readString(intent, const ['currency']) ??
          'USD',
    );
  }
}
