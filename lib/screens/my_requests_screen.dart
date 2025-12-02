import 'package:flutter/material.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  static const Color kScreenTeal = Color(0xFFE0F9FB);
  static const Color kUniRideTeal1 = Color(0xFF00BCC9);
  static const Color kUniRideTeal2 = Color(0xFF009DAE);

  @override
  Widget build(BuildContext context) {
    // For now, this is SAMPLE DATA – later we can replace with Firestore.
    final requests = [
      {
        "driver": "Talal AlHamer",
        "rating": "4.8",
        "car": "Honda Civic - Blue",
        "pickup": "AUBH Campus",
        "destination": "City Center",
        "time": "2:30 PM",
        "price": "BD 2.0",
        "status": "Pending",
      },
      {
        "driver": "Renad Ibrahim",
        "rating": "4.9",
        "car": "Kia Sportage - White",
        "pickup": "Manama",
        "destination": "Riffa",
        "time": "4:00 PM",
        "price": "BD 3.0",
        "status": "Accepted",
      },
      {
        "driver": "Sultan Ali",
        "rating": "4.5",
        "car": "Toyota Corolla - Gray",
        "pickup": "AUBH Campus",
        "destination": "Isa Town",
        "time": "5:15 PM",
        "price": "BD 1.5",
        "status": "Declined",
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
          "My Requests",
          style: TextStyle(
            color: kUniRideTeal2,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: requests.isEmpty
            ? const Center(
                child: Text(
                  "You haven't requested any rides yet.",
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.separated(
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final r = requests[index];
                  return _requestCard(
                    driver: r["driver"] as String,
                    rating: r["rating"] as String,
                    car: r["car"] as String,
                    pickup: r["pickup"] as String,
                    destination: r["destination"] as String,
                    time: r["time"] as String,
                    price: r["price"] as String,
                    status: r["status"] as String,
                  );
                },
              ),
      ),
    );
  }

  Widget _requestCard({
    required String driver,
    required String rating,
    required String car,
    required String pickup,
    required String destination,
    required String time,
    required String price,
    required String status,
  }) {
    final Color statusColor;
    switch (status) {
      case "Accepted":
        statusColor = Colors.green;
        break;
      case "Declined":
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = kUniRideTeal2;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver + rating + status
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kUniRideTeal1,
                child: Text(
                  driver[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      car,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            "$pickup → $destination",
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kUniRideTeal2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
