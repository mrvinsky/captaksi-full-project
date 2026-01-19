import 'package:flutter/material.dart';
import 'package:captaksi_driver_app/services/api_service.dart';
import 'package:captaksi_driver_app/screens/login_screen.dart';
import 'package:captaksi_driver_app/screens/driver_home_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isLoading = false;

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    try {
      // Profil endpoint'i is_approved bilgisini de dönüyor (Backend güncellendi)
      final profile = await ApiService().getDriverProfile();
      
      if (profile['is_approved'] == true) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Hesabınız Onaylandı!"), backgroundColor: Colors.green)
           );
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
           );
         }
      } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Henüz onaylanmamış. Lütfen bekleyin."), backgroundColor: Colors.orange)
           );
         }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.deleteToken();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Onay Bekleniyor"),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time_filled, size: 100, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                "Hesabınız İnceleniyor",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Yüklediğiniz belgeler ve bilgiler admin tarafından incelenmektedir. Onaylandığında bildirim alacaksınız veya buradan kontrol edebilirsiniz.",
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _checkStatus,
                icon: const Icon(Icons.refresh),
                label: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                    : const Text("DURUMU KONTROL ET"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
