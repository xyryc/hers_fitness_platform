import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/trainer_review_model.dart';

class ReviewService {
  ReviewService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<void> submitTrainerReview({
    required String trainerUserId,
    required int rating,
    required String comment,
  }) async {
    await _apiClient.post(
      ApiEndpoints.trainerReviews(trainerUserId),
      body: {'rating': rating, 'comment': comment},
    );
  }

  Future<List<TrainerReviewModel>> getTrainerReviews(
    String trainerUserId,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.trainerReviews(trainerUserId),
    );

    return _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(TrainerReviewModel.fromJson)
        .toList();
  }

  Future<List<TrainerReviewModel>> getMyTrainerReviews() async {
    final response = await _apiClient.get(ApiEndpoints.memberTrainerReviews);

    return _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(TrainerReviewModel.fromJson)
        .toList();
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid server response');
    }

    final data = response['data'];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in const ['items', 'reviews', 'results']) {
        final value = data[key];
        if (value is List) return value;
      }
    }

    for (final key in const ['items', 'reviews', 'results']) {
      final value = response[key];
      if (value is List) return value;
    }

    return const [];
  }
}
