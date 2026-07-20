import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/services/device_location_service.dart';
import 'package:fitness/services/location_service.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';

class TrainerListController extends GetxController {
  TrainerListController({
    LocationService? locationService,
    DeviceLocationService? deviceLocationService,
  }) : _locationService = locationService ?? LocationService(),
       _deviceLocationService =
           deviceLocationService ?? DeviceLocationService();

  final LocationService _locationService;
  final DeviceLocationService _deviceLocationService;

  var selectedTab = "Near You".obs;
  var searchQuery = "".obs;
  final nearbyTrainers = <Map<String, dynamic>>[].obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  final isLoadingNearby = false.obs;
  final isLoadingSearch = false.obs;
  final showBookmarkedOnly = false.obs;
  final currentLat = Rxn<double>();
  final currentLng = Rxn<double>();

  static const double defaultLat = 23.8103;
  static const double defaultLng = 90.4125;
  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    fetchNearbyTrainers();
    _searchWorker = debounce<String>(
      searchQuery,
      (_) => searchTrainers(),
      time: const Duration(milliseconds: 450),
    );
  }

  void setTab(String tab) {
    showBookmarkedOnly.value = false;
    selectedTab.value = tab;
    if (tab == "Near You" && nearbyTrainers.isEmpty) {
      fetchNearbyTrainers();
    }
  }

  void toggleBookmarkedOnly() {
    showBookmarkedOnly.toggle();
  }

  void onSearch(String query) {
    searchQuery.value = query;
  }

  Future<void> fetchNearbyTrainers({
    double? lat,
    double? lng,
    double radiusKm = 10,
    bool showError = false,
  }) async {
    try {
      isLoadingNearby.value = true;
      final position = lat != null && lng != null
          ? DeviceLocationResult(lat: lat, lng: lng)
          : await _deviceLocationService.getCurrentLocation();
      currentLat.value = position.lat;
      currentLng.value = position.lng;
      try {
        await _locationService.saveMemberLocation(
          lat: position.lat,
          lng: position.lng,
        );
      } catch (_) {
        // Nearby search can still work even when saving current location fails.
      }
      final response = await _locationService.findNearbyTrainers(
        lat: position.lat,
        lng: position.lng,
        radiusKm: radiusKm,
      );
      nearbyTrainers.assignAll(response.map((item) => item.toUiMap()));
    } on DeviceLocationPermissionException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Location permission required',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Nearby trainers failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'Nearby trainers failed',
          'Could not load nearby trainers.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingNearby.value = false;
    }
  }

  Future<void> searchTrainers({bool showError = false}) async {
    final query = searchQuery.value.trim();
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isLoadingSearch.value = true;
      final response = await _locationService.searchTrainers(name: query);
      searchResults.assignAll(response.map((item) => item.toUiMap()));
    } on ApiException catch (error) {
      if (showError) {
        showAppSnackbar(
          'Trainer search failed',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      if (showError) {
        showAppSnackbar(
          'Trainer search failed',
          'Could not search trainers.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoadingSearch.value = false;
    }
  }

  Map<String, dynamic> trainerArgs(Map<String, dynamic> trainer) {
    return {
      'trainerId': trainer['id'],
      'trainer': trainer,
      if (currentLat.value != null) 'lat': currentLat.value,
      if (currentLng.value != null) 'lng': currentLng.value,
    };
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }
}
