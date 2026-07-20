import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/trainer_profile_model.dart';

class LocationService {
  LocationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<void> setTrainerBaseLocation({
    required double lat,
    required double lng,
    String? timezone,
  }) async {
    await _apiClient.post(
      ApiEndpoints.trainerBaseLocation,
      body: {
        'lat': lat,
        'lng': lng,
        if (timezone != null) 'timezone': timezone,
      },
    );
  }

  Future<void> updateTrainerLiveLocation({
    required double lat,
    required double lng,
  }) async {
    await _apiClient.put(
      ApiEndpoints.trainerLiveLocation,
      body: {'lat': lat, 'lng': lng},
    );
  }

  Future<void> clearTrainerLiveLocation() async {
    await _apiClient.delete(ApiEndpoints.trainerLiveLocation);
  }

  Future<void> updateTrainerOnlineStatus({required bool isOnline}) async {
    await _apiClient.put(
      ApiEndpoints.trainerOnlineStatus,
      body: {'isOnline': isOnline},
    );
  }

  Future<void> saveMemberLocation({
    required double lat,
    required double lng,
  }) async {
    await _apiClient.post(
      ApiEndpoints.memberLocation,
      body: {'lat': lat, 'lng': lng},
    );
  }

  Future<List<TrainerProfileModel>> findNearbyTrainers({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.nearbyTrainers,
      queryParameters: {'lat': lat, 'lng': lng, 'radiusKm': radiusKm},
    );

    return _extractList(response).map(TrainerProfileModel.fromJson).toList();
  }

  Future<List<TrainerProfileModel>> searchTrainers({
    String? specialty,
    double? priceMin,
    double? priceMax,
    String? name,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.searchTrainers,
      queryParameters: {
        if (specialty != null && specialty.trim().isNotEmpty)
          'specialty': specialty.trim(),
        if (priceMin != null) 'priceMin': priceMin,
        if (priceMax != null) 'priceMax': priceMax,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      },
    );

    return _extractList(response).map(TrainerProfileModel.fromJson).toList();
  }

  Future<TrainerProfileModel> getTrainerProfile({
    required String id,
    double? lat,
    double? lng,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.apiTrainerDetails(id),
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );

    return TrainerProfileModel.fromJson(_extractObject(response));
  }

  Future<Map<String, dynamic>> getTrainerOverview({
    required String trainerUserId,
    double? lat,
    double? lng,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.trainerOverview(trainerUserId),
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );

    return _extractObject(response);
  }

  List<Map<String, dynamic>> _extractList(dynamic response) {
    if (response is List) {
      return response.whereType<Map>().map(_toStringMap).toList();
    }

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid server response');
    }

    final data = response['data'];
    if (data is List) {
      return data.whereType<Map>().map(_toStringMap).toList();
    }
    if (data is Map) {
      final dataMap = _toStringMap(data);
      for (final key in const ['items', 'trainers', 'results']) {
        final value = dataMap[key];
        if (value is List) {
          return value.whereType<Map>().map(_toStringMap).toList();
        }
      }
    }

    for (final key in const ['items', 'trainers', 'results']) {
      final value = response[key];
      if (value is List) {
        return value.whereType<Map>().map(_toStringMap).toList();
      }
    }

    return const [];
  }

  Map<String, dynamic> _extractObject(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid server response');
    }

    final data = response['data'];
    if (data is Map) {
      final dataMap = _toStringMap(data);
      final trainer = dataMap['trainer'] ?? dataMap['user'];
      if (trainer is Map) {
        return <String, dynamic>{...dataMap, ..._toStringMap(trainer)};
      }
      return dataMap;
    }

    final trainer = response['trainer'] ?? response['user'];
    if (trainer is Map) {
      return <String, dynamic>{...response, ..._toStringMap(trainer)};
    }

    return response;
  }

  Map<String, dynamic> _toStringMap(Map value) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}
