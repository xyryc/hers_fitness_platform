import 'package:fitness/utils/image_url.dart';

class ChatParticipant {
  final String id;
  final String name;
  final String? profileImageUrl;

  const ChatParticipant({
    required this.id,
    required this.name,
    this.profileImageUrl,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: _readString(json, const ['id', 'userId', 'user_id']) ?? '',
      name: _displayName(json) ?? 'User',
      profileImageUrl: normalizeImageUrl(
        _readString(json, const [
          'profileImageUrl',
          'profile_image_url',
          'imageUrl',
          'image_url',
          'avatar',
          'avatarUrl',
          'avatar_url',
        ]),
      ),
    );
  }
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderUserId;
  final String messageType;
  final String text;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime? seenAt;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.messageType,
    required this.text,
    this.attachmentUrl,
    this.attachmentType,
    this.seenAt,
    this.createdAt,
    this.raw = const <String, dynamic>{},
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final sender = _object(data['sender']) ?? _object(data['senderUser']);

    return ChatMessageModel(
      id: _readString(data, const ['id', 'messageId', 'message_id']) ?? '',
      conversationId:
          _readString(data, const [
            'conversationId',
            'conversation_id',
            'chatConversationId',
            'chat_conversation_id',
          ]) ??
          '',
      senderUserId:
          _readString(data, const [
            'senderUserId',
            'sender_user_id',
            'senderId',
            'sender_id',
            'fromUserId',
            'from_user_id',
            'userId',
            'user_id',
          ]) ??
          _readString(sender, const ['id', 'userId', 'user_id']) ??
          '',
      messageType:
          (_readString(data, const ['messageType', 'message_type', 'type']) ??
                  'TEXT')
              .toUpperCase(),
      text:
          _readString(data, const [
            'text',
            'message',
            'messageText',
            'message_text',
            'content',
            'body',
          ]) ??
          '',
      attachmentUrl: normalizeImageUrl(
        _readString(data, const ['attachmentUrl', 'attachment_url']),
      ),
      attachmentType: _readString(data, const [
        'attachmentType',
        'attachment_type',
      ]),
      seenAt: _readDate(data, const ['seenAt', 'seen_at']),
      createdAt: _readDate(data, const [
        'createdAt',
        'created_at',
        'sentAt',
        'sent_at',
        'timestamp',
      ]),
      raw: data,
    );
  }
}

