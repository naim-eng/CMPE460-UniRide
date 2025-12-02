import 'package:flutter/material.dart';
import 'package:uniride_app/screens/RideRequestsScreen.dart';

class MyOfferedRidesScreen extends StatelessWidget {
  const MyOfferedRidesScreen({super.key});

  // Colors
  static const Color kScreenTeal = Color(0xFFE0F9FB);
  static const Color kUniRideTeal2 = Color(0xFF009DAE);

  @override
  Widget build(BuildContext context) {
    // -------- SAMPLE DATA (UI ONLY) --------
    final List<Map<String, dynamic>> offeredRides = [
      {
        "from": "AUBH Campus",
        "to": "City Center",
        "day": "28 Nov 2025",
        "time": "2:30 PM",
        "price": "BD 2.0",
        "requests": 3,
      },
      {
        "from": "Riffa",
        "to": "Seef",
        "day": "30 Nov 2025",
        "time": "1:00 PM",
        "price": "BD 1.5",
        "requests": 1,
      },
    ];

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
          "My Offered Rides",
          style: TextStyle(
            color: kUniRideTeal2,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // -------- LIST OF OFFERED RIDES --------
            Expanded(
              child: ListView.builder(
                itemCount: offeredRides.length,
                itemBuilder: (_, index) {
                  final r = offeredRides[index];

                  return _rideCard(
                    context,
                    from: r["from"] as String,
                    to: r["to"] as String,
                    day: r["day"] as String,
                    time: r["time"] as String,
                    price: r["price"] as String,
                    requests: r["requests"] as int,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- CARD UI -------------------
  Widget _rideCard(
    BuildContext context, {
    required String from,
    required String to,
    required String day,
    required String time,
    required String price,
    required int requests,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RideRequestsScreen(
              from: from,
              to: to,
              day: day,
              time: time,
              price: price,
              requests: requests,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon circle
            CircleAvatar(
              radius: 26,
              backgroundColor: kUniRideTeal2.withOpacity(0.15),
              child: const Icon(Icons.directions_car, color: kUniRideTeal2),
            ),
            const SizedBox(width: 14),

            // Ride details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$from → $to",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$day   •   $time",
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Requests badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$requests req",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
