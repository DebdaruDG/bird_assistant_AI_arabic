import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String url;
  WebSocketChannel? _channel;
  Timer? _keepAliveTimer;
  bool _isConnected = false;
  final _messageController = StreamController<dynamic>.broadcast();
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _keepAliveInterval = Duration(minutes: 15);

  WebSocketService({required this.url});

  /// Stream to listen to incoming WebSocket messages
  Stream<dynamic> get messages => _messageController.stream;

  /// Check if WebSocket is connected
  bool get isConnected => _isConnected;

  /// Connect to the WebSocket
  Future<void> connect() async {
    if (_isConnected) {
      developer.log('WebSocket already connected to $url');
      return;
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      _reconnectAttempts = 0;
      developer.log('WebSocket connected to $url');

      // Set up keep-alive pings
      _startKeepAlive();

      // Listen to incoming messages
      _channel!.stream.listen(
        (message) {
          developer.log('Received message: $message');
          try {
            // Attempt to parse JSON, but pass raw message if not JSON
            final decoded = jsonDecode(message);
            _messageController.add(decoded);
          } catch (e) {
            _messageController.add(message);
          }
        },
        onError: (error) {
          developer.log('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          developer.log(
            'WebSocket closed with code: ${_channel?.closeCode}, reason: ${_channel?.closeReason}',
          );
          _handleDisconnect();
        },
      );
    } catch (e) {
      developer.log('WebSocket connection error: $e');
      _handleDisconnect();
    }
  }

  /// Send a message to the WebSocket
  Future<void> sendMessage(dynamic message) async {
    try {
      await _ensureConnection();
      final messageJson = message is String ? message : jsonEncode(message);
      _channel!.sink.add(messageJson);
      developer.log('Sent message: $messageJson');
    } catch (e) {
      developer.log('Error sending message: $e');
      rethrow;
    }
  }

  /// Start listening to WebSocket events in UI logic
  StreamSubscription<dynamic> listenToEvents(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    return messages.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: false,
    );
  }

  /// Ensure WebSocket is connected before sending messages
  Future<void> _ensureConnection() async {
    if (!_isConnected) {
      await connect();
      if (!_isConnected) {
        throw Exception('Failed to establish WebSocket connection to $url');
      }
    }
  }

  /// Start sending keep-alive pings
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(_keepAliveInterval, (timer) {
      if (_isConnected) {
        sendMessage({"action": "ping"}).catchError((e) {
          developer.log('Error sending ping: $e');
        });
      }
    });
  }

  /// Handle disconnection and attempt reconnection
  void _handleDisconnect() {
    _isConnected = false;
    _keepAliveTimer?.cancel();
    _messageController.addError('WebSocket disconnected');
    _channel?.sink.close();
    _channel = null;

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      developer.log(
        'Attempting to reconnect ($_reconnectAttempts/$_maxReconnectAttempts)...',
      );
      Future.delayed(_reconnectDelay, () {
        if (!_isConnected) {
          connect();
        }
      });
    } else {
      developer.log('Max reconnect attempts reached. Giving up.');
      _messageController.addError('Max reconnect attempts reached');
    }
  }

  /// Close the WebSocket connection
  void close() {
    _keepAliveTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _reconnectAttempts = 0;
    _messageController.close();
    developer.log('WebSocket closed for $url');
  }

  /// Dispose of resources
  void dispose() {
    close();
  }
}
