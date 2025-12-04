import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'request_confirmation_screen.dart';
import 'rating_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;

  const RideDetailsScreen({
    super.key,
    required this.rideId,
    required this.rideData,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  static const Color kScreenTeal = Color(0xFFE0F9FB);
  static const Color kUniRideTeal2 = Color(0xFF009DAE);
  static const Color kUniRideYellow = Color(0xFFFFC727);

  bool _isRequesting = false;
  GoogleMapController? _mapController;

  void _fitMap(LatLng from, LatLng to) {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        (from.latitude <= to.latitude) ? from.latitude : to.latitude,
        (from.longitude <= to.longitude) ? from.longitude : to.longitude,
      ),
      northeast: LatLng(
        (from.latitude >= to.latitude) ? from.latitude : to.latitude,
        (from.longitude >= to.longitude) ? from.longitude : to.longitude,
      ),
    );

    Future.delayed(const Duration(milliseconds: 250), () {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
    });
  }

  Future<void> _requestToJoinRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage("Please log in to request a ride");
      return;
    }

    if (widget.rideData['driverId'] == user.uid) {
      _showMessage("You cannot request your own ride");
      return;
    }

    final existingRequest = await FirebaseFirestore.instance
        .collection('ride_requests')
        .where('rideId', isEqualTo: widget.rideId)
        .where('passengerId', isEqualTo: user.uid)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      _showMessage("You have already requested this ride");
      return;
    }

    setState(() => _isRequesting = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userProfile = userDoc.data() ?? {};
      final passengerPhone = userProfile['phone'] ?? '';

      await FirebaseFirestore.instance.collection('ride_requests').add({
        'rideId': widget.rideId,
        'passengerId': user.uid,
        'passengerName': user.displayName ?? 'UniRide User',
        'passengerEmail': user.email ?? '',
        'passengerPhone': passengerPhone,
        'driverId': widget.rideData['driverId'],
        'driverName': widget.rideData['driverName'],
        'driverPhone': widget.rideData['driverPhone'] ?? '',
        'from': widget.rideData['from'],
        'to': widget.rideData['to'],
        'date': widget.rideData['date'],
        'time': widget.rideData['time'],
        'price': widget.rideData['price'],
        'seats': 1,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isRequesting = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RequestConfirmationScreen()),
        );
      }
    } catch (e) {
      setState(() => _isRequesting = false);
      _showMessage("Error requesting ride: $e");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.rideData;

    final driverName = data['driverName'] ?? 'UniRide User';
    final driverRating = data['driverRating']?.toString() ?? '—';

    final carMake = data['vehicleMake'] ?? "Car";
    final carModel = data['vehicleModel'] ?? "";
    final carColor = data['vehicleColor'] ?? "";
    final licensePlate = data['vehicleLicensePlate'] ?? "";

    final from = data['from'] ?? 'Unknown';
    final to = data['to'] ?? 'Unknown';
    final date = data['date'] ?? 'N/A';
    final time = data['time'] ?? 'N/A';
    final price = data['price']?.toString() ?? '0.0';
    final seats = data['seatsAvailable']?.toString() ?? '0';

    final fromLat = data['fromLat'];
    final fromLng = data['fromLng'];
    final toLat = data['toLat'];
    final toLng = data['toLng'];

    final distanceKm = data['distanceKm']?.toStringAsFixed(1) ?? '?';
    final durationMin = data['durationMinutes']?.toString() ?? '?';

    LatLng? pickupPoint = (fromLat != null && fromLng != null)
        ? LatLng(fromLat, fromLng)
        : null;
    LatLng? dropoffPoint = (toLat != null && toLng != null)
        ? LatLng(toLat, toLng)
        : null;

    return Scaffold(
      backgroundColor: kScreenTeal,
      appBar: AppBar(
        backgroundColor: kScreenTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kUniRideTeal2,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Ride Details",
          style: TextStyle(color: kUniRideTeal2, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecor(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: kUniRideTeal2.withOpacity(0.15),
                    child: Text(
                      driverName[0].toUpperCase(),
                      style: const TextStyle(
                        color: kUniRideTeal2,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.orange[300]),
                          const SizedBox(width: 4),
                          Text(driverRating),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecor(),
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: 30, color: kUniRideTeal2),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$carMake $carModel - $carColor",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "License: $licensePlate",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (pickupPoint != null && dropoffPoint != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: _cardDecor(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Route Overview",
                      style: TextStyle(
                        color: kUniRideTeal2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          onMapCreated: (c) {
                            _mapController = c;
                            _fitMap(pickupPoint, dropoffPoint);
                          },
                          initialCameraPosition: CameraPosition(
                            target: pickupPoint,
                            zoom: 12,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId("from"),
                              position: pickupPoint,
                            ),
                            Marker(
                              markerId: const MarkerId("to"),
                              position: dropoffPoint,
                            ),
                          },
                          polylines: {
                            Polyline(
                              polylineId: const PolylineId("route"),
                              points: [pickupPoint, dropoffPoint],
                              color: kUniRideTeal2,
                              width: 4,
                            ),
                          },
                          zoomControlsEnabled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$distanceKm km  •  ~$durationMin mins",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            const Text(
              "Ride Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _info("Pickup", from),
            _info("Destination", to),
            _info("Date", date),
            _info("Time", time),
            _info("Seats Available", seats),
            _info("Price", "BD $price"),

            const SizedBox(height: 30),

            _actionBtn(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('ride_requests')
          .where('rideId', isEqualTo: widget.rideId)
          .where('passengerId', isEqualTo: user?.uid ?? '')
          .get(),
      builder: (context, snapshot) {
        final hasRequest = snapshot.data?.docs.isNotEmpty ?? false;
        final status = hasRequest
            ? snapshot.data!.docs.first['status'] as String?
            : null;

        final accepted = status == "accepted";

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: accepted
                ? () {}
                : (_isRequesting ? null : _requestToJoinRide),
            style: ElevatedButton.styleFrom(
              backgroundColor: kUniRideYellow,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isRequesting
                ? const CircularProgressIndicator(
                    color: Colors.black87,
                    strokeWidth: 2,
                  )
                : Text(
                    accepted ? "Finish Ride" : "Request to Join Ride",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
