import 'package:flutter/material.dart';
import 'package:captaksi_app/services/api_service.dart';

class RatingScreen extends StatefulWidget {
  final Map<String, dynamic> finishedRide;

  const RatingScreen({super.key, required this.finishedRide});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final ApiService _apiService = ApiService();

  int drivingQuality = 0;
  int politeness = 0;
  int cleanliness = 0;
  bool _isSubmitting = false;
  final TextEditingController _commentController = TextEditingController();

  Future<void> _submitRating() async {
    if (drivingQuality == 0 || politeness == 0 || cleanliness == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm kriterleri puanlayın.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _apiService.rateRide(
        rideId: widget.finishedRide["id"].toString(),
        additionalRatings: {
          'drivingQuality': drivingQuality,
          'politeness': politeness,
          'cleanliness': cleanliness,
        },
        comment: _commentController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Puanlar başarıyla gönderildi!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildRatingRow(String emoji, String label, int current, Function(int) onSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('$emoji $label', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: current > index ? Colors.amber : Colors.grey[400],
                  ),
                  onPressed: () => onSelect(index + 1),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.finishedRide;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yolculuğu Değerlendir'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'Varış Noktası:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ride["bitis_adres_metni"] ?? 'Bilinmeyen Hedef',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Ücret: ₺${ride["gerceklesen_ucret"] ?? '0.00'}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),

            const Divider(height: 32),

            // Rating satırları
            _buildRatingRow('🚗', 'Sürüş Kalitesi', drivingQuality, (val) {
              setState(() => drivingQuality = val);
            }),
            _buildRatingRow('🗣️', 'Nezaket & İletişim', politeness, (val) {
              setState(() => politeness = val);
            }),
            _buildRatingRow('🧼', 'Araç Temizliği', cleanliness, (val) {
              setState(() => cleanliness = val);
            }),

            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Yorum (isteğe bağlı)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Gönder butonu
            Center(
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text(
                        'Gönder',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _submitRating,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
