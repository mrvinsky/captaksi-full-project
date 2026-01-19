import 'package:flutter/material.dart';
import 'package:captaksi_app/screens/home_screen.dart';
import 'package:captaksi_app/services/api_service.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String token; // Token'ı taşıyoruz, doğrulama bitince lazım olabilir

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
    // NOT: Backend tarafında "verify" endpoint'i henüz yazılmadı,
    // şu an sadece "register" ve "login" var.
    // Ancak senaryo gereği burada bir API çağrısı yapılmalı.
    // Şimdilik MOCK olarak ilerliyoruz veya is_verified kontrolü yapıyoruz.
    
    // TODO: Backend'e /verify-email endpointi eklenmeli.
    // Şimdilik simüle ediyoruz.
    
    setState(() => _isLoading = true);
    
    // Simülasyon gecikmesi
    await Future.delayed(const Duration(seconds: 1));

    if (_codeController.text.length == 6) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Hesap Doğrulandı!'), backgroundColor: Colors.green)
         );
         Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false
         );
      }
    } else {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Hatalı Kod! (6 haneli olmalı)'), backgroundColor: Colors.red)
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
            const Icon(Icons.mark_email_read, size: 80, color: Colors.amber),
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
