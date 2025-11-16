import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Profil Bilgilerim"),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          "Bu ekranda: Ad / Soyad / Email / Fotoğraf düzenleme olacak.",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
