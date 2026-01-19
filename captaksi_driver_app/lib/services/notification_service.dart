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
      debugPrint('Sürücü bildirim izni verdi.');
    } else {
      debugPrint('Sürücü bildirim iznini reddetti.');
    }

    // 2. Token'i al
    String? token = await _firebaseMessaging.getToken();
    debugPrint("Driver FCM Token: $token");

    // 3. Foreground Mesajları Dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Sürücüye Ön Planda Bildirim Geldi!');
      debugPrint('Başlık: ${message.notification?.title}');
      debugPrint('İçerik: ${message.notification?.body}');
    });
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
