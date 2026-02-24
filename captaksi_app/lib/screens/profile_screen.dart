import 'package:flutter/material.dart';
import 'package:captaksi_app/models/user_model.dart';
import 'package:captaksi_app/models/ride_model.dart';
import 'package:captaksi_app/services/api_service.dart';
import 'rating_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadProfileData();
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    final user = await _apiService.getUserProfile();
    final rides = await _apiService.getRideHistory();
    return {'user': user, 'rides': rides};
  }

  void _navigateToRating(Ride ride) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatingScreen(
          finishedRide: {
            "id": ride.id,
            "bitis_adres_metni": ride.bitisAdresMetni ?? 'Bilinmeyen Hedef',
            "gerceklesen_ucret": ride.gerceklesenUcret ?? '0.00'
          },
        ),
      ),
    );

    setState(() {
      _dataFuture = _loadProfileData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Profilim", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E2C), Color(0xFF13131D)],
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            } else if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Veri bulunamadı.', style: TextStyle(color: Colors.white70)));
            }

            final User user = snapshot.data!['user'];
            final List<Ride> rides = snapshot.data!['rides'];
            final stats = user.stats;

            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _dataFuture = _loadProfileData());
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
                children: [
                  // --- PROFİL KARTI ---
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
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.person, size: 45, color: Colors.amber),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '${user.ad} ${user.soyad}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Text(user.email, style: const TextStyle(color: Colors.white38, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text(user.telefonNumarasi, style: const TextStyle(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- İSTATİSTİKLER ---
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('🏡', 'Yolculuk', '${stats['total_rides']}')),
                      const SizedBox(width: 15),
                      Expanded(child: _buildStatCard('🔥', 'Harcanan', '₺${stats['total_spent']}')),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildStatCard('🚩', 'Toplam Mesafe', '${stats['total_distance_km']} km', isFullWidth: true),

                  const SizedBox(height: 35),
                  const Text(
                    'Son Yolculuklarım',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                    rides.isEmpty
                        ? _emptyRides()
                        : Column(
                            children: rides.take(5).map((ride) => _buildRideTile(ride)).toList(),
                          ),

                    const SizedBox(height: 40),

                    // --- ÇIKIŞ BUTONU ---
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          await ApiService.deleteToken();
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                        label: const Text(
                          "OTURUMU KAPAT",
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, {bool isFullWidth = false}) {
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
              Text(emoji, style: const TextStyle(fontSize: 24)),
              if (isFullWidth) const SizedBox(width: 15),
              if (isFullWidth) Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          if (!isFullWidth) const SizedBox(height: 10),
          if (!isFullWidth) Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
        ],
      ),
    );
  }

  Widget _emptyRides() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: Text('Henüz bir yolculuk yapmadınız.', style: TextStyle(color: Colors.white38))),
    );
  }

  Widget _buildRideTile(Ride ride) {
    bool canRate = ride.durum == 'tamamlandi' && ride.rating == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.location_on, color: Colors.amber, size: 20),
        ),
        title: Text(ride.bitisAdresMetni ?? 'Hedef Bilinmiyor', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('₺${ride.gerceklesenUcret ?? '0.00'} • ${ride.durum}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: canRate
            ? ElevatedButtonTheme(
                data: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40), padding: const EdgeInsets.symmetric(horizontal: 12))),
                child: ElevatedButton(onPressed: () => _navigateToRating(ride), child: const Text('Puan Ver', style: TextStyle(fontSize: 12))),
              )
            : (ride.rating != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ride.rating.toString(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                    ],
                  )
                : null),
      ),
    );
  }
}
