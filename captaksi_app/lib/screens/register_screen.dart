import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:captaksi_app/services/api_service.dart';
import 'package:captaksi_app/screens/home_screen.dart';
import 'package:captaksi_app/screens/login_screen.dart'; // Geri dönmek için eklendi

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  File? _profileImage;
  File? _criminalRecordPdf;

  Future<void> _pickProfileImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickCriminalRecord() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _criminalRecordPdf = File(result.files.single.path!);
      });
    }
  }

  // GÜNCELLENDİ: Artık çok daha basit!
  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      // 1. Tek bir API çağrısı ile hem kayıt ol hem de token al
      final token = await ApiService().registerUser(
        ad: _adController.text,
        soyad: _soyadController.text,
        telefonNumarasi: _telefonController.text,
        email: _emailController.text,
        password: _passwordController.text,
        profileImage: _profileImage,
        criminalRecordPdf: _criminalRecordPdf,
      );

      // 2. Alınan token'ı güvenli hafızaya kaydet
      await ApiService.storeToken(token);

      // 3. Ana sayfaya yönlendir
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Oluştur'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600])
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(controller: _adController, decoration: InputDecoration(labelText: 'Ad', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.person))),
              const SizedBox(height: 16),
              TextField(controller: _soyadController, decoration: InputDecoration(labelText: 'Soyad', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.person_outline))),
              const SizedBox(height: 16),
              TextField(controller: _telefonController, decoration: InputDecoration(labelText: 'Telefon Numarası', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.phone)), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Şifre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock)), obscureText: true),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickCriminalRecord,
                icon: const Icon(Icons.picture_as_pdf),
                label: Flexible(
                  child: Text(
                    _criminalRecordPdf == null
                        ? 'Sabıka Kaydı Yükle (PDF)'
                        : 'PDF Seçildi: ${_criminalRecordPdf!.path.split(Platform.pathSeparator).last}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kayıt Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

