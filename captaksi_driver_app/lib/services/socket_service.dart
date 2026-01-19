import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'api_service.dart';

/// Sürücü uygulaması için Socket.IO servisi.
/// - JWT token ile bağlanır.
/// - `new_ride_request` event'lerini dinler.
/// - Dışarıya Stream üzerinden bildirir.
class SocketService {
  SocketService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  IO.Socket? _socket;
  final StreamController<Map<String, dynamic>> _rideRequestController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Yeni yolculuk taleplerini dışarıya ileten stream.
  Stream<Map<String, dynamic>> get rideRequests =>
      _rideRequestController.stream;
  
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Gelen chat mesajlarını dinlemek için stream.
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected => _socket != null && _socket!.connected;

  /// Socket bağlantısı kur ve event'leri dinlemeye başla.
  Future<void> connectAndListen() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('Socket bağlantısı için token bulunamadı.');
      return;
    }

    // Platforma göre dinamik URL
    String socketUrl = 'http://localhost:3000';
    if (!kIsWeb && Platform.isAndroid) {
      socketUrl = 'http://10.0.2.2:3000';
    }

    if (_socket != null && _socket!.connected) {
      debugPrint('Socket zaten bağlı.');
      return;
    }

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders(<String, dynamic>{
            'x-auth-token': token,
          })
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('Socket connected: ${_socket!.id}');
      // Sürücü odasına katılma (backend implementasyonuna göre değişebilir)
      _socket!.emit('join_driver', <String, dynamic>{
        'token': token,
      });
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    _socket!.onError((data) {
      debugPrint('Socket error: $data');
    });

    _socket!.on('new_ride_request', (dynamic data) {
      try {
        if (data is Map<String, dynamic>) {
          _rideRequestController.add(data);
        } else if (data is Map) {
          _rideRequestController.add(
            Map<String, dynamic>.from(data as Map),
          );
        } else {
          debugPrint(
            'new_ride_request data tipi beklenmedik: ${data.runtimeType}',
          );
        }
      } catch (e) {
        debugPrint('new_ride_request parse edilemedi: $e');
      }
    });

    _socket!.on('receive_message', (dynamic data) {
      debugPrint('Yeni mesaj geldi: $data');
      if (data is Map<String, dynamic>) {
         _messageController.add(data);
      } else if (data is Map) {
         _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  /// Sunucuya manuel event göndermek gerektiğinde kullanılabilir.
  void emit(String event, dynamic data) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit(event, data);
  }

  /// Mesaj gönderme fonksiyonu.
  /// [receiverId]: Mesajın gönderileceği kişinin ID'si (integer olmalı).
  /// [message]: Gönderilecek metin.
  void sendMessage({required int receiverId, required String message}) {
    if (_socket == null || !_socket!.connected) return;

    // Backend: socket.on('send_message', (data) => ...)
    // data: { receiverId, receiverType, message }
    _socket!.emit('send_message', <String, dynamic>{
      'receiverId': receiverId,
      'receiverType': 'user', // Sürücü -> Yolcuya atıyor
      'message': message,
    });
  }

  void _clearSocketListeners() {
    if (_socket == null) return;
    _socket!
      ..off('new_ride_request')
      ..off('connect')
      ..off('disconnect')
      ..off('error')
      ..off('receive_message');
  }

  void disconnect() {
    _clearSocketListeners();
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _rideRequestController.close();
    _messageController.close();
    _apiService.dispose();
  }
}
