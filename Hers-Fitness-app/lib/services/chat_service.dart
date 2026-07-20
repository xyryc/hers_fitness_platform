import 'dart:io';

import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/core/network/api_endpoints.dart';
import 'package:fitness/models/chat_models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatService {
  ChatService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<ChatConversationModel> startConversation({
    required String trainerUserId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatConversations,
      body: {'trainerUserId': trainerUserId},
    );

    return ChatConversationModel.fromJson(readMapPayload(response));
  }

  Future<List<ChatConversationModel>> getConversations() async {
    final response = await _apiClient.get(ApiEndpoints.chatConversations);
    return readListPayload(response, const [
      'conversations',
      'items',
      'results',
    ]).map(ChatConversationModel.fromJson).toList();
  }

  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final response = await _apiClient.get(
      ApiEndpoints.chatConversationMessages(conversationId),
    );
    final messages = readListPayload(response, const [
      'messages',
      'chatMessages',
      'conversationMessages',
      'items',
      'results',
      'rows',
      'list',
      'messageList',
      'chat',
    ]).map(ChatMessageModel.fromJson).toList();
    debugPrint(
      'ChatService.getMessages($conversationId) parsed ${messages.length} messages',
    );
    return messages;
  }

  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String text,
    String messageType = 'TEXT',
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.chatConversationMessages(conversationId),
      body: {
        'messageType': messageType,
        'text': text,
        if (attachmentUrl != null && attachmentUrl.isNotEmpty)
          'attachmentUrl': attachmentUrl,
        if (attachmentType != null && attachmentType.isNotEmpty)
          'attachmentType': attachmentType,
      },
    );

    return ChatMessageModel.fromJson(readMapPayload(response));
  }

  Future<ChatMessageModel> sendImageMessage({
    required String conversationId,
    required File image,
  }) async {
    if (!await image.exists()) {
      throw const ApiException('Selected image was not found.');
    }

    final response = await _apiClient.multipartPost(
      endpoint: ApiEndpoints.chatConversationMessageImage(conversationId),
      fields: const <String, String>{},
      files: [await http.MultipartFile.fromPath('image', image.path)],
    );

    return ChatMessageModel.fromJson(readMapPayload(response));
  }

  Future<void> markSeen(String conversationId) async {
    await _apiClient.patch(ApiEndpoints.chatConversationSeen(conversationId));
  }
}
