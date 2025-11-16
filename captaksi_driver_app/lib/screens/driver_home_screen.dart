import 'dart:async';
import 'dart:convert';
import '../services/location_service.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

enum RidePhase {
  idle,
  enRouteToPickup,
  enRouteToDropoff,
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final Completer<GoogleMapController> _mapController = Completer();

  bool _isOnline = false;
  bool _isLoading = false;
  Position? _currentPosition;

  Timer? _locationUpdateTimer;

  // Socket'ten gelen aktif yolculuk
  Map<String, dynamic>? _activeRide;
  RidePhase _ridePhase = RidePhase.idle;

  // Harita durumları
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenRideRequests();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final newPerm = await Geolocator.requestPermission();
        if (newPerm == LocationPermission.denied ||
            newPerm == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konum izni olmadan uygulama çalışamaz.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      _moveCamera(
        LatLng(position.latitude, position.longitude),
        zoom: 15,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum alınamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _listenRideRequests() {
    _socketService.rideRequests.listen((rideData) {
      if (!mounted) return;
      if (_ridePhase != RidePhase.idle || _activeRide != null) {
        // Şimdilik sadece loglayalım; ileride "queue" mantığı eklenebilir.
        debugPrint('Yeni ride geldi ama sürücü meşgul: $rideData');
        return;
      }
      _showIncomingRideSheet(rideData);
    });
  }

  Future<void> _moveCamera(LatLng target, {double zoom = 14}) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  // ONLINE / OFFLINE
  Future<void> _toggleOnlineStatus() async {
    if (_currentPosition == null) {
      await _initLocation();
      if (_currentPosition == null) return;
    }

    final newStatus = !_isOnline;

    setState(() => _isLoading = true);

    try {
      await _apiService.updateDriverStatus(
        newStatus,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      setState(() {
        _isOnline = newStatus;
      });

      if (newStatus) {
        await _socketService.connectAndListen();
        _startSendingLocationUpdates();
      } else {
        _locationUpdateTimer?.cancel();
        _socketService.dispose();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus
              ? 'Artık aktifsiniz ve çağrı alabilirsiniz.'
              : 'Çevrimdışı oldunuz.'),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startSendingLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!_isOnline || _currentPosition == null) {
        timer.cancel();
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );

        setState(() {
          _currentPosition = position;
        });

        await _apiService.updateDriverStatus(
          true,
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        debugPrint('Konum güncellenemedi: $e');
      }
    });
  }

  // GİRİŞ / ÇIKIŞ
  Future<void> _logout() async {
    await ApiService.deleteToken();
    _socketService.dispose();
    _locationUpdateTimer?.cancel();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // RIDE AKIŞI

  void _showIncomingRideSheet(Map<String, dynamic> rideData) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final pickup = rideData['baslangic_adres_metni'] ?? 'Alış noktası';
        final dropoff = rideData['bitis_adres_metni'] ?? 'Varış noktası';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Yeni Yolculuk Talebi',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Alış: $pickup',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Varış: $dropoff',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Reddet'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _acceptRide(rideData);
                        },
                        child: const Text('Kabul Et'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _acceptRide(Map<String, dynamic> rideData) async {
    try {
      final rideId = _extractRideId(rideData);
      final response = await _apiService.acceptRide(rideId);

      // Backend ya direkt ride objesini, ya da { ride: {...} } dönebilir.
      final rideFromResponse =
          response['ride'] is Map<String, dynamic> ? response['ride'] as Map<String, dynamic> : response;

      setState(() {
        _activeRide = rideFromResponse;
        _ridePhase = RidePhase.enRouteToPickup;
      });

      await _drawRouteToPickup();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yolculuk kabul edilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _extractRideId(Map<String, dynamic> ride) {
    // Bazı endpointler { ride: {...} } şeklinde dönebilir.
    final inner = ride['ride'];
    final map = inner is Map<String, dynamic> ? inner : ride;

    final dynamicId = map['id'] ?? map['_id'] ?? map['rideId'];
    if (dynamicId == null) {
      throw Exception('Yolculuk bilgisi eksik: id alanı bulunamadı.');
    }
    return dynamicId.toString();
  }

  Future<void> _drawRouteToPickup() async {
    if (_activeRide == null || _currentPosition == null) return;

    final pickupPoint = _parseCoordinates(_activeRide!['baslangic_konumu']);
    final driverPoint =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    await _drawRoute(
      driverPoint,
      pickupPoint,
      id: 'route_to_pickup',
      color: Colors.blueAccent,
    );

    setState(() {
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickupPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: 'Yolcu Alış Noktası',
              snippet: _activeRide!['baslangic_adres_metni'] ?? '',
            ),
          ),
        );
    });

    await _moveCamera(pickupPoint, zoom: 14);
  }

  Future<void> _drawRouteToDropoff() async {
    if (_activeRide == null || _currentPosition == null) return;

    final dropoffPoint = _parseCoordinates(_activeRide!['bitis_konumu']);
    final pickupPoint = _parseCoordinates(_activeRide!['baslangic_konumu']);

    await _drawRoute(
      pickupPoint,
      dropoffPoint,
      id: 'route_to_dropoff',
      color: Colors.redAccent,
    );

    setState(() {
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: dropoffPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Varış Noktası',
              snippet: _activeRide!['bitis_adres_metni'] ?? '',
            ),
          ),
        );
    });

    await _moveCamera(dropoffPoint, zoom: 14);
  }

  LatLng _parseCoordinates(dynamic value) {
    // Backend'den "POINT(lon lat)" veya [lon, lat] gelebilir.
    if (value is String) {
      // "POINT(lon lat)" formatını çöz
      final cleaned = value
          .replaceAll('POINT', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .trim();
      final parts = cleaned.split(RegExp(r'\s+'));
      if (parts.length == 2) {
        final lon = double.tryParse(parts[0]) ?? 0;
        final lat = double.tryParse(parts[1]) ?? 0;
        return LatLng(lat, lon);
      }
    } else if (value is List && value.length == 2) {
      final lon = (value[0] as num).toDouble();
      final lat = (value[1] as num).toDouble();
      return LatLng(lat, lon);
    }

    // Fallback: Mevcut konum
    if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    return const LatLng(0, 0);
  }

  Future<void> _drawRoute(
    LatLng origin,
    LatLng destination, {
    required String id,
    required Color color,
  }) async {
    try {
      final routeData = await _apiService.getDirections(origin, destination);
      final encodedPolyline = routeData['polyline_points'] as String;
      final distanceText = routeData['distance'] as String?;
      final durationText = routeData['duration'] as String?;

      final points = polylinePoints.decodePolyline(encodedPolyline);
      final polylineCoordinates = points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(growable: false);

      setState(() {
        _polylines.removeWhere((p) => p.polylineId.value == id);
        _polylines.add(
          Polyline(
            polylineId: PolylineId(id),
            width: 5,
            color: color,
            points: polylineCoordinates,
          ),
        );
      });

      debugPrint(
          'Rota çizildi ($id) - Mesafe: $distanceText, Süre: $durationText');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rota çizilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startTrip() async {
    if (_activeRide == null) return;

    try {
      final rideId = _extractRideId(_activeRide!);
      await _apiService.startRide(rideId);
      setState(() {
        _ridePhase = RidePhase.enRouteToDropoff;
      });
      await _drawRouteToDropoff();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yolculuk başlatılamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _finishTrip() async {
    if (_activeRide == null) return;

    try {
      final rideId = _extractRideId(_activeRide!);
      await _apiService.finishRide(rideId);

      setState(() {
        _activeRide = null;
        _ridePhase = RidePhase.idle;
        _markers.clear();
        _polylines.clear();
      });

      if (_currentPosition != null) {
        await _moveCamera(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 15,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yolculuk başarıyla tamamlandı.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yolculuk bitirilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CapTaksi Sürücü'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          _buildTopStatusBar(),
          _buildBottomPanel(),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) {
      return const Center(
        child: Text('Konum alınıyor...'),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        zoom: 15,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
        }
      },
    );
  }

  Widget _buildTopStatusBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off,
                color: _isOnline ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isOnline ? 'Çevrimiçi - Çağrı alıyorsunuz' : 'Çevrimdışı',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Switch(
                value: _isOnline,
                onChanged: (_) => _toggleOnlineStatus(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: Colors.black26,
                offset: Offset(0, -4),
              ),
            ],
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: _buildRideInfoContent(),
        ),
      ),
    );
  }

  Widget _buildRideInfoContent() {
    if (_activeRide == null) {
      return const Text(
        'Aktif yolculuk yok.\nYeni çağrılar geldiğinde burada göreceksiniz.',
        textAlign: TextAlign.center,
      );
    }

    final pickup = _activeRide!['baslangic_adres_metni'] ?? 'Alış noktası';
    final dropoff = _activeRide!['bitis_adres_metni'] ?? 'Varış noktası';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _ridePhase == RidePhase.enRouteToPickup
              ? 'Yolcuya Gidiliyor'
              : 'Yolculuk Devam Ediyor',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 18),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                pickup,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.flag, size: 18),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                dropoff,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_ridePhase == RidePhase.enRouteToPickup)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startTrip,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Yolculuğu Başlat'),
                ),
              ),
            if (_ridePhase == RidePhase.enRouteToDropoff)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _finishTrip,
                  icon: const Icon(Icons.check),
                  label: const Text('Yolculuğu Bitir'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
