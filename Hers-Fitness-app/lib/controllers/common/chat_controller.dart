import 'dart:async';
import 'dart:io';

import 'package:fitness/core/network/api_client.dart';
import 'package:fitness/models/chat_models.dart';
import 'package:fitness/models/user_profile_model.dart';
import 'package:fitness/services/chat_service.dart';
import 'package:fitness/services/chat_socket_service.dart';
import 'package:fitness/services/user_service.dart';
import 'package:fitness/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderUserId;
  final String text;
  final bool isMe;
  final String time;
  final DateTime? createdAt;
  final String messageType;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime? seenAt;
  final bool isPending;
  final bool isFailed;
  final String? senderName;
  final String? senderAvatarUrl;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.text,
    required this.isMe,
    required this.time,
    this.createdAt,
    this.messageType = 'TEXT',
    this.attachmentUrl,
    this.attachmentType,
    this.seenAt,
    this.isPending = false,
    this.isFailed = false,
    this.senderName,
    this.senderAvatarUrl,
  });

  factory ChatMessage.fromModel(
    ChatMessageModel model, {
    required String? currentUserId,
  }) {
    // Extract sender info from raw if available
    final data = model.raw;
    final sender = data['sender'] ?? data['senderUser'];
    String? name;
    String? avatar;

    if (sender is Map) {
      name = sender['displayName'] ?? sender['name'] ?? sender['fullName'];
      avatar =
          sender['profileImageUrl'] ??
          sender['imageUrl'] ??
          sender['profile_image_url'] ??
          sender['avatarUrl'];
    }

    return ChatMessage(
      id: model.id,
      conversationId: model.conversationId,
      senderUserId: model.senderUserId,
      text: model.text,
      isMe: currentUserId != null && model.senderUserId == currentUserId,
      time: _formatMessageTime(model.createdAt),
      createdAt: model.createdAt,
      messageType: model.messageType,
      attachmentUrl: model.attachmentUrl,
      attachmentType: model.attachmentType,
      seenAt: model.seenAt,
      senderName: name,
      senderAvatarUrl: avatar,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderUserId,
    String? text,
    bool? isMe,
    String? time,
    DateTime? createdAt,
    String? messageType,
    String? attachmentUrl,
    String? attachmentType,
    DateTime? seenAt,
    bool? isPending,
    bool? isFailed,
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderUserId: senderUserId ?? this.senderUserId,
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      seenAt: seenAt ?? this.seenAt,
      isPending: isPending ?? this.isPending,
      isFailed: isFailed ?? this.isFailed,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
    );
  }
}

class ChatContact {
  final String id;
  final String? memberUserId;
  final String? trainerUserId;
  final String? participantUserId;
  final String name;
  final String lastMessage;
  final String? avatarUrl;
  final int unreadCount;
  final DateTime? updatedAt;
  final bool isParticipantActive;

  const ChatContact({
    required this.id,
    this.memberUserId,
    this.trainerUserId,
    this.participantUserId,
    required this.name,
    required this.lastMessage,
    this.avatarUrl,
    this.unreadCount = 0,
    this.updatedAt,
    this.isParticipantActive = false,
  });

  factory ChatContact.fromModel(
    ChatConversationModel model, {
    required String? currentUserId,
  }) {
    final isTrainer =
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        currentUserId == model.trainerUserId;
    final participant = isTrainer ? model.member : model.trainer;
    final participantUserId = isTrainer
        ? model.memberUserId
        : model.trainerUserId;
    final participantStatus = isTrainer
        ? model.memberStatus
        : model.trainerStatus;

    return ChatContact(
      id: model.id,
      memberUserId: model.memberUserId,
      trainerUserId: model.trainerUserId,
      participantUserId: participantUserId,
      name: participant?.name ?? (isTrainer ? 'Member' : 'Trainer'),
      lastMessage: model.lastMessagePreview,
      avatarUrl: participant?.profileImageUrl,
      updatedAt: model.sortDate,
      isParticipantActive: participantStatus == 'ACTIVE',
    );
  }

  ChatContact copyWith({
    String? id,
    String? memberUserId,
    String? trainerUserId,
    String? participantUserId,
    String? name,
    String? lastMessage,
    String? avatarUrl,
    int? unreadCount,
    DateTime? updatedAt,
    bool? isParticipantActive,
  }) {
    return ChatContact(
      id: id ?? this.id,
      memberUserId: memberUserId ?? this.memberUserId,
      trainerUserId: trainerUserId ?? this.trainerUserId,
      participantUserId: participantUserId ?? this.participantUserId,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      isParticipantActive: isParticipantActive ?? this.isParticipantActive,
    );
  }
}

