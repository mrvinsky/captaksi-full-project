class VehicleType {
  final int id;
  final String tipAdi;
  final String aciklama;
  final String tabanUcret;
  final String kmUcreti;

  VehicleType({
    required this.id,
    required this.tipAdi,
    required this.aciklama,
    required this.tabanUcret,
    required this.kmUcreti,
  });

  // Gelen JSON verisini VehicleType nesnesine dönüştüren fabrika metodu
  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'],
      tipAdi: json['tip_adi'],
      aciklama: json['aciklama'] ?? '', // Açıklama boş gelebilir diye kontrol
      tabanUcret: json['taban_ucret'],
      kmUcreti: json['km_ucreti'],
    );
  }
}
