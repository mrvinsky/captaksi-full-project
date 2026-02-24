import 'dart:convert';
import 'dart:io';
import 'package:captaksi_app/models/place_model.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/vehicle_type_model.dart';
import '../models/driver_model.dart';
import '../models/ride_model.dart';

class ApiService {
  // 🌍 YOLCU API'sinin temel URL'si
  // 🌍 YOLCU API'sinin temel URL'si
  // Fiziksel Cihaz / LAN Testi için IP:
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    } catch (_) {}
    return 'http://localhost:3000/api';
  }
  static const _storage = FlutterSecureStorage();

  // 🔑 Google API Anahtarımız
  static const String _googleApiKey = 'AIzaSyB_Jh5g94flU9RjvtAeVFM7H44HmIBXlEk';

  // --- TOKEN YÖNETİMİ ---
  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // --- KULLANICI GİRİŞ & KAYIT ---
  Future<String> loginUser(String email, String password, {String? fcmToken}) async {
    final url = Uri.parse('$_baseUrl/users/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'email': email, 
        'sifre': password,
        'fcm_token': fcmToken // [YENİ]
      }),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['token'];
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Giriş sırasında bir hata oluştu.');
    }
  }

  Future<String> registerUser({
    required String ad,
    required String soyad,
    required String telefonNumarasi,
    required String email,
    required String password,
    String? fcmToken, // [YENİ]
    File? profileImage,
    File? criminalRecordPdf,
  }) async {
    final url = Uri.parse('$_baseUrl/users/register');
    var request = http.MultipartRequest('POST', url);
    request.fields['ad'] = ad;
    request.fields['soyad'] = soyad;
    request.fields['telefon_numarasi'] = telefonNumarasi;
    request.fields['email'] = email;
    request.fields['sifre'] = password;
    if (fcmToken != null) request.fields['fcm_token'] = fcmToken; // [YENİ]

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath('profileImage', profileImage.path));
    }
    if (criminalRecordPdf != null) {
      request.files.add(await http.MultipartFile.fromPath('criminalRecord', criminalRecordPdf.path));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['token'];
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Kayıt sırasında bir hata oluştu.');
    }
  }

  // --- PROFİL & GEÇMİŞ ---
  Future<User> getUserProfile() async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/users/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'x-auth-token': token ?? ''
      },
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Profil bilgileri alınamadı.');
    }
  }

  Future<List<Ride>> getRideHistory() async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/users/me/rides');

    final response = await http.get(
      url,
      headers: {'x-auth-token': token ?? ''},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Ride.fromJson(json)).toList();
    } else {
      throw Exception('Yolculuk geçmişi alınamadı.');
    }
  }

  // --- ARAÇ TİPLERİ ---
  Future<List<VehicleType>> getVehicleTypes() async {
    final url = Uri.parse('$_baseUrl/vehicle-types');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => VehicleType.fromJson(json)).toList();
      } else {
        throw Exception('Araç tipleri yüklenemedi.');
      }
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı.');
    }
  }

  // --- YAKIN SÜRÜCÜLER ---
  Future<List<Driver>> getNearbyDrivers(Position position) async {
    final token = await getToken();
    final url = Uri.parse(
        '$_baseUrl/drivers/nearby?lat=${position.latitude}&lon=${position.longitude}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token ?? ''
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Driver.fromJson(json)).toList();
      } else {
        throw Exception('Yakındaki sürücüler yüklenemedi.');
      }
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı.');
    }
  }

  // --- YOLCULUK OLUŞTURMA ---
  Future<Map<String, dynamic>> createRide({
    required LatLng origin,
    required LatLng destination,
    required String originAddress,
    required String destinationAddress,
    required int vehicleTypeId,
    required String estimatedFare,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/rides');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'x-auth-token': token ?? ''
      },
      body: jsonEncode({
        'origin': {'latitude': origin.latitude, 'longitude': origin.longitude},
        'destination': {'latitude': destination.latitude, 'longitude': destination.longitude},
        'originAddress': originAddress,
        'destinationAddress': destinationAddress,
        'vehicleTypeId': vehicleTypeId,
        'estimatedFare': estimatedFare.replaceAll('₺', ''),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Yolculuk talebi oluşturulamadı.');
    }
  }

  // --- PUANLAMA (GÜNCEL) ---
  Future<Map<String, dynamic>> rateRide({
    required String rideId,
    String? comment,
    required Map<String, int> additionalRatings,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/rides/$rideId/rate');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'x-auth-token': token ?? ''
      },
      body: jsonEncode({
        'driving_quality': additionalRatings['drivingQuality'],
        'politeness': additionalRatings['politeness'],
        'cleanliness': additionalRatings['cleanliness'],
        'comment': comment,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Puanlama yapılamadı.');
    }
  }

  // --- İPTAL ETME ---
  Future<void> cancelRide(String rideId) async {
    final token = await getToken();
    final url = Uri.parse('$_baseUrl/rides/$rideId/cancel-by-user');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'x-auth-token': token ?? ''
      },
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'İptal edilemedi.');
    }
  }

  // --- GOOGLE MAPS API ---
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$_googleApiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
        return 'Adres detayı bulunamadı.';
      }
      return 'Adres alınamadı (Sunucu Hatası).';
    } catch (e) {
      return 'Adres alınamadı (Ağ Hatası).';
    }
  }

  Future<List<PlaceSuggestion>> fetchSuggestions(String input, String sessionToken) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&sessiontoken=$sessionToken&components=country:tr');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        return result['predictions']
            .map<PlaceSuggestion>((p) => PlaceSuggestion.fromJson(p))
            .toList();
      }
      return [];
    } else {
      throw Exception('Adres önerileri alınamadı.');
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId, String sessionToken) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey&sessiontoken=$sessionToken&fields=formatted_address,geometry');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        final Map<String, dynamic> place = {
          'address': result['result']['formatted_address'],
          'lat': result['result']['geometry']['location']['lat'],
          'lng': result['result']['geometry']['location']['lng'],
        };
        return place;
      }
      throw Exception('Adres detayı bulunamadı.');
    } else {
      throw Exception('Adres detayı alınamadı.');
    }
  }

  Future<Map<String, dynamic>> getDirections(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleApiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        return {
          'polyline_points': route['overview_polyline']['points'],
          'distance': leg['distance']['text'],
          'duration': leg['duration']['text'],
          'distance_value': leg['distance']['value'],
        };
      }
      throw Exception('Rota bulunamadı. Status: ${data['status']}');
    } else {
      throw Exception('Rota bilgisi alınamadı.');
    }
  }
}