class ChatController extends GetxController {
  ChatController({
    ChatService? chatService,
    ChatSocketService? socketService,
    UserService? userService,
  }) : _chatService = chatService ?? ChatService(),
       _socketService = socketService ?? ChatSocketService(),
       _userService = userService ?? UserService();

  final ChatService _chatService;
  final ChatSocketService _socketService;
  final UserService _userService;

  final messages = <ChatMessage>[].obs;
  final contacts = <ChatContact>[].obs;
  final selectedContact = Rxn<ChatContact>();
  final isLoadingConversations = false.obs;
  final isLoadingMessages = false.obs;
  final isSending = false.obs;
  final isSendingImage = false.obs;
  final isStartingConversation = false.obs;
  final isParticipantTyping = false.obs;
  final isSocketConnected = false.obs;
  final messagesError = ''.obs;
  final conversationsError = ''.obs;
  final searchQuery = ''.obs;
  final composerText = ''.obs;
  final currentUserProfile = Rxn<UserProfileModel>();

  final messageController = TextEditingController();
  final searchController = TextEditingController();

  final List<StreamSubscription<Map<String, dynamic>>> _subscriptions = [];
  Timer? _participantTypingTimer;
  Timer? _typingStopTimer;
  String? _currentUserId;
  String? _joinedConversationId;
  final Map<String, List<ChatMessage>> _messageCache = {};
  // Tracks the conversation ID represented by the current message list.
  // Used by fetchMessages to decide whether to clear the list before fetching:
  // clearing is only necessary when switching to a different conversation. For
  // the same conversation (e.g. a silent refresh after navigating
  // back-and-forward, or a reconnect), we keep the existing messages visible so
  // the user never sees "No messages yet." as a flash.
  String? _loadedConversationId;

  // Prevents concurrent openConversation calls from wiping already-loaded
  // messages.  The most common trigger is a double-tap on the conversation
  // list: without this guard both ChatScreen instances call openConversation
  // through their addPostFrameCallback, causing a second messages.clear() to
  // run immediately after the first fetch completes and the loaded messages
  // are briefly visible — producing the "flash of history → No messages yet."
  // symptom.
  bool _isOpeningConversation = false;
  int _messagesFetchSerial = 0;

