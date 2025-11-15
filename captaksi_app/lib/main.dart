import 'package:captaksi_app/screens/splash_screen.dart'; // Değişti
import 'package:flutter/material.dart';

void main() {
  runApp(const CaptaksiApp());
}

class CaptaksiApp extends StatelessWidget {
  const CaptaksiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Captaksi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      // Uygulamanın ana ekranı olarak SplashScreen'i ayarladık
      home: const SplashScreen(), // Değişti
    );
  }
}