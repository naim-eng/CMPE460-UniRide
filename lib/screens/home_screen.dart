import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'offer_ride_screen.dart';
import 'find_ride_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(26.0667, 50.5577); // Default Bahrain location
  LatLng? _userLocation;
  LatLng? _selectedPoint;
  bool _mapLoaded = false;

  // UniRide Colors
  static const Color kUniRideTeal2 = Color(0xFF009DAE);
  static const Color kUniRideYellow = Color(0xFFFFC727);
  static const Color kScreenTeal = Color(0xFFE0F9FB);

  @override
  void initState() {
    super.initState();
    _loadUserLocation(); // Auto-center on startup (Option A)
  }

  // -----------------------
  // USER LOCATION LOADING
  // -----------------------
  Future<void> _loadUserLocation() async {
    bool allowed = await _handleLocationPermission(context);

    if (!allowed) {
      setState(() => _mapLoaded = true);
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _userLocation = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _center = _userLocation!;
      _mapLoaded = true;
    });

    // Auto move map to the user's location
    _mapController.move(_center, 14);
  }

  Future<bool> _handleLocationPermission(BuildContext context) async {
    LocationPermission permission;

    if (!await Geolocator.isLocationServiceEnabled()) {
      _showMessage("Please enable location services.");
      return false;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        _showMessage("UniRide works best with your location enabled.");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage("Location permission permanently denied. Open Settings.");
      return false;
    }

    return true;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // -----------------------
  // UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScreenTeal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "UniRide",
                style: TextStyle(
                  color: kUniRideTeal2,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              // MAP CARD
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        //! THE MAP
                        SizedBox(
                          height: 280,
                          width: double.infinity,
                          child: !_mapLoaded
                              ? const Center(child: CircularProgressIndicator())
                              : FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _center,
                                    initialZoom: 13,
                                    onTap: (_, point) {
                                      setState(() {
                                        _selectedPoint = point;
                                      });
                                    },
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.uniride_app',
                                    ),

                                    // USER LOCATION MARKER
                                    if (_userLocation != null)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _userLocation!,
                                            child: const Icon(
                                              Icons.my_location,
                                              size: 28,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),

                                    // PIN WHERE USER TAPS
                                    if (_selectedPoint != null)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _selectedPoint!,
                                            child: const Icon(
                                              Icons.location_pin,
                                              size: 40,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                        ),

                        // ⭐ CENTER MY LOCATION BUTTON
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              if (_userLocation != null) {
                                _mapController.move(_userLocation!, 14);
                              } else {
                                _showMessage("Location not available.");
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Where do you want to go?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: kUniRideTeal2,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Choose an option to get started",
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),

              const SizedBox(height: 32),

              // OFFER RIDE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OfferRideScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kUniRideYellow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Offer a Ride",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // FIND RIDE BUTTON
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FindRideScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: kUniRideTeal2, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Find a Ride",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kUniRideTeal2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
