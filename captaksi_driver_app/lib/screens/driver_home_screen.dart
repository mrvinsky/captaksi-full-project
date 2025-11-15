import 'dart:async';
import 'dart:convert';
import 'package:captaksi_driver_app/services/socket_service.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'profile_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = false;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  
  final SocketService _socketService = SocketService();
  StreamSubscription? _rideRequestSubscription;
  bool _isRideDialogShowing = false;
  
  final List<Map<String, dynamic>> _rideRequests = [];

  GoogleMapController? _mapController;
  Position? _currentPosition;
  Timer? _locationUpdateTimer;

  // YOLCULUK DURUM DEĞİŞKENLERİ
  Map<String, dynamic>? _activeRide; // Kabul edilen yolculuğun verilerini tutar
  bool _isEnrouteToPassenger = false; // Yolcuya mı gidiyor?
  bool _isEnrouteToDestination = false; // Yolcuyla hedefe mi gidiyor?

  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(41.0082, 28.9784), // İstanbul
    zoom: 11.0,
  );

  @override
  void initState() {
    super.initState();
    _rideRequestSubscription = _socketService.rideRequests.listen((ride) {
      print("Stream'den yeni yolculuk talebi geldi!");
      if (mounted && !_isEnrouteToPassenger && !_isEnrouteToDestination) {
        setState(() {
          _rideRequests.insert(0, ride);
        });
      }
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _rideRequestSubscription?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Konum servisleri kapalı.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('Konum izni verilmedi.');
    }
    
    if (permission == LocationPermission.deniedForever) throw Exception('Konum izinleri kalıcı olarak reddedildi, ayarları açın.');

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    if(mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
    return position;
  }

  void _animateToUserLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Future<void> _toggleOnlineStatus() async {
    setState(() => _isLoading = true);
    try {
      final Position position = await _determinePosition();
      final bool newStatus = !_isOnline;
      await _apiService.updateDriverStatus(newStatus, position.latitude, position.longitude);
      
      if(mounted) {
        setState(() { _isOnline = newStatus; });
      }

      if (_isOnline) {
        _animateToUserLocation();
        await _socketService.connectAndListen();
        _startSendingLocationUpdates();
      } else {
        _locationUpdateTimer?.cancel();
        _socketService.dispose();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isOnline ? 'Artık aktifsiniZ ve çağrı alabilirsiniz.' : 'Çevrimdışı oldunuz.'),
          backgroundColor: _isOnline ? Colors.green : Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startSendingLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!_isOnline || _currentPosition == null) { timer.cancel(); return; }
      try {
        final Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        await _apiService.updateDriverStatus(true, position.latitude, position.longitude);
        if(mounted) {
          setState(() => _currentPosition = position);
        }
        print("Sürücü konumu güncellendi: ${position.latitude}, ${position.longitude}");
      } catch (e) {
        print("Periyodik konum güncelleme hatası: $e");
      }
    });
  }

  // Koordinatları parse eden yardımcı fonksiyon
  LatLng _parseCoordinates(String geoJsonString) {
    try {
      var coords = jsonDecode(geoJsonString)['coordinates'];
      return LatLng(coords[1], coords[0]); // GeoJSON [lon, lat]'dır, LatLng (lat, lon) ister
    } catch (e) {
      print("Koordinat parse hatası: $e");
      return const LatLng(0, 0); // Hata durumunda geçersiz konum
    }
  }

  // Rota Çizme Fonksiyonu
  Future<void> _drawRoute(LatLng origin, LatLng destination, {String id = 'route', Color color = Colors.blueAccent}) async {
    try {
      final routeInfo = await _apiService.getDirections(origin, destination);
      final String encodedPolyline = routeInfo['polyline_points'];
      
      List<PointLatLng> polylineCoordinates = PolylinePoints().decodePolyline(encodedPolyline);
      List<LatLng> polylinePoints = polylineCoordinates.map((point) => LatLng(point.latitude, point.longitude)).toList();
      
      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: PolylineId(id),
          color: color,
          width: 6,
          points: polylinePoints,
        ));
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(
          southwest: LatLng(
            origin.latitude < destination.latitude ? origin.latitude : destination.latitude,
            origin.longitude < destination.longitude ? origin.longitude : destination.longitude,
          ),
          northeast: LatLng(
            origin.latitude > destination.latitude ? origin.latitude : destination.latitude,
            origin.longitude > destination.longitude ? origin.longitude : destination.longitude,
          ),
        ), 100.0,),);
    } catch(e) {
      print("Rota çizilirken hata: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rota çizilemedi: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }
  
  // "Yolcuyu Aldım" Butonuna Basılınca
  Future<void> _startTrip() async {
    if (_activeRide == null) return;
    
    try {
      await _apiService.startRide(_activeRide!['id'].toString());
      
      final LatLng passengerPos = _parseCoordinates(_activeRide!['baslangic_konumu']);
      final LatLng destinationPos = _parseCoordinates(_activeRide!['bitis_konumu']);

      // 2. Pipeline'ı (Yolcudan Hedefe) kırmızı renkte çiz
      _drawRoute(passengerPos, destinationPos, id: 'route_to_destination', color: Colors.redAccent);

      setState(() {
        _isEnrouteToPassenger = false;
        _isEnrouteToDestination = true;
        _markers.clear();
        _markers.add(Marker(
          markerId: const MarkerId('destination_pin'),
          position: destinationPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: "Varış Noktası", snippet: _activeRide!['bitis_adres_metni'])
        ));
      });
      
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  // "Yolculuğu Bitir" Butonuna Basılınca
  Future<void> _finishTrip() async {
    if (_activeRide == null) return;
    
    try {
      await _apiService.finishRide(_activeRide!['id'].toString());
      
      setState(() {
        _activeRide = null;
        _isEnrouteToPassenger = false;
        _isEnrouteToDestination = false;
        _polylines.clear();
        _markers.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yolculuk Tamamlandı!'), backgroundColor: Colors.green)
        );
      }
      
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }


  // Yolculuk talebi geldiğinde gösterilecek pencere
  void _showRideRequestDialog(Map<String, dynamic> ride) {
    if (!mounted || _currentPosition == null || _isRideDialogShowing) return;
    
    setState(() => _isRideDialogShowing = true);
    
    final LatLng passengerPos = _parseCoordinates(ride['baslangic_konumu']);
    final double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude, passengerPos.latitude, passengerPos.longitude);
    final String passengerDistance = "${(distanceInMeters / 1000).toStringAsFixed(1)} km";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yeni Yolculuk Talebi!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alış: ${ride['baslangic_adres_metni']}'),
              Text('Varış: ${ride['bitis_adres_metni']}'),
              const SizedBox(height: 10),
              Text('Yolcu Mesafesi: $passengerDistance', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Tahmini Kazanç: ₺${ride['gerceklesen_ucret']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('REDDET'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _rideRequests.remove(ride));
              },
            ),
            ElevatedButton(
              child: const Text('KABUL ET'),
              onPressed: () async {
                try {
                  final rideId = ride['id'].toString();
                  final result = await _apiService.acceptRide(rideId);
                  
                  Navigator.of(context).pop();
                  setState(() {
                    _activeRide = result['ride']; // Güncellenmiş yolculuk bilgisini al
                    _rideRequests.clear(); // Diğer tüm talepleri temizle
                    _isEnrouteToPassenger = true; // 1. Aşamaya geç
                  });
                  
                  // 1. Pipeline'ı (Sürücüden Yolcuya) mavi renkte çiz
                  final LatLng driverPos = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
                  _drawRoute(driverPos, passengerPos, id: 'route_to_passenger', color: Colors.blueAccent);
                  
                  // Yolcu için pin ekle
                  setState(() {
                    _markers.clear();
                    _markers.add(Marker(
                      markerId: const MarkerId('passenger_pickup'),
                      position: passengerPos,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                      infoWindow: InfoWindow(title: 'Yolcu Alış Noktası', snippet: ride['baslangic_adres_metni'])
                    ));
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yolculuk Kabul Edildi! Lütfen yolcuyu alın.'), backgroundColor: Colors.green)
                    );
                  }
                } catch(e) {
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red)
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    ).then((_) {
      if(mounted) {
        setState(() => _isRideDialogShowing = false);
      }
    });
  }

  // Çevrimdışı ekranını (büyük buton) oluşturan fonksiyon
  Widget _buildOfflineView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: SizedBox(
          width: 200,
          height: 200,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _toggleOnlineStatus,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24),
              backgroundColor: _isLoading ? Colors.grey : Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, size: 70),
                      const Text(
                        'ÇALIŞMAYA BAŞLA',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Çevrimiçi (harita + alttan açılan panel) ekranını oluşturan fonksiyon
  Widget _buildOnlineView() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _kInitialPosition,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            if (_currentPosition != null) {
              _animateToUserLocation();
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _markers,
          polylines: _polylines,
        ),
        
        // Konumumu Bul Butonu
        Positioned(
          // Butonun yerini, alttaki panelin durumuna göre ayarla
          bottom: _isEnrouteToPassenger || _isEnrouteToDestination ? 220.0 : MediaQuery.of(context).size.height * 0.3 + 20, // Panelin yüksekliğine göre ayarlandı
          right: 16,
          child: FloatingActionButton(
            onPressed: _animateToUserLocation,
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location),
          ),
        ),

        // Arayüzü duruma göre değiştir
        if (!_isEnrouteToPassenger && !_isEnrouteToDestination)
          // Durum: Boşta, iş bekliyor
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.5,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0),),
                  boxShadow: [ BoxShadow(blurRadius: 10.0, color: Colors.grey.withOpacity(0.5),),],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12),),),
                    ),
                    Text(
                      _rideRequests.isEmpty ? "Yeni yolculuk talepleri bekleniyor..." : "Gelen Talepler (${_rideRequests.length})",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(),
                    Expanded(
                      child: _rideRequests.isEmpty
                          ? const Center(child: Text("Şu anda aktif bir talep yok."))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _rideRequests.length,
                              itemBuilder: (BuildContext context, int index) {
                                final ride = _rideRequests[index];
                                return ListTile(
                                  leading: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                                  title: Text('Alış: ${ride['baslangic_adres_metni']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Varış: ${ride['bitis_adres_metni']}'),
                                  trailing: Text('₺${ride['gerceklesen_ucret']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                                  onTap: () => _showRideRequestDialog(ride),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          )
        else
          // Durum: Bir yolculukta (Yolcuya gidiyor veya hedefe gidiyor)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0),),
                boxShadow: [BoxShadow(blurRadius: 10.0, color: Colors.black26,)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEnrouteToPassenger ? "YOLCUYA GİDİLİYOR" : "YOLCULUK DEVAM EDİYOR",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isEnrouteToPassenger 
                        ? (_activeRide?['baslangic_adres_metni'] ?? 'Adres yükleniyor...')
                        :( _activeRide?['bitis_adres_metni'] ?? 'Adres yükleniyor...'),
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isEnrouteToPassenger ? _startTrip : _finishTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEnrouteToPassenger ? Colors.blueAccent : Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Text(_isEnrouteToPassenger ? 'YOLCUYU ALDIM' : 'YOLCULUĞU BİTİR'),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOnline ? 'Durum: Aktif' : 'Durum: Çevrimdışı'),
        backgroundColor: _isOnline ? Colors.green[700] : Colors.blue[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            if (!_isEnrouteToPassenger && !_isEnrouteToDestination) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Yolculuk sırasında profilinize bakamazsınız.'),
                backgroundColor: Colors.orange,
              ));
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: _isOnline ? 'Çalışmayı Bitir' : 'Çalışmaya Başla',
            icon: Icon(_isOnline ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 30),
            onPressed: _isLoading || (_isEnrouteToPassenger || _isEnrouteToDestination) ? null : _toggleOnlineStatus,
          ),
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout),
            onPressed: (_isEnrouteToPassenger || _isEnrouteToDestination) ? null : () async {
              if(_isOnline) {
                try {
                  await _apiService.updateDriverStatus(false, 0, 0);
                } catch (e) {
                  print("Çıkış yaparken çevrimdışı olma hatası: $e");
                }
              }
              _locationUpdateTimer?.cancel();
              _socketService.dispose();
              await ApiService.deleteToken();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: _isOnline ? _buildOnlineView() : _buildOfflineView(),
    );
  }
}