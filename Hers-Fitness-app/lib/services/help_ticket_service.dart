import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/help_ticket_model.dart';

class HelpTicketService {
  HelpTicketService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// POST /api/help-tickets — submit a new ticket
  Future<HelpTicketModel> submitTicket({
    required String title,
    required String body,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.helpTickets,
      body: {'title': title, 'body': body},
    );
    return HelpTicketModel.fromJson(_asMap(response));
  }

  /// GET /api/help-tickets/my — list my tickets
  Future<List<HelpTicketModel>> getMyTickets() async {
    final response = await _apiClient.get(ApiEndpoints.helpTicketsMy);
    final map = _asMap(response);
    final list = (map['data'] ?? map) as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(HelpTicketModel.fromJson)
        .toList();
  }

  /// GET /api/help-tickets/my/:id — single ticket with admin reply
  Future<HelpTicketModel> getTicketById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.helpTicketById(id));
    return HelpTicketModel.fromJson(_asMap(response));
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    throw const ApiException('Invalid server response');
  }
}
