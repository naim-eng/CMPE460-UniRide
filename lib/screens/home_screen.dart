import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'offer_ride_screen.dart';
import 'find_ride_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;

  final LatLng _center = const LatLng(26.0667, 50.5577); // Bahrain

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // UniRide colors
  static const Color kUniRideTeal1 = Color(0xFF00BCC9);
  static const Color kUniRideTeal2 = Color(0xFF009DAE);
  static const Color kUniRideYellow = Color(0xFFFFC727);

  // Screen background (same as OfferRide)
  static const Color kScreenTeal = Color(0xFFE0F9FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScreenTeal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- HEADER TITLE ----------------
              const Text(
                "UniRide",
                style: TextStyle(
                  color: kUniRideTeal2,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // ---------------- MAP CARD ----------------
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 270,
                    width: double.infinity,
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 12,
                      ),
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ---------------- TITLE TEXT ----------------
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  "Where do you want to go?",
                  style: TextStyle(
                    color: kUniRideTeal2,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  "Choose an option to get started",
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
              ),

              const SizedBox(height: 28),

              // ---------------- OFFER RIDE BUTTON ----------------
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
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Colors.black26,
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

              const SizedBox(height: 16),

              // ---------------- FIND RIDE BUTTON ----------------
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
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: kUniRideTeal2, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
