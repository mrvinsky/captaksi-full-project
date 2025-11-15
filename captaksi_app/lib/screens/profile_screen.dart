import 'package:flutter/material.dart';
import 'package:captaksi_app/models/user_model.dart';
import 'package:captaksi_app/models/ride_model.dart';
import 'package:captaksi_app/services/api_service.dart';
import 'rating_screen.dart';

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
      appBar: AppBar(
        title: const Text("Profilim"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Veri bulunamadı.'));
          }

          final User user = snapshot.data!['user'];
          final List<Ride> rides = snapshot.data!['rides'];
          final stats = user.stats;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _dataFuture = _loadProfileData());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- PROFİL KARTI ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.black12,
                          child: Icon(Icons.person_outline,
                              size: 50, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${user.ad} ${user.soyad}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(user.email,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(user.telefonNumarasi,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- İSTATİSTİKLER KARTI ---
                Card(
                  color: Colors.amber[50],
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          '🚘',
                          'Yolculuk',
                          '${stats['total_rides']}',
                        ),
                        _buildStatItem(
                          '💸',
                          'Toplam Harcama',
                          '₺${stats['total_spent']}',
                        ),
                        _buildStatItem(
                          '📍',
                          'Toplam Mesafe',
                          '${stats['total_distance_km']} km',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Son Yolculuklarım',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                rides.isEmpty
                    ? const Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                              child: Text('Henüz bir yolculuk yapmadınız.')),
                        ),
                      )
                    : Column(
                        children: rides
                            .take(5)
                            .map((ride) => _buildRideTile(ride))
                            .toList(),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRideTile(Ride ride) {
    bool canRate = ride.durum == 'tamamlandi' && ride.rating == null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
        title: Text(ride.bitisAdresMetni ?? 'Hedef Bilinmiyor'),
        subtitle: Text('Ücret: ₺${ride.gerceklesenUcret ?? 'N/A'}'),
        trailing: canRate
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber, foregroundColor: Colors.black),
                onPressed: () => _navigateToRating(ride),
                child: const Text('Puan Ver'),
              )
            : (ride.rating != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ride.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                    ],
                  )
                : Text(ride.durum,
                    style: const TextStyle(
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500))),
      ),
    );
  }
}
