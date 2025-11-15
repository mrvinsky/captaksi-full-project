import 'dart:convert';

class Driver {
  final int id;
  final String ad;
  final String puanOrtalamasi;
  final double latitude;
  final double longitude;

  Driver({
    required this.id,
    required this.ad,
    required this.puanOrtalamasi,
    required this.latitude,
    required this.longitude,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    // Backend'den gelen GeoJSON formatındaki konumu ayrıştırıyoruz.
    // Önce "konum" alanını bir string olarak alıp, sonra onu JSON'a çeviriyoruz.
    final List<dynamic> coordinates = jsonDecode(json['konum'])['coordinates'];
    return Driver(
      id: json['id'],
      ad: json['ad'],
      puanOrtalamasi: json['puan_ortalamasi'],
      longitude: coordinates[0] as double, // Önce boylam gelir
      latitude: coordinates[1] as double,  // Sonra enlem gelir
    );
  }
}

