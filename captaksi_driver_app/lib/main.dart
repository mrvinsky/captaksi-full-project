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

import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint("Firebase başlatma hatası: $e");
  }
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
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900 (Deep Blue)
        primaryColor: const Color(0xFF38BDF8), // Sky 400 (Cyan/Blue)
        cardColor: const Color(0xFF1E293B), // Slate 800
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
          primary: const Color(0xFF38BDF8),
          secondary: const Color(0xFF0EA5E9),
          surface: const Color(0xFF1E293B),
          background: const Color(0xFF0F172A),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Modern font if available, or default
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38BDF8),
            foregroundColor: Colors.black, // Text color on button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
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
