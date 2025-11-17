import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final ApiService api = ApiService();

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController oldPassCtrl = TextEditingController();
  final TextEditingController newPassCtrl = TextEditingController();

  bool saving = false;

  Future<void> saveChanges() async {
    if (saving) return;

    setState(() => saving = true);

    try {
      await api.updateDriverInfo(
        email: emailCtrl.text,
        telefonNumarasi: phoneCtrl.text,
        oldPassword: oldPassCtrl.text,
        newPassword: newPassCtrl.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bilgiler başarıyla güncellendi."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget buildInput(String label, TextEditingController ctrl,
      {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: isPass,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Güvenlik Ayarları"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hesap Bilgileri",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            buildInput("E-posta", emailCtrl),
            buildInput("Telefon Numarası", phoneCtrl),

            const SizedBox(height: 10),
            const Text(
              "Şifre Değiştir",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            buildInput("Mevcut Şifre", oldPassCtrl, isPass: true),
            buildInput("Yeni Şifre", newPassCtrl, isPass: true),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "DEĞİŞİKLİKLERİ KAYDET",
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 35),

            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "Hesabı Kalıcı Olarak Sil",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
