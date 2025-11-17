import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  String? errorMsg;
  Map<String, dynamic>? vehicle;

  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    loadVehicle();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> loadVehicle() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final res = await ApiService().getDriverVehicle();

      /// Backend ister { vehicle: {...} } ister {...} göndersin:
      vehicle = res["vehicle"] ?? res;

      _anim.forward();
    } catch (e) {
      errorMsg = e.toString().replaceAll("Exception: ", "");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  String v(List<String> keys) {
    for (final k in keys) {
      final val = vehicle?[k];
      if (val != null && val.toString().isNotEmpty) return val.toString();
    }
    return "-";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Araç Bilgilerim", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loading ? null : loadVehicle,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(errorMsg!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadVehicle,
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrar dene"),
              ),
            ],
          ),
        ),
      );
    }

    if (vehicle == null) {
      return const Center(
        child: Text(
          "Sistemde kayıtlı araç bulunamadı.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final plate = v(["plaka", "plate"]);
    final brand = v(["marka", "brand"]);
    final model = v(["model"]);
    final year = v(["yil", "year"]);
    final color = v(["renk", "color"]);
    final typeName = v(["tip_adi", "type_name"]);

    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // ÜST KART
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.local_taxi, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plate,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$brand $model",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),

            _tile("Plaka", plate, Icons.confirmation_number),
            _tile("Marka / Model", "$brand $model", Icons.directions_car),
            _tile("Renk", color, Icons.color_lens),
            _tile("Model Yılı", year, Icons.event),
            _tile("Araç Tipi", typeName, Icons.local_taxi),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white70)),
        subtitle: Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
      ),
    );
  }
}
