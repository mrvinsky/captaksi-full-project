import 'package:flutter/material.dart';
import 'package:captaksi_driver_app/screens/driver_home_screen.dart';
import 'package:captaksi_driver_app/screens/pending_approval_screen.dart'; // [YENİ]

class VerificationScreen extends StatefulWidget {
  final String email;
  final String token;

  const VerificationScreen({
    super.key, 
    required this.email,
    required this.token,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify() async {
    // TODO: Backend /verify endpoint entegrasyonu
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(seconds: 1));

    if (_codeController.text.length == 6) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Hesap Doğrulandı!'), backgroundColor: Colors.green)
         );
         // [GÜNCELLEME]: Doğrulama sonrası Onay Bekleme Ekranına git
         Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
            (route) => false
         );
      }
    } else {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Hatalı Kod!'), backgroundColor: Colors.red)
         );
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hesap Doğrulama")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.verified_user_outlined, size: 80, color: Colors.cyan),
            const SizedBox(height: 24),
            Text(
              "${widget.email} adresine gönderilen 6 haneli kodu giriniz.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : const Text("DOĞRULA"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
