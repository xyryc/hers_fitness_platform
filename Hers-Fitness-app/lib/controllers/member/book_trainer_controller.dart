import 'dart:async';

import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/member_class_model.dart';
import 'package:fitness/services/member_class_service.dart';
import 'package:fitness/services/user_service.dart';
import 'package:fitness/utils/AppConstants/app_constant.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BookTrainerController extends GetxController {
  BookTrainerController({
    MemberClassService? classService,
    UserService? userService,
  }) : _classService = classService ?? MemberClassService(),
       _userService = userService ?? UserService();

  final MemberClassService _classService;
  final UserService _userService;

  final currentStep = 1.obs;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final commentController = TextEditingController();
  final couponController = TextEditingController();

  final selectedClassType = 'ONLINE'.obs;
  final selectedClassIndex = 0.obs;
  final selectedSlotIds = <String>{}.obs;

  final selectedDate = DateTime.now().obs;
  final selectedMonthlyDate = Rxn<DateTime>();
  final focusedDate = DateTime.now().obs;
  final selectedTime = ''.obs;
  final selectedSlotIndex = 0.obs;
  final selectedPeriod = 'AM'.obs;
  final selectedSessionIndex = 0.obs;
  final selectedPaymentMethod = 'Stripe'.obs;
  final isReminderEnabled = true.obs;

  final cardHolderController = TextEditingController();
  final cardNumberController = TextEditingController();
  final expController = TextEditingController();
  final cvcController = TextEditingController();

  late final Map<String, dynamic> trainer = _trainerFromArgs();
  final memberClasses = <MemberClassModel>[].obs;
  final bookingHold = Rxn<BookingHoldModel>();
  final isLoadingClasses = false.obs;
  final isSubmitting = false.obs;
  final holdRemainingSeconds = 0.obs;
  final isAccountApproved = true.obs;
  final classesErrorMessage = ''.obs;

  Timer? _holdTimer;

  final List<String> classTypes = const ['ONLINE', 'IN_PERSON'];

  List<MemberClassModel> get filteredClasses {
    return memberClasses
        .where((item) => item.matchesClassType(selectedClassType.value))
        .toList();
  }

  MemberClassModel? get selectedClass {
    final classes = filteredClasses;
    if (classes.isEmpty) return null;
    final index = selectedClassIndex.value.clamp(0, classes.length - 1).toInt();
    return classes[index];
  }

  List<MemberAvailabilitySlotModel> get selectedClassSlots {
    return selectedClass?.availableSlots ?? const [];
  }

  List<MemberAvailabilitySlotModel> get selectedSlots {
    final ids = selectedSlotIds;
    return selectedClassSlots.where((slot) => ids.contains(slot.id)).toList();
  }

  MemberAvailabilitySlotModel? get selectedSlot {
    final slots = selectedSlots;
    return slots.isEmpty ? null : slots.first;
  }

  List<Map<String, dynamic>> get sessions {
    final klass = selectedClass;
    if (klass == null) return const [];
    return klass.availableSlots.map(klass.toSessionMap).toList();
  }

  List<MemberAvailabilitySlotModel> get filteredSlots {
    return selectedClassSlots
        .where(
          (slot) =>
              _sameDate(slot.date, selectedDate.value) &&
              _slotPeriod(slot.startTime) == selectedPeriod.value,
        )
        .toList();
  }

  List<String> get availableSlots {
    return filteredSlots.map((slot) => slot.startTime).toList();
  }

  bool get isMonthlySelection => selectedClass?.isMonthlySession ?? false;

  String get trainerName => _readTrainerString('name', 'Trainer');

  String get trainerImageUrl => _readTrainerString(
    'imageUrl',
    'https://as1.ftcdn.net/jpg/02/26/49/16/1000_F_226491635_4Qp2RzkMlglsfSLIzXjLeRmqdTnaD4p8.jpg',
  );

  double get trainerRating {
    final value = trainer['rating'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int get reviewCount {
    final value = trainer['reviewCount'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get displayDate {
    final slot = selectedSlot;
    return slot?.displayDate ??
        DateFormat('MMMM dd, yyyy').format(selectedDate.value);
  }

  String get summaryDate {
    final slots = _summarySlots;
    if (slots.isEmpty) return displayDate;
    return slots.map((slot) => slot.displayDate).join(', ');
  }

  String get summaryTime {
    final slots = _summarySlots;
    if (slots.isEmpty) return selectedSlot?.displayTime ?? selectedTime.value;
    return slots.map((slot) => slot.displayTime).join(', ');
  }

  String get selectedDatesTimes {
    final slots = _summarySlots;
    if (slots.isEmpty) return 'No slot selected';
    return slots
        .map((slot) => '${slot.displayDate} • ${slot.displayTime}')
        .join('\n');
  }

  String get summaryLocation {
    final memberLocation = locationController.text.trim();
    if (memberLocation.isNotEmpty) return memberLocation;
    final classLocation = selectedClass?.location?.trim();
    if (classLocation != null && classLocation.isNotEmpty) return classLocation;
    final trainerLocation = trainer['location']?.toString().trim();
    if (trainerLocation != null && trainerLocation.isNotEmpty) {
      return trainerLocation;
    }
    return 'Location unavailable';
  }

  double get trainingPrice =>
      _money(bookingHold.value?.perMemberPrice ?? selectedClass?.price ?? '');

  double get subtotal => _money(bookingHold.value?.subtotal ?? '');

  double get discount => _money(bookingHold.value?.discount ?? '');

  double get tax => _money(bookingHold.value?.tax ?? '');

  bool get hasDiscount => discount > 0;

  bool get hasTax => tax > 0;

  double get total {
    final holdTotal = bookingHold.value?.totalAmount;
    if (holdTotal != null && holdTotal.trim().isNotEmpty) {
      return _money(holdTotal);
    }
    final fallbackSubtotal = subtotal > 0
        ? subtotal
        : trainingPrice * selectedSlotIds.length;
    return fallbackSubtotal - discount + tax;
  }

  String get holdCountdown {
    final seconds = holdRemainingSeconds.value;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  List<MemberAvailabilitySlotModel> get _summarySlots {
    final holdSlots = bookingHold.value?.selectedSlots ?? const [];
    return holdSlots.isEmpty ? selectedSlots : holdSlots;
  }

  String priceText(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchApprovalStatus();
      fetchClasses(showError: true);
    });
  }

  Future<void> nextStep() async {
    if (isSubmitting.value) return;

    if (currentStep.value == 1) {
      if (selectedSlotIds.isEmpty) {
        showAppSnackbar(
          'Select a slot',
          'Please select an available session to continue.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      currentStep.value = 2;
      return;
    }

    if (currentStep.value == 2) {
      if (!_validateMemberInfo()) return;
      final held = await createHold();
      if (held) currentStep.value = 3;
      return;
    }

    if (currentStep.value == 3) {
      await payWithStripe();
    }
  }

  void previousStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
      return;
    }
    Get.back();
  }

  void setClassType(String value) {
    selectedClassType.value = value;
    selectedClassIndex.value = 0;
    selectedMonthlyDate.value = null;
    _selectFirstBookableSlot();
    bookingHold.value = null;
  }

  void setClassIndex(int index) {
    selectedClassIndex.value = index;
    selectedSessionIndex.value = 0;
    selectedSlotIndex.value = 0;
    selectedMonthlyDate.value = null;
    _selectFirstBookableSlot();
    bookingHold.value = null;
  }

  void setSessionIndex(int index) {
    final slots = selectedClassSlots;
    if (index < 0 || index >= slots.length) return;
    selectSlot(slots[index]);
  }

  void selectSlot(MemberAvailabilitySlotModel slot) {
    if (!slot.isBookable) {
      showAppSnackbar(
        'Slot unavailable',
        'Please choose an available slot with open spots.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    var shouldAdvanceToNextDate = false;
    if (isMonthlySelection) {
      final wasSelected = selectedSlotIds.contains(slot.id);
      _removeSlotsForDate(slot.date);
      if (!wasSelected) {
        selectedSlotIds.add(slot.id);
        shouldAdvanceToNextDate = true;
      }
      selectedSlotIds.refresh();
    } else {
      selectedSlotIds
        ..clear()
        ..add(slot.id);
      selectedSlotIds.refresh();
    }

    final actualIndex = selectedClassSlots.indexWhere(
      (item) => item.id == slot.id,
    );
    selectedSessionIndex.value = actualIndex < 0 ? 0 : actualIndex;
    selectedSlotIndex.value = selectedSessionIndex.value;
    selectedTime.value = slot.startTime;
    selectedDate.value = DateTime.tryParse(slot.date) ?? selectedDate.value;
    focusedDate.value = selectedDate.value;
    selectedPeriod.value = _slotPeriod(slot.startTime);
    if (shouldAdvanceToNextDate) {
      _focusNextAvailableDate(after: DateTime.tryParse(slot.date));
    }
    bookingHold.value = null;
  }

  void setTimeSlot(int index) {
    final slots = filteredSlots;
    if (index < 0 || index >= slots.length) return;
    selectSlot(slots[index]);
  }

  void selectDate(DateTime selectedDay, DateTime focusedDay) {
    if (isMonthlySelection) {
      final isAlreadyViewed = _sameDate(
        selectedDate.value.toString(),
        selectedDay,
      );

      if (isAlreadyViewed && hasSelectedSlot(selectedDay)) {
        // Toggling off: Deselect all slots for this date.
        final slotsForDate = selectedClassSlots
            .where((slot) => _sameDate(slot.date, selectedDay))
            .toList();
        for (var s in slotsForDate) {
          selectedSlotIds.remove(s.id);
        }
      }

      selectedDate.value = selectedDay;
      selectedMonthlyDate.value = selectedDay;
      focusedDate.value = focusedDay;
    } else {
      selectedDate.value = selectedDay;
      focusedDate.value = focusedDay;

      final slotsForDate = selectedClassSlots
          .where((slot) => _sameDate(slot.date, selectedDay) && slot.isBookable)
          .toList();

      selectedSlotIds.clear();
      if (slotsForDate.isNotEmpty) {
        selectedSlotIds.add(slotsForDate.first.id);
      }
    }

    selectedSlotIds.refresh();
    bookingHold.value = null;
  }

  void setPeriod(String value) {
    selectedPeriod.value = value;
    final nextSlot = filteredSlots.firstWhereOrNull((slot) => slot.isBookable);
    if (nextSlot != null) selectSlot(nextSlot);
  }

  void setPaymentMethod(String value) {
    selectedPaymentMethod.value = value;
  }

  bool hasAvailableSlot(DateTime day) {
    return selectedClassSlots.any(
      (slot) => _sameDate(slot.date, day) && slot.isBookable,
    );
  }

  bool hasBookedSlot(DateTime day) {
    return selectedClassSlots.any(
      (slot) => _sameDate(slot.date, day) && !slot.isBookable,
    );
  }

  bool hasSelectedSlot(DateTime day) {
    return selectedClassSlots.any(
      (slot) => selectedSlotIds.contains(slot.id) && _sameDate(slot.date, day),
    );
  }

  Future<void> fetchApprovalStatus() async {
    try {
      final user = await _userService.getCurrentUser();
      _hydrateMemberFields(user);
      final status = user.accountStatus?.trim().toUpperCase();
      isAccountApproved.value =
          status == null || status.isEmpty || status == 'APPROVED';
    } catch (_) {
      isAccountApproved.value = true;
    }
  }

  Future<void> fetchClasses({bool showError = false}) async {
    try {
      isLoadingClasses.value = true;
      classesErrorMessage.value = '';
      final response = await _classService.getClasses(
        trainerUserId: _trainerUserId,
      );
      memberClasses.assignAll(response);
      _applyInitialSelection();
    } on ApiException catch (error) {
      classesErrorMessage.value = error.message;
      if (showError) {
        showAppSnackbar(
          'Classes failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      classesErrorMessage.value = 'Could not load available classes.';
      if (showError) {
        showAppSnackbar(
          'Classes failed',
          'Could not load available classes.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingClasses.value = false;
    }
  }

  Future<bool> createHold() async {
    final klass = selectedClass;
    if (klass == null) {
      showAppSnackbar(
        'Select a class',
        'Please select an available class.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final slotIds = selectedSlotIds.toList();
    if (slotIds.isEmpty) {
      showAppSnackbar(
        'Select a slot',
        klass.isMonthlySession
            ? 'Please select at least one available class slot.'
            : 'Please select one available class slot.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (bookingHold.value != null) return true;

    try {
      isSubmitting.value = true;
      final hold = await _classService.holdBooking(
        classId: klass.id,
        isMonthlySession: klass.isMonthlySession,
        availabilitySlotIds: slotIds,
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        location: locationController.text.trim(),
        selectedClassType: selectedClassType.value,
        comment: commentController.text.trim(),
        couponCode: couponController.text.trim(),
      );
      bookingHold.value = hold;
      _startHoldTimer(hold.reservedUntil);
      return true;
    } on ApiException catch (error) {
      if (_isTrainerPayoutNotReady(error)) {
        showAppSnackbar(
          'Trainer unavailable',
          'This trainer is not currently accepting payments. Please try another trainer.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        showAppSnackbar(
          'Booking hold failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    } catch (_) {
      showAppSnackbar(
        'Booking hold failed',
        'Could not reserve this class slot.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  bool _isTrainerPayoutNotReady(ApiException error) {
    final data = error.data;
    if (data is Map<String, dynamic>) {
      return data['code'] == 'TRAINER_PAYOUT_NOT_READY' ||
          (data['data'] is Map &&
              (data['data'] as Map)['code'] == 'TRAINER_PAYOUT_NOT_READY');
    }
    return false;
  }

  Future<bool> payWithStripe() async {
    final paymentId = bookingHold.value?.paymentId;
    if (paymentId == null || paymentId.isEmpty) {
      showAppSnackbar(
        'Payment missing',
        'Could not find the reserved payment.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    StripePaymentIntentModel? intent;
    try {
      isSubmitting.value = true;
      intent = await _classService.createStripePaymentIntent(paymentId);
      if (intent.clientSecret.isEmpty) {
        throw const ApiException('Stripe client secret was not returned.');
      }

      final publishableKey = intent.publishableKey.trim().isNotEmpty
          ? intent.publishableKey.trim()
          : AppConstants.Publishable_key.trim();
      if (publishableKey.isEmpty) {
        throw const ApiException('Stripe publishable key was not returned.');
      }

      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: AppConstants.APP_NAME,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      await _classService.confirmStripePayment(
        paymentId: paymentId,
        paymentIntentId: intent.paymentIntentId,
      );
      _holdTimer?.cancel();
      _showPaymentResultDialog(success: true);
      return true;
    } on StripeException catch (error) {
      _debugPaymentError('StripeException', error);
      final message =
          error.error.localizedMessage ??
          error.error.message ??
          'Stripe payment was cancelled or failed.';
      showAppSnackbar(
        'Payment failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
      _showPaymentResultDialog(success: false);
      return false;
    } on ApiException catch (error) {
      _debugPaymentError('ApiException', error);
      if (_isPaymentNotFound(error)) {
        _clearBookingHold();
        showAppSnackbar(
          'Reservation expired',
          'Please reserve this slot again before paying.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      if (intent?.paymentIntentId.isNotEmpty == true) {
        await _markPaymentFailed(paymentId, intent?.paymentIntentId);
      }
      showAppSnackbar(
        'Payment failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (error) {
      _debugPaymentError('Unexpected payment error', error);
      if (intent?.paymentIntentId.isNotEmpty == true &&
          !_isLocalStripeSetupError(error)) {
        await _markPaymentFailed(paymentId, intent?.paymentIntentId);
      }
      showAppSnackbar(
        'Payment failed',
        'Could not complete your payment.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  bool _isLocalStripeSetupError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('flutter_stripe initialization failed') ||
        message.contains('flutterfragmentactivity') ||
        message.contains('main activity');
  }

  bool _isPaymentNotFound(ApiException error) {
    final errorCode = error.data is Map ? error.data['errorCode'] : null;
    return error.statusCode == 404 ||
        errorCode?.toString() == 'PAYMENT_NOT_FOUND' ||
        error.message.toLowerCase().contains('payment not found');
  }

  void _clearBookingHold() {
    _holdTimer?.cancel();
    bookingHold.value = null;
    holdRemainingSeconds.value = 0;
    if (currentStep.value >= 3) currentStep.value = 2;
  }

  void _debugPaymentError(String label, Object error) {
    debugPrint('Payment debug [$label]: $error');
    if (error is StripeException) {
      debugPrint('Stripe code: ${error.error.code}');
      debugPrint('Stripe message: ${error.error.message}');
      debugPrint('Stripe localizedMessage: ${error.error.localizedMessage}');
      debugPrint('Stripe declineCode: ${error.error.declineCode}');
    }
    if (error is ApiException) {
      debugPrint('API statusCode: ${error.statusCode}');
      debugPrint('API data: ${error.data}');
    }
  }

  Future<void> _markPaymentFailed(
    String paymentId,
    String? paymentIntentId,
  ) async {
    try {
      await _classService.failStripePayment(
        paymentId: paymentId,
        paymentIntentId: paymentIntentId,
      );
    } catch (_) {
      // Failure reporting should not block the user from trying again.
    }
  }

  bool _validateMemberInfo() {
    if (!isAccountApproved.value) {
      showAppSnackbar(
        'Account pending',
        'Your account must be approved before booking.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final location = locationController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        location.isEmpty) {
      showAppSnackbar(
        'Missing information',
        'Please fill in your name, email, phone, and location.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!GetUtils.isEmail(email)) {
      showAppSnackbar(
        'Invalid email',
        'Please enter a valid email address.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (phone.replaceAll(RegExp(r'\D'), '').length < 7) {
      showAppSnackbar(
        'Invalid phone',
        'Please enter a valid phone number.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  void _showPaymentResultDialog({required bool success}) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 34),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: success ? Colors.green : Colors.red,
                size: 44,
              ),
              const SizedBox(height: 14),
              Text(
                success ? 'Payment Completed!' : 'Payment Unsuccessful',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                success
                    ? 'Your class booking is confirmed.'
                    : 'The payment was cancelled or failed. Please try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Get.back();
                    if (success) {
                      await Get.delete<BookTrainerController>(force: true);
                      Get.offNamed('/my_classes_screen');
                    }
                  },
                  child: Text(success ? 'Done' : 'Try again'),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: !success,
    );
  }

  void _startHoldTimer(DateTime? reservedUntil) {
    _holdTimer?.cancel();
    if (reservedUntil == null) {
      holdRemainingSeconds.value = 0;
      return;
    }

    void tick() {
      final remaining = reservedUntil.difference(DateTime.now()).inSeconds;
      holdRemainingSeconds.value = remaining > 0 ? remaining : 0;
      if (remaining <= 0) {
        _holdTimer?.cancel();
        bookingHold.value = null;
        if (currentStep.value >= 3) currentStep.value = 2;
        showAppSnackbar(
          'Reservation expired',
          'The held slot was released. Please select a time again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    tick();
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _applyInitialSelection() {
    final args = Get.arguments;
    final initialClassId = args is Map ? args['classId']?.toString() : null;
    final initialSlotId = args is Map ? args['slotId']?.toString() : null;
    final selectedFromArgs = memberClasses.firstWhereOrNull(
      (item) => item.id == initialClassId,
    );

    if (selectedFromArgs?.classType != null) {
      selectedClassType.value = selectedFromArgs!.classType!.toUpperCase();
    }

    final classes = filteredClasses;
    if (initialClassId != null && initialClassId.isNotEmpty) {
      final classIndex = classes.indexWhere(
        (item) => item.id == initialClassId,
      );
      if (classIndex >= 0) selectedClassIndex.value = classIndex;
    }

    if (initialSlotId != null && initialSlotId.isNotEmpty) {
      final slot = selectedClassSlots.firstWhereOrNull(
        (item) => item.id == initialSlotId,
      );
      if (slot != null && slot.isBookable) {
        selectSlot(slot);
        return;
      }
    }

    _selectFirstBookableSlot();
  }

  void _selectFirstBookableSlot() {
    final slot = selectedClassSlots.firstWhereOrNull((item) => item.isBookable);
    selectedSlotIds.clear();
    if (slot != null) {
      if (!isMonthlySelection) selectedSlotIds.add(slot.id);
      selectedTime.value = slot.startTime;
      selectedDate.value = DateTime.tryParse(slot.date) ?? DateTime.now();
      focusedDate.value = selectedDate.value;
      selectedPeriod.value = _slotPeriod(slot.startTime);
      selectedSessionIndex.value = selectedClassSlots.indexOf(slot);
      selectedSlotIndex.value = selectedSessionIndex.value;
    }
    selectedSlotIds.refresh();
  }

  void _removeSlotsForDate(String date) {
    for (final slot in selectedClassSlots.where((slot) => slot.date == date)) {
      selectedSlotIds.remove(slot.id);
    }
  }

  void _focusNextAvailableDate({DateTime? after}) {
    if (after == null) return;

    final selectedDateKeys = selectedSlots
        .map((slot) => _dateKey(DateTime.tryParse(slot.date)))
        .whereType<String>()
        .toSet();

    final nextSlot = selectedClassSlots.firstWhereOrNull((slot) {
      if (!slot.isBookable) return false;
      final date = DateTime.tryParse(slot.date);
      if (date == null || !date.isAfter(after)) return false;
      return !selectedDateKeys.contains(_dateKey(date));
    });

    if (nextSlot == null) return;
    final nextDate = DateTime.tryParse(nextSlot.date);
    if (nextDate == null) return;
    selectedDate.value = nextDate;
    selectedMonthlyDate.value = nextDate;
    focusedDate.value = nextDate;
    selectedPeriod.value = _slotPeriod(nextSlot.startTime);
  }

  String? _dateKey(DateTime? date) {
    if (date == null) return null;
    return '${date.year}-${date.month}-${date.day}';
  }

  bool _sameDate(String date, DateTime day) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return false;
    return parsed.year == day.year &&
        parsed.month == day.month &&
        parsed.day == day.day;
  }

  String _slotPeriod(String time) {
    final hour = int.tryParse(time.split(':').first);
    if (hour == null) return selectedPeriod.value;
    return hour >= 12 ? 'PM' : 'AM';
  }

  double _money(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(sanitized) ?? 0;
  }

  Map<String, dynamic> _trainerFromArgs() {
    final args = Get.arguments;
    if (args is Map && args['trainer'] is Map) {
      return (args['trainer'] as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return const <String, dynamic>{};
  }

  String _readTrainerString(String key, String fallback) {
    final value = trainer[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    return fallback;
  }

  String? get _trainerUserId {
    final value = (trainer['trainerUserId']?.toString() ?? '').trim();
    if (value.isNotEmpty) return value;
    final id = (trainer['id']?.toString() ?? '').trim();
    if (id.isNotEmpty) return id;
    return null;
  }

  void _hydrateMemberFields(dynamic user) {
    _setIfEmpty(fullNameController, user.displayName);
    _setIfEmpty(emailController, user.email);
    _setIfEmpty(phoneController, user.phoneNumber);

    final location = user.displayLocation;
    if (location != 'Location not added') {
      _setIfEmpty(locationController, location);
    }
  }

  void _setIfEmpty(TextEditingController controller, String? value) {
    final text = value?.trim();
    if (controller.text.trim().isEmpty && text != null && text.isNotEmpty) {
      controller.text = text;
    }
  }

  @override
  void onClose() {
    _holdTimer?.cancel();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    commentController.dispose();
    couponController.dispose();
    cardHolderController.dispose();
    cardNumberController.dispose();
    expController.dispose();
    cvcController.dispose();
    super.onClose();
  }
}
