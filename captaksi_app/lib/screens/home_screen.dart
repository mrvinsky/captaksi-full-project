import 'dart:async';
import 'dart:ui' as ui;
import 'package:captaksi_app/models/driver_model.dart';
import 'package:captaksi_app/models/vehicle_type_model.dart';
import 'package:captaksi_app/services/api_service.dart';
import 'package:captaksi_app/services/socket_service.dart'; // YENİ: Yolcu Socket Servisi
import 'package:captaksi_app/screens/rating_screen.dart'; // YENİ: Puanlama Ekranı
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'address_search_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  int _selectedVehicleIndex = -1;
  late Future<List<VehicleType>> _vehicleTypesFuture;
  final Set<Marker> _driverMarkers = {};
  Timer? _driverFetchTimer;
  bool _isSelectingDestination = false;
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  Set<Marker> _markers = {};
  BitmapDescriptor _taxiIcon = BitmapDescriptor.defaultMarker;
  final ApiService _apiService = ApiService();
  final Set<Polyline> _polylines = {};
  LatLng? _originPosition;
  LatLng? _destinationPosition;
  String? _routeDistance;
  String? _routeDuration;
  int? _routeDistanceValue;
  bool _isFindingDriver = false;

  // YENİ: Yolcu Socket Servisi
  final SocketService _socketService = SocketService();
  StreamSubscription? _rideFinishedSubscription;
  StreamSubscription? _rideAcceptedSubscription; // Sürücü kabul ettiğinde

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(39.9334, 32.8597),
    zoom: 5.0,
  );

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
    _initializeMap();
    _vehicleTypesFuture = _apiService.getVehicleTypes();

    // YENİ: Socket'e bağlan ve sinyalleri dinle
    _socketService.connectAndListen();
    
    // Yolculuk bitti sinyalini dinle
    _rideFinishedSubscription = _socketService.rideFinishedStream.listen((ride) {
      print("HomeScreen: Yolculuk bitti sinyali alındı!");
      if (mounted) {
        // Puanlama ekranını göster
        _showRatingScreen(ride);
      }
    });

    // TODO: Sürücü kabul etti sinyalini dinle
    // _rideAcceptedSubscription = _socketService.rideAcceptedStream.listen((ride) {
    //   print("HomeScreen: Sürücü talebi kabul etti!");
    //   if (mounted) {
    //     // "Sürücü aranıyor" ekranını kapatıp "Sürücü geliyor" ekranını aç
    //   }
    // });
  }
  
  @override
  void dispose() {
    _driverFetchTimer?.cancel();
    _destinationController.dispose();
    _originController.dispose();
    // YENİ: Socket bağlantılarını kapat
    _socketService.dispose();
    _rideFinishedSubscription?.cancel();
    _rideAcceptedSubscription?.cancel();
    super.dispose();
  }

  // YENİ: Puanlama Ekranını Gösteren Fonksiyon
  void _showRatingScreen(Map<String, dynamic> ride) {
    // Arayüzü temizle (rotayı, pini vb. kaldır)
    setState(() {
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId.value == 'destination_pin');
      _destinationController.clear();
      _routeDistance = null;
      _routeDuration = null;
      _routeDistanceValue = null;
      _selectedVehicleIndex = -1;
      _isFindingDriver = false; // Sürücü arama durumunu sıfırla
    });

    // Puanlama ekranını bir modal sayfa olarak aç
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true, // Tam ekran modal olarak açılır
        builder: (context) => RatingScreen(finishedRide: ride),
      ),
    );
  }

  Future<void> _loadCustomIcons() async {
    _taxiIcon = await _getTaxiIconFromIconData(Icons.local_taxi, Colors.amber[700]!, 130);
  }

  Future<BitmapDescriptor> _getTaxiIconFromIconData(IconData iconData, Color color, double size) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final Radius radius = Radius.circular(size / 2);
    canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(0.0, 0.0, size, size),topLeft: radius, topRight: radius, bottomLeft: radius, bottomRight: radius,), paint);
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(text: String.fromCharCode(iconData.codePoint), style: TextStyle(fontSize: size * 0.7, fontFamily: iconData.fontFamily, color: Colors.white));
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));
    final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation(setOrigin: true);
    _startDriverFetching();
  }

  Future<void> _getCurrentLocation({bool setOrigin = false}) async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum servisleri kapalı. Lütfen açın.')));
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum izni verilmedi.')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum izinleri kalıcı olarak reddedildi, ayarları manuel olarak açmalısınız.')));
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final currentLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = position;
        if (setOrigin) {
           _originPosition = currentLatLng;
           _updateAddressFromCoordinates(currentLatLng, isOrigin: true);
           _markers.removeWhere((m) => m.markerId.value == 'origin_pin');
           _markers.add(Marker(markerId: const MarkerId('origin_pin'), position: currentLatLng, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
        }
      });
      _animateToUserLocation();
    } catch (e) {
      print("Konum alınırken hata oluştu: $e");
    }
  }

  Future<void> _fetchNearbyDrivers() async {
    if (_currentPosition == null || !mounted || _isFindingDriver) return;
    try {
      List<Driver> drivers = await _apiService.getNearbyDrivers(_currentPosition!);
      setState(() {
        _driverMarkers.clear();
        for (var driver in drivers) {
          _driverMarkers.add(Marker(markerId: MarkerId('driver_${driver.id}'), position: LatLng(driver.latitude, driver.longitude), icon: _taxiIcon, infoWindow: InfoWindow(title: driver.ad, snippet: 'Puan: ${driver.puanOrtalamasi}'),),);
        }
        _updateMarkers();
      });
    } catch (e) {
      print("Sürücüler çekilirken hata: $e");
    }
  }
  
  void _updateMarkers() {
    setState(() {
      _markers.clear();
      if (_isSelectingDestination) {
        final destinationPin = _markers.where((m) => m.markerId.value == 'destination_pin').firstOrNull;
        if (destinationPin != null) _markers.add(destinationPin);
      } else {
        _markers.addAll(_driverMarkers);
        final destinationPin = _markers.where((m) => m.markerId.value == 'destination_pin').firstOrNull;
        if (destinationPin != null) _markers.add(destinationPin);
      }
    });
  }

  void _startDriverFetching() {
    _fetchNearbyDrivers();
    _driverFetchTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if(!_isSelectingDestination && !_isFindingDriver) {
          _fetchNearbyDrivers();
      }
    });
  }
  
  Future<void> _onMapTapped(LatLng position) async {
    if (_isFindingDriver) return; // Sürücü aranırken haritaya dokunmayı engelle
    if (!_isSelectingDestination) return;
    _setDestination(position);
  }

  Future<void> _updateAddressFromCoordinates(LatLng position, {bool isOrigin = false}) async {
     try {
        final address = await _apiService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (mounted) {
          setState(() {
            if (isOrigin) {
              _originController.text = address;
            }
          });
        }
      } catch (e) {
        print("Adres çevirme hatası: $e");
      }
  }
  
  Future<void> _setDestination(LatLng position) async {
    final address = await _apiService.getAddressFromCoordinates(position.latitude, position.longitude);
    setState(() {
      _destinationController.text = address;
      _destinationPosition = position;
      _markers.removeWhere((m) => m.markerId.value == 'destination_pin');
      _markers.add(Marker(markerId: const MarkerId('destination_pin'), position: position, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), infoWindow: InfoWindow(title: "Hedef", snippet: address)),);
      _isSelectingDestination = false;
    });
     _updateMarkers();
     if (_originPosition != null) {
        _drawRoute(_originPosition!, position);
     }
  }

  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    try {
      final routeInfo = await _apiService.getDirections(origin, destination);
      final String encodedPolyline = routeInfo['polyline_points'];
      
      List<PointLatLng> polylineCoordinates = PolylinePoints().decodePolyline(encodedPolyline);
      List<LatLng> polylinePoints = polylineCoordinates.map((point) => LatLng(point.latitude, point.longitude)).toList();
      
      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(polylineId: const PolylineId('route'), color: Colors.blueAccent, width: 6, points: polylinePoints,));
        _routeDistance = routeInfo['distance'];
        _routeDuration = routeInfo['duration'];
        _routeDistanceValue = routeInfo['distance_value'];
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rota çizilemedi: ${e.toString()}'), backgroundColor: Colors.red,));
    }
  }

  void _animateToUserLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), zoom: 15.0,),),);
    }
  }
  
  Future<void> _openAddressSearch({required bool isOrigin}) async {
    if (_isFindingDriver) return; // Sürücü aranırken adres değiştirmeyi engelle

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressSearchScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final lat = result['lat'];
      final lng = result['lng'];
      final address = result['address'];
      final newPosition = LatLng(lat, lng);
      
      setState(() {
        if (isOrigin) {
          _originController.text = address;
          _originPosition = newPosition;
          _markers.removeWhere((m) => m.markerId.value == 'origin_pin');
          _markers.add(Marker(markerId: const MarkerId('origin_pin'), position: newPosition, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
        } else {
          _destinationController.text = address;
          _destinationPosition = newPosition;
          _markers.removeWhere((m) => m.markerId.value == 'destination_pin');
          _markers.add(Marker(markerId: const MarkerId('destination_pin'), position: newPosition, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)));
        }
      });

      if (_originPosition != null && _destinationPosition != null) {
        _drawRoute(_originPosition!, _destinationPosition!);
      }
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 15));
    }
  }

  String _calculateFare(List<VehicleType> vehicleTypes) {
    if (_selectedVehicleIndex != -1 && _routeDistanceValue != null) {
      final selectedVehicle = vehicleTypes[_selectedVehicleIndex];
      try {
        final distanceInKm = _routeDistanceValue! / 1000.0;
        final fare = (distanceInKm * double.parse(selectedVehicle.kmUcreti)) + double.parse(selectedVehicle.tabanUcret);
        return fare.toStringAsFixed(2);
      } catch (e) {
        return "0.00";
      }
    }
    return "0.00";
  }

  Future<void> _requestRide(List<VehicleType> vehicleTypes) async {
    if (_originPosition == null || _destinationPosition == null || _selectedVehicleIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen başlangıç, hedef ve araç tipi seçin.'), backgroundColor: Colors.orange,));
      return;
    }

    setState(() => _isFindingDriver = true);

    try {
      final selectedVehicle = vehicleTypes[_selectedVehicleIndex];
      final estimatedFare = _calculateFare(vehicleTypes);

      final result = await _apiService.createRide(
        origin: _originPosition!,
        destination: _destinationPosition!,
        originAddress: _originController.text,
        destinationAddress: _destinationController.text,
        vehicleTypeId: selectedVehicle.id,
        estimatedFare: estimatedFare,
      );

      print('Yolculuk talebi sonucu: $result');
      
      // Arayüzü "Sürücü Aranıyor" moduna geçir
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']), 
        backgroundColor: Colors.blue,
        duration: const Duration(minutes: 5), // Sürücü bulunana kadar açık kalsın (sembolik)
      ));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red,));
      }
      setState(() => _isFindingDriver = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: (_isSelectingDestination || _isFindingDriver) ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.person, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),),
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.black), onPressed: () async {
              await ApiService.deleteToken();
              if (mounted) {
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              }
            },)],),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _kInitialPosition,
            onMapCreated: (GoogleMapController controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
            onTap: _onMapTapped,
          ),
          
          if (_isSelectingDestination) ...[
             Positioned(top: 60, left: 20,
              child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => setState(() {
                    _isSelectingDestination = false;
                  }),),),),
          ],
          
          // Sürücü aranırken arayüzü gizle
          if (!_isSelectingDestination && !_isFindingDriver) ...[
            Positioned(bottom: MediaQuery.of(context).size.height * 0.3 + 20, right: 16,
              child: FloatingActionButton(
                onPressed: () => _getCurrentLocation(setOrigin: true),
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Colors.white,
                child: const Icon(Icons.my_location),
              ),
            ),
            Positioned(top: 100, left: 15, right: 15,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _originController, readOnly: true,
                      onTap: () => _openAddressSearch(isOrigin: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        filled: false,
                        hintText: "Nereden?", 
                        hintStyle: TextStyle(color: Colors.white54),
                        prefixIcon: Icon(Icons.my_location, color: Colors.greenAccent), 
                        border: InputBorder.none,
                      ),
                    ),
                    Divider(color: Colors.grey[700]), 
                    TextField(controller: _destinationController, readOnly: true,
                      onTap: () => _openAddressSearch(isOrigin: false),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: false,
                        hintText: "Nereye? (Arama veya Pin)",
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                        suffixIcon: IconButton(tooltip: "Haritadan Seç", icon: const Icon(Icons.push_pin_outlined, color: Colors.white70),
                          onPressed: () {
                             setState(() {
                               _isSelectingDestination = true;
                             });
                          },
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.15,
              maxChildSize: 0.6,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
                    boxShadow: [BoxShadow(blurRadius: 10.0, color: Colors.black.withOpacity(0.5))],
                  ),
                  child: FutureBuilder<List<VehicleType>>(
                    future: _vehicleTypesFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                      }
                      final vehicleTypes = snapshot.data!;
                      return Column(
                        children: [
                           Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(12)),),),
                          
                          if (_routeDistance != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Builder(
                                builder: (context) {
                                  final estimatedFare = _calculateFare(vehicleTypes);
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _infoColumn(Icons.directions_car, _routeDistance ?? '-'),
                                        _infoColumn(Icons.timer, _routeDuration ?? '-'),
                                        _infoColumn(Icons.payments, '₺$estimatedFare', isBold: true),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ),
                          
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: vehicleTypes.length,
                              itemBuilder: (BuildContext context, int index) {
                                final vehicle = vehicleTypes[index];
                                final isSelected = _selectedVehicleIndex == index;
                                return ListTile(
                                  onTap: () => setState(() => _selectedVehicleIndex = index),
                                  tileColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                                  leading: Icon(Icons.local_taxi, size: 40, color: isSelected ? Theme.of(context).primaryColor : Colors.white70),
                                  title: Text(vehicle.tipAdi, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Theme.of(context).primaryColor : Colors.white)),
                                  subtitle: Text(vehicle.aciklama, style: const TextStyle(color: Colors.white54)),
                                  trailing: Text('₺${vehicle.tabanUcret}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Theme.of(context).primaryColor : Colors.white)),
                                );
                              },
                            ),
                          ),
                          
                          if (_destinationPosition != null)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ElevatedButton(
                                onPressed: (_selectedVehicleIndex == -1 || _isFindingDriver) ? null : () => _requestRide(vehicleTypes),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 55),
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isFindingDriver 
                                    ? const CircularProgressIndicator(color: Colors.black) 
                                    : const Text('TAKSİ ÇAĞIR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            )
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ],

          // YENİ: Sürücü Aranıyor Ekranı
          if (_isFindingDriver)
            Container(
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Theme.of(context).primaryColor),
                  const SizedBox(height: 20),
                  const Text('Sürücü Aranıyor...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // TODO: Yolculuk talebini iptal etme API'sini çağır
                      setState(() => _isFindingDriver = false);
                    }, 
                    child: Text('İptal Et', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16))
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _infoColumn(IconData icon, String text, {bool isBold = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 4),
        Text(text, style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
      ],
    );
  }
}