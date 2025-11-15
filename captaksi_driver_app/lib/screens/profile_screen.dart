import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Ad Soyad'),
            subtitle: const Text('Test Sürücüsü'),
            onTap: () {
              // TODO: Ad soyad düzenleme
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: const Text('surucu@test.com'),
            onTap: () {
              // TODO: Email düzenleme
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Belgelerim'),
            subtitle: const Text('Ehliyet, Sabıka Kaydı...'),
            onTap: () {
              // TODO: Belge yönetimi ekranına git
            },
          ),
          ListTile(
            leading: const Icon(Icons.car_rental),
            title: const Text('Araç Bilgilerim'),
            subtitle: const Text('34 ABC 01 - Sarı Egea'),
            onTap: () {
              // TODO: Araç yönetimi ekranına git
            },
          ),
        ],
      ),
    );
  }
}
