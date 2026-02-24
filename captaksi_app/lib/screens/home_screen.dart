import 'dart:async';
import 'dart:ui' as ui;
import 'package:captaksi_app/models/driver_model.dart';
import 'package:captaksi_app/models/vehicle_type_model.dart';
import 'package:captaksi_app/screens/paytr_webview_screen.dart';
import 'package:captaksi_app/services/api_service.dart';
import 'package:captaksi_app/services/socket_service.dart';
import 'package:captaksi_app/screens/rating_screen.dart';
import 'package:captaksi_app/screens/chat_screen.dart';
import 'package:captaksi_app/widgets/address_input_header.dart';
import 'package:captaksi_app/widgets/ride_selection_sheet.dart';
import 'package:captaksi_app/widgets/active_ride_panel.dart';
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
  Map<String, dynamic>? _acceptedRide;
  int? _pendingRideId; // To track the ride while searching

  final SocketService _socketService = SocketService();
  StreamSubscription? _rideFinishedSubscription;
  StreamSubscription? _rideAcceptedSubscription;
  StreamSubscription? _driverArrivedSubscription;
  StreamSubscription? _rideStartedSubscription;
  StreamSubscription? _rideCancelledSubscription;
  String _rideStatusText = "";

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
    _socketService.connectAndListen();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _rideFinishedSubscription = _socketService.rideFinishedStream.listen((ride) {
      if (mounted) _showRatingScreen(ride);
    });

    _rideAcceptedSubscription = _socketService.rideAcceptedStream.listen((data) {
      if (mounted) {
        setState(() {
          _isFindingDriver = false;
          _acceptedRide = data;
          _rideStatusText = "Sürücü Geliyor";
        });
        
        try {
            final driverLat = double.parse(data['driver']['latitude'].toString());
            final driverLng = double.parse(data['driver']['longitude'].toString());
            final driverPos = LatLng(driverLat, driverLng);
            if (_originPosition != null && _destinationPosition != null) {
                _drawDualRoutes(driverPos, _originPosition!, _destinationPosition!);
            }
        } catch (e) {
            print("Rota çizimi için koordinat hatası: $e");
        }
      }
    });

    _driverArrivedSubscription = _socketService.driverArrivedStream.listen((data) {
        if (mounted) setState(() => _rideStatusText = "Sürücü Kapıda!");
    });

    _rideStartedSubscription = _socketService.rideStartedStream.listen((data) {
        if (mounted) {
            setState(() {
                _rideStatusText = "Yolculuk Başladı";
                _polylines.removeWhere((p) => p.polylineId.value == 'driver_to_pickup');
            });
        }
    });

    _rideCancelledSubscription = _socketService.rideCancelledStream.listen((data) {
        if (mounted) {
            _resetToInitialState();
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("⚠️ ${data['message'] ?? 'Yolculuk iptal edildi.'}"), backgroundColor: Colors.red),
            );
        }
    });
  }

  @override
  void dispose() {
    _driverFetchTimer?.cancel();
    _destinationController.dispose();
    _originController.dispose();
    _socketService.dispose();
    _rideFinishedSubscription?.cancel();
    _rideAcceptedSubscription?.cancel();
    _driverArrivedSubscription?.cancel();
    _rideStartedSubscription?.cancel();
    _rideCancelledSubscription?.cancel();
    super.dispose();
  }

  void _showRatingScreen(Map<String, dynamic> ride) {
    _resetToInitialState();
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
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
      print("Konum hatası: $e");
    }
  }

  void _startDriverFetching() {
    _fetchNearbyDrivers();
    _driverFetchTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if(!_isSelectingDestination && !_isFindingDriver && _acceptedRide == null) {
          _fetchNearbyDrivers();
      }
    });
  }

  Future<void> _fetchNearbyDrivers() async {
    if (_currentPosition == null || !mounted || _isFindingDriver || _acceptedRide != null) return;
    try {
      List<Driver> drivers = await _apiService.getNearbyDrivers(_currentPosition!);
      setState(() {
        _driverMarkers.clear();
        for (var driver in drivers) {
          _driverMarkers.add(Marker(markerId: MarkerId('driver_${driver.id}'), position: LatLng(driver.latitude, driver.longitude), icon: _taxiIcon));
        }
        _updateMarkers();
      });
    } catch (e) {
      print("Sürücü çekme hatası: $e");
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value.startsWith('driver_'));
      if (!_isSelectingDestination && _acceptedRide == null) {
        _markers.addAll(_driverMarkers);
      }
    });
  }

  void _resetToInitialState() {
      setState(() {
          _polylines.clear();
          _markers.removeWhere((m) => m.markerId.value == 'destination_pin');
          _destinationController.clear();
          _routeDistance = null;
          _routeDuration = null;
          _routeDistanceValue = null;
          _selectedVehicleIndex = -1;
          _isFindingDriver = false;
          _acceptedRide = null;
          _rideStatusText = "";
          _pendingRideId = null;
      });
      _fetchNearbyDrivers();
  }

  Future<void> _cancelRide() async {
      final rideId = _acceptedRide != null ? _acceptedRide!['ride']['id'] : _pendingRideId;
      if (rideId == null) return;
      
      try {
          await _apiService.cancelRide(rideId.toString());
          _resetToInitialState();
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yolculuk iptal edildi.")));
      } catch (e) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("İptal Hatası: $e")));
      }
  }

  Future<void> _updateAddressFromCoordinates(LatLng position, {bool isOrigin = false}) async {
      try {
        final address = await _apiService.getAddressFromCoordinates(position.latitude, position.longitude);
        if (mounted) setState(() => isOrigin ? _originController.text = address : null);
      } catch (e) {}
  }

  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    try {
      final routeInfo = await _apiService.getDirections(origin, destination);
      final coordinates = PolylinePoints().decodePolyline(routeInfo['polyline_points']);
      List<LatLng> points = coordinates.map((p) => LatLng(p.latitude, p.longitude)).toList();
      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(polylineId: const PolylineId('route'), color: Colors.blueAccent, width: 6, points: points));
        _routeDistance = routeInfo['distance'];
        _routeDuration = routeInfo['duration'];
        _routeDistanceValue = routeInfo['distance_value'];
      });
      _fitMapToRoute(origin, destination);
    } catch(e) {}
  }

  void _fitMapToRoute(LatLng origin, LatLng destination) {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(
        southwest: LatLng(origin.latitude < destination.latitude ? origin.latitude : destination.latitude, origin.longitude < destination.longitude ? origin.longitude : destination.longitude),
        northeast: LatLng(origin.latitude > destination.latitude ? origin.latitude : destination.latitude, origin.longitude > destination.longitude ? origin.longitude : destination.longitude),
      ), 100.0));
  }

  Future<void> _drawDualRoutes(LatLng driverLoc, LatLng pickupLoc, LatLng destLoc) async {
    setState(() => _polylines.clear());
    // Simplified for logic brevity, actual implementation can chain multiple directions calls
    _drawRoute(pickupLoc, destLoc); // Draw the main route
    // Could add driver-to-pickup polyline here if desired
  }

  void _animateToUserLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131D), // Dark background for gaps
      body: Stack(
        children: [
          _buildMap(),
          _buildAddressHeader(),
          _buildBottomPanel(),
          
          // Profil Butonu
          if (_acceptedRide == null && !_isFindingDriver)
            Positioned(
              top: 60,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                child: Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.person, color: Colors.amber, size: 24),
                ),
              ),
            ),

          // Konumum Butonu
          if (_acceptedRide == null && !_isFindingDriver)
            Positioned(
              bottom: 300, // RideSelectionSheet'in üzerinde kalması için ayarlandı
              right: 20,
              child: FloatingActionButton(
                heroTag: "my_location_btn",
                mini: true,
                backgroundColor: const Color(0xFF1E1E2C),
                child: const Icon(Icons.my_location, color: Colors.amber),
                onPressed: _animateToUserLocation,
              ),
            ),

          if (_isFindingDriver) _buildFindingDriverOverlay(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: _kInitialPosition,
      onMapCreated: (controller) {
        _mapController = controller;
        controller.setMapStyle(_darkMapStyle); // Daha dengeli premium stil aktif edildi
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: _markers,
      polylines: _polylines,
      onTap: (pos) => _isSelectingDestination ? _setDestination(pos) : null,
    );
  }

  Widget _buildAddressHeader() {
    if (_acceptedRide != null || _isFindingDriver) return const SizedBox.shrink();
    return Positioned(
      top: 125, // Profil butonu için yer ayrıldı
      left: 15, right: 15,
      child: AddressInputHeader(
        originController: _originController,
        destinationController: _destinationController,
        onOriginTap: () => _openAddressSearch(isOrigin: true),
        onDestinationTap: () => _openAddressSearch(isOrigin: false),
        onPinTap: () => setState(() => _isSelectingDestination = true),
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (_acceptedRide != null) {
      return Positioned(
        left: 0, right: 0, bottom: 0,
        child: ActiveRidePanel(
          acceptedRide: _acceptedRide!,
          rideStatusText: _rideStatusText,
          onCancelToggle: _cancelRide,
          onChatTap: () => Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                receiverId: int.parse(_acceptedRide!['driver']['id'].toString()), 
                receiverName: "${_acceptedRide!['driver']['ad']} ${_acceptedRide!['driver']['soyad']}",
                socketService: _socketService,
              ),
            ),
          ),
        ),
      );
    }

    if (_isSelectingDestination) {
        return Positioned(
            bottom: 40, left: 20, right: 20,
            child: ElevatedButton(
                onPressed: () => setState(() => _isSelectingDestination = false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
                child: const Text("PİNİ ONAYLA", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return FutureBuilder<List<VehicleType>>(
          future: _vehicleTypesFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return RideSelectionSheet(
              scrollController: scrollController,
              vehicleTypes: snapshot.data!,
              selectedIndex: _selectedVehicleIndex,
              onVehicleSelected: (idx) => setState(() => _selectedVehicleIndex = idx),
              distance: _routeDistance,
              duration: _routeDuration,
              calculatedFare: _calculateFare(snapshot.data!),
              isFindingDriver: _isFindingDriver,
              onRideRequested: (method) => _requestRide(snapshot.data!, method),
            );
          },
        );
      },
    );
  }

  Widget _buildFindingDriverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            const SizedBox(height: 30),
            const Text('Size En Yakın Sürücüyü Buluyoruz', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Lütfen bekleyin...', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 40),
            TextButton(
              onPressed: _cancelRide,
              child: const Text('TALEBİ İPTAL ET', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  // --- Search & Set Destination Logic ---
  Future<void> _openAddressSearch({required bool isOrigin}) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressSearchScreen()));
    if (result != null && result is Map<String, dynamic>) {
        final newPos = LatLng(result['lat'], result['lng']);
        setState(() {
            if (isOrigin) { _originController.text = result['address']; _originPosition = newPos; }
            else { _destinationController.text = result['address']; _destinationPosition = newPos; }
            _markers.add(Marker(markerId: MarkerId(isOrigin ? 'origin_pin' : 'destination_pin'), position: newPos, icon: BitmapDescriptor.defaultMarkerWithHue(isOrigin ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed)));
        });
        if (_originPosition != null && _destinationPosition != null) _drawRoute(_originPosition!, _destinationPosition!);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 15));
    }
  }

  void _setDestination(LatLng pos) async {
      final addr = await _apiService.getAddressFromCoordinates(pos.latitude, pos.longitude);
      setState(() {
          _destinationController.text = addr;
          _destinationPosition = pos;
          _markers.add(Marker(markerId: const MarkerId('destination_pin'), position: pos, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)));
          _isSelectingDestination = false;
      });
      if (_originPosition != null) _drawRoute(_originPosition!, pos);
  }

  String _calculateFare(List<VehicleType> vehicleTypes) {
    if (_selectedVehicleIndex == -1 || _routeDistanceValue == null) return "0.00";
    final v = vehicleTypes[_selectedVehicleIndex];
    return ((_routeDistanceValue! / 1000.0 * double.parse(v.kmUcreti)) + double.parse(v.tabanUcret)).toStringAsFixed(2);
  }

  Future<void> _requestRide(List<VehicleType> vehicleTypes, String paymentMethod) async {
    final fareStr = _calculateFare(vehicleTypes);

    if (paymentMethod == "Kredi / Banka Kartı") {
      final double fareAmount = double.tryParse(fareStr) ?? 0.0;
      final paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayTRWebViewScreen(
            amount: fareAmount,
            orderId: "TEMP_ORDER_${DateTime.now().millisecondsSinceEpoch}",
          ),
        ),
      );

      // result null ya da false ise işlem başarısız demektir
      if (paymentResult != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ödeme işlemi iptal edildi veya başarısız oldu."),
            backgroundColor: Colors.red,
          )
        );
        return;
      }
    }

    setState(() => _isFindingDriver = true);
    try {
        final result = await _apiService.createRide(
            origin: _originPosition!, 
            destination: _destinationPosition!,
            originAddress: _originController.text, 
            destinationAddress: _destinationController.text,
            vehicleTypeId: vehicleTypes[_selectedVehicleIndex].id,
            estimatedFare: fareStr
        );
        setState(() => _pendingRideId = result['rideId']);
    } catch (e) {
        setState(() => _isFindingDriver = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  final String _darkMapStyle = '''
  [
    { "elementType": "geometry", "stylers": [ { "color": "#1e1e2c" } ] },
    { "elementType": "labels.text.fill", "stylers": [ { "color": "#8ec3b9" } ] },
    { "elementType": "labels.text.stroke", "stylers": [ { "color": "#1a3646" } ] },
    { "featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [ { "color": "#4b6878" } ] },
    { "featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [ { "color": "#64779e" } ] },
    { "featureType": "administrative.province", "elementType": "geometry.stroke", "stylers": [ { "color": "#4b6878" } ] },
    { "featureType": "landscape.man_made", "elementType": "geometry.stroke", "stylers": [ { "color": "#334e87" } ] },
    { "featureType": "landscape.natural", "elementType": "geometry", "stylers": [ { "color": "#13131d" } ] },
    { "featureType": "poi", "elementType": "geometry", "stylers": [ { "color": "#1e1e2c" } ] },
    { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [ { "color": "#6f9ba5" } ] },
    { "featureType": "poi.park", "elementType": "geometry", "stylers": [ { "color": "#13131d" } ] },
    { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [ { "color": "#3C7680" } ] },
    { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#2c2c3c" } ] },
    { "featureType": "road", "elementType": "labels.text.fill", "stylers": [ { "color": "#98a5be" } ] },
    { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#3c3c4c" } ] },
    { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [ { "color": "#1f2835" } ] },
    { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [ { "color": "#b0d5ce" } ] },
    { "featureType": "transit", "elementType": "geometry", "stylers": [ { "color": "#2f3948" } ] },
    { "featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] },
    { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#13131d" } ] },
    { "featureType": "water", "elementType": "labels.text.fill", "stylers": [ { "color": "#515c6d" } ] },
    { "featureType": "water", "elementType": "labels.text.stroke", "stylers": [ { "color": "#17263c" } ] }
  ]
  ''';
}