  List<ChatContact> get filteredContacts {
    final query = searchQuery.value.trim().toLowerCase();
    final visible = query.isEmpty
        ? contacts.toList()
        : contacts.where((contact) {
            return contact.name.toLowerCase().contains(query) ||
                contact.lastMessage.toLowerCase().contains(query);
          }).toList();

    visible.sort((a, b) {
      final aDate = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return visible;
  }

  bool get canSend => composerText.value.trim().isNotEmpty && !isSending.value;

  bool get canPickImage => !isSendingImage.value;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    messageController.addListener(_handleComposerChanged);
    _bindSocketEvents();
    unawaited(fetchConversations());
    // Connect the socket immediately so the backend's handleConnection can
    // mark the user as ACTIVE across all their conversations the moment the
    // app is open — not just when a specific chat screen is opened.
    unawaited(_connectSocket());
  }

  Future<void> fetchConversations({bool showError = false}) async {
    try {
      isLoadingConversations.value = true;
      conversationsError.value = '';
      await _loadCurrentUserId();

      final response = await _chatService.getConversations();
      contacts.assignAll(
        response.map(
          (conversation) => ChatContact.fromModel(
            conversation,
            currentUserId: _currentUserId,
          ),
        ),
      );
      _refreshSelectedContact();
    } on ApiException catch (error) {
      conversationsError.value = error.message;
      if (showError) _showError('Messages failed', error.message);
    } catch (_) {
      conversationsError.value = 'Could not load conversations.';
      if (showError) _showError('Messages failed', conversationsError.value);
    } finally {
      isLoadingConversations.value = false;
    }
  }

  Future<void> openConversation(ChatContact contact) async {
    // Guard: skip if another openConversation is already in-flight.
    // This is the primary defence against the "messages load then disappear"
    // bug: a double-tap pushes two ChatScreen instances that share this
    // singleton controller and both call openConversation.  The second call
    // arriving while the first fetch is in progress would clear the freshly-
    // loaded messages list and restart the fetch — if that second fetch
    // returned empty (or the UI rendered between the clear and the re-fill)
    // the user saw "No messages yet." instead of the conversation history.
    if (_isOpeningConversation) return;
    _isOpeningConversation = true;

    // Set the loading flag immediately (synchronously, before any awaits) so
    // that the very first frame of ChatScreen shows a spinner rather than the
    // "No messages yet." empty-state.  Without this the UI renders one frame
    // with isLoadingMessages=false and messages=[] — which matches the empty-
    // state condition — causing a brief but jarring flash before the real fetch
    // starts.
    if (messages.isEmpty) {
      isLoadingMessages.value = true;
    }

    try {
      selectedContact.value = contact;
      await _connectSocket();
      _joinConversation(contact.id);
      // fetchMessages already calls markSeen internally once messages are loaded.
      // Do NOT call markSeen here again — it fires a redundant PATCH /seen request.
      await fetchMessages(contact.id, showError: true);
    } finally {
      _isOpeningConversation = false;
    }
  }

  void closeActiveConversation() {
    // With in-app active status, we do NOT emit chat:leave when the user
    // navigates away from a conversation screen. The user is still in the app
    // so they stay ACTIVE. INACTIVE is only set when the socket disconnects
    // (app closed / sent to background and OS kills the connection).
    _joinedConversationId = null;
    isParticipantTyping.value = false;
    _typingStopTimer?.cancel();
    _participantTypingTimer?.cancel();
  }

  Future<ChatContact?> startConversationWithTrainer({
    required String trainerUserId,
    String? trainerName,
    String? avatarUrl,
  }) async {
    if (trainerUserId.trim().isEmpty) {
      _showError('Chat unavailable', 'Trainer user id is missing.');
      return null;
    }

    try {
      isStartingConversation.value = true;
      await _loadCurrentUserId();
      final conversation = await _chatService.startConversation(
        trainerUserId: trainerUserId.trim(),
      );
      var contact = ChatContact.fromModel(
        conversation,
        currentUserId: _currentUserId,
      );
      if (contact.id.isEmpty) {
        throw const ApiException('Conversation id not found');
      }
      if (contact.name == 'Trainer' && trainerName != null) {
        contact = contact.copyWith(name: trainerName);
      }
      if (contact.avatarUrl == null && avatarUrl != null) {
        contact = contact.copyWith(avatarUrl: avatarUrl);
      }

      _upsertContact(contact);
      return contact;
    } on ApiException catch (error) {
      final existing = await _findExistingConversationForTrainer(
        trainerUserId.trim(),
      );
      if (existing != null) {
        return existing;
      }
      _showError('Chat failed', _friendlyChatStartError(error));
    } catch (_) {
      _showError('Chat failed', 'Could not start the conversation.');
    } finally {
      isStartingConversation.value = false;
    }

    return null;
  }

  Future<ChatContact?> _findExistingConversationForTrainer(
    String trainerUserId,
  ) async {
    try {
      final response = await _chatService.getConversations();
      ChatContact? contact;
      for (final item in response.map(
        (conversation) =>
            ChatContact.fromModel(conversation, currentUserId: _currentUserId),
      )) {
        if (item.trainerUserId == trainerUserId) {
          contact = item;
          break;
        }
      }
      if (contact != null) _upsertContact(contact);
      return contact;
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchMessages(
    String conversationId, {
    bool showError = false,
  }) async {
    final normalizedConversationId = conversationId.trim();
    if (normalizedConversationId.isEmpty) return;

    final fetchSerial = ++_messagesFetchSerial;

    try {
      isLoadingMessages.value = true;
      messagesError.value = '';

      // Only wipe the message list when switching to a DIFFERENT conversation.
      // When re-fetching the same conversation (back-and-forward navigation,
      // reconnect, retry, or any sequential openConversation call), keeping
      // the existing messages visible prevents the "No messages yet." flash
      // that was caused by messages.clear() running while the new API call
      // was still in flight.
      // When switching conversations we still clear immediately so the user
      // never sees the previous conversation's history during the load.
      if (_loadedConversationId != normalizedConversationId) {
        final cachedMessages = _messageCache[normalizedConversationId];
        if (cachedMessages != null && cachedMessages.isNotEmpty) {
          messages.assignAll(cachedMessages);
        } else {
          messages.clear();
        }
      }
      _loadedConversationId = normalizedConversationId;

      await _loadCurrentUserId();

      final response = await _chatService.getMessages(normalizedConversationId);
      if (fetchSerial != _messagesFetchSerial) return;

      response.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

      final nextMessages = _dedupeMessages(
        response.map(
          (message) =>
              ChatMessage.fromModel(message, currentUserId: _currentUserId),
        ),
      );

      // If a duplicate/silent refresh for the same conversation parses as
      // empty, keep the history that is already on screen. This prevents a
      // late empty response from replacing visible chat history with the empty
      // state while still allowing genuinely empty newly opened chats.
      if (nextMessages.isEmpty && messages.isNotEmpty) {
        markSeen(normalizedConversationId);
        return;
      }

      messages.assignAll(nextMessages);
      _messageCache[normalizedConversationId] = List<ChatMessage>.unmodifiable(
        nextMessages,
      );
      markSeen(normalizedConversationId);
    } on ApiException catch (error) {
      if (fetchSerial != _messagesFetchSerial) return;
      messagesError.value = error.message;
      if (showError) _showError('Messages failed', error.message);
    } catch (_) {
      if (fetchSerial != _messagesFetchSerial) return;
      messagesError.value = 'Could not load messages.';
      if (showError) _showError('Messages failed', messagesError.value);
    } finally {
      if (fetchSerial == _messagesFetchSerial) {
        isLoadingMessages.value = false;
      }
    }
  }

  Future<void> sendMessage() async {
    final contact = selectedContact.value;
    final text = messageController.text.trim();

    if (contact == null || contact.id.isEmpty || text.isEmpty) return;

    await _loadCurrentUserId();
    final now = DateTime.now();
    final pendingId = 'local-${now.microsecondsSinceEpoch}';
    final pending = ChatMessage(
      id: pendingId,
      conversationId: contact.id,
      senderUserId: _currentUserId ?? '',
      text: text,
      isMe: true,
      time: _formatMessageTime(now),
      createdAt: now,
      isPending: true,
      senderName: currentUserProfile.value?.displayName,
      senderAvatarUrl: currentUserProfile.value?.imageUrl,
    );

    messageController.clear();
    _addOrReplaceMessage(pending);
    _upsertContact(contact.copyWith(lastMessage: text, updatedAt: now));
    _sendTyping(false);

    // Emit via socket for real-time delivery to the other participant.
    // This is fire-and-forget: REST is the single source of truth for
    // DB persistence and sender confirmation. Sending via socket only
    // delivers the event to others immediately; the server does NOT echo
    // back to the sender, so a fallback timer would always fire and create
    // a second DB record — which was the root cause of duplicate messages.
    unawaited(
      _connectSocket().then((_) {
        _socketService.sendText(conversationId: contact.id, text: text);
      }),
    );

    // Always confirm via REST to get the server-assigned ID and ensure
    // exactly one DB record is created.
    await _sendMessageOverRest(
      conversationId: contact.id,
      text: text,
      pendingId: pendingId,
    );
  }

  Future<void> pickAndSendImage(ImageSource source) async {
    final contact = selectedContact.value;
    if (contact == null || contact.id.isEmpty || isSendingImage.value) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
      );
      if (picked == null) return;

      isSendingImage.value = true;
      await _sendImageFile(conversationId: contact.id, file: File(picked.path));
    } on ApiException catch (error) {
      _showError('Image failed', error.message);
    } catch (_) {
      _showError('Image failed', 'Could not send the image.');
    } finally {
      isSendingImage.value = false;
    }
  }

  Future<void> _sendImageFile({
    required String conversationId,
    required File file,
  }) async {
    await _loadCurrentUserId();
    final contact = selectedContact.value;
    final now = DateTime.now();
    final pendingId = 'local-${now.microsecondsSinceEpoch}';
    final pending = ChatMessage(
      id: pendingId,
      conversationId: conversationId,
      senderUserId: _currentUserId ?? '',
      text: '',
      isMe: true,
      time: _formatMessageTime(now),
      createdAt: now,
      messageType: 'IMAGE',
      attachmentUrl: file.path,
      attachmentType: 'image/jpeg',
      isPending: true,
    );

    _addOrReplaceMessage(pending);
    if (contact != null) {
      _upsertContact(contact.copyWith(lastMessage: 'Photo', updatedAt: now));
    }
    _sendTyping(false);

    try {
      final response = await _chatService.sendImageMessage(
        conversationId: conversationId,
        image: file,
      );
      _replacePendingMessage(
        pendingId,
        ChatMessage.fromModel(response, currentUserId: _currentUserId),
      );
    } on ApiException catch (_) {
      _markPendingFailed(pendingId);
      rethrow;
    } catch (_) {
      _markPendingFailed(pendingId);
      rethrow;
    }
  }

  void markSeen(String conversationId) {
    if (conversationId.isEmpty) return;
    _socketService.emitSeen(conversationId);
    unawaited(_markSeenRest(conversationId));
  }

  Future<void> _sendMessageOverRest({
    required String conversationId,
    required String text,
    required String pendingId,
  }) async {
    try {
      isSending.value = true;
      final response = await _chatService.sendMessage(
        conversationId: conversationId,
        text: text,
      );
      _replacePendingMessage(
        pendingId,
        ChatMessage.fromModel(response, currentUserId: _currentUserId),
      );
    } on ApiException catch (error) {
      _markPendingFailed(pendingId);
      messageController.text = text;
      _showError('Message failed', error.message);
    } catch (_) {
      _markPendingFailed(pendingId);
      messageController.text = text;
      _showError('Message failed', 'Could not send your message.');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> _markSeenRest(String conversationId) async {
    try {
      await _chatService.markSeen(conversationId);
      final contact = selectedContact.value;
      if (contact != null && contact.id == conversationId) {
        final updated = contact.copyWith(unreadCount: 0);
        selectedContact.value = updated;
        _upsertContact(updated);
      }
    } catch (_) {}
  }

  Future<void> _connectSocket() async {
    // Register the reconnect handler once so that if the socket drops and
    // reconnects automatically, we re-join the active conversation room.
    // Without this, a mid-session network blip would silently remove the
    // client from the room and stop real-time messages from arriving.
    _socketService.onReconnected ??= () {
      final conversationId = _joinedConversationId;
      if (conversationId != null && conversationId.isNotEmpty) {
        debugPrint('Socket reconnected — re-joining room $conversationId');
        _socketService.join(conversationId);
      }
    };
    await _socketService.connect();
    isSocketConnected.value = _socketService.isConnected;
  }

  void _joinConversation(String conversationId) {
    if (_joinedConversationId == conversationId) return;
    closeActiveConversation();
    _joinedConversationId = conversationId;
    _socketService.join(conversationId);
  }

  void _bindSocketEvents() {
    _subscriptions.addAll([
      _socketService.messages.listen(_handleSocketMessage),
      _socketService.typing.listen(_handleSocketTyping),
      _socketService.seen.listen(_handleSocketSeen),
      _socketService.status.listen(_handleSocketStatus),
      _socketService.userDisconnected.listen(_handleSocketDisconnected),
    ]);
  }

  void _handleSocketMessage(Map<String, dynamic> payload) {
    final model = ChatMessageModel.fromJson(readMapPayload(payload));
    if (model.id.isEmpty) return;

    final message = ChatMessage.fromModel(model, currentUserId: _currentUserId);

    // Own messages are confirmed via the REST response (_replacePendingMessage).
    // broadcastNewMessage on the backend also emits chat:message to the sender's
    // own socket. If the confirmed message is already in the list (REST won the
    // race), ignore the echo — replacing the same widget would restart
    // Image.network loading and cause the image to flash blank again.
    if (message.isMe) {
      final alreadyConfirmed = messages.any(
        (m) => m.id == message.id && !m.isPending,
      );
      if (alreadyConfirmed) return;

      // IMAGE guard: if the socket echo for our own IMAGE message has no
      // attachmentUrl, the backend broadcast omitted the upload URL.  Allowing
      // this echo to replace the pending (which holds the local file path)
      // would wipe the URL and leave the image bubble blank — the subsequent
      // REST response would see the message as "already confirmed" and skip
      // the update.  Skip the echo here; _replacePendingMessage will apply
      // the correct Cloudinary URL once the REST response arrives.
      if (message.messageType == 'IMAGE' && message.attachmentUrl == null) {
        return;
      }
    }

    _addOrReplaceMessage(message);

    final contact = selectedContact.value;
    if (contact != null && contact.id == model.conversationId) {
      _upsertContact(
        contact.copyWith(
          lastMessage: message.messageType == 'IMAGE' ? 'Photo' : message.text,
          updatedAt: message.createdAt ?? DateTime.now(),
        ),
      );
      // Guard against _currentUserId being null: compare senderUserId directly
      // so we never call markSeen on our own outgoing messages even if the
      // current user ID hasn't been loaded yet.
      final isOwnMessage = _currentUserId != null
          ? model.senderUserId == _currentUserId
          : false;
      if (!isOwnMessage) markSeen(model.conversationId);
    } else {
      unawaited(fetchConversations());
    }
  }

  void _handleSocketTyping(Map<String, dynamic> payload) {
    final conversationId = payload['conversationId']?.toString();
    if (conversationId != selectedContact.value?.id) return;

    final senderUserId = payload['senderUserId']?.toString();
    if (senderUserId != null && senderUserId == _currentUserId) return;

    final isTyping = payload['isTyping'] == true;
    isParticipantTyping.value = isTyping;
    _participantTypingTimer?.cancel();
    if (isTyping) {
      _participantTypingTimer = Timer(const Duration(seconds: 3), () {
        isParticipantTyping.value = false;
      });
    }
  }

  void _handleSocketSeen(Map<String, dynamic> payload) {
    final conversationId = payload['conversationId']?.toString();
    if (conversationId == null || conversationId != selectedContact.value?.id) {
      return;
    }

    // The backend now sends seenAt as a top-level field alongside `messages`.
    // Fall back to DateTime.now() if the field is absent (old server versions).
    final seenAt =
        DateTime.tryParse(payload['seenAt']?.toString() ?? '') ??
        DateTime.now();

    // Only update messages sent by the current user that haven't been seen yet.
    // We do NOT replace the whole list — just patch the seenAt field so the
    // "Seen" receipt appears under the sender's bubbles.
    final updated = messages.map((message) {
      if (!message.isMe || message.seenAt != null) return message;
      return message.copyWith(seenAt: seenAt);
    }).toList();

    // Skip the assignAll entirely if nothing actually changed — avoids an
    // unnecessary GetX rebuild that can cause a brief flicker.
    final anyChanged = updated.any(
      (m) =>
          m.seenAt != null &&
          messages.any((o) => o.id == m.id && o.seenAt == null),
    );
    if (anyChanged) messages.assignAll(updated);
  }

  void _handleSocketStatus(Map<String, dynamic> payload) {
    // Server emits the full ChatConversationResponseDto on join/leave/disconnect.
    final conversationId = payload['id']?.toString();
    final memberUserId = payload['memberUserId']?.toString();
    final trainerUserId = payload['trainerUserId']?.toString();
    final memberStatus = payload['memberStatus']?.toString();
    final trainerStatus = payload['trainerStatus']?.toString();

    // Must have both participant IDs and both statuses to do anything useful.
    if (memberUserId == null ||
        trainerUserId == null ||
        memberStatus == null ||
        trainerStatus == null) {
      return;
    }

    for (var index = 0; index < contacts.length; index++) {
      final contact = contacts[index];

      // ── Step 1: find the right contact ──────────────────────────────────
      // Primary: match by conversation ID (unambiguous).
      // Fallback: match by the pair of participant IDs (covers cases where
      //   the payload id field is absent or the contact was built differently).
      final matchById =
          conversationId != null &&
          conversationId.isNotEmpty &&
          contact.id == conversationId;
      final matchByParticipants =
          (contact.memberUserId == memberUserId &&
              contact.trainerUserId == trainerUserId) ||
          (contact.memberUserId == trainerUserId &&
              contact.trainerUserId == memberUserId);

      if (!matchById && !matchByParticipants) continue;

      // ── Step 2: pick the OTHER participant's status ──────────────────────
      // Priority 1 — use _currentUserId (loaded after first API call, most reliable).
      // Priority 2 — use contact.participantUserId (set when the contact was built).
      // Priority 3 — skip; we cannot determine which side is "us".
      bool? isActive;

      if (_currentUserId == memberUserId) {
        // I am the member → the other person is the trainer.
        isActive = trainerStatus.toUpperCase() == 'ACTIVE';
      } else if (_currentUserId == trainerUserId) {
        // I am the trainer → the other person is the member.
        isActive = memberStatus.toUpperCase() == 'ACTIVE';
      } else {
        // _currentUserId not loaded yet — fall back to participantUserId.
        final pid = contact.participantUserId;
        if (pid == memberUserId) {
          isActive = memberStatus.toUpperCase() == 'ACTIVE';
        } else if (pid == trainerUserId) {
          isActive = trainerStatus.toUpperCase() == 'ACTIVE';
        }
      }

      if (isActive != null) {
        contacts[index] = contact.copyWith(isParticipantActive: isActive);
      }
      // Don't break — a user could theoretically appear in multiple contacts
      // (shouldn't happen with 1-to-1 chats, but safe to update all matches).
    }

    _refreshSelectedContact();
  }

  void _handleSocketDisconnected(Map<String, dynamic> payload) {
    final userId =
        payload['userId']?.toString() ??
        payload['trainerUserId']?.toString() ??
        payload['memberUserId']?.toString();
    if (userId == null) return;

    for (var index = 0; index < contacts.length; index++) {
      final contact = contacts[index];
      if (contact.participantUserId == userId ||
          contact.trainerUserId == userId ||
          contact.memberUserId == userId) {
        contacts[index] = contact.copyWith(isParticipantActive: false);
      }
    }
    _refreshSelectedContact();
  }

  void _handleComposerChanged() {
    composerText.value = messageController.text;
    _sendTyping(true);
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(milliseconds: 1400), () {
      _sendTyping(false);
    });
  }

  void _sendTyping(bool isTyping) {
    final conversationId = selectedContact.value?.id;
    if (conversationId == null || conversationId.isEmpty) return;
    _socketService.emitTyping(
      conversationId: conversationId,
      isTyping: isTyping,
    );
  }

  void _addOrReplaceMessage(ChatMessage message) {
    if (message.id.isNotEmpty && !message.id.startsWith('local-')) {
      final existingIndex = messages.indexWhere(
        (item) => item.id == message.id,
      );
      if (existingIndex != -1) {
        messages[existingIndex] = message;
        _cacheCurrentMessages();
        return;
      }

      final pendingIndex = messages.indexWhere((item) {
        return item.isPending &&
            item.isMe == message.isMe &&
            item.text == message.text &&
            item.messageType == message.messageType &&
            item.conversationId == message.conversationId;
      });
      if (pendingIndex != -1) {
        messages[pendingIndex] = message;
        _cacheCurrentMessages();
        return;
      }

      final duplicateIndex = _findDuplicateMessageIndex(message);
      if (duplicateIndex != -1) {
        messages[duplicateIndex] = _mergeDuplicateMessage(
          messages[duplicateIndex],
          message,
        );
        _cacheCurrentMessages();
        return;
      }
    }

    messages.add(message);
    _sortMessages();
    _cacheCurrentMessages();
  }

  List<ChatMessage> _dedupeMessages(Iterable<ChatMessage> source) {
    final unique = <ChatMessage>[];
    for (final message in source) {
      final idIndex = unique.indexWhere(
        (item) => item.id.isNotEmpty && item.id == message.id,
      );
      if (idIndex != -1) {
        unique[idIndex] = _mergeDuplicateMessage(unique[idIndex], message);
        continue;
      }

      final duplicateIndex = unique.indexWhere(
        (item) => _isLikelyDuplicateMessage(item, message),
      );
      if (duplicateIndex != -1) {
        unique[duplicateIndex] = _mergeDuplicateMessage(
          unique[duplicateIndex],
          message,
        );
        continue;
      }

      unique.add(message);
    }

    unique.sort(_compareMessages);
    return unique;
  }

  int _findDuplicateMessageIndex(ChatMessage message) {
    return messages.indexWhere((item) {
      if (item.id.isNotEmpty &&
          message.id.isNotEmpty &&
          item.id == message.id) {
        return false;
      }
      return _isLikelyDuplicateMessage(item, message);
    });
  }

  bool _isLikelyDuplicateMessage(ChatMessage a, ChatMessage b) {
    if (a.conversationId != b.conversationId) return false;
    if (a.messageType != b.messageType) return false;
    if (a.text.trim() != b.text.trim()) return false;
    if ((a.attachmentUrl ?? '') != (b.attachmentUrl ?? '')) return false;
    if ((a.attachmentType ?? '') != (b.attachmentType ?? '')) return false;

    final sameSender = a.senderUserId.isNotEmpty && b.senderUserId.isNotEmpty
        ? a.senderUserId == b.senderUserId
        : a.isMe == b.isMe;
    if (!sameSender) return false;

    final aDate = a.createdAt;
    final bDate = b.createdAt;
    if (aDate == null || bDate == null) return a.time == b.time;

    return aDate.difference(bDate).abs() <= const Duration(seconds: 12);
  }

  ChatMessage _mergeDuplicateMessage(
    ChatMessage current,
    ChatMessage incoming,
  ) {
    if (current.isPending && !incoming.isPending) return incoming;
    if (current.isFailed && !incoming.isFailed) return incoming;
    if (current.id.startsWith('local-') && !incoming.id.startsWith('local-')) {
      return incoming;
    }
    if (current.seenAt == null && incoming.seenAt != null) {
      return current.copyWith(seenAt: incoming.seenAt);
    }
    return current;
  }

  void _sortMessages() {
    messages.sort((a, b) {
      return _compareMessages(a, b);
    });
    _cacheCurrentMessages();
  }

  int _compareMessages(ChatMessage a, ChatMessage b) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aDate.compareTo(bDate);
  }

  void _replacePendingMessage(String pendingId, ChatMessage replacement) {
    final index = messages.indexWhere((message) => message.id == pendingId);
    if (index == -1) {
      // The socket echo (from broadcastNewMessage) may have already replaced
      // the pending before the REST response was processed here.
      if (replacement.id.isNotEmpty) {
        final confirmedIndex = messages.indexWhere(
          (m) => m.id == replacement.id && !m.isPending,
        );
        if (confirmedIndex != -1) {
          // The echo is already confirmed.  For IMAGE messages the socket
          // broadcast can arrive without an attachmentUrl (the backend may not
          // include it in the room event).  The REST response always has the
          // correct Cloudinary URL — apply it now so the bubble renders.
          final confirmed = messages[confirmedIndex];
          if (confirmed.messageType == 'IMAGE' &&
              confirmed.attachmentUrl == null &&
              replacement.attachmentUrl != null) {
            messages[confirmedIndex] = confirmed.copyWith(
              attachmentUrl: replacement.attachmentUrl,
              attachmentType: replacement.attachmentType,
            );
            _cacheCurrentMessages();
          }
          return;
        }
      }
      _addOrReplaceMessage(replacement);
      return;
    }
    messages[index] = replacement.copyWith(isPending: false);
    _cacheCurrentMessages();
  }

  void _markPendingFailed(String pendingId) {
    final index = messages.indexWhere((message) => message.id == pendingId);
    if (index == -1) return;
    messages[index] = messages[index].copyWith(
      isPending: false,
      isFailed: true,
    );
    _cacheCurrentMessages();
  }

  void _cacheCurrentMessages() {
    final conversationId = _loadedConversationId ?? selectedContact.value?.id;
    if (conversationId == null || conversationId.isEmpty || messages.isEmpty) {
      return;
    }
    _messageCache[conversationId] = List<ChatMessage>.unmodifiable(messages);
  }

  void _upsertContact(ChatContact contact) {
    final index = contacts.indexWhere((item) => item.id == contact.id);
    if (index == -1) {
      contacts.add(contact);
    } else {
      contacts[index] = contact;
    }
    _refreshSelectedContact();
  }

  void _refreshSelectedContact() {
    final selected = selectedContact.value;
    if (selected == null) return;

    final updated = contacts.firstWhereOrNull((item) => item.id == selected.id);
    if (updated != null) selectedContact.value = updated;
  }

  Future<void> _loadCurrentUserId() async {
    if (_currentUserId != null) return;
    try {
      final user = await _userService.getCurrentUser();
      _currentUserId = user.id;
      currentUserProfile.value = user;
    } catch (_) {}
  }

  void _showError(String title, String message) {
    showAppSnackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  String _friendlyChatStartError(ApiException error) {
    final message = error.message;
    if (error.statusCode == 500 ||
        message.contains('Prisma') ||
        message.contains('chatConversation.upsert')) {
      return 'Could not start the chat right now. Please try again shortly.';
    }
    return message;
  }

  @override
  void onClose() {
    closeActiveConversation();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _typingStopTimer?.cancel();
    _participantTypingTimer?.cancel();
    unawaited(_socketService.dispose());
    messageController.dispose();
    searchController.dispose();
    super.onClose();
  }
}

String _formatMessageTime(DateTime? value) {
  if (value == null) return 'Now';
  return DateFormat('hh:mm a').format(value.toLocal());
}
