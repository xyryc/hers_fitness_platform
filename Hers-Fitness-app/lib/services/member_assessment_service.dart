import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';

class MemberAssessmentService {
  MemberAssessmentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<dynamic> getAssessment() {
    return _apiClient.get(ApiEndpoints.memberAssessment);
  }

  Future<dynamic> updateAssessment(Map<String, dynamic> payload) {
    return _apiClient.put(ApiEndpoints.memberAssessment, body: payload);
  }
}
