import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../services/api_service.dart';
import '../services/socket_service.dart';
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

  static const CameraPosition initialCam = CameraPosition(
    target: LatLng(41.0082, 28.9784),
    zoom: 11,
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

  // ---------------- STATE ----------------
  String driverRating = "0.0";

  Future<void> fetchStats() async {
    try {
      final res = await api.getDriverStats();
      setState(() {
        driverRating = res['puan_ortalamasi']?.toString() ?? "5.0";
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    rideSub.cancel();
    socket.dispose();
    super.dispose();
  }

  // ---------------- LOCATION ----------------
  Future<Position> determinePos() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Konum servisleri kapalı.");

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied)
      throw Exception("Konum izni verilmedi.");
    if (perm == LocationPermission.deniedForever)
      throw Exception("Kalıcı engel.");

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() => currentPosition = pos);
    return pos;
  }

  void animateToLocation() {
    if (mapController == null || currentPosition == null) return;
    mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        15,
      ),
    );
  }

  // ---------------- ONLINE TOGGLE ----------------
  Future<void> toggleOnline() async {
    setState(() => isLoading = true);

    try {
      final pos = await determinePos();
      final newStatus = !isOnline;

      await api.updateDriverStatus(newStatus, pos.latitude, pos.longitude);

      if (mounted) setState(() => isOnline = newStatus);

      if (newStatus) {
        animateToLocation();
        await socket.connectAndListen();
        startLocationUpdates();
        fetchStats(); // Puanı çek
      } else {
        locationTimer?.cancel();
        socket.dispose();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void startLocationUpdates() {
    locationTimer?.cancel();
    locationTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      if (!isOnline) return;
      try {
        final pos = await Geolocator.getCurrentPosition();
        await api.updateDriverStatus(true, pos.latitude, pos.longitude);
        setState(() => currentPosition = pos);
      } catch (_) {}
    });
  }

  // ---------------- MAP HELPERS ----------------
  LatLng getCoord(Map<String, dynamic> ride, String prefix) {
    try {
      // 1. Önce ayrı sütunlara bak (lat, lng)
      if (ride['${prefix}_lat'] != null && ride['${prefix}_lng'] != null) {
        return LatLng(
          double.parse(ride['${prefix}_lat'].toString()),
          double.parse(ride['${prefix}_lng'].toString()),
        );
      }
      
      // 2. GeoJSON String formatı (eski yapı)
      if (ride['${prefix}_konumu'] != null) {
         var data = jsonDecode(ride['${prefix}_konumu'])['coordinates'];
         return LatLng(data[1], data[0]); 
      }
      return const LatLng(0, 0);
    } catch (_) {
      return const LatLng(0, 0);
    }
  }

  Future<void> drawRoute(LatLng a, LatLng b,
      {String id = "route", Color color = Colors.blue}) async {
    List<LatLng> latlng = [];
    try {
      final route = await api.getDirections(a, b);
      final encoded = route['polyline_points'];
      final pts = PolylinePoints().decodePolyline(encoded);
      latlng = pts.map((e) => LatLng(e.latitude, e.longitude)).toList();
    } catch (e) {
      debugPrint("Harita API Hatası (Fallback düz çizgi kullanılıyor): $e");
      // Fallback: Düz çizgi (Start -> End)
      latlng = [a, b];
    }

    if (latlng.isNotEmpty) {
      if (mounted) {
        setState(() {
          // Eski rotayı sil (aynı ID varsa)
          polylines.removeWhere((p) => p.polylineId.value == id);
          
          polylines.add(
            Polyline(
              polylineId: PolylineId(id),
              points: latlng,
              width: 5,
              color: color,
            ),
          );
        });
      }
    }
  }

  // ---------------- POPUP ----------------
  void showRidePopup(Map<String, dynamic> ride) {
    if (currentPosition == null) return;

    final pickup = getCoord(ride, 'baslangic');

    final distance = Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          pickup.latitude,
          pickup.longitude,
        ) /
        1000;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Yeni Yolculuk!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Alış: ${ride['baslangic_adres_metni']}"),
              Text("Varış: ${ride['bitis_adres_metni']}"),
              const SizedBox(height: 10),
              Text("Mesafe: ${distance.toStringAsFixed(1)} km"),
              Text("Kazanç: ₺${ride['gerceklesen_ucret']}"),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      child: const Text("Reddet"),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => rideRequests.remove(ride));
                      },
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      child: const Text("Kabul Et"),
                      onPressed: () async {
                        Navigator.pop(context);

                        try {
                          final res = await api.acceptRide("${ride['id']}");

                          setState(() {
                            activeRide = res['ride'];
                            rideRequests.clear();
                            goingToPickup = true;
                          });

                          final driver = LatLng(currentPosition!.latitude,
                              currentPosition!.longitude);
                          final passenger = pickup;

                          drawRoute(driver, passenger, id: "toPickup");

                          markers.clear();
                          markers.add(Marker(
                            markerId: const MarkerId("pickup"),
                            position: passenger,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen),
                          ));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }



  // ---------------- POPUP (OTOMATIK OR LIST) ----------------
  // Note: We are using list-card approach per previous user interaction.

  // ---------------- TRIP ACTIONS ----------------
  Future<void> notifyArrival() async {
    if (activeRide == null) return;
    try {
      await api.notifyArrival("${activeRide!['id']}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yolcuya bildirim gönderildi! 🔔")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> startTrip() async {
    if (activeRide == null) return;
    try { 
      await api.startRide("${activeRide!['id']}");
      
      final pickup = getCoord(activeRide!, 'baslangic');
      final dest = getCoord(activeRide!, 'bitis');

      // Pickup bittiği için Mavi rotayı temizle
      setState(() {
         polylines.removeWhere((p) => p.polylineId.value == "toPickup");
      });

      // Kırmızı: Yolcu -> Varış
      drawRoute(pickup, dest, id: "toDest", color: Colors.redAccent);

      setState(() {
        goingToPickup = false;
        goingToDestination = true;
        
        // Marker güncelle: Desinasyon kalsın, Pickup silinsin
        markers.removeWhere((m) => m.markerId.value == "pickup");
        markers.add(Marker(
          markerId: const MarkerId("dest"),
          position: dest,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      });
    } catch(e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> finishTrip() async {
    if (activeRide == null) return;
    
    try {
      // 1. Backend'e bitir isteği at
      await api.completeRide("${activeRide!['id']}");

      // 2. Rating Ekranına Git
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RatePassengerScreen(
            rideId: "${activeRide!['id']}",
            passengerName: "${activeRide!['yolcu_adi'] ?? 'Yolcu'}",
          ),
        ),
      );
      
    } catch(e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ... 

  // Inside buildTripPanel
  Widget buildTripPanel() {
    final String title =
        goingToPickup ? "YOLCUYA GİDİLİYOR" : "YOLCULUK DEVAM EDİYOR";

    final String subtitle = goingToPickup
        ? (activeRide?["baslangic_adres_metni"] ?? "")
        : (activeRide?["bitis_adres_metni"] ?? "");

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            
            // [YENİ] CHAT BUTONU
            if (activeRide != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text("MESAJ"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: const BorderSide(color: Colors.black87),
                              padding: const EdgeInsets.symmetric(vertical: 12)
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    receiverId: activeRide!['kullanici_id'],
                                    receiverName: activeRide!['yolcu_adi'] ?? 'Yolcu',
                                    socketService: socket,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Notify Arrival Button
                        if (goingToPickup) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.notifications_active),
                              label: const Text("GELDİM"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange[800],
                                side: BorderSide(color: Colors.orange[800]!),
                                padding: const EdgeInsets.symmetric(vertical: 12)
                              ),
                              onPressed: notifyArrival,
                            ),
                          )
                        ]
                      ],
                    )
                ),
              ),

            ElevatedButton(
              onPressed: goingToPickup ? startTrip : finishTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: goingToPickup ? Colors.blue : Colors.green,
                minimumSize: const Size(double.infinity, 55),
              ),
              child: Text(
                goingToPickup ? "YOLCULUĞU BAŞLAT" : "YOLCULUĞU TAMAMLA",
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to init stats in toggleOnline
  // Find toggleOnline and add fetchStats invocation:
  /*
      if (newStatus) {
        fetchStats(); // Add this
        animateToLocation();
        ...
  */


  // ---------------- UI ----------------
  Widget offlineView() {
    return Stack(
      children: [
        // ----- ARKA PLAN (Modern Dark Gradient) -----
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F172A), // Deep Blue
                Color(0xFF1E293B), // Slate 800
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.map, size: 400, color: Colors.white),
            ),
          ),
        ),

        // ----- BOTTOM PANEL -----
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B), // Card Color
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- DURUM YAZISI ---
                const Text(
                  "Şu anda çevrimdışısın",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Yolculuk almaya başlamak için aktife geç",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 30),

                // --- ONLINE BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : toggleOnline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8), // Cyan/Blue
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF38BDF8).withOpacity(0.4),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.black,
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.power_settings_new),
                              SizedBox(width: 12),
                              Text(
                                "ÇALIŞMAYA BAŞLA",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget onlineView() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: initialCam,
          myLocationEnabled: true,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          markers: markers,
          polylines: polylines,
          onMapCreated: (c) => mapController = c,
        ),

        // Konum Butonu
        Positioned(
          right: 15,
          bottom: goingToPickup || goingToDestination ? 200 : 260,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.black),
            onPressed: animateToLocation,
          ),
        ),

        // ----------- BOTTOM PANEL -----------
        (!goingToPickup && !goingToDestination)
            ? buildWaitingPanel()
            : buildTripPanel(),
      ],
    );
  }

  // Yeni yolculuk paneli
