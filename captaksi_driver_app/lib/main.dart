import 'package:flutter/material.dart';

// EKRANLAR
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/profile_screen.dart';

// AYRINTILI EKRANLAR (yeni eklediklerimiz)
import 'screens/profile_details_screen.dart';
import 'screens/vehicle_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/security_screen.dart';
import 'screens/help_screen.dart';

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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      // BAŞLANGIÇ EKRANI → Splash
      home: const SplashScreen(),

      // TÜM ROUTELAR
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const DriverHomeScreen(),
        '/profile': (context) => const ProfileScreen(),

        // PROFIL ALT SAYFALARI
        '/profile-details': (context) => const ProfileDetailsScreen(),
        '/vehicle': (context) => const VehicleScreen(),
        '/earnings': (context) => const EarningsScreen(),
        '/security': (context) => const SecurityScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  }
}
