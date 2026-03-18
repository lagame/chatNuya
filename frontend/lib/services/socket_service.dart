import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:chat_app/models/message.dart';
import 'package:chat_app/config/app_config.dart';
import 'package:chat_app/services/storage_service.dart';

class SocketService {
  static const String socketUrl = AppConfig.socketUrl;
  late IO.Socket socket;
  int? currentUserId;

  // Callbacks
  Function(List<int>)? onOnlineUsersChanged;
  Function(Message)? onMessageReceived;
  Function(int)? onUserTyping;
  Function(int)? onUserStopTyping;

  SocketService() {
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(45000)
          .disableAutoConnect()
          .build(),
    );

    socket.on('connect', (_) {
      print('Socket connected');
      if (currentUserId != null) {
        socket.emit('user_join', currentUserId);
      }
    });

    socket.on('reconnect', (_) {
      print('Socket reconnected');
      if (currentUserId != null) {
        socket.emit('user_join', currentUserId);
      }
    });

    socket.on('online_users', (data) {
      print('Online users: $data');
      if (onOnlineUsersChanged != null) {
        onOnlineUsersChanged!(List<int>.from(data ?? []));
      }
    });

    socket.on('receive_message', (data) {
      print('Message received: $data');
      if (onMessageReceived != null) {
        onMessageReceived!(Message.fromJson(data));
      }
    });

    socket.on('message_sent', (data) {
      print('Message sent: $data');
      if (onMessageReceived != null) {
        onMessageReceived!(Message.fromJson(data));
      }
    });

    socket.on('user_typing', (data) {
      if (onUserTyping != null) {
        onUserTyping!(data['senderId'] as int);
      }
    });

    socket.on('user_stop_typing', (data) {
      if (onUserStopTyping != null) {
        onUserStopTyping!(data['senderId'] as int);
      }
    });

    socket.on('disconnect', (_) {
      print('Socket disconnected');
    });

    socket.on('error', (error) {
      print('Socket error: $error');
    });
  }

  Future<void> connect() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      print('Socket connect skipped: missing auth token');
      return;
    }

    final options = socket.io.options ?? <String, dynamic>{};
    options['auth'] = {'token': token};
    options['extraHeaders'] = {'Authorization': 'Bearer $token'};
    socket.io.options = options;

    if (!socket.connected) {
      socket.connect();
    }
  }

  void disconnect() {
    if (socket.connected) {
      socket.disconnect();
    }
  }

  void joinUser(int userId) {
    currentUserId = userId;
    socket.emit('user_join', userId);
  }

  void sendMessage({
    required int senderId,
    required int receiverId,
    required String content,
  }) {
    socket.emit('send_message', {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
    });
  }

  void getMessages({
    required int userId1,
    required int userId2,
    required Function(List<Message>) callback,
  }) {
    socket.emitWithAck('get_messages', {
      'userId1': userId1,
      'userId2': userId2,
    }, ack: (data) {
      final messages =
          (data as List).map((msg) => Message.fromJson(msg)).toList();
      callback(messages);
    });
  }

  void notifyTyping({
    required int senderId,
    required int receiverId,
  }) {
    socket.emit('typing', {
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }

  void notifyStopTyping({
    required int senderId,
    required int receiverId,
  }) {
    socket.emit('stop_typing', {
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }
}
