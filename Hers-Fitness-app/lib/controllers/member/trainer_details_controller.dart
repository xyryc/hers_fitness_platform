import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/member_class_model.dart';
import 'package:fitness/models/trainer_review_model.dart';
import 'package:fitness/services/location_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fitness/utils/app_snackbar.dart';

class TrainerDetailsController extends GetxController {
  TrainerDetailsController({LocationService? locationService})
    : _locationService = locationService ?? LocationService();

  final LocationService _locationService;

  final selectedClassId = ''.obs;
  final trainer = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;
  final isLoadingClasses = false.obs;
  final isLoadingReviews = false.obs;
  final availableClasses = <MemberClassModel>[].obs;
  final reviews = <Map<String, String>>[].obs;
  final classesErrorMessage = ''.obs;
  final reviewsErrorMessage = ''.obs;

  List<Map<String, Object?>> get availabilityOptions {
    final options = <Map<String, Object?>>[];
    final fallbackLocation =
        trainer.value?['locationLabel']?.toString() ?? 'Location unavailable';

    for (final item in availableClasses) {
      if (item.availableSlots.isEmpty) continue;

      final firstSlot = item.availableSlots.first;
      final totalSlots = item.availableSlots.length;

      // Calculate Date Range
      final validDates = item.availableSlots
          .map((s) => DateTime.tryParse(s.date))
          .whereType<DateTime>()
          .toList();

      String displayDate = firstSlot.displayDate;
      if (validDates.length > 1) {
        validDates.sort();
        final firstDate = validDates.first;
        final lastDate = validDates.last;
        if (firstDate.year == lastDate.year &&
            firstDate.month == lastDate.month &&
            firstDate.day != lastDate.day) {
          displayDate =
              '${DateFormat('MMMM d').format(firstDate)} - ${DateFormat('d, yyyy').format(lastDate)}';
        } else if (firstDate.year == lastDate.year &&
            firstDate.month != lastDate.month) {
          displayDate =
              '${DateFormat('MMM d').format(firstDate)} - ${DateFormat('MMM d, yyyy').format(lastDate)}';
        } else if (firstDate.year != lastDate.year) {
          displayDate =
              '${DateFormat('MMM d, yyyy').format(firstDate)} - ${DateFormat('MMM d, yyyy').format(lastDate)}';
        }
      }

      final seenTimeRanges = <String>{};
      final uniqueRawSlots = <Map<String, dynamic>>[];

      for (final s in item.availableSlots) {
        final parsedDate = DateTime.tryParse(s.date);
        final datePrefix = parsedDate != null
            ? DateFormat('MMM d').format(parsedDate)
            : '';

        final displayStart = s.displayTime;
        final displayEnd = s.displayEndTime;

        final timeOnly = displayEnd.isNotEmpty
            ? '$displayStart - $displayEnd'
            : displayStart;

        final fullTimeRange = datePrefix.isNotEmpty
            ? '$datePrefix • $timeOnly'
            : timeOnly;

        if (!seenTimeRanges.contains(fullTimeRange)) {
          seenTimeRanges.add(fullTimeRange);
          uniqueRawSlots.add({
            'id': s.id,
            'time': fullTimeRange,
            'date': s.displayDate,
            'spotsRemaining': s.spotsRemaining,
          });
        }
      }

      final String finalLocation =
          (item.location != null && item.location!.isNotEmpty)
          ? item.location!
          : (fallbackLocation.isNotEmpty
                ? fallbackLocation
                : 'Location unavailable');

      options.add({
        'classId': item.id,
        'title': item.title,
        'time': firstSlot.displayTime,
        'date': displayDate,
        'location': finalLocation,
        'classType': item.classType ?? 'N/A',
        'sessionFormat': item.sessionFormat ?? 'Session',
        'planType': item.sessionPlanType ?? 'Single',
        'price': item.price ?? '0.00',
        'spotsRemaining': firstSlot.spotsRemaining,
        'totalSlots': totalSlots,
        'slots': uniqueRawSlots,
      });
    }
    return options;
  }

  void selectClass(String classId) {
    selectedClassId.value = classId;
  }

  Map<String, dynamic> get bookingArguments {
    final selectedClass = _selectedClass;
    return {
      'trainer': trainer.value,
      if (selectedClass != null) 'classId': selectedClass.id,
    };
  }

  @override
  void onInit() {
    super.onInit();
    _loadInitialTrainer();
    fetchTrainerOverview(showError: true);
  }

