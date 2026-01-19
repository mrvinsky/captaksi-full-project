import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'driver_home_screen.dart';

class RatePassengerScreen extends StatefulWidget {
  final String rideId;
  final String passengerName; // Opsiyonel: Yolcunun adını göstermek için

  const RatePassengerScreen({Key? key, required this.rideId, this.passengerName = "Yolcu"}) : super(key: key);

  @override
  State<RatePassengerScreen> createState() => _RatePassengerScreenState();
}

class _RatePassengerScreenState extends State<RatePassengerScreen> {
  final ApiService api = ApiService();
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  void _submitRating() async {
    setState(() => _isLoading = true);
    try {
      await api.ratePassenger(widget.rideId, _rating, _commentController.text.trim());
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teşekkürler! Puanınız kaydedildi.")),
      );

      // Ana Ekrana Dön
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
        (route) => false,
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStar(int index) {
    IconData icon;
    Color color;

    if (index < _rating) {
      icon = Icons.star;
      color = Colors.amber;
    } else {
      icon = Icons.star_border;
      color = Colors.grey;
    }

    return IconButton(
      icon: Icon(icon, color: color, size: 40),
      onPressed: () {
        setState(() {
          _rating = index + 1.0;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark Theme
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 80),
              const SizedBox(height: 16),
              const Text(
                "Yolculuk Tamamlandı!",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "${widget.passengerName} adlı yolcuyu değerlendirin",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              
              const SizedBox(height: 40),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => _buildStar(index)),
              ),
              
              const SizedBox(height: 8),
              Text(
                "$_rating/5",
                style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Yorumunuz (opsiyonel)",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("GÖNDER VE BİTİR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
