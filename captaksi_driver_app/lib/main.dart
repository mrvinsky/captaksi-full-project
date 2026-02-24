import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF13131D), // Deep Navy
        primaryColor: Colors.amber,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          onPrimary: Colors.black,
          secondary: Color(0xFF1E1E2C),
          onSecondary: Colors.white,
          surface: Color(0xFF1E1E2C),
          onSurface: Colors.white,
          error: Color(0xFFFF5252),
          outline: Colors.white12,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
          titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E2C),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.all(color: Colors.white.withOpacity(0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.amber, width: 1.5)),
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIconColor: Colors.amber.withOpacity(0.7),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            elevation: 8,
            shadowColor: Colors.amber.withOpacity(0.3),
            textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 18),
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
