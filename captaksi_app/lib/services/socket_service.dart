import 'dart:async';
import 'dart:io'; // [YENİ]
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart'; // Token almak için

class SocketService {
  IO.Socket? _socket;

  // Yolculuk bitti sinyalini 'HomeScreen'e iletmek için bir Stream
  final StreamController<Map<String, dynamic>> _rideFinishedController =
      StreamController.broadcast();
  
  Stream<Map<String, dynamic>> get rideFinishedStream => _rideFinishedController.stream;
  
  // Sürücü Kabul Etti Stream'i
  final StreamController<Map<String, dynamic>> _rideAcceptedController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get rideAcceptedStream => _rideAcceptedController.stream;

  // Sürücü Kapıda Stream'i
  final StreamController<Map<String, dynamic>> _driverArrivedController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get driverArrivedStream => _driverArrivedController.stream;

  // Yolculuk Başladı Stream'i
  final StreamController<Map<String, dynamic>> _rideStartedController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get rideStartedStream => _rideStartedController.stream;

  // Yolculuk İptal Stream'i
  final StreamController<Map<String, dynamic>> _rideCancelledController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get rideCancelledStream => _rideCancelledController.stream;

  // Mesaj Stream'i
  
  // Mesaj Stream'i
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<void> connectAndListen() async {
    final token = await ApiService.getToken();
    if (token == null) {
      print("Socket (Yolcu) bağlantısı için token bulunamadı.");
      return;
    }

    // Backend sunucumuzun adresi
    // Fiziksel Cihaz / LAN Testi için IP:
    String socketUrl = 'http://10.0.2.2:3000';

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

    // Sürücü kabul etti sinyalini dinle
    _socket!.on('ride_accepted', (data) {
      print('SocketService (Yolcu): Sürücü kabul etti -> $data');
      if (data is Map<String, dynamic>) {
        _rideAcceptedController.add(data);
      } else if (data is Map) {
         _rideAcceptedController.add(Map<String, dynamic>.from(data));
      }
    });

    // Sürücü Kapıda Sinyali
    _socket!.on('driver_arrived', (data) {
       print('SocketService (Yolcu): Sürücü Kapıda -> $data');
       _driverArrivedController.add(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    // Yolculuk Başladı Sinyali
    _socket!.on('ride_started', (data) {
       print('SocketService (Yolcu): Yolculuk Başladı -> $data');
       _rideStartedController.add(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    // İptal Sinyali
    _socket!.on('ride_cancelled', (data) {
       print('SocketService (Yolcu): Yolculuk İptal Edildi -> $data');
       // Burada özel bir stream kullanabiliriz veya direkt home_screen içinde dinleyebiliriz.
       // Pratiklik adına rideFinishedController'ı "hata" gibi tetikleyebiliriz ya da yeni bir stream.
       // En temizi yeni stream.
       _rideCancelledController.add(data is Map ? Map<String, dynamic>.from(data) : {});
    });

    // Mesaj dinle

    // Mesaj dinle
    _socket!.on('receive_message', (data) {
      print('SocketService (Yolcu): Yeni mesaj -> $data');
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      } else if (data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onDisconnect((_) => print('Socket (Yolcu) bağlantısı kesildi.'));
    _socket!.onError((data) => print('Socket (Yolcu) Hatası: $data'));
  }

  void sendMessage({required int receiverId, required String message}) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit('send_message', <String, dynamic>{
      'receiverId': receiverId,
      'receiverType': 'driver', // Yolcu -> Sürücüye atıyor
      'message': message,
    });
  }

  void dispose() {
    _socket?.disconnect();
    _rideFinishedController.close();
    _rideAcceptedController.close();
    _driverArrivedController.close();
    _rideStartedController.close();
    _rideCancelledController.close();
    _messageController.close();
  }
}