Widget buildWaitingPanel() {
  return Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF101010),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            spreadRadius: 3,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: rideRequests.isEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.local_taxi, size: 36, color: Colors.white38),
                SizedBox(height: 12),
                Text(
                  "Yeni yolculuklar bekleniyor...",
                  style: TextStyle(
                    fontSize: 18, 
                    color: Colors.white70,
                    fontWeight: FontWeight.w500
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Gelen Yolculuk Talepleri",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ...rideRequests.map((ride) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Column(
                        children: [
                          Row(
                            children: [
                              // ICON SECTION
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.location_on_rounded,
                                    color: Colors.blueAccent, size: 30),
                              ),

                              const SizedBox(width: 14),

                              // TEXT SECTION
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ride['baslangic_adres_metni'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ride['bitis_adres_metni'],
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // PRICE BADGE
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "₺${ride['gerceklesen_ucret']}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // ACTION BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() => rideRequests.remove(ride));
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(
                                        color: Colors.redAccent),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text("Reddet"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                    onPressed: () async {
                                    try {
                                      final res = await api.acceptRide("${ride['id']}");

                                      setState(() {
                                        activeRide = res['ride'];
                                        rideRequests.clear();
                                        goingToPickup = true;
                                        polylines.clear();
                                        markers.clear();
                                      });

                                      if (currentPosition != null) {
                                        final driver = LatLng(currentPosition!.latitude, currentPosition!.longitude);
                                        final passenger = getCoord(activeRide ?? ride, 'baslangic');
                                        final dest = getCoord(activeRide ?? ride, 'bitis');

                                        // 1. Mavi: Sürücü -> Yolcu
                                        drawRoute(driver, passenger, id: "toPickup", color: Colors.blueAccent);
                                        
                                        // 2. Kırmızı: Yolcu -> Varış
                                        drawRoute(passenger, dest, id: "toDest", color: Colors.redAccent);

                                        markers.clear();
                                        markers.add(Marker(
                                          markerId: const MarkerId("pickup"),
                                          position: passenger,
                                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                                        ));
                                        
                                        markers.add(Marker(
                                          markerId: const MarkerId("dest"),
                                          position: dest,
                                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                        ));
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text("Kabul Et", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                  );
                }).toList()
              ],
            ),
    ),
  );
}




  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                isOnline ? "Aktif" : "Çevrimdışı",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            if (isOnline) ...[
              const Icon(Icons.star, color: Colors.yellowAccent, size: 20),
              const SizedBox(width: 4),
              Text(
                driverRating,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
        backgroundColor: isOnline
            ? const Color(0xFF10B981) // Emerald 500
            : Colors.transparent, // Transparent for seamless look
        elevation: isOnline ? 4 : 0,
        actions: [
          IconButton(
            icon: Icon(isOnline ? Icons.pause : Icons.play_arrow),
            onPressed: isLoading ? null : toggleOnline,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              if (goingToPickup || goingToDestination) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Yolculuk sırasında profil açılamaz.")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              locationTimer?.cancel();
              socket.dispose();
              await ApiService.deleteToken();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: isOnline ? onlineView() : offlineView(),
    );
  }
}
