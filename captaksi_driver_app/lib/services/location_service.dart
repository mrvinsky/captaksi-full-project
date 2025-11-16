import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Tüm konum işlemlerini yöneten merkezi servis.
/// - İzin kontrolü
/// - Anlık konum alma
/// - Aralıksız konum stream'i
/// - High accuracy mod
class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;

  StreamSubscription<Position>? _geolocatorStream;

  /// Konum iznini kontrol eder, gerekirse sorar.
  Future<bool> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }

    permission = await Geolocator.requestPermission();

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Başlangıç konumunu alır.
  Future<Position?> getInitialPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } catch (e) {
      debugPrint('İlk konum alınamadı: $e');
      return null;
    }
  }

  /// Sürücünün konumunu sürekli dinler (stream).
  void startListening() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      debugPrint('Konum izni verilmedi, dinleme başlatılamadı.');
      return;
    }

    // Eğer daha önce stream varsa temizle
    await _geolocatorStream?.cancel();

    _geolocatorStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2, // 2 metre hareket sonrası yeni lokasyon
      ),
    ).listen(
      (Position position) {
        _positionController.add(position);
      },
      onError: (e) {
        debugPrint('Konum stream hatası: $e');
      },
    );
  }

  /// Konum dinlemeyi durdur.
  Future<void> stopListening() async {
    await _geolocatorStream?.cancel();
    _geolocatorStream = null;
  }

  /// Servisi tamamen temizle.
  void dispose() {
    stopListening();
    _positionController.close();
  }
}
