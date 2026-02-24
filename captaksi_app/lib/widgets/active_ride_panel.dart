import 'package:flutter/material.dart';

class ActiveRidePanel extends StatelessWidget {
  final Map<String, dynamic> acceptedRide;
  final String rideStatusText;
  final VoidCallback onCancelToggle;
  final VoidCallback onChatTap;

  const ActiveRidePanel({
    super.key,
    required this.acceptedRide,
    required this.rideStatusText,
    required this.onCancelToggle,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final driver = acceptedRide['driver'];
    final vehicle = acceptedRide['vehicle'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBar(),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildDriverAvatar(driver['ad']),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${driver['ad']} ${driver['soyad']}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      "Araç: ${vehicle['plaka']} • ${vehicle['marka']}",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _actionButton(Icons.chat_bubble_rounded, Colors.amber, onChatTap),
                  const SizedBox(height: 10),
                  const Text("Sohbet", style: TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Text(
        rideStatusText.isNotEmpty ? rideStatusText : "Sürücü Yolda!",
        style: const TextStyle(color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDriverAvatar(String name) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
      ),
      child: const Icon(Icons.person, color: Colors.amber, size: 35),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildCancelButton() {
    return OutlinedButton(
      onPressed: onCancelToggle,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: Colors.redAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        foregroundColor: Colors.redAccent,
      ),
      child: const Text("Yolculuğu İptal Et", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
