import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // Uygulamayı başlatacak olan Splash Ekranı

void main() {
  runApp(const CaptaksiDriverApp());
}

class CaptaksiDriverApp extends StatelessWidget {
  const CaptaksiDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Captaksi Sürücü',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Ana temayı, yolcu uygulamasından (sarı) ayırmak için mavi yapalım
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), 
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // Genel arka plan rengi
      ),
      // Uygulamayı Splash Screen'den başlatıyoruz
      home: const SplashScreen(), 
    );
  }
}

