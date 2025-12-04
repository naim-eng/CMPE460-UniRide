import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rating_screen.dart';

const Color kScreenTeal = Color(0xFFE0F9FB);
const Color kUniRideTeal1 = Color(0xFF00BCC9);
const Color kUniRideTeal2 = Color(0xFF009DAE);
const Color kUniRideYellow = Color(0xFFFFC727);

class DriverRideDetailsScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideData;

  const DriverRideDetailsScreen({
    super.key,
    required this.rideId,
    required this.rideData,
  });

  @override
  State<DriverRideDetailsScreen> createState() => _DriverRideDetailsScreenState();
}

class _DriverRideDetailsScreenState extends State<DriverRideDetailsScreen> {
  List<Map<String, dynamic>> acceptedPassengers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAcceptedPassengers();
  }

  Future<void> _loadAcceptedPassengers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('rideId', isEqualTo: widget.rideId)
          .where('status', isEqualTo: 'accepted')
          .get();

      setState(() {
        acceptedPassengers = snapshot.docs
            .map((doc) => {
                  'requestId': doc.id,
                  ...doc.data(),
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading passengers: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _endRide() async {
    if (acceptedPassengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No passengers to rate')),
      );
      return;
    }

    // Extract passenger info for rating
    final usersToRate = acceptedPassengers.map((passenger) {
      return {
        'userId': passenger['passengerId'],
        'name': passenger['passengerName'] ?? 'Passenger',
      };
    }).toList();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RatingScreen(
            rideId: widget.rideId,
            isDriver: true,
            usersToRate: usersToRate,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.rideData['from'] ?? 'Unknown';
    final to = widget.rideData['to'] ?? 'Unknown';
    final date = widget.rideData['date'] ?? 'N/A';
    final time = widget.rideData['time'] ?? 'N/A';
    final price = (widget.rideData['price'] ?? 0).toString();
    final seatsValue = widget.rideData['seats'] ?? 0;
    final totalSeatsNum = seatsValue is int ? seatsValue : (seatsValue is double ? seatsValue.toInt() : int.tryParse(seatsValue.toString()) ?? 0);
    final distanceKm = widget.rideData['distanceKm']?.toStringAsFixed(1) ?? '?';
    final durationMinutes = widget.rideData['durationMinutes'] ?? '?';

    return Scaffold(
      backgroundColor: kScreenTeal,
      appBar: AppBar(
        backgroundColor: kScreenTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kUniRideTeal2),
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kUniRideTeal2),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Route",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _rideInfoRow("From", from),
                        const SizedBox(height: 8),
                        _rideInfoRow("To", to),
                        const Divider(height: 20),
                        _rideInfoRow("Date", date),
                        _rideInfoRow("Time", time),
                        _rideInfoRow("Distance", "$distanceKm km"),
                        _rideInfoRow("Duration", "$durationMinutes min"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ride Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ride Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _rideInfoRow("Total Seats", totalSeatsNum.toString()),
                        _rideInfoRow("Booked Seats", "${acceptedPassengers.length}"),
                        _rideInfoRow("Available Seats", "${totalSeatsNum - acceptedPassengers.length}"),
                        const Divider(height: 20),
                        _rideInfoRow("Price per Seat", "BD $price"),
                        _rideInfoRow("Total Earnings", "BD ${(double.parse(price) * acceptedPassengers.length).toStringAsFixed(2)}"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Passengers Section
                  const Text(
                    "Booked Passengers",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (acceptedPassengers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "No passengers booked yet",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: acceptedPassengers.map((passenger) {
                        return _passengerCard(passenger);
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // End Ride Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: acceptedPassengers.isEmpty ? null : _endRide,
                      icon: const Icon(Icons.flag, size: 20),
                      label: const Text("End Ride"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kUniRideYellow,
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _rideInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _passengerCard(Map<String, dynamic> passenger) {
    final name = passenger['passengerName'] ?? 'Passenger';
    final email = passenger['passengerEmail'] ?? 'N/A';
    final seats = passenger['seats'] ?? 1;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: kUniRideTeal1,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'P',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kUniRideTeal2.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kUniRideTeal2, width: 1),
            ),
            child: Text(
              "$seats seat${seats > 1 ? 's' : ''}",
              style: const TextStyle(
                color: kUniRideTeal2,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