class ChatConversationModel {
  final String id;
  final String memberUserId;
  final String trainerUserId;
  final String memberStatus;
  final String trainerStatus;
  final DateTime? lastMessageAt;
  final ChatParticipant? member;
  final ChatParticipant? trainer;
  final ChatMessageModel? lastMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  const ChatConversationModel({
    required this.id,
    required this.memberUserId,
    required this.trainerUserId,
    required this.memberStatus,
    required this.trainerStatus,
    this.lastMessageAt,
    this.member,
    this.trainer,
    this.lastMessage,
    this.createdAt,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final member = _object(data['member']);
    final trainer = _object(data['trainer']);
    final lastMessage = _object(data['lastMessage'] ?? data['last_message']);

    return ChatConversationModel(
      id:
          _readString(data, const [
            'id',
            'conversationId',
            'conversation_id',
          ]) ??
          '',
      memberUserId:
          _readString(data, const ['memberUserId', 'member_user_id']) ??
          _readString(member, const ['id', 'userId', 'user_id']) ??
          '',
      trainerUserId:
          _readString(data, const ['trainerUserId', 'trainer_user_id']) ??
          _readString(trainer, const ['id', 'userId', 'user_id']) ??
          '',
      memberStatus:
          (_readString(data, const ['memberStatus', 'member_status']) ??
                  'INACTIVE')
              .toUpperCase(),
      trainerStatus:
          (_readString(data, const ['trainerStatus', 'trainer_status']) ??
                  'INACTIVE')
              .toUpperCase(),
      lastMessageAt: _readDate(data, const [
        'lastMessageAt',
        'last_message_at',
      ]),
      member: member == null ? null : ChatParticipant.fromJson(member),
      trainer: trainer == null ? null : ChatParticipant.fromJson(trainer),
      lastMessage: lastMessage == null
          ? null
          : ChatMessageModel.fromJson(lastMessage),
      createdAt: _readDate(data, const ['createdAt', 'created_at']),
      updatedAt: _readDate(data, const ['updatedAt', 'updated_at']),
      raw: data,
    );
  }

  String get title => trainer?.name ?? 'Trainer';

  String? get avatarUrl => trainer?.profileImageUrl;

  String get lastMessagePreview {
    final message = lastMessage;
    if (message == null) return 'No messages yet';
    if (message.messageType == 'IMAGE') return 'Photo';
    return message.text.isEmpty ? 'Message' : message.text;
  }

  DateTime? get sortDate => lastMessageAt ?? updatedAt ?? createdAt;
}

List<Map<String, dynamic>> readListPayload(
  dynamic response,
  List<String> keys,
) {
  if (response is List) {
    return response.whereType<Map>().map(_stringMap).toList();
  }

  if (response is Map) {
    return _readListFromMap(_stringMap(response), keys, <int>{});
  }

  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _readListFromMap(
  Map<String, dynamic> map,
  List<String> keys,
  Set<int> visited,
) {
  final identity = identityHashCode(map);
  if (!visited.add(identity)) return const <Map<String, dynamic>>[];

  for (final key in keys) {
    final value = map[key];
    if (value is List) return value.whereType<Map>().map(_stringMap).toList();
    if (value is Map) {
      final nested = _readListFromMap(_stringMap(value), keys, visited);
      if (nested.isNotEmpty) return nested;
    }
  }

  for (final key in const [
    'data',
    'conversation',
    'message',
    'item',
    'result',
  ]) {
    final value = map[key];
    if (value is List) return value.whereType<Map>().map(_stringMap).toList();
    if (value is Map) {
      final nested = _readListFromMap(_stringMap(value), keys, visited);
      if (nested.isNotEmpty) return nested;
    }
  }

  for (final value in map.values) {
    if (value is Map) {
      final nested = _readListFromMap(_stringMap(value), keys, visited);
      if (nested.isNotEmpty) return nested;
    }
  }

  // Last-resort fallback: backend sometimes stores the list under an
  // unexpected key (e.g. "rows", "list", "chatHistory").  After all
  // known-key and Map-recursion attempts have failed, return the first
  // non-empty list of objects found in the remaining values.  We only
  // return lists whose items are Maps (i.e. JSON objects) so that
  // incidental primitive arrays (IDs, tags, etc.) are ignored.
  for (final value in map.values) {
    if (value is List) {
      final list = value.whereType<Map>().map(_stringMap).toList();
      if (list.isNotEmpty) return list;
    }
  }

  return const <Map<String, dynamic>>[];
}

Map<String, dynamic> readMapPayload(dynamic response) {
  if (response is Map) {
    final map = _stringMap(response);
    final data = map['data'];
    if (data is Map) {
      final dataMap = _stringMap(data);
      for (final key in const ['conversation', 'message', 'item', 'result']) {
        final value = dataMap[key];
        if (value is Map) return _stringMap(value);
      }
      return dataMap;
    }
    for (final key in const ['conversation', 'message', 'item', 'result']) {
      final value = map[key];
      if (value is Map) return _stringMap(value);
    }
    return map;
  }

  return const <String, dynamic>{};
}

Map<String, dynamic>? _object(dynamic value) {
  if (value is Map) return _stringMap(value);
  return null;
}

Map<String, dynamic> _stringMap(Map value) {
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String? _displayName(Map<String, dynamic>? user) {
  if (user == null) return null;

  final firstName = _readString(user, const ['firstName', 'first_name']);
  final lastName = _readString(user, const ['lastName', 'last_name']);
  final combinedName = [
    firstName,
    lastName,
  ].where((value) => value != null && value.trim().isNotEmpty).join(' ');

  return _readString(user, const ['name', 'fullName', 'full_name']) ??
      (combinedName.isEmpty ? null : combinedName) ??
      _readString(user, const ['email']);
}

String? _readString(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;

  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is Map || value is Iterable) continue;

    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }

  return null;
}

DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) return null;
  return DateTime.tryParse(value);
}
