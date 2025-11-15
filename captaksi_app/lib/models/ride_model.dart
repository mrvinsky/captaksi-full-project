class Ride {
  final String id;
  final String? bitisAdresMetni;
  final String? gerceklesenUcret;
  final String durum;
  final int? rating; // Puan null olabilir

  Ride({
    required this.id,
    this.bitisAdresMetni,
    this.gerceklesenUcret,
    required this.durum,
    this.rating,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      bitisAdresMetni: json['bitis_adres_metni'],
      gerceklesenUcret: json['gerceklesen_ucret'],
      durum: json['durum'],
      rating: json['rating'],
    );
  }
}