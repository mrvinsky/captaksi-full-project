import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Kazanç Geçmişi"),
      ),
      body: const Center(
        child: Text(
          "Burada günlük / haftalık / aylık kazanç raporları olacak.",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