  Future<void> fetchTrainerOverview({bool showError = false}) async {
    final id = _trainerUserId;
    if (id == null || id.isEmpty) return;

    try {
      isLoading.value = true;
      isLoadingClasses.value = true;
      isLoadingReviews.value = true;
      classesErrorMessage.value = '';
      reviewsErrorMessage.value = '';
      final args = Get.arguments;
      final lat = args is Map && args['lat'] is num
          ? (args['lat'] as num).toDouble()
          : null;
      final lng = args is Map && args['lng'] is num
          ? (args['lng'] as num).toDouble()
          : null;
      final response = await _locationService.getTrainerOverview(
        trainerUserId: id,
        lat: lat,
        lng: lng,
      );
      trainer.value = _overviewToTrainerMap(response);
      availableClasses.assignAll(_overviewClasses(response));
      reviews.assignAll(_overviewReviews(response));

      if (availabilityOptions.isNotEmpty && selectedClassId.value.isEmpty) {
        selectedClassId.value = availabilityOptions.first['classId'].toString();
      }
    } on ApiException catch (error) {
      classesErrorMessage.value = error.message;
      reviewsErrorMessage.value = error.message;
      if (showError) {
        showAppSnackbar(
          'Trainer overview failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      classesErrorMessage.value = 'Could not load trainer overview.';
      reviewsErrorMessage.value = 'Could not load trainer overview.';
      if (showError) {
        showAppSnackbar(
          'Trainer overview failed',
          'Could not load trainer overview.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
      isLoadingClasses.value = false;
      isLoadingReviews.value = false;
    }
  }

  MemberClassModel? get _selectedClass {
    for (final item in availableClasses) {
      if (item.id == selectedClassId.value) return item;
    }
    if (availableClasses.isEmpty) return null;
    return availableClasses.first;
  }

  void _loadInitialTrainer() {
    final args = Get.arguments;
    if (args is Map && args['trainer'] is Map) {
      final trainerMap = args['trainer'] as Map;
      trainer.value = trainerMap.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return;
    }

    if (args is Map && args['trainerId'] != null) {
      trainer.value = {'id': args['trainerId'].toString()};
    }
  }

  Map<String, dynamic> _overviewToTrainerMap(Map<String, dynamic> data) {
    final stats = _object(data['stats']) ?? const <String, dynamic>{};
    final location = _object(data['location']) ?? const <String, dynamic>{};
    final lat = _readDouble(location, const [
      'liveLocationLat',
      'live_location_lat',
      'baseLocationLat',
      'base_location_lat',
      'lat',
    ]);
    final lng = _readDouble(location, const [
      'liveLocationLng',
      'live_location_lng',
      'baseLocationLng',
      'base_location_lng',
      'lng',
    ]);

    return {
      'id': _readString(data, const ['id']),
      'trainerUserId': _readString(data, const ['trainerUserId', 'id']),
      'name': _readString(data, const ['name', 'displayName']) ?? 'Trainer',
      'expertise':
          _readString(data, const ['classesTaught', 'classes_taught']) ??
          'Fitness Trainer',
      'rating':
          _readDouble(stats, const ['averageRating', 'average_rating']) ?? 0,
      'price': _formatStartingPrice(
        _readString(data, const ['startingPrice', 'starting_price']),
      ),
      'priceRange':
          _readString(data, const ['priceRange', 'price_range']) ??
          _readString(data, const ['startingPrice', 'starting_price']),
      'experience':
          _readString(data, const [
            'instructorExperience',
            'instructor_experience',
          ]) ??
          '${_readInt(stats, const ['experienceYears', 'experience_years']) ?? 0} years',
      'experienceYears':
          _readInt(stats, const ['experienceYears', 'experience_years']) ?? 0,
      'imageUrl':
          _readString(data, const [
            'profileImageUrl',
            'profile_image_url',
            'imageUrl',
          ]) ??
          '',
      'distance': _formatDistance(
        _readDouble(location, const ['distanceMeters', 'distance_meters']),
      ),
      'distanceMeters': _readDouble(location, const [
        'distanceMeters',
        'distance_meters',
      ]),
      'locationLabel':
          _readString(location, const ['label', 'locationLabel']) ?? '',
      'reviewCount':
          _readInt(stats, const ['reviewCount', 'review_count']) ?? 0,
      'clients': _readInt(stats, const ['clients']) ?? 0,
      'bio': _readString(data, const ['bio', 'description']) ?? '',
      'certifications': _readString(data, const ['certifications']),
      'classDeliveryMode': _readString(data, const [
        'classDeliveryMode',
        'class_delivery_mode',
      ]),
      'isOnline': _readBool(data, const ['isOnline', 'is_online']) ?? false,
      'lastSeen': _readString(data, const ['lastSeen', 'last_seen']),
      'lat': lat,
      'lng': lng,
      'isActiveNow': _readBool(data, const ['isOnline', 'is_online']) ?? false,
    };
  }

  List<MemberClassModel> _overviewClasses(Map<String, dynamic> data) {
    final classes = data['classes'];
    if (classes is! List) return const [];

    return classes
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(MemberClassModel.fromJson)
        .toList();
  }

  List<Map<String, String>> _overviewReviews(Map<String, dynamic> data) {
    final rawReviews = data['reviews'];
    if (rawReviews is! List) return const [];

    return rawReviews
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(TrainerReviewModel.fromJson)
        .map((item) => item.toUiMap())
        .toList();
  }

  String? get _trainerUserId {
    final value = trainer.value;
    if (value == null) return null;
    final trainerUserId = (value['trainerUserId']?.toString() ?? '').trim();
    if (trainerUserId.isNotEmpty) return trainerUserId;

    final id = (value['id']?.toString() ?? '').trim();
    if (id.isNotEmpty) return id;

    return null;
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

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value == null) return null;
    return int.tryParse(value) ?? double.tryParse(value)?.round();
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value == null) return null;
    return double.tryParse(value);
  }

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys)?.toLowerCase();
    if (value == null) return null;
    if (value == 'true' || value == '1' || value == 'yes') return true;
    if (value == 'false' || value == '0' || value == 'no') return false;
    return null;
  }

  static String _formatStartingPrice(String? value) {
    if (value == null || value.isEmpty) return 'Price unavailable';
    if (value.startsWith(r'$')) return '$value/session';
    return '\$$value/session';
  }

  static String _formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) return '${meters.round()}m';
    final km = meters / 1000;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)}km';
  }
}
