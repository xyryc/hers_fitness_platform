import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/services/device_location_service.dart';
import 'package:fitness/services/location_service.dart';
import 'package:get/get.dart';
import 'package:fitness/utils/app_snackbar.dart';

class TrainerLocationController extends GetxController {
  TrainerLocationController({
    LocationService? locationService,
    DeviceLocationService? deviceLocationService,
  }) : _locationService = locationService ?? LocationService(),
       _deviceLocationService =
           deviceLocationService ?? DeviceLocationService();

  final LocationService _locationService;
  final DeviceLocationService _deviceLocationService;

  final isOnline = false.obs;
  final isUpdating = false.obs;
  final baseLat = Rxn<double>();
  final baseLng = Rxn<double>();

  static const double defaultLat = 23.8103;
  static const double defaultLng = 90.4125;

  Future<bool> setCurrentLocationAsBase() async {
    try {
      isUpdating.value = true;
      final position = await _deviceLocationService.getCurrentLocation();
      await _locationService.setTrainerBaseLocation(
        lat: position.lat,
        lng: position.lng,
        timezone: DateTime.now().timeZoneName,
      );
      baseLat.value = position.lat;
      baseLng.value = position.lng;
      showAppSnackbar(
        'Base location saved',
        'Your current location is now your trainer base location.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on DeviceLocationPermissionException catch (error) {
      showAppSnackbar(
        'Location permission required',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (error) {
      showAppSnackbar(
        'Location update failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Location update failed',
        'Could not update trainer base location.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUpdating.value = false;
    }

    return false;
  }

  Future<bool> setBaseLocation({
    required double lat,
    required double lng,
  }) async {
    try {
      isUpdating.value = true;
      await _locationService.setTrainerBaseLocation(
        lat: lat,
        lng: lng,
        timezone: DateTime.now().timeZoneName,
      );
      baseLat.value = lat;
      baseLng.value = lng;
      showAppSnackbar(
        'Base location saved',
        'Your trainer base location has been updated.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on ApiException catch (error) {
      showAppSnackbar(
        'Location update failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Location update failed',
        'Could not update trainer base location.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUpdating.value = false;
    }

    return false;
  }

  Future<bool> updateLiveLocation({
    required double lat,
    required double lng,
    bool showSuccess = true,
  }) async {
    try {
      isUpdating.value = true;
      await _locationService.updateTrainerLiveLocation(lat: lat, lng: lng);
      if (showSuccess) {
        showAppSnackbar(
          'Live location updated',
          'Members can now see your latest live location.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return true;
    } on ApiException catch (error) {
      showAppSnackbar(
        'Live location failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Live location failed',
        'Could not update trainer live location.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUpdating.value = false;
    }

    return false;
  }

  Future<bool> clearLiveLocation({bool showSuccess = true}) async {
    try {
      isUpdating.value = true;
      await _locationService.clearTrainerLiveLocation();
      if (showSuccess) {
        showAppSnackbar(
          'Live location cleared',
          'Your live location is no longer visible.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return true;
    } on ApiException catch (error) {
      showAppSnackbar(
        'Live location failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      showAppSnackbar(
        'Live location failed',
        'Could not clear trainer live location.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUpdating.value = false;
    }

    return false;
  }

  Future<void> toggleOnlineStatus(
    bool value, {
    double? lat,
    double? lng,
  }) async {
    final previousValue = isOnline.value;
    isOnline.value = value;

    try {
      isUpdating.value = true;

      if (value) {
        final position = lat != null && lng != null
            ? DeviceLocationResult(lat: lat, lng: lng)
            : await _deviceLocationService.getCurrentLocation();
        await _locationService.updateTrainerLiveLocation(
          lat: position.lat,
          lng: position.lng,
        );
        await _locationService.updateTrainerOnlineStatus(isOnline: true);
      } else {
        await _locationService.clearTrainerLiveLocation();
      }

      showAppSnackbar(
        value ? 'You are online' : 'You are offline',
        value
            ? 'Your live location is active for nearby members.'
            : 'Your live location has been cleared.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on DeviceLocationPermissionException catch (error) {
      isOnline.value = previousValue;
      showAppSnackbar(
        'Location permission required',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (error) {
      isOnline.value = previousValue;
      showAppSnackbar(
        'Status update failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      isOnline.value = previousValue;
      showAppSnackbar(
        'Status update failed',
        'Could not update trainer online status.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUpdating.value = false;
    }
  }
}
