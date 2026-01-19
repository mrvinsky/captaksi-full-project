import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. İzin İste
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Kullanıcı bildirim izni verdi.');
    } else {
      debugPrint('Kullanıcı bildirim iznini reddetti.');
    }

    // 2. Token'i al ve logla (Daha sonra login/register'da backend'e gidecek)
    String? token = await _firebaseMessaging.getToken();
    debugPrint("FCM Token: $token");

    // 3. Foreground Mesajları Dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Ön Planda Bildirim Geldi!');
      debugPrint('Başlık: ${message.notification?.title}');
      debugPrint('İçerik: ${message.notification?.body}');
      
      // Burada yerel bildirim (Local Notification) gösterilebilir.
      // Şimdilik sadece print ediyoruz.
    });
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
