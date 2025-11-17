import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_details_screen.dart';
import 'vehicle_screen.dart';
import 'earnings_screen.dart';
import 'security_screen.dart';
import 'help_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? profileData;
  Map<String, dynamic>? statsData;
  bool loading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    loadData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      profileData = await ApiService().getDriverProfile();
      statsData = await ApiService().getDriverStats();
    } catch (e) {
      debugPrint("Hata: $e");
    }

    setState(() => loading = false);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final double rating =
        double.tryParse(profileData?["puan"]?.toString() ?? "5") ?? 5.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Sürücü Profiliniz",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ----------------- PROFIL KARTI -----------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // PROFİL FOTO
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: profileData?['profileImage'] != null
                          ? NetworkImage(profileData!['profileImage'])
                          : null,
                      child: profileData?['profileImage'] == null
                          ? const Icon(Icons.person,
                              size: 45, color: Colors.white)
                          : null,
                    ),

                    const SizedBox(width: 20),

                    // AD, SOYAD, EMAIL
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${profileData?['ad']} ${profileData?['soyad']}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profileData?['email'] ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Aktif etiket
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Aktif Sürücü",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ⭐ PUAN KISMI ⭐
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 26,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${rating.toStringAsFixed(1)} / 5.0",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ----------------- ISTATISTIKLER -----------------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sürüş İstatistikleri",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: statCard(
                      "TAMAMLANAN SÜRÜŞ",
                      statsData?["rides"] ?? 0,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: statCard(
                      "TOPLAM KM",
                      statsData?["distance"] ?? 0,
                      Icons.alt_route_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: statCard(
                      "TOPLAM GELİR",
                      "${statsData?['earnings'] ?? 0} RSD",
                      Icons.monetization_on_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // ----------------- MENÜ -----------------
              settingsTile(Icons.person, "Profil Bilgilerim", () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileDetailsScreen()));
              }),

              settingsTile(Icons.car_rental, "Araç Bilgilerim", () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VehicleScreen()));
              }),

              settingsTile(Icons.receipt_long, "Kazanç Geçmişi", () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EarningsScreen()));
              }),
              settingsTile(Icons.account_balance_wallet, "Cüzdanım", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              }),

              settingsTile(Icons.security, "Güvenlik Ayarları", () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SecurityScreen()));
              }),

              settingsTile(Icons.help_outline, "Yardım ve Destek", () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()));
              }),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  ApiService.deleteToken();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  "Çıkış Yap",
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------- STAT CARD -----------------
  Widget statCard(String title, dynamic value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 10),
          Text(
            "$value",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ----------------- SETTINGS TILE -----------------
  Widget settingsTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }
}
