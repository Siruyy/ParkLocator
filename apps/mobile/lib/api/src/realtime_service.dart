import 'dart:async';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as io;

class RealtimeService {
  RealtimeService({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://localhost:3000';

  final String _baseUrl;
  io.Socket? _socket;
  final _levelUpdatesController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get levelUpdates => _levelUpdatesController.stream;

  void connect() {
    _socket = io.io(_baseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket?.connect();

    _socket?.onConnect((_) {
      print('Connected to WebSocket');
    });

    _socket?.onDisconnect((_) {
      print('Disconnected from WebSocket');
    });
  }

  void subscribeToLevel(String levelId) {
    _socket?.on('level:$levelId', (data) {
      if (data is Map<String, dynamic>) {
        _levelUpdatesController.add({'levelId': levelId, ...data});
      }
    });
  }

  void unsubscribeFromLevel(String levelId) {
    _socket?.off('level:$levelId');
  }

  void dispose() {
    _socket?.dispose();
    _levelUpdatesController.close();
  }
}
