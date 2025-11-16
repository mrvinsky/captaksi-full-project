import 'package:flutter/material.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Güvenlik Ayarları"),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          "Bu ekranda şifre değiştirme, 2FA vb. olacak.",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
