import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rating_screen.dart';
import 'package:uniride_app/services/rating_service.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {

  static const Color kScreenTeal = Color(0xFFE0F9FB);
  static const Color kUniRideTeal1 = Color(0xFF00BCC9);
  static const Color kUniRideTeal2 = Color(0xFF009DAE);

  Future<void> _acceptRequest(String requestId, String rideId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(requestId)
          .update({'status': 'accepted'});
      
      _showMessage("Request accepted!");
    } catch (e) {
      _showMessage("Error accepting request: $e");
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(requestId)
          .update({'status': 'declined'});
      
      _showMessage("Request declined");
    } catch (e) {
      _showMessage("Error declining request: $e");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
      body: user == null
          ? const Center(
              child: Text(
                "Please log in to view ride requests",
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ride_requests')
                  .where('driverId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kUniRideTeal2),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No ride requests yet",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Requests from passengers will appear here",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black38,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final requests = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ListView.separated(
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = requests[index];
                      final data = doc.data() as Map<String, dynamic>;
                      
                      return _requestCard(
                        requestId: doc.id,
                        rideId: data['rideId'] ?? '',
                        passengerId: data['passengerId'] ?? '',
                        passengerName: data['passengerName'] ?? 'UniRide User',
                        pickup: data['from'] ?? 'Unknown',
                        destination: data['to'] ?? 'Unknown',
                        time: data['time'] ?? 'N/A',
                        date: data['date'] ?? 'N/A',
                        price: data['price']?.toString() ?? '0.0',
                        status: data['status'] ?? 'pending',
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _requestCard({
    required String requestId,
    required String rideId,
    required String passengerId,
    required String passengerName,
    required String pickup,
    required String destination,
    required String time,
    required String date,
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
          // Passenger info + status + rating
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kUniRideTeal1,
                child: Text(
                  passengerName.isNotEmpty ? passengerName[0].toUpperCase() : 'P',
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
                      passengerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<double>(
                      future: RatingService.getAverageRating(passengerId),
                      builder: (context, snapshot) {
                        final rating = snapshot.data ?? 0.0;
                        return Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: rating > 0 ? Colors.amber : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating > 0 ? rating.toStringAsFixed(1) : "No rating",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  status == 'accepted' ? 'Accepted' : status == 'declined' ? 'Declined' : 'Pending',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: kUniRideTeal2),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pickup,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.arrow_downward, size: 16, color: Colors.black38),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(width: 16),
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
              const Spacer(),
              Text(
                "BD $price",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kUniRideTeal2,
                ),
              ),
            ],
          ),

          // Action buttons for pending requests
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _declineRequest(requestId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Decline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red[200]!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptRequest(requestId, rideId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[50],
                      foregroundColor: Colors.green[700],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.green[200]!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (status == 'accepted') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RatingScreen(
                        rideId: rideId,
                        isDriver: true,
                        usersToRate: [
                          {'userId': passengerId, 'name': passengerName}
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.flag, size: 18),
                label: const Text('Finish Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFC727),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
