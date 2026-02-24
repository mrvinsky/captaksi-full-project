import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'verification_screen.dart'; // [YENİ]
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  // Bu const DEĞİL, çünkü StatefulWidget
  RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // [YENİ] Araç Bilgileri
  final _plakaController = TextEditingController();
  final _markaController = TextEditingController();
  final _modelController = TextEditingController();
  final _renkController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  File? _profileImage;
  File? _criminalRecordPdf;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _pickCriminalRecord() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _criminalRecordPdf = File(result.files.single.path!);
      });
    }
  }

  Future<void> _register() async {
    // Validasyon
    if (_adController.text.isEmpty || _soyadController.text.isEmpty || 
        _emailController.text.isEmpty || _passwordController.text.isEmpty ||
        _telefonController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tüm kişisel bilgileri doldurunuz.')));
        return;
    }

    if (_plakaController.text.isEmpty || _markaController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen araç bilgilerini giriniz.')));
        return;
    }

    setState(() => _isLoading = true);
    try {
      String? fcmToken;
      try {
        fcmToken = await NotificationService().getToken().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint("FCM Token alınamadı: $e");
      }

      await _apiService.registerDriver(
        ad: _adController.text,
        soyad: _soyadController.text,
        telefonNumarasi: _telefonController.text,
        email: _emailController.text,
        password: _passwordController.text,
        fcmToken: fcmToken,
        profileImage: _profileImage,
        criminalRecordPdf: _criminalRecordPdf,
        // [YENİ] Araç
        plaka: _plakaController.text,
        marka: _markaController.text,
        model: _modelController.text,
        renk: _renkController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! Lütfen hesabınızı doğrulayın.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              email: _emailController.text,
              token: "TOKEN_YOK",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _plakaController.dispose();
    _markaController.dispose();
    _modelController.dispose();
    _renkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131D),
      appBar: AppBar(
        title: Text('Kaptan Kaydı', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kişisel Bilgiler',
                style: GoogleFonts.outfit(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildInputField(controller: _adController, label: 'Ad', icon: Icons.person),
              const SizedBox(height: 15),
              _buildInputField(controller: _soyadController, label: 'Soyad', icon: Icons.person_outline),
              const SizedBox(height: 15),
              _buildInputField(controller: _telefonController, label: 'Telefon', icon: Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 15),
              _buildInputField(controller: _emailController, label: 'Email', icon: Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildInputField(controller: _passwordController, label: 'Şifre', icon: Icons.lock, isPassword: true),
              
              const SizedBox(height: 35),
              Text(
                'Araç Bilgileri',
                style: GoogleFonts.outfit(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildInputField(controller: _plakaController, label: 'Plaka', icon: Icons.badge),
              const SizedBox(height: 15),
              _buildInputField(controller: _markaController, label: 'Marka', icon: Icons.directions_car),
              const SizedBox(height: 15),
              _buildInputField(controller: _modelController, label: 'Model', icon: Icons.model_training),
              const SizedBox(height: 15),
              _buildInputField(controller: _renkController, label: 'Renk', icon: Icons.color_lens),
              
              const SizedBox(height: 35),
              Text(
                'Belgeler',
                style: GoogleFonts.outfit(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              _buildFileButton(
                icon: Icons.account_circle,
                label: _profileImage == null ? 'Profil Resmi Seç' : 'Resim Seçildi ✅',
                onTap: _pickProfileImage,
              ),
              const SizedBox(height: 12),
              _buildFileButton(
                icon: Icons.description,
                label: _criminalRecordPdf == null ? 'Adli Sicil Kaydı (PDF)' : 'PDF Yüklendi ✅',
                onTap: _pickCriminalRecord,
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('KAYDI TAMAMLA'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.amber.withOpacity(0.7)),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildFileButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.amber, size: 22),
            const SizedBox(width: 15),
            Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

