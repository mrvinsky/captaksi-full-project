import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      stats = await ApiService().getDriverStats();
    } catch (e) {
      print("Kazanç verisi hatası: $e");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final int rides = int.tryParse(stats?["rides"].toString() ?? "0") ?? 0;
    final double earnings = double.tryParse(stats?["earnings"].toString() ?? "0") ?? 0.0;
    final double distance = double.tryParse(stats?["distance"].toString() ?? "0") ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Kazançlarım"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            // --- Günlük toplam ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Toplam Kazanç",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${earnings.toStringAsFixed(0)} RSD",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- İstatistik kartları ---
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.directions_car_filled,
                    title: "Sürüş",
                    value: "$rides",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.route,
                    title: "KM",
                    value: distance.toStringAsFixed(1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.attach_money,
                    title: "Kazanç",
                    value: "${earnings.toStringAsFixed(0)} RSD",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Divider(color: Colors.white10),

            const SizedBox(height: 20),

            Expanded(
              child: Center(
                child: Text(
                  "Yakında: günlük → haftalık → aylık kazanç grafikleri",
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          )
        ],
      ),
    );
  }
}
