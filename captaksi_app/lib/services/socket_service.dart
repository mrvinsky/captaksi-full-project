import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart'; // Token almak için

class SocketService {
  IO.Socket? _socket;

  // Yolculuk bitti sinyalini 'HomeScreen'e iletmek için bir Stream
  final StreamController<Map<String, dynamic>> _rideFinishedController =
      StreamController.broadcast();
  
  Stream<Map<String, dynamic>> get rideFinishedStream => _rideFinishedController.stream;

  Future<void> connectAndListen() async {
    final token = await ApiService.getToken();
    if (token == null) {
      print("Socket (Yolcu) bağlantısı için token bulunamadı.");
      return;
    }

    // Backend sunucumuzun adresi (Emülatör için)
    const String socketUrl = 'http://10.0.2.2:3000';

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket sunucusuna (Yolcu) bağlandı: ${_socket!.id}');
      // Sunucuya kim olduğumuzu (token) söylüyoruz ve YOLCU odamıza katılıyoruz
      _socket!.emit('join_user_room', token);
    });

    // Sunucudan 'ride_finished' sinyalini dinle
    _socket!.on('ride_finished', (data) {
      print('SocketService (Yolcu): Yolculuk bittii sinyali alındı!');
      _rideFinishedController.add(data as Map<String, dynamic>);
    });

    _socket!.onDisconnect((_) => print('Socket (Yolcu) bağlantısı kesildi.'));
    _socket!.onError((data) => print('Socket (Yolcu) Hatası: $data'));
  }

  void dispose() {
    _socket?.disconnect();
    _rideFinishedController.close();
  }
}