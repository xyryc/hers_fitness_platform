import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/faq_model.dart';

class FaqService {
  FaqService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// GET /api/faqs — returns active FAQs sorted by [order] ascending
  Future<List<FaqModel>> getFaqs() async {
    final response = await _apiClient.get(ApiEndpoints.faqs);
    final map = _asMap(response);
    final list = (map['data'] ?? map) as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(FaqModel.fromJson)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    throw const ApiException('Invalid server response');
  }
}
