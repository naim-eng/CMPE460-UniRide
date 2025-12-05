import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'driver_ride_details_screen.dart';
import 'ride_details_screen.dart';

const Color kScreenTeal = Color(0xFFE0F9FB);
const Color kUniRideTeal1 = Color(0xFF00BCC9);
const Color kUniRideTeal2 = Color(0xFF009DAE);
const Color kUniRideYellow = Color(0xFFFFC727);

class MyOfferedRidesScreen extends StatefulWidget {
  const MyOfferedRidesScreen({super.key});

  @override
  State<MyOfferedRidesScreen> createState() => _MyOfferedRidesScreenState();
}

class _MyOfferedRidesScreenState extends State<MyOfferedRidesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kScreenTeal,
      appBar: AppBar(
        backgroundColor: kScreenTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: kUniRideTeal2),
        centerTitle: true,
        title: const Text(
          "My Rides",
          style: TextStyle(
            color: kUniRideTeal2,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kUniRideTeal2,
          unselectedLabelColor: Colors.black54,
          indicatorColor: kUniRideTeal2,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Offered Rides"),
            Tab(text: "Requested Rides"),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please log in to view your rides"))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOfferedRidesTab(user.uid),
                _buildRequestedRidesTab(user.uid),
              ],
            ),
    );
  }

  Widget _buildOfferedRidesTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("rides")
          .where("driverId", isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kUniRideTeal2),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "You haven't offered any rides yet.",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          );
        }

        final rides = snapshot.data!.docs;

        return ListView.separated(
          itemCount: rides.length,
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = rides[index];
            final data = doc.data() as Map<String, dynamic>;

            return _rideCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildRequestedRidesTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ride_requests')
          .where('driverId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kUniRideTeal2),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No requests for your offered rides yet.",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.separated(
          itemCount: requests.length,
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>;
            final passengerId = data['passengerId'] ?? '';

            // Fetch passenger rating from users collection
            return FutureBuilder<DocumentSnapshot?>(
              future: passengerId.isNotEmpty
                  ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(passengerId)
                        .get()
                  : Future<DocumentSnapshot?>.value(null),
              builder: (context, passengerSnapshot) {
                final passengerData =
                    (passengerSnapshot.data?.data() as Map<String, dynamic>?) ??
                    {};
                final passengerRating = (passengerData['averageRating'] ?? 0)
                    .toDouble();

                return _requestCard(
                  requestId: doc.id,
                  rideId: data['rideId'] ?? '',
                  requesterName: data['passengerName'] ?? 'Unknown',
                  requesterRating: passengerRating,
                  status: data['status'] ?? 'pending',
                  from: data['from'] ?? 'Unknown',
                  to: data['to'] ?? 'Unknown',
                  date: data['date'] ?? 'N/A',
                  time: data['time'] ?? 'N/A',
                  seats: data['seats'] ?? 1,
                  price: data['price']?.toString() ?? '0.0',
                  cancellationReason: data['cancellationReason'],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _rideCard(String rideId, Map<String, dynamic> data) {
    final from = data["from"] ?? "Unknown";
    final to = data["to"] ?? "Unknown";
    final date = data["date"] ?? "—";
    final time = data["time"] ?? "—";
    final price = data["price"]?.toString() ?? "0.0";
    final seatsAvailable = data["seatsAvailable"] ?? 0;
    final status = data["status"] ?? "active";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DriverRideDetailsScreen(rideId: rideId, rideData: data),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
            // ROUTE
            Text(
              "$from → $to",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),

            // DATE / TIME
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(date, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text(time, style: const TextStyle(fontSize: 14)),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // SEATS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: seatsAvailable <= 0
                        ? Colors.red.withOpacity(0.15)
                        : kUniRideTeal2.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    seatsAvailable <= 0
                        ? "Full"
                        : "$seatsAvailable seat${seatsAvailable > 1 ? "s" : ""} left",
                    style: TextStyle(
                      color: seatsAvailable <= 0 ? Colors.red : kUniRideTeal2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // PRICE
                Text(
                  "BD $price",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kUniRideTeal2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (status == "active")
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverRideDetailsScreen(
                              rideId: rideId,
                              rideData: data,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kUniRideTeal2,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text("View Details"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelRide(rideId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.cancel),
                      label: const Text("Cancel Ride"),
                    ),
                  ),
                ],
              )
            else
              const Text(
                "Ride is completed / canceled",
                style: TextStyle(color: Colors.black45, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard({
    required String requestId,
    required String rideId,
    required String requesterName,
    required double requesterRating,
    required String status,
    required String from,
    required String to,
    required String date,
    required String time,
    required int seats,
    required String price,
    String? cancellationReason,
  }) {
    final Color statusColor;
    switch (status) {
      case "accepted":
        statusColor = Colors.green;
        break;
      case "declined":
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Driver info + status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requesterName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          requesterRating > 0
                              ? requesterRating.toStringAsFixed(1)
                              : "No rating",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  status == 'accepted'
                      ? 'Accepted'
                      : status == 'declined'
                      ? 'Declined'
                      : 'Pending',
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
          const Divider(),
          const SizedBox(height: 12),

          // Route
          Text(
            "$from → $to",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Date / Time / Seats / Price
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kUniRideTeal2.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$seats seat${seats > 1 ? "s" : ""}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: kUniRideTeal2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "BD $price",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kUniRideTeal2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Cancellation reason if cancelled
          if (status == 'cancelled' && cancellationReason != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cancellation Reason:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cancellationReason,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Action buttons
          if (status == 'accepted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewRideDetails(rideId),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('View Ride Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kUniRideTeal2,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelRequest(requestId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 0),
        ],
      ),
    );
  }

  Future<void> _cancelRide(String rideId) async {
    try {
      await FirebaseFirestore.instance.collection("rides").doc(rideId).update({
        "status": "cancelled",
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ride canceled.")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error canceling ride: $e")));
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    showDialog(
      context: context,
      builder: (_) => _CancellationReasonDialog(
        onCancel: (reason) async {
          Navigator.pop(context);

          try {
            final requestDoc = await FirebaseFirestore.instance
                .collection('ride_requests')
                .doc(requestId)
                .get();

            final requestData = requestDoc.data() ?? {};
            final seatsBooked = requestData['seats'] ?? 1;
            final rideId = requestData['rideId'] ?? '';

            // Update ride request status
            await FirebaseFirestore.instance
                .collection('ride_requests')
                .doc(requestId)
                .update({
                  'status': 'cancelled',
                  'cancellationReason': reason,
                  'cancelledAt': FieldValue.serverTimestamp(),
                });

            // Increase available seats on the ride
            if (rideId.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('rides')
                  .doc(rideId)
                  .update({
                    'seatsAvailable': FieldValue.increment(seatsBooked),
                  });
            }

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Request cancelled.")));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error cancelling request: $e")),
            );
          }
        },
      ),
    );
  }

  Future<void> _viewRideDetails(String rideId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .get();
      final Map<String, dynamic> data = (doc.exists && doc.data() != null)
          ? Map<String, dynamic>.from(doc.data() as Map)
          : <String, dynamic>{};

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideDetailsScreen(rideId: rideId, rideData: data),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading ride details: $e')));
    }
  }
}

class _CancellationReasonDialog extends StatefulWidget {
  final Function(String reason) onCancel;

  const _CancellationReasonDialog({required this.onCancel});

  @override
  State<_CancellationReasonDialog> createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends State<_CancellationReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final List<String> _presetReasons = [
    "Plans changed",
    "Found another ride",
    "No longer needed",
    "Other reason",
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Cancel Request?"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please let the driver know why you're cancelling:",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ...List.generate(_presetReasons.length, (index) {
              final reason = _presetReasons[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => widget.onCancel(reason),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF009DAE),
                      side: const BorderSide(color: Color(0xFF009DAE)),
                    ),
                    child: Text(reason),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Or type your own reason...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Keep Request"),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _reasonController.text.trim().isEmpty
                ? "No reason provided"
                : _reasonController.text.trim();
            widget.onCancel(reason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text("Cancel"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
