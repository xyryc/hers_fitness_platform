import 'package:geolocator/geolocator.dart';

class DeviceLocationResult {
  final double lat;
  final double lng;

  const DeviceLocationResult({required this.lat, required this.lng});
}

class DeviceLocationPermissionException implements Exception {
  final String message;

  const DeviceLocationPermissionException(this.message);

  @override
  String toString() => message;
}

class DeviceLocationService {
  Future<DeviceLocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const DeviceLocationPermissionException(
        'Please turn on location services and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const DeviceLocationPermissionException(
        'Location permission is required to go online.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return DeviceLocationResult(
      lat: position.latitude,
      lng: position.longitude,
    );
  }
}
