import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final double rating = double.tryParse(profileData?["puan"]?.toString() ?? "5.0") ?? 5.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Kaptan Profili",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E2C), Color(0xFF13131D)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
            child: Column(
              children: [
                // ----------------- PROFIL KARTI -----------------
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                       Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white10,
                          child: const Icon(Icons.person, size: 45, color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "${profileData?['ad']} ${profileData?['soyad']}",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(profileData?['email'] ?? "", style: const TextStyle(color: Colors.white38, fontSize: 14)),
                      const SizedBox(height: 15),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Text("Aktif Kaptan", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                Text("${rating.toStringAsFixed(1)}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ----------------- ISTATISTIKLER -----------------
                Row(
                  children: [
                    Expanded(child: statCard("SÜRÜŞ", statsData?["rides"] ?? 0, Icons.directions_car_rounded)),
                    const SizedBox(width: 15),
                    Expanded(child: statCard("KM", statsData?["distance"] ?? 0, Icons.speed_rounded)),
                  ],
                ),
                const SizedBox(height: 15),
                statCard("TOPLAM KAZANÇ", "₺${statsData?['earnings'] ?? 0}", Icons.account_balance_wallet_rounded, isFullWidth: true),

                const SizedBox(height: 35),

                // ----------------- MENÜ -----------------
                _buildMenuSection([
                  _menuItem(Icons.person_outline_rounded, "Profil Bilgilerim", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()))),
                  _menuItem(Icons.drive_eta_outlined, "Araç Bilgilerim", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleScreen()))),
                  _menuItem(Icons.history_rounded, "Kazanç Geçmişi", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()))),
                  _menuItem(Icons.security_rounded, "Güvenlik Ayarları", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()))),
                  _menuItem(Icons.help_outline_rounded, "Yardım ve Destek", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
                ]),

                const SizedBox(height: 30),

                // Çıkış Butonu
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      ApiService.deleteToken();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: const Text("OTURUMU KAPAT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                      backgroundColor: Colors.redAccent.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget statCard(String title, dynamic value, IconData icon, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.amber, size: 24),
              if (isFullWidth) const SizedBox(width: 15),
              if (isFullWidth) Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          if (!isFullWidth) const SizedBox(height: 10),
          if (!isFullWidth) Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(
            "$value",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: Colors.white38, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
    );
  }
}
