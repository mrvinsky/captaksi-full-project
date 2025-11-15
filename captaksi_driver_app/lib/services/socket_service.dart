import 'dart:async'; // StreamController için bu gerekli (HATA DÜZELTİLDİ)
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart'; // Token almak için ApiService'i kullanacağız

class SocketService {
  IO.Socket? _socket;

  // Gelen yolculuk taleplerini 'HomeScreen'e iletmek için bir Stream (yayın kanalı) oluşturuyoruz.
  final StreamController<Map<String, dynamic>> _rideRequestController =
      StreamController.broadcast();
  
  // HomeScreen bu stream'i dinleyecek
  Stream<Map<String, dynamic>> get rideRequests => _rideRequestController.stream;

  Future<void> connectAndListen() async {
    // Önce Sürücünün token'ını güvenli hafızadan al
    final token = await ApiService.getToken();
    if (token == null) {
      print("Socket bağlantısı için token bulunamadı.");
      return;
    }

    // Sunucu adresimiz
    const String socketUrl = 'http://10.0.2.2:3000';

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // Bağlantıyı manuel olarak başlat
    _socket!.connect();

    // Bağlantı başarılı olduğunda...
    _socket!.onConnect((_) {
      print('Socket sunucusuna bağlandı: ${_socket!.id}');
      // Sunucuya kim olduğumuzu (token) söylüyoruz ve doğru odaya katılmasını istiyoruz
      _socket!.emit('join_driver_room', token);
    });

    // Sunucudan 'new_ride_request' sinyalini dinle
    _socket!.on('new_ride_request', (data) {
      print('Yeni yolculuk talebi alındı!');
      // Gelen veriyi (yolculuk detayları) stream'e ekle
      _rideRequestController.add(data as Map<String, dynamic>);
    });

    _socket!.onDisconnect((_) => print('Socket bağlantısı kesildi.'));
    _socket!.onError((data) => print('Socket Hatası: $data'));
  }

  // Sürücü çevrimdışı olduğunda veya çıkış yaptığında bağlantıyı kapat
  void dispose() {
    _socket?.disconnect();
    _rideRequestController.close();
  }
}

