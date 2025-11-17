import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Cüzdanım",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ------------------- BAKIYE KARTI -------------------
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E2E2E), Color(0xFF1C1C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: const [
                  Text(
                    "Mevcut Bakiye",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "₺0.00",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // ------------------- İŞLEMLER -------------------
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Para ekleme özelliği yakında eklenecek."),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(0, 55),
                    ),
                    child: const Text("Para Ekle",
                        style: TextStyle(color: Colors.white, fontSize: 17)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Para çekme özelliği yakında eklenecek."),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(0, 55),
                    ),
                    child: const Text("Para Çek",
                        style: TextStyle(color: Colors.white, fontSize: 17)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Son İşlemler",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 15),

            _transaction("Yolculuk kazancı", "+₺245", true),
            _transaction("Yolculuk kazancı", "+₺120", true),
            _transaction("Cüzdan bakiyesi kullanımı", "₺-50", false),
            _transaction("Yolculuk kazancı", "+₺88", true),
          ],
        ),
      ),
    );
  }

  Widget _transaction(String title, String amount, bool positive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(
            amount,
            style: TextStyle(
              color: positive ? Colors.greenAccent : Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
