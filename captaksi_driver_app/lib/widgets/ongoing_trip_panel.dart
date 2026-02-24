import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OngoingTripPanel extends StatelessWidget {
  final Map<String, dynamic> activeRide;
  final bool goingToPickup;
  final VoidCallback onChat;
  final VoidCallback onNotifyArrival;
  final VoidCallback onAction; // Start or Finish

  const OngoingTripPanel({
    super.key,
    required this.activeRide,
    required this.goingToPickup,
    required this.onChat,
    required this.onNotifyArrival,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final String title = goingToPickup ? "YOLCUYA GİDİLİYOR" : "YOLCULUK DEVAM EDİYOR";
    final String address = goingToPickup 
        ? (activeRide['baslangic_adres_metni'] ?? "") 
        : (activeRide['bitis_adres_metni'] ?? "");

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
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
            // Status Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: goingToPickup ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    goingToPickup ? Icons.near_me_rounded : Icons.flag_rounded,
                    color: goingToPickup ? Colors.blue : Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Address Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                address,
                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
              ),
            ),
            const SizedBox(height: 25),

            // Action Buttons
            Row(
              children: [
                // Chat Button
                Expanded(
                  child: _buildSecondaryButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: "MESAJ",
                    onTap: onChat,
                  ),
                ),
                const SizedBox(width: 15),
                // Arrival Button (Only if going to pickup)
                if (goingToPickup) ...[
                  Expanded(
                    child: _buildSecondaryButton(
                      icon: Icons.notifications_active_outlined,
                      label: "GELDİM",
                      color: Colors.amber.withOpacity(0.7),
                      onTap: onNotifyArrival,
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              ],
            ),
            const SizedBox(height: 15),

            // Primary Action Button (Start or Finish)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: goingToPickup ? Colors.blue : Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shadowColor: (goingToPickup ? Colors.blue : Colors.green).withOpacity(0.3),
                ),
                child: Text(
                   goingToPickup ? "YOLCULUĞU BAŞLAT" : "YOLCULUĞU TAMAMLA",
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white54,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
