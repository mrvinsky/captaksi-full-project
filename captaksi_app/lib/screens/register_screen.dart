import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:captaksi_app/services/api_service.dart';
import 'package:captaksi_app/services/notification_service.dart'; // [YENİ]
import 'package:captaksi_app/screens/verification_screen.dart'; // [YENİ]
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
      // [YENİ] FCM Token al
      final fcmToken = await NotificationService().getToken();

      // 1. Tek bir API çağrısı ile hem kayıt ol hem de token al
      final token = await ApiService().registerUser(
        ad: _adController.text,
        soyad: _soyadController.text,
        telefonNumarasi: _telefonController.text,
        email: _emailController.text,
        password: _passwordController.text,
        fcmToken: fcmToken, // [YENİ]
        profileImage: _profileImage,
        criminalRecordPdf: _criminalRecordPdf,
      );

      // 2. Alınan token'ı güvenli hafızaya kaydet
      await ApiService.storeToken(token);

      // 3. Doğrulama Sayfasına yönlendir (HomeScreen yerine)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              email: _emailController.text,
              token: token,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Hesap Oluştur', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- PROFILE PHOTO ---
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                          image: _profileImage != null
                              ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _profileImage == null
                            ? const Icon(Icons.person_add_rounded, size: 50, color: Colors.white54)
                            : null,
                      ),
                      if (_profileImage != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.edit, size: 18, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- FORM INPUTS ---
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _adController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person_outlined)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _soyadController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Soyad', prefixIcon: Icon(Icons.person_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _telefonController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Şifre', prefixIcon: Icon(Icons.lock_outline)),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // --- FILE UPLOAD ---
              InkWell(
                onTap: _pickCriminalRecord,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: _criminalRecordPdf != null ? Colors.greenAccent : Colors.white54,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _criminalRecordPdf != null
                              ? 'Sabıka Kaydı Seçildi (Değiştir)'
                              : 'Sabıka Kaydı Yükle (PDF)',
                          style: TextStyle(
                            color: _criminalRecordPdf != null ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_criminalRecordPdf != null) const Icon(Icons.check_circle, color: Colors.greenAccent),
                    ],
                  ),
                ),
              ),
              if (_criminalRecordPdf != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    _criminalRecordPdf!.path.split(Platform.pathSeparator).last,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
                
              const SizedBox(height: 40),

              // --- REGISTER BUTTON ---
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                        )
                      : Text(
                          'KAYIT OL',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

