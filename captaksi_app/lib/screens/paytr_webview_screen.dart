import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PayTRWebViewScreen extends StatefulWidget {
  final double amount;
  final String orderId;

  const PayTRWebViewScreen({
    super.key,
    required this.amount,
    required this.orderId,
  });

  @override
  State<PayTRWebViewScreen> createState() => _PayTRWebViewScreenState();
}

class _PayTRWebViewScreenState extends State<PayTRWebViewScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Sahte iFrame yüklenme animasyonu
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _simulatePaymentSuccess() {
    setState(() => _isProcessing = true);
    
    // İşleniyor...
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // API Callback'i simüle ediliyor (Backend bu işi zaten webhookta yapar ama UI'dan da tetikleyebiliriz)
        Navigator.pop(context, true); // true = Başarılı
      }
    });
  }

  void _simulatePaymentFailure() {
    Navigator.pop(context, false); // false = Başarısız
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // PayTR genelde beyaz iframe'dir
      appBar: AppBar(
        title: Text(
          "Güvenli Ödeme - PayTR",
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false), // İptal edildi
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 20),
                  Text("PayTR Güvenli Ödeme Sayfasına Yönlendiriliyorsunuz...", style: TextStyle(color: Colors.black54)),
                ],
              ),
            )
          : _isProcessing
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.green),
                      const SizedBox(height: 20),
                      Text(
                        "Ödemeniz işleniyor, lütfen bekleyin...",
                        style: GoogleFonts.outfit(color: Colors.black87, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mockup Kredi Kartı Formu
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Ödenecek Tutar:", style: GoogleFonts.outfit(fontSize: 16)),
                                Text("₺${widget.amount.toStringAsFixed(2)}", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                              ],
                            ),
                            const Divider(height: 30),
                            const TextField(
                              decoration: InputDecoration(
                                labelText: "Kart Üzerindeki İsim",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),
                            const TextField(
                              decoration: InputDecoration(
                                labelText: "Kart Numarası",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: Icon(Icons.credit_card),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: const [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: "Ay/Yıl",
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: "CVV",
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    obscureText: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),

                      // Test Butonları (Prod ortamda bu alan PayTR tarafından handle edilir)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "🛠 MOCKUP TEST PENCERESİ\n(Gerçekte bu ekran PayTR'nin kendi iFrame'i olacaktır)",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                                onPressed: _simulatePaymentSuccess,
                                child: const Text("Ödemeyi Onayla (BAŞARILI)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                                onPressed: _simulatePaymentFailure,
                                child: const Text("Ödemeyi Reddet (BAŞARISIZ)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
