import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  Map<String, dynamic>? driver; // profil datası
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService().getDriverProfile();

      setState(() {
        driver = data["driver"] ?? data; // backend bazen {driver:{}} bazen {} döndürüyor
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil yüklenemedi: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Profil Bilgilerim"),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // ⭐ PUAN DEĞERİNİ ALALIM (boş gelirse 5.0 yapıyorum)
    final double rating =
        double.tryParse(driver?["puan"]?.toString() ?? "5.0") ?? 5.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Profil Bilgilerim"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---------------------------------------------------------
            // PROFIL FOTO
            // ---------------------------------------------------------
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: (driver?["profileImage"] != null &&
                        driver!["profileImage"].toString().isNotEmpty)
                    ? NetworkImage(driver!["profileImage"])
                    : null,
                child: (driver?["profileImage"] == null ||
                        driver!["profileImage"].toString().isEmpty)
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
            ),

            const SizedBox(height: 30),

            // ---------------------------------------------------------
            // PUAN ALANI ⭐
            // ---------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Text(
                    "Sürücü Puanı",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        size: 32,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${rating.toStringAsFixed(1)} / 5.0",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),

            // ---------------------------------------------------------
            // PROFIL BILGI KARTI
            // ---------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _infoRow("Ad", driver?["ad"] ?? "-"),
                  _infoRow("Soyad", driver?["soyad"] ?? "-"),
                  _infoRow("E-mail", driver?["email"] ?? "-"),
                  _infoRow("Telefon", driver?["telefon_numarasi"] ?? "-"),
                  _infoRow(
                    "Durum",
                    (driver?["aktif_mi"] == true) ? "Aktif" : "Pasif",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ---------------------------------------------------------
            // DUZENLE BUTONU
            // ---------------------------------------------------------
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 55),
              ),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Bilgileri Düzenle",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Düzenleme ekranı yakında eklenecek."),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // INFO ROW WIDGET
  // ---------------------------------------------------------
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
