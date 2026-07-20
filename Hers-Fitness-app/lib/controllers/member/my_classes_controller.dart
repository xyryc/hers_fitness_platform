import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/member_booking_model.dart';
import 'package:fitness/models/trainer_review_model.dart';
import 'package:fitness/services/member_booking_service.dart';
import 'package:fitness/services/review_service.dart';
import 'package:fitness/services/user_service.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:fitness/utils/booking_action_visibility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MyClassesController extends GetxController {
  MyClassesController({
    MemberBookingService? bookingService,
    ReviewService? reviewService,
    UserService? userService,
  }) : _bookingService = bookingService ?? MemberBookingService(),
       _reviewService = reviewService ?? ReviewService(),
       _userService = userService ?? UserService();

  final MemberBookingService _bookingService;
  final ReviewService _reviewService;
  final UserService _userService;

  final selectedFilter = 'All'.obs;
  final selectedRescheduleDate = 'mm/dd/yyyy'.obs;
  final selectedRescheduleTime = '07:00 AM'.obs;
  final bookings = <MemberBookingModel>[].obs;
  final myTrainerReviews = <TrainerReviewModel>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final isSubmittingReview = false.obs;
  final memberUserId = RxnString();

  final List<String> filters = [
    'All',
    'Meditation',
    'Yoga',
    'Cardio',
    'Strength',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchCurrentUser();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      await Future.wait([fetchBookings(), fetchMyReviews()]);
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  List<Map<String, dynamic>> get filteredSchedules {
    final schedules = bookings.map((booking) {
      final uiMap = booking.toUiMap(memberUserId: memberUserId.value);
      final actions = _getMyClassActions(booking);
      return {...uiMap, ...actions};
    }).toList();

    if (selectedFilter.value == 'All') return schedules;
    return schedules
        .where((schedule) => schedule['category'] == selectedFilter.value)
        .toList();
  }

  Map<String, dynamic> _getMyClassActions(MemberBookingModel booking) {
    final now = DateTime.now();
    final source = <String, dynamic>{
      'bookingStatus': booking.bookingStatus,
      'paymentStatus': booking.paymentStatus,
      'scheduledDate': booking.scheduledDate,
      'startTime': booking.startTime,
      'endTime': booking.endTime,
      'startAt': booking.startAt,
      'endAt': booking.endAt,
      'memberCompletedAt': booking.memberCompletedAt,
      'trainerCompletedAt': booking.trainerCompletedAt,
      'completedAt': booking.completedAt,
    };

    DateTime? startAt;
    if (booking.startAt != null) {
      startAt = DateTime.tryParse(booking.startAt!);
    }
    startAt ??= DateTime.tryParse(
      '${booking.scheduledDate} ${booking.startTime}',
    );

    DateTime? endAt;
    if (booking.endAt != null) {
      endAt = DateTime.tryParse(booking.endAt!);
    }
    endAt ??= DateTime.tryParse(
      '${booking.scheduledDate} ${booking.endTime ?? booking.startTime}',
    );

    final isPaid = booking.paymentStatus == "PAID";
    final isClassActive = booking.classStatus == "ACTIVE";

    final isConfirmed = booking.bookingStatus == "CONFIRMED";
    final isRescheduled = booking.bookingStatus == "RESCHEDULED";
    final isRescheduleRequested =
        booking.bookingStatus == "RESCHEDULE_REQUESTED";
    final isCompleted = booking.bookingStatus == "COMPLETED";

    final sessionUpcoming = startAt != null && now.isBefore(startAt);
    final sessionEnded = endAt != null && now.isAfter(endAt);

    final memberMarkedComplete =
        booking.memberCompletedAt != null &&
        booking.memberCompletedAt!.isNotEmpty;
    final trainerMarkedComplete =
        booking.trainerCompletedAt != null &&
        booking.trainerCompletedAt!.isNotEmpty;

    final existingReview = myTrainerReviews.firstWhereOrNull(
      (review) => review.trainerUserId == booking.trainerUserId,
    );

    final currentMemberUserId = memberUserId.value;

    return {
      'showReschedule':
          isPaid &&
          isClassActive &&
          sessionUpcoming &&
          (isConfirmed || isRescheduled),

      'showCheckIn': canShowCheckIn(source, 'MEMBER'),
      'showCheckInEnabled': canEnableCheckIn(source, 'MEMBER'),

      'showMarkAsComplete':
          isPaid &&
          isClassActive &&
          sessionEnded &&
          (isConfirmed || isRescheduled) &&
          !memberMarkedComplete,

      'showChecking':
          isPaid &&
          ((memberMarkedComplete && !trainerMarkedComplete && !isCompleted) ||
              (isRescheduleRequested &&
                  booking.rescheduleRequestedByUserId == currentMemberUserId)),

      'showAcceptReschedule':
          isPaid &&
          isRescheduleRequested &&
          booking.rescheduleRequestedByUserId != currentMemberUserId,

      'showReview':
          isPaid &&
          isCompleted &&
          booking.completedAt != null &&
          existingReview == null,

      'showEditReview':
          isPaid &&
          isCompleted &&
          booking.completedAt != null &&
          existingReview != null,

      'existingReview': existingReview,
    };
  }

  Future<void> fetchCurrentUser() async {
    try {
      final user = await _userService.getCurrentUser();
      memberUserId.value = user.id;
    } catch (_) {
      memberUserId.value = null;
    }
  }

  Future<void> fetchBookings({bool showError = false}) async {
    try {
      final response = await _bookingService.getBookedClasses();
      bookings.assignAll(response);
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Bookings failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'Bookings failed',
          'Could not load your bookings.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> fetchMyReviews() async {
    try {
      final response = await _reviewService.getMyTrainerReviews();
      myTrainerReviews.assignAll(response);
    } catch (_) {
      // Ignore review fetch errors
    }
  }

  Future<void> requestReschedule(String bookingId) async {
    if (isSubmitting.value) return;

    if (bookingId.trim().isEmpty) {
      _showErrorDialog('Booking missing', 'Could not find this booking.');
      return;
    }

    final newDate = _apiDate(selectedRescheduleDate.value);
    final newStartTime = _apiTime(selectedRescheduleTime.value);

    if (newDate == null || newStartTime == null) {
      _showErrorDialog('Invalid time', 'Please select a valid date and time.');
      return;
    }

    try {
      isSubmitting.value = true;
      await _bookingService.requestReschedule(
        bookingId: bookingId,
        newDate: newDate,
        newStartTime: newStartTime,
      );
      await fetchData();
      showAppSnackbar(
        'Reschedule requested',
        'Your new time has been sent to the trainer.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (error) {
      _showErrorDialog('Reschedule failed', _friendlyErrorMessage(error));
    } catch (_) {
      _showErrorDialog('Reschedule failed', 'Could not request a new time.');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> acceptReschedule(String bookingId) async {
    if (isSubmitting.value) return;

    if (bookingId.trim().isEmpty) {
      _showErrorDialog('Booking missing', 'Could not find this booking.');
      return;
    }

    try {
      isSubmitting.value = true;
      await _bookingService.acceptReschedule(bookingId);
      await fetchData();
    } on ApiException catch (error) {
      _showErrorDialog('Accept failed', _friendlyErrorMessage(error));
    } catch (_) {
      _showErrorDialog('Accept failed', 'Could not accept the new time.');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> checkIn(String bookingId) async {
    if (isSubmitting.value) return;

    if (bookingId.trim().isEmpty) {
      _showErrorDialog('Booking missing', 'Could not find this booking.');
      return;
    }

    try {
      isSubmitting.value = true;
      await _bookingService.checkIn(bookingId);
      await fetchData();
      showAppSnackbar(
        'Checked in!',
        'You have successfully checked in to your class.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (error) {
      _showErrorDialog('Check-in failed', _friendlyErrorMessage(error));
    } catch (_) {
      _showErrorDialog(
        'Check-in failed',
        'Could not check in. Please try again.',
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> completeBooking(String bookingId) async {
    if (isSubmitting.value) return;

    if (bookingId.trim().isEmpty) {
      _showErrorDialog('Booking missing', 'Could not find this booking.');
      return;
    }

    try {
      isSubmitting.value = true;
      await _bookingService.completeBooking(bookingId);
      await fetchData();
      showAppSnackbar(
        'Class completed',
        'Your booking has been marked as complete.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (error) {
      final isNotEnded = _isBookingNotEndedError(error);
      _showErrorDialog(
        isNotEnded ? 'Class still ongoing' : 'Complete failed',
        _friendlyErrorMessage(error, bookingId: bookingId),
      );
    } catch (_) {
      _showErrorDialog(
        'Complete failed',
        'Could not mark this class as complete.',
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> submitTrainerReview({
    String? bookingId,
    required String trainerUserId,
    required int rating,
    required String comment,
  }) async {
    if (isSubmittingReview.value) return false;

    final resolvedTrainerUserId = trainerUserId.trim().isNotEmpty
        ? trainerUserId.trim()
        : _trainerUserIdForBooking(bookingId);
    final cleanComment = comment.trim();
    if (resolvedTrainerUserId.isEmpty) {
      showAppSnackbar(
        'Trainer missing',
        'Could not find this trainer for review.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (rating < 1 || rating > 5) {
      showAppSnackbar(
        'Rating required',
        'Please select a rating from 1 to 5.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (cleanComment.isEmpty) {
      showAppSnackbar(
        'Comment required',
        'Please write a short review.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isSubmittingReview.value = true;
      await _reviewService.submitTrainerReview(
        trainerUserId: resolvedTrainerUserId,
        rating: rating,
        comment: cleanComment,
      );
      await fetchData();
      showAppSnackbar(
        'Review posted',
        'Thanks for sharing your feedback.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on ApiException catch (error) {
      showAppSnackbar(
        'Review failed',
        _friendlyErrorMessage(error),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (_) {
      showAppSnackbar(
        'Review failed',
        'Could not post your review.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmittingReview.value = false;
    }
  }

  String _trainerUserIdForBooking(String? bookingId) {
    if (bookingId == null || bookingId.trim().isEmpty) return '';

    final booking = bookings.firstWhereOrNull((item) => item.id == bookingId);
    return booking?.trainerUserId?.trim() ?? '';
  }

  String _friendlyErrorMessage(ApiException error, {String? bookingId}) {
    if (_isBookingNotEndedError(error)) {
      return _bookingNotEndedMessage(error, bookingId: bookingId);
    }

    if (_errorText(error).contains('BOOKING_NOT_FOUND')) {
      return 'We could not find this booking. It might have been cancelled.';
    }

    final serverMessage = _serverMessage(error);
    return serverMessage.isNotEmpty ? serverMessage : error.message;
  }

  bool _isBookingNotEndedError(ApiException error) {
    final errorText = _errorText(error);
    return errorText.contains('BOOKING_NOT_ENDED') ||
        errorText.toLowerCase().contains('has not ended') ||
        errorText.toLowerCase().contains('ends at');
  }

  String _bookingNotEndedMessage(ApiException error, {String? bookingId}) {
    final serverMessage = _serverMessage(error);
    final endTime =
        _endDateTimeFromServerMessage(serverMessage) ??
        _endDateTimeFromBooking(bookingId);

    if (endTime == null) {
      return serverMessage.isNotEmpty
          ? serverMessage
          : 'This class is still running. You can mark it as complete after the scheduled end time.';
    }

    final remaining = endTime.difference(DateTime.now());
    if (!remaining.isNegative) {
      return 'Booking session has not ended yet. It ends at ${_formatEndTime(endTime)}.\n\nYou can mark it as complete in about ${_formatDuration(remaining)}.';
    }

    return 'The scheduled end time has passed, but the server has not accepted completion yet. Please try again in a few seconds.';
  }

  DateTime? _endDateTimeFromServerMessage(String message) {
    final match = RegExp(
      r'ends at (\d{1,2}:\d{2}) on (\d{4}-\d{2}-\d{2})',
      caseSensitive: false,
    ).firstMatch(message);

    if (match == null) return null;

    final time = match.group(1);
    final date = match.group(2);
    if (time == null || date == null) return null;

    return DateTime.tryParse('$date $time');
  }

  DateTime? _endDateTimeFromBooking(String? bookingId) {
    if (bookingId == null || bookingId.trim().isEmpty) return null;

    final booking = bookings.firstWhereOrNull((item) => item.id == bookingId);
    final endTime = booking?.endTime;
    if (booking == null || endTime == null || endTime.isEmpty) return null;

    return DateTime.tryParse(
      '${booking.scheduledDate.trim()} ${endTime.trim()}',
    );
  }

  String _formatEndTime(DateTime endTime) {
    final date = DateFormat('MMM d, yyyy').format(endTime);
    final time = DateFormat('hh:mm a').format(endTime);
    final now = DateTime.now();
    final isToday =
        now.year == endTime.year &&
        now.month == endTime.month &&
        now.day == endTime.day;

    return isToday ? '$time today' : '$time on $date';
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    if (totalMinutes <= 0) return 'less than 1 minute';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} $minutes minute${minutes == 1 ? '' : 's'}';
    }
    if (hours > 0) return '$hours hour${hours == 1 ? '' : 's'}';
    return '$minutes minute${minutes == 1 ? '' : 's'}';
  }

  String _serverMessage(ApiException error) {
    final data = error.data;
    if (data is Map) {
      final message = data['message'];
      if (message is List && message.isNotEmpty)
        return message.first.toString();
      if (message != null) return message.toString();
    }

    return '';
  }

  String _errorText(ApiException error) {
    final parts = <String>[error.message, _serverMessage(error)];
    final data = error.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Iterable) {
        parts.addAll(errors.map((item) => item.toString()));
      } else if (errors is Map) {
        parts.addAll(errors.values.map((item) => item.toString()));
      } else if (errors != null) {
        parts.add(errors.toString());
      }
    }

    return parts.join(' ');
  }

  void _showErrorDialog(String title, String message) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF121212),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4A4A4A)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF121212),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Understood'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void updateRescheduleDate(String date) {
    selectedRescheduleDate.value = date;
  }

  void updateRescheduleTime(String time) {
    selectedRescheduleTime.value = time;
  }

  String? _apiDate(String value) {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return value;

    try {
      final parsed = DateFormat('MM/dd/yyyy').parseStrict(value);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return null;
    }
  }

  String? _apiTime(String value) {
    if (RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) return value;

    try {
      final parsed = DateFormat('hh:mm a').parseStrict(value);
      return DateFormat('HH:mm').format(parsed);
    } catch (_) {
      return null;
    }
  }
}
