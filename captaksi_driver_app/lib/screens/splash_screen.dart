import 'package:flutter/material.dart';
import 'package:captaksi_driver_app/services/api_service.dart';
import 'login_screen.dart';
import 'driver_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Hafızadaki token'ı kontrol et
    final token = await ApiService.getToken();

    // 2 saniye bekle (splash ekranı görünsün diye)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return; // Eğer widget kapandıysa işlem yapma

    if (token != null) {
      // Token varsa Ana Sayfaya yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
      );
    } else {
      // Token yoksa Login Ekranına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Temayla uyumlu basit bir yükleme ekranı
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.drive_eta, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

