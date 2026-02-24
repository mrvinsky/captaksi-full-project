import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get _baseUrlHost {
    if (kIsWeb) return 'http://localhost:3000';
    // Fiziksel cihaz testi için Local IP, Emulator için platforma göre otomatik seçim
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    } catch (_) {}
    return 'http://localhost:3000';
  }

  static String get _driverBaseUrl => '$_baseUrlHost/api/drivers';
  static String get _rideBaseUrl => '$_baseUrlHost/api/rides';

  // GOOGLE KEY
  static const String _googleApiKey = 'AIzaSyB_Jh5g94flU9RjvtAeVFM7H44HmIBXlEk';

  // <<< BURASI ÖNEMLİ: typo düzeltildi >>>
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ---------------- TOKEN ----------------
  static Future<void> storeToken(String token) async =>
      await _storage.write(key: "jwt_token", value: token);

  static Future<String?> getToken() async =>
      await _storage.read(key: "jwt_token");

  static Future<void> deleteToken() async =>
      await _storage.delete(key: "jwt_token");

  // ---------------- HELPERS ----------------
  Uri _buildUri(String base, String path) => Uri.parse("$base$path");

  Map<String, String> _jsonHeaders(String? token) {
    final headers = {
      HttpHeaders.contentTypeHeader: "application/json; charset=utf-8",
    };
    if (token != null && token.isNotEmpty) {
      headers["x-auth-token"] = token;
    }
    return headers;
  }

  Exception _buildException(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      return Exception(data["message"] ?? "Hata: ${res.statusCode}");
    } catch (_) {
      return Exception("HTTP ${res.statusCode}");
    }
  }

  // ---------------- AUTH ----------------

  Future<Map<String, dynamic>> loginDriver(String email, String password, {String? fcmToken}) async {
    final url = _buildUri(_driverBaseUrl, "/login");

    final res = await _client.post(
      url,
      headers: _jsonHeaders(null),
      body: jsonEncode({
        "email": email,
        "sifre": password,
        "fcm_token": fcmToken
      }),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final token = body["token"];
      if (token == null) throw Exception("Token alınamadı.");

      await storeToken(token);
      return body; // Tüm body'i dön (is_verified, is_approved dahil)
    }

    throw _buildException(res);
  }

  Future<String> registerDriver({
    required String ad,
    required String soyad,
    required String telefonNumarasi,
    required String email,
    required String password,
    // [YENİ]
    required String plaka,
    required String marka,
    String? model,
    String? renk,
    String? fcmToken,
    File? profileImage,
    File? criminalRecordPdf,
  }) async {
    final url = _buildUri(_driverBaseUrl, "/register");

    final req = http.MultipartRequest("POST", url)
      ..fields["ad"] = ad
      ..fields["soyad"] = soyad
      ..fields["telefon_numarasi"] = telefonNumarasi
      ..fields["email"] = email
      ..fields["sifre"] = password
      ..fields["plaka"] = plaka
      ..fields["marka"] = marka
      ..fields["model"] = model ?? ""
      ..fields["renk"] = renk ?? "";
      
    if (fcmToken != null) req.fields['fcm_token'] = fcmToken;

    if (profileImage != null) {
      req.files.add(
        await http.MultipartFile.fromPath("profileImage", profileImage.path),
      );
    }

    if (criminalRecordPdf != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
            "criminalRecord", criminalRecordPdf.path),
      );
    }

    debugPrint("Enviando registro para: $url");
    try {
      final stream = await req.send().timeout(const Duration(seconds: 15));
      final res = await http.Response.fromStream(stream);

      debugPrint("Registro response: ${res.statusCode} - ${res.body}");

      if (res.statusCode == 201) {
        final body = jsonDecode(res.body);
        if (body["token"] != null) {
          await storeToken(body["token"]);
        }
        return body["message"] ?? "Kayıt başarılı.";
      }

      throw _buildException(res);
    } catch (e) {
      debugPrint("Registro hatası: $e");
      if (e is SocketException) {
        throw Exception("Sunucuya bağlanılamadı. Lütfen internet bağlantınızı ve API adresini kontrol edin.");
      }
      rethrow;
    }
  }

  // ---------------- DURUM / KONUM ----------------

  Future<void> updateDriverStatus(bool aktif, double lat, double lng) async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_driverBaseUrl, "/me/status");

    final res = await _client.patch(
      url,
      headers: _jsonHeaders(token),
      body: jsonEncode({
        "aktif": aktif,
        "konum": {
          "latitude": lat,
          "longitude": lng,
        }
      }),
    );

    if (res.statusCode != 200) throw _buildException(res);
  }

  // ---------------- RIDE ----------------

  Future<Map<String, dynamic>> acceptRide(String id) async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_rideBaseUrl, "/$id/accept");

    final res = await _client.patch(url, headers: _jsonHeaders(token));

    if (res.statusCode == 200) return jsonDecode(res.body);

    throw _buildException(res);
  }

  Future<Map<String, dynamic>> notifyArrival(String id) async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_rideBaseUrl, "/$id/notify-arrival");

    // Backend POST bekliyor
    final res = await _client.post(url, headers: _jsonHeaders(token));

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw _buildException(res);
  }

  Future<Map<String, dynamic>> startRide(String id) async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_rideBaseUrl, "/$id/start");

    // Backend POST bekliyor
    final res = await _client.post(url, headers: _jsonHeaders(token));
    if (res.statusCode == 200) return jsonDecode(res.body);

    throw _buildException(res);
  }

  Future<Map<String, dynamic>> completeRide(String id) async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_rideBaseUrl, "/$id/complete");

    // Backend POST bekliyor
    final res = await _client.post(url, headers: _jsonHeaders(token));
    if (res.statusCode == 200) return jsonDecode(res.body);

    throw _buildException(res);
  }

  Future<Map<String, dynamic>> ratePassenger(String id, double rating, String comment) async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_rideBaseUrl, "/$id/rate-passenger");

    final body = jsonEncode({
      "rating": rating,
      "comment": comment
    });

    final res = await _client.post(url, headers: _jsonHeaders(token), body: body);
    if (res.statusCode == 200) return jsonDecode(res.body);

    throw _buildException(res);
  }

  // ---------------- PROFILE GET ----------------

  Future<Map<String, dynamic>> getDriverProfile() async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_driverBaseUrl, "/me");

    final res = await _client.get(url, headers: _jsonHeaders(token));

    if (res.statusCode == 200) return jsonDecode(res.body);

    throw _buildException(res);
  }

  Future<Map<String, dynamic>> getDriverStats() async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_driverBaseUrl, "/me/stats");

    final res = await _client.get(url, headers: _jsonHeaders(token));

    if (res.statusCode == 200) return jsonDecode(res.body);

    throw _buildException(res);
  }

  // ---------------- PROFILE UPDATE ----------------

  Future<void> updateDriverInfo({
    String? email,
    String? telefonNumarasi,
    String? oldPassword,
    String? newPassword,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_driverBaseUrl, "/me/update");

    final res = await _client.patch(
      url,
      headers: _jsonHeaders(token),
      body: jsonEncode({
        "email": email,
        "telefon_numarasi": telefonNumarasi,
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    if (res.statusCode != 200) throw _buildException(res);
  }

  // ---------------- PAYOUT / WITHDRAWAL ----------------
  
  Future<Map<String, dynamic>> requestWithdrawal(double amount, String iban) async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_driverBaseUrl, "/withdraw");

    final res = await _client.post(
      url,
      headers: _jsonHeaders(token),
      body: jsonEncode({"amount": amount, "iban": iban}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) return jsonDecode(res.body);

    throw _buildException(res);
  }

  // ---------------- VEHICLE ----------------
  // vehicle_screen.dart içindeki getDriverVehicle çağrısını karşılar

  Future<Map<String, dynamic>> getDriverVehicle() async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_driverBaseUrl, "/me/vehicles");

    final res = await _client.get(
      url,
      headers: _jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw _buildException(res);
  }

  // Eğer ileride ihtiyaç olursa:
  Future<void> updateDriverVehicle({
    required int vehicleTypeId,
    required String plaka,
    String? marka,
    String? model,
    String? renk,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_driverBaseUrl, "/me/vehicle");

    final res = await _client.put(
      url,
      headers: _jsonHeaders(token),
      body: jsonEncode({
        "vehicle_type_id": vehicleTypeId,
        "plaka": plaka,
        "marka": marka,
        "model": model,
        "renk": renk,
      }),
    );

    if (res.statusCode != 200) throw _buildException(res);
  }

  // ---------------- GOOGLE ROUTE ----------------

  Future<Map<String, dynamic>> getDirections(LatLng origin, LatLng dest) async {
    final url =
        Uri.parse("https://maps.googleapis.com/maps/api/directions/json?"
            "origin=${origin.latitude},${origin.longitude}"
            "&destination=${dest.latitude},${dest.longitude}"
            "&mode=driving"
            "&key=$_googleApiKey");

    final res = await _client.get(url);

    if (res.statusCode != 200) throw Exception("Google Directions hatası");

    final data = jsonDecode(res.body);
    if (data["routes"] == null || data["routes"].isEmpty) {
      throw Exception("Rota bulunamadı");
    }

    final route = data["routes"][0];

    return {
      "polyline_points": route["overview_polyline"]["points"],
      "distance_text": route["legs"][0]["distance"]["text"],
      "duration_text": route["legs"][0]["duration"]["text"],
    };
  }

  void dispose() => _client.close();
}
