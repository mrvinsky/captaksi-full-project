import 'package:captaksi_app/models/vehicle_type_model.dart';
import 'package:flutter/material.dart';

class RideSelectionSheet extends StatefulWidget {
  final ScrollController scrollController;
  final List<VehicleType> vehicleTypes;
  final int selectedIndex;
  final Function(int) onVehicleSelected;
  final String? distance;
  final String? duration;
  final String calculatedFare;
  final bool isFindingDriver;
  final Function(String) onRideRequested;

  const RideSelectionSheet({
    super.key,
    required this.scrollController,
    required this.vehicleTypes,
    required this.selectedIndex,
    required this.onVehicleSelected,
    this.distance,
    this.duration,
    required this.calculatedFare,
    required this.isFindingDriver,
    required this.onRideRequested,
  });

  @override
  State<RideSelectionSheet> createState() => _RideSelectionSheetState();
}

class _RideSelectionSheetState extends State<RideSelectionSheet> {
  String _selectedPaymentMethod = "Nakit";

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20.0,
            color: Colors.black.withOpacity(0.6),
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          if (widget.distance != null) _buildTripStats(),
          _buildPaymentSelector(),
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: widget.vehicleTypes.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final vehicle = widget.vehicleTypes[index];
                final isSelected = widget.selectedIndex == index;
                return _buildVehicleItem(vehicle, isSelected, index);
              },
            ),
          ),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        width: 45,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildTripStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(Icons.route, widget.distance ?? '-'),
            _statItem(Icons.access_time_filled, widget.duration ?? '-'),
            _statItem(Icons.payments, '₺${widget.calculatedFare}', isBold: true, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String label, {bool isBold = false, Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Ödeme Yöntemi",
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: _showPaymentMethodPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedPaymentMethod == "Nakit" ? Icons.money : Icons.credit_card,
                    color: Colors.amber,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedPaymentMethod,
                    style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.amber, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252535),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          const Text("Ödeme Yöntemi Seçin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.money, color: Colors.green),
            title: const Text("Nakit", style: TextStyle(color: Colors.white)),
            trailing: _selectedPaymentMethod == "Nakit" ? const Icon(Icons.check, color: Colors.amber) : null,
            onTap: () { setState(() => _selectedPaymentMethod = "Nakit"); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card, color: Colors.blue),
            title: const Text("Kredi / Banka Kartı", style: TextStyle(color: Colors.white)),
            trailing: _selectedPaymentMethod == "Kredi / Banka Kartı" ? const Icon(Icons.check, color: Colors.amber) : null,
            onTap: () { setState(() => _selectedPaymentMethod = "Kredi / Banka Kartı"); Navigator.pop(context); },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVehicleItem(VehicleType vehicle, bool isSelected, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.amber.withOpacity(0.08) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? Colors.amber.withOpacity(0.4) : Colors.white.withOpacity(0.05),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () => widget.onVehicleSelected(index),
        leading: Hero(
          tag: 'vehicle_${vehicle.id}',
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_taxi,
              size: 28,
              color: isSelected ? Colors.black : Colors.white70,
            ),
          ),
        ),
        title: Text(
          vehicle.tipAdi,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.amber : Colors.white,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          vehicle.aciklama,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₺${vehicle.tabanUcret}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? Colors.amber : Colors.white,
              ),
            ),
            Text(
              "Taban",
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      child: ElevatedButton(
        // [MODIFIED] Pass the selected payment method to the parent callback
        onPressed: (widget.selectedIndex == -1 || widget.isFindingDriver) 
            ? null 
            : () => widget.onRideRequested(_selectedPaymentMethod),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          elevation: 5,
          shadowColor: Colors.amber.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: widget.isFindingDriver
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
              )
            : const Text(
                'TAKSİ ÇAĞIR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
      ),
    );
  }
}
