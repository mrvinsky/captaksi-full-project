import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'verification_screen.dart'; // [YENİ]

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
    if (_plakaController.text.isEmpty || _markaController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen araç bilgilerini giriniz.')));
        return;
    }

    setState(() => _isLoading = true);
    try {
      final fcmToken = await NotificationService().getToken();

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
      appBar: AppBar(title: const Text('Sürücü Olarak Kayıt Ol')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _adController, decoration: const InputDecoration(labelText: 'Ad')),
              const SizedBox(height: 12),
              TextField(controller: _soyadController, decoration: const InputDecoration(labelText: 'Soyad')),
              const SizedBox(height: 12),
              TextField(controller: _telefonController, decoration: const InputDecoration(labelText: 'Telefon Numarası'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Şifre'), obscureText: true),
              const SizedBox(height: 24),
              
              Text('Araç Bilgileri', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(controller: _plakaController, decoration: const InputDecoration(labelText: 'Plaka (34 AB 123)')),
              const SizedBox(height: 12),
              TextField(controller: _markaController, decoration: const InputDecoration(labelText: 'Marka (Fiat)')),
              const SizedBox(height: 12),
              TextField(controller: _modelController, decoration: const InputDecoration(labelText: 'Model (Egea)')),
              const SizedBox(height: 12),
              TextField(controller: _renkController, decoration: const InputDecoration(labelText: 'Renk (Sarı)')),
              const SizedBox(height: 24),

              Text('Belgeler (Zorunlu)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              
              OutlinedButton.icon(
                icon: const Icon(Icons.account_circle),
                label: Text(_profileImage == null ? 'Profil Resmi Yükle' : 'Resim Yüklendi (Değiştir)'),
                onPressed: _pickProfileImage,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.badge),
                label: Text(_criminalRecordPdf == null ? 'Sabıka Kaydı (PDF) Yükle' : 'PDF Yüklendi (Değiştir)'),
                onPressed: _pickCriminalRecord,
              ),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 18)
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kayıt Ol ve Aracı Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

