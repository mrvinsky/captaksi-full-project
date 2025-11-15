import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ApiService {
  // ----------- BASE URL -----------
  static const String _ip = "10.0.2.2"; // Emulator için doğru IP
  static const String _driverBase = "http://$_ip:3000/api/drivers";
  static const String _ridesBase = "http://$_ip:3000/api/rides";

  // ----------- GOOGLE API KEY -----------
  static const String _googleApiKey = 'AIzaSyBh_TTuFpUAbM0yw3lrzq4PYTPBv_R9ivA';

  // ----------- TOKEN STORAGE -----------
  static const _storage = FlutterSecureStorage();

  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // ----------- DRIVER LOGIN -----------
  Future<String> loginDriver(String email, String password) async {
    final url = Uri.parse("$_driverBase/login");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'sifre': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['token'];
    } else {
      throw Exception(data['message'] ?? "Login failed");
    }
  }

  // ----------- DRIVER REGISTER -----------
  Future<String> registerDriver({
    required String ad,
    required String soyad,
    required String telefonNumarasi,
    required String email,
    required String password,
    File? profileImage,
    File? criminalRecordPdf,
  }) async {
    final url = Uri.parse("$_driverBase/register");
    var request = http.MultipartRequest("POST", url);

    request.fields['ad'] = ad;
    request.fields['soyad'] = soyad;
    request.fields['telefon_numarasi'] = telefonNumarasi;
    request.fields['email'] = email;
    request.fields['sifre'] = password;

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'profileImage', profileImage.path));
    }
    if (criminalRecordPdf != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'criminalRecord', criminalRecordPdf.path));
    }

    var streamed = await request.send();
    var response = await http.Response.fromStream(streamed);

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data['message'];
    } else {
      throw Exception(data['message'] ?? "Register failed");
    }
  }

  // ----------- UPDATE DRIVER LOCATION & STATUS -----------
  Future<void> updateDriverStatus(
      bool isActive, double latitude, double longitude) async {
    final token = await getToken();
    if (token == null) throw Exception("Token missing!");

    final url = Uri.parse("$_driverBase/me/status");

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token
      },
      body: jsonEncode({
        'aktif': isActive,
        'konum': {'latitude': latitude, 'longitude': longitude}
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          jsonDecode(response.body)['message'] ?? "Status update failed");
    }
  }

  // ----------- ACCEPT RIDE -----------
  Future<Map<String, dynamic>> acceptRide(String rideId) async {
    final token = await getToken();
    if (token == null) throw Exception("Token missing!");

    final url = Uri.parse("$_ridesBase/$rideId/accept");

    final response =
        await http.patch(url, headers: {'x-auth-token': token});

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? "Accept failed");
    }
  }

  // ----------- START RIDE -----------
  Future<Map<String, dynamic>> startRide(String rideId) async {
    final token = await getToken();
    if (token == null) throw Exception("Token missing!");

    final url = Uri.parse("$_ridesBase/$rideId/start");

    final response =
        await http.patch(url, headers: {'x-auth-token': token});

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? "Start failed");
    }
  }

  // ----------- FINISH RIDE -----------
  Future<Map<String, dynamic>> finishRide(String rideId) async {
    final token = await getToken();
    if (token == null) throw Exception("Token missing!");

    final url = Uri.parse("$_ridesBase/$rideId/finish");

    final response =
        await http.patch(url, headers: {'x-auth-token': token});

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? "Finish failed");
    }
  }

  // ----------- GET GOOGLE DIRECTIONS -----------
  Future<Map<String, dynamic>> getDirections(
      LatLng origin, LatLng destination) async {
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&key=$_googleApiKey");

    final response = await http.get(url);

    final data = jsonDecode(response.body);

    if (data['status'] != "OK") {
      throw Exception("Route not found");
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
}
