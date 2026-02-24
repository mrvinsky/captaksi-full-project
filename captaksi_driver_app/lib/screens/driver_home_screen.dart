import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../widgets/offline_status_panel.dart';
import '../widgets/ride_request_list.dart';
import '../widgets/ongoing_trip_panel.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'rate_passenger_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool isOnline = false;
  bool isLoading = false;
  bool goingToPickup = false;
  bool goingToDestination = false;

  Position? currentPosition;
  GoogleMapController? mapController;

  Map<String, dynamic>? activeRide;
  List<Map<String, dynamic>> rideRequests = [];

  final ApiService api = ApiService();
  final SocketService socket = SocketService();

  late StreamSubscription rideSub;
  Timer? locationTimer;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  String driverRating = "5.0";

  static const CameraPosition initialCam = CameraPosition(
    target: LatLng(39.9334, 32.8597),
    zoom: 6,
  );

  @override
  void initState() {
    super.initState();
    rideSub = socket.rideRequests.listen((data) {
      if (!goingToPickup && !goingToDestination) {
        setState(() => rideRequests.insert(0, data));
      }
    });
  }

  Future<void> fetchStats() async {
    try {
      final res = await api.getDriverStats();
      setState(() => driverRating = res['puan_ortalamasi']?.toString() ?? "5.0");
    } catch (_) {}
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    rideSub.cancel();
    socket.dispose();
    super.dispose();
  }

  // ---------------- LOCATION & STATUS ----------------
  Future<void> toggleOnline() async {
    setState(() => isLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final newStatus = !isOnline;

      await api.updateDriverStatus(newStatus, pos.latitude, pos.longitude);
      if (mounted) setState(() {
          isOnline = newStatus;
          currentPosition = pos;
      });

      if (newStatus) {
        _animateToCurrentPosition();
        await socket.connectAndListen();
        _startLocationUpdates();
        fetchStats();
      } else {
        locationTimer?.cancel();
        socket.dispose();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startLocationUpdates() {
    locationTimer?.cancel();
    locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!isOnline) return;
      try {
        final pos = await Geolocator.getCurrentPosition();
        await api.updateDriverStatus(true, pos.latitude, pos.longitude);
        setState(() => currentPosition = pos);
      } catch (_) {}
    });
  }

  void _animateToCurrentPosition() {
    if (mapController != null && currentPosition != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(currentPosition!.latitude, currentPosition!.longitude), 15));
    }
  }

  // ---------------- RIDE LOGIC ----------------
  LatLng getCoord(Map<String, dynamic> ride, String prefix) {
    try {
      if (ride['${prefix}_lat'] != null && ride['${prefix}_lng'] != null) {
        return LatLng(double.parse(ride['${prefix}_lat'].toString()), double.parse(ride['${prefix}_lng'].toString()));
      }
      return const LatLng(0, 0);
    } catch (_) { return const LatLng(0, 0); }
  }

  Future<void> drawRoute(LatLng a, LatLng b, {String id = "route", Color color = Colors.amber}) async {
    try {
      final route = await api.getDirections(a, b);
      final pts = PolylinePoints().decodePolyline(route['polyline_points']);
      final latlng = pts.map((e) => LatLng(e.latitude, e.longitude)).toList();
      setState(() {
        polylines.removeWhere((p) => p.polylineId.value == id);
        polylines.add(Polyline(polylineId: PolylineId(id), points: latlng, width: 6, color: color));
      });
    } catch (e) {
      setState(() => polylines.add(Polyline(polylineId: PolylineId(id), points: [a, b], width: 4, color: color.withOpacity(0.5))));
    }
  }

  Future<void> acceptRide(Map<String, dynamic> ride) async {
    try {
      final res = await api.acceptRide("${ride['id']}");
      setState(() {
        activeRide = res['ride'];
        rideRequests.clear();
        goingToPickup = true;
        polylines.clear();
        markers.clear();
      });

      final driver = LatLng(currentPosition!.latitude, currentPosition!.longitude);
      final pickup = getCoord(activeRide!, 'baslangic');
      final dest = getCoord(activeRide!, 'bitis');

      drawRoute(driver, pickup, id: "toPickup", color: Colors.blue);
      drawRoute(pickup, dest, id: "toDest", color: Colors.amber);

      markers.add(Marker(markerId: const MarkerId("pickup"), position: pickup, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)));
      markers.add(Marker(markerId: const MarkerId("dest"), position: dest, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)));
      _animateToCurrentPosition();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> notifyArrival() async {
    try { await api.notifyArrival("${activeRide!['id']}"); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yolcuya bildirim gönderildi! 🔔"))); } catch (e) {}
  }

  Future<void> startTrip() async {
    try {
      await api.startRide("${activeRide!['id']}");
      setState(() { polylines.removeWhere((p) => p.polylineId.value == "toPickup"); markers.removeWhere((m) => m.markerId.value == "pickup"); goingToPickup = false; goingToDestination = true; });
    } catch (e) {}
  }

  Future<void> finishTrip() async {
    try {
      await api.completeRide("${activeRide!['id']}");
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RatePassengerScreen(rideId: "${activeRide!['id']}", passengerName: "${activeRide!['yolcu_adi'] ?? 'Yolcu'}")));
    } catch (e) {}
  }

  // ---------------- UI BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isOnline ? _buildOnlineView() : OfflineStatusPanel(isLoading: isLoading, onToggle: toggleOnline),
    );
  }

  Widget _buildOnlineStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          const Text("Çevrimiçi", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(width: 15),
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(driverRating, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildOnlineView() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: initialCam,
          myLocationEnabled: true,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          markers: markers,
          polylines: polylines,
          onMapCreated: (c) {
            mapController = c;
            c.setMapStyle(_darkMapStyle); // Daha dengeli premium stil aktif edildi
          },
        ),

        // Premium Profil Butonu (Sol Üst)
        Positioned(
          top: 60,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
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

        // Online Durum Başlığı (Üst Orta)
        Positioned(
          top: 60,
          left: 80,
          right: 80,
          child: Center(child: _buildOnlineStatusHeader()),
        ),
        
        // Floating Controls
        Positioned(
          right: 20,
          bottom: (goingToPickup || goingToDestination) ? 280 : 250,
          child: Column(
            children: [
               FloatingActionButton(
                heroTag: 'loc',
                mini: true,
                backgroundColor: const Color(0xFF1E1E2C),
                child: const Icon(Icons.my_location, color: Colors.amber),
                onPressed: _animateToCurrentPosition,
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'toggle',
                mini: true,
                backgroundColor: Colors.redAccent.withOpacity(0.8),
                child: const Icon(Icons.power_settings_new, color: Colors.white),
                onPressed: toggleOnline,
              ),
            ],
          ),
        ),

        // Bottom Panels
        if (!goingToPickup && !goingToDestination)
          Positioned(left: 0, right: 0, bottom: 0, child: RideRequestList(rideRequests: rideRequests, onAccept: acceptRide, onReject: (r) => setState(() => rideRequests.remove(r))))
        else if (activeRide != null)
          OngoingTripPanel(
            activeRide: activeRide!,
            goingToPickup: goingToPickup,
            onChat: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(receiverId: activeRide!['kullanici_id'], receiverName: activeRide!['yolcu_adi'] ?? 'Yolcu', socketService: socket))),
            onNotifyArrival: notifyArrival,
            onAction: goingToPickup ? startTrip : finishTrip,
          ),
      ],
    );
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
