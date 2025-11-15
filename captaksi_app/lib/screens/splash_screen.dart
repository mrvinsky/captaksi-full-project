import 'package:captaksi_app/screens/home_screen.dart';
import 'package:captaksi_app/screens/login_screen.dart';
import 'package:captaksi_app/services/api_service.dart';
import 'package:flutter/material.dart';

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
    // Biraz bekleyelim ki splash ekranı görünsün
    await Future.delayed(const Duration(seconds: 2));

    final token = await ApiService.getToken();
    if (token != null) {
      // Token varsa anasayfaya git
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      // Token yoksa login ekranına git
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}