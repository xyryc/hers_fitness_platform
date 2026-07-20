import 'dart:async';

import 'package:fitness/core/storage/token_storage.dart';
import 'package:fitness/utils/AppConstants/app_constant.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketService {
  ChatSocketService({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;
  io.Socket? _socket;

  // Completer that resolves when the socket's onConnect fires.
  // Prevents _joinConversation from being emitted before the handshake
  // has completed (the root cause of real-time messages not arriving).
  Completer<void>? _connectCompleter;

  // Callback invoked by the controller so it can re-emit chat:join after
  // an automatic reconnect.
  VoidCallback? onReconnected;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _seenController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _disconnectController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get typing => _typingController.stream;
  Stream<Map<String, dynamic>> get seen => _seenController.stream;
  Stream<Map<String, dynamic>> get status => _statusController.stream;
  Stream<Map<String, dynamic>> get userDisconnected =>
      _disconnectController.stream;

  bool get isConnected => _socket?.connected == true;

  /// Connects the socket and waits until the connection is truly established
  /// (the onConnect event fires) before returning.
  ///
  /// Previously this method called [socket.connect()] and returned immediately,
  /// causing [join()] to be called while the socket was still mid-handshake.
  /// [_emit] checks [socket.connected], which is still false at that point, so
  /// the join event was silently dropped and the server never added the client
  /// to the room — breaking real-time message delivery.
  Future<void> connect() async {
    if (isConnected) return;

    // If a connection attempt is already in-flight, wait for it instead of
    // creating a second socket.
    if (_connectCompleter != null) {
      return _connectCompleter!.future;
    }

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    final socketUrl = _socketUrl;
    if (socketUrl.isEmpty) return;

    _connectCompleter = Completer<void>();

    final socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('Chat socket connected');
      // Complete the in-flight connect() call so callers can proceed to join.
      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        _connectCompleter!.complete();
      }
      _connectCompleter = null;
      // If the socket reconnected automatically (after a drop), notify the
      // controller so it can re-emit chat:join for the active conversation.
      onReconnected?.call();
    });

    socket.onDisconnect((_) => debugPrint('Chat socket disconnected'));

    socket.onConnectError((error) {
      debugPrint('Chat socket connect error: $error');
      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        // Complete with null (not an error) so the caller doesn't crash; the
        // subsequent _emit guard will handle the not-connected state gracefully.
        _connectCompleter!.complete();
      }
      _connectCompleter = null;
    });

    socket.onError((error) => debugPrint('Chat socket error: $error'));

    socket.on('chat:message', (payload) {
      final map = _payloadMap(payload);
      if (map != null) _messageController.add(map);
    });
    socket.on('chat:typing', (payload) {
      final map = _payloadMap(payload);
      if (map != null) _typingController.add(map);
    });
    socket.on('chat:seen', (payload) {
      final map = _payloadMap(payload);
      if (map != null) _seenController.add(map);
    });
    socket.on('chat:status', (payload) {
      final map = _payloadMap(payload);
      if (map != null) _statusController.add(map);
    });
    socket.on('chat:userDisconnected', (payload) {
      final map = _payloadMap(payload);
      if (map != null) _disconnectController.add(map);
    });

    _socket = socket;
    socket.connect();

    // Wait for the handshake to complete (or fail) before returning, so that
    // callers can safely emit events immediately after awaiting connect().
    try {
      await _connectCompleter!.future.timeout(const Duration(seconds: 10));
    } catch (_) {
      // Timeout or error: proceed anyway; _emit will no-op if not connected.
      _connectCompleter = null;
    }
  }

  void join(String conversationId) {
    if (conversationId.isEmpty) return;
    _emit('chat:join', {'conversationId': conversationId});
  }

  void leave(String conversationId) {
    if (conversationId.isEmpty) return;
    _emit('chat:leave', {'conversationId': conversationId});
  }

  bool sendText({required String conversationId, required String text}) {
    return _emit('chat:sendMessage', {
      'conversationId': conversationId,
      'messageType': 'TEXT',
      'text': text,
    });
  }

  bool sendImage({
    required String conversationId,
    required String attachmentUrl,
    required String attachmentType,
  }) {
    return _emit('chat:sendMessage', {
      'conversationId': conversationId,
      'messageType': 'IMAGE',
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
    });
  }

  bool emitTyping({required String conversationId, required bool isTyping}) {
    return _emit('chat:typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  bool emitSeen(String conversationId) {
    if (conversationId.isEmpty) return false;
    return _emit('chat:seen', {'conversationId': conversationId});
  }

  bool _emit(String event, Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null || socket.connected != true) return false;
    socket.emit(event, payload);
    return true;
  }

  void disconnect() {
    _connectCompleter = null;
    _socket?.dispose();
    _socket = null;
  }

  Future<void> dispose() async {
    disconnect();
    await _messageController.close();
    await _typingController.close();
    await _seenController.close();
    await _statusController.close();
    await _disconnectController.close();
  }

  String get _socketUrl {
    final base = AppConstants.BASE_URL.trim();
    if (base.isEmpty) return '';

    var normalized = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    if (normalized.endsWith('/api')) {
      normalized = normalized.substring(0, normalized.length - 4);
    }
    return '$normalized/chat';
  }

  Map<String, dynamic>? _payloadMap(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
