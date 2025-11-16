import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Yardım ve Destek"),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          "Burada müşteri hizmetleri, sık sorulan sorular vb. olacak.",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
