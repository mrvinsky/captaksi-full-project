import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Sürücü uygulaması için API katmanı.
/// Tüm HTTP istekleri buradan geçer, token yönetimi merkezi olarak yapılır.
class ApiService {
  // Emülatörde backend için 10.0.2.2 kullanıyoruz.
  static const String _driverBaseUrl = 'http://10.0.2.2:3000/api/drivers';
  static const String _rideBaseUrl = 'http://10.0.2.2:3000/api/rides';

  // !!! GERÇEK KEYİ REPOYA KOYMA !!!
  static const String _googleApiKey = 'BURAYA_GOOGLE_API_KEY_GELECEK';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ---------------- TOKEN YÖNETİMİ ----------------

  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: 'jwt_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // ---------------- GENEL ----------------

  Uri _buildUri(String base, String path) {
    return Uri.parse('$base$path');
  }

  Map<String, String> _jsonHeaders(String? token) {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    };
    if (token != null && token.isNotEmpty) {
      headers['x-auth-token'] = token;
    }
    return headers;
  }

  Exception _buildException(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final msg = body is Map && body['message'] != null
          ? body['message']
          : 'İstek başarısız oldu. (${response.statusCode})';
      return Exception(msg.toString());
    } catch (e) {
      return Exception('HTTP ${response.statusCode}');
    }
  }

  // ---------------- AUTH ----------------

  Future<String> loginDriver(String email, String password) async {
    final url = _buildUri(_driverBaseUrl, '/login');

    final response = await _client.post(
      url,
      headers: _jsonHeaders(null),
      body: jsonEncode({
        'email': email,
        'sifre': password,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final token = body['token']?.toString() ?? "";
      if (token.isEmpty) throw Exception("Token alınamadı.");

      await ApiService.storeToken(token);
      return token;
    }

    throw _buildException(response);
  }

  Future<String> registerDriver({
    required String ad,
    required String soyad,
    required String telefonNumarasi,
    required String email,
    required String password,
    File? profileImage,
    File? criminalRecordPdf,
  }) async {
    final url = _buildUri(_driverBaseUrl, '/register');

    final req = http.MultipartRequest("POST", url)
      ..fields['ad'] = ad
      ..fields['soyad'] = soyad
      ..fields['telefon_numarasi'] = telefonNumarasi
      ..fields['email'] = email
      ..fields['sifre'] = password;

    if (profileImage != null) {
      req.files.add(await http.MultipartFile.fromPath(
          'profileImage', profileImage.path));
    }

    if (criminalRecordPdf != null) {
      req.files.add(await http.MultipartFile.fromPath(
          'criminalRecord', criminalRecordPdf.path));
    }

    final stream = await req.send();
    final response = await http.Response.fromStream(stream);

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return body['message'] ?? "Kayıt başarılı.";
    }

    throw _buildException(response);
  }

  // ---------------- STATUS ----------------

  Future<void> updateDriverStatus(
      bool isActive, double lat, double lng) async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_driverBaseUrl, '/me/status');

    final response = await _client.patch(
      url,
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'aktif': isActive,
        'konum': {'latitude': lat, 'longitude': lng}
      }),
    );

    if (response.statusCode != 200) throw _buildException(response);
  }

  // ---------------- RIDES ----------------

  Future<Map<String, dynamic>> acceptRide(String rideId) async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_rideBaseUrl, '/$rideId/accept');
    final response = await _client.patch(url, headers: _jsonHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw _buildException(response);
  }

  Future<Map<String, dynamic>> startRide(String rideId) async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_rideBaseUrl, '/$rideId/start');
    final response = await _client.patch(url, headers: _jsonHeaders(token));

    if (response.statusCode == 200) return jsonDecode(response.body);

    throw _buildException(response);
  }

  Future<Map<String, dynamic>> finishRide(String rideId) async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_rideBaseUrl, '/$rideId/finish');
    final response = await _client.patch(url, headers: _jsonHeaders(token));

    if (response.statusCode == 200) return jsonDecode(response.body);

    throw _buildException(response);
  }

  // ---------------- GOOGLE DIRECTIONS ----------------

  Future<Map<String, dynamic>> getDirections(
      LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/directions/json?"
      "origin=${origin.latitude},${origin.longitude}"
      "&destination=${destination.latitude},${destination.longitude}"
      "&key=$_googleApiKey",
    );

    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception("Rota alınamadı: HTTP ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') {
      throw Exception("Rota bulunamadı. Status: ${data['status']}");
    }

    final route = data['routes'][0];
    final leg = route['legs'][0];

    return {
      'polyline_points': route['overview_polyline']['points'],
      'distance': leg['distance']['text'],
      'duration': leg['duration']['text'],
      'distance_value': leg['distance']['value'],
    };
  }

  // ---------------- PROFILE ----------------

  /// Sürücü profil bilgilerini getirir.
  Future<Map<String, dynamic>> getDriverProfile() async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_driverBaseUrl, '/me');
    final response = await _client.get(url, headers: _jsonHeaders(token));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['driver'];
    }

    throw _buildException(response);
  }

  /// Sürücü istatistiklerini getirir (Bolt Driver tarzı).
  Future<Map<String, dynamic>> getDriverStats() async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception("Giriş gerekli.");

    final url = _buildUri(_driverBaseUrl, '/me/stats');
    final response = await _client.get(url, headers: _jsonHeaders(token));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['stats'];
    }

    throw _buildException(response);
  }

  // ---------------- CLEANUP ----------------

  void dispose() {
    _client.close();
  }
}
