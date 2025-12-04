import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'request_confirmation_screen.dart';
import 'rating_screen.dart';

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

  Future<void> _requestToJoinRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage("Please log in to request a ride");
      return;
    }

    // Check if user is the driver
    if (widget.rideData['driverId'] == user.uid) {
      _showMessage("You cannot request your own ride");
      return;
    }

    // Check if already requested
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
      // Get passenger's full profile info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userProfile = userDoc.data() ?? {};
      final passengerPhone = userProfile['phone'] ?? '';

      // Create ride request
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
        'seats': 1, // Default: requesting 1 seat
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isRequesting = false);

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RequestConfirmationScreen(),
          ),
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

  Future<void> _finishRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if user is a passenger on this ride
    final requestSnapshot = await FirebaseFirestore.instance
        .collection('ride_requests')
        .where('rideId', isEqualTo: widget.rideId)
        .where('passengerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (requestSnapshot.docs.isNotEmpty) {
      // User is a passenger, rate the driver
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RatingScreen(
              rideId: widget.rideId,
              isDriver: false,
              usersToRate: [
                {
                  'userId': widget.rideData['driverId'],
                  'name': widget.rideData['driverName'] ?? 'Driver',
                }
              ],
            ),
          ),
        );
      }
    } else {
      _showMessage('This ride is not accepted yet');
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.rideData['driverName'] ?? 'UniRide User';
    final from = widget.rideData['from'] ?? 'Unknown';
    final to = widget.rideData['to'] ?? 'Unknown';
    final date = widget.rideData['date'] ?? 'N/A';
    final time = widget.rideData['time'] ?? 'N/A';
    final price = widget.rideData['price']?.toString() ?? '0.0';
    final seats = widget.rideData['seatsAvailable']?.toString() ?? '0';
    final distanceKm = widget.rideData['distanceKm']?.toStringAsFixed(1) ?? '?';
    final durationMin = widget.rideData['durationMinutes']?.toString() ?? '?';

    return Scaffold(
      backgroundColor: kScreenTeal,

      // ---------------- APP BAR ----------------
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
          style: TextStyle(
            color: kUniRideTeal2,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- DRIVER CARD ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: kUniRideTeal2.withOpacity(0.15),
                    child: Text(
                      driverName.isNotEmpty ? driverName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kUniRideTeal2,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.orange[300],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.rideData['driverRating']?.toString() ?? '4.5',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---------------- CAR CARD ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: 30, color: kUniRideTeal2),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Honda Civic - Blue",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "License: ABC-1234",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- ROUTE MAP PREVIEW ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kUniRideTeal2.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      "Route Overview",
                      style: TextStyle(
                        color: kUniRideTeal2,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$distanceKm km - $durationMin mins",
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ---------------- RIDE INFO TITLE ----------------
            const Text(
              "Ride Information",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // ---------------- RIDE INFO DETAILS ----------------
            _rideInfoRow("Pickup", from),
            _rideInfoRow("Destination", to),
            _rideInfoRow("Date", date),
            _rideInfoRow("Time", time),
            _rideInfoRow("Seats Available", seats),
            _rideInfoRow("Price", "BD $price"),

            const SizedBox(height: 30),

            // ---------------- ACTION BUTTON ----------------
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('ride_requests')
                  .where('rideId', isEqualTo: widget.rideId)
                  .where('passengerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                }

                final hasRequest = snapshot.data?.docs.isNotEmpty ?? false;
                final requestStatus = hasRequest
                    ? snapshot.data!.docs.first['status'] as String?
                    : null;
                final isAccepted = requestStatus == 'accepted';

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAccepted
                        ? _finishRide
                        : (_isRequesting ? null : _requestToJoinRide),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kUniRideYellow,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isRequesting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black87,
                            ),
                          )
                        : Text(
                            isAccepted ? "Finish Ride" : "Request to Join Ride",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ---------------- REUSABLE INFO ROW ----------------
  Widget _rideInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
