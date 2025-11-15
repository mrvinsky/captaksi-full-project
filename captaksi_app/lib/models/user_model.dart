class User {
  final String ad;
  final String soyad;
  final String email;
  final String telefonNumarasi;
  final Map<String, dynamic> stats;

  User({
    required this.ad,
    required this.soyad,
    required this.email,
    required this.telefonNumarasi,
    required this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      ad: json['ad'] ?? 'Bilinmiyor',
      soyad: json['soyad'] ?? 'Bilinmiyor',
      email: json['email'] ?? '',
      telefonNumarasi: json['telefon_numarasi'] ?? '',
      stats: json['stats'] ?? {},
    );
  }
}
