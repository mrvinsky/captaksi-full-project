import 'package:flutter/material.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Araç Bilgilerim"),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          "Bu ekranda: Araç tipi, model, plaka bilgileri gösterilecek.",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
