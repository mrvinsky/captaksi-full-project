class Ride {
  final String id;
  final String? bitisAdresMetni;
  final String? gerceklesenUcret;
  final String durum;
  final num? rating; // Changed to num to handle int/double/string parsing

  Ride({
    required this.id,
    this.bitisAdresMetni,
    this.gerceklesenUcret,
    required this.durum,
    this.rating,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'].toString(), // Safely convert int to String
      bitisAdresMetni: json['bitis_adres_metni'],
      gerceklesenUcret: json['gerceklesen_ucret'],
      durum: json['durum'],
      rating: json['rating'] != null ? num.tryParse(json['rating'].toString()) : null,
    );
  }
}