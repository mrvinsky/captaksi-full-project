import 'package:flutter/material.dart';

class AddressInputHeader extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final VoidCallback onOriginTap;
  final VoidCallback onDestinationTap;
  final VoidCallback onPinTap;

  const AddressInputHeader({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.onOriginTap,
    required this.onDestinationTap,
    required this.onPinTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C), // Deep premium navy
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInputField(
            controller: originController,
            hintText: "Nereden?",
            icon: Icons.my_location,
            iconColor: Colors.greenAccent,
            onTap: onOriginTap,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Divider(color: Colors.white.withOpacity(0.1), height: 1),
          ),
          _buildInputField(
            controller: destinationController,
            hintText: "Nereye? (Arama veya Pin)",
            icon: Icons.location_on,
            iconColor: Colors.redAccent,
            onTap: onDestinationTap,
            suffixIcon: IconButton(
              tooltip: "Haritadan Seç",
              icon: const Icon(Icons.push_pin_outlined, color: Colors.white70),
              onPressed: onPinTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        suffixIcon: suffixIcon,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}
