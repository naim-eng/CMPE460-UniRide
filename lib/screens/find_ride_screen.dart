import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'ride_details_screen.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  // UniRide colors
  static const Color kScreenTeal = Color(0xFFE0F9FB);
  static const Color kUniRideTeal2 = Color(0xFF009DAE);
  static const Color kUniRideYellow = Color(0xFFFFC727);

  // ---------------- DATE PICKER ----------------
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _dateController.text = "${picked.year}/${picked.month}/${picked.day}";
    }
  }

  // ---------------- WHEEL TIME PICKER ----------------
  Future<void> _openWheelPicker({required bool isStart}) async {
    TimeOfDay selected = TimeOfDay.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                "Select Time",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: false,
                  onDateTimeChanged: (value) {
                    selected = TimeOfDay(
                      hour: value.hour,
                      minute: value.minute,
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (isStart) {
                      startTime = selected;
                    } else {
                      endTime = selected;
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  "Done",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kUniRideTeal2,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScreenTeal,

      // ---------- APP BAR WITH BACK BUTTON ----------
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
        title: const Text(
          "Find a Ride",
          style: TextStyle(
            color: kUniRideTeal2,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ---------- BODY ----------
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              const Text(
                "Enter your details to search for available rides.",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),

              const SizedBox(height: 20),

              // ---------------- PICKUP ----------------
              _inputField(
                controller: _pickupController,
                icon: Icons.location_on_outlined,
                hint: "Pickup Location",
              ),

              const SizedBox(height: 16),

              // ---------------- DATE ----------------
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: _inputField(
                    controller: _dateController,
                    icon: Icons.calendar_today_outlined,
                    hint: "Date (dd/mm/yyyy)",
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- START TIME ----------------
              GestureDetector(
                onTap: () => _openWheelPicker(isStart: true),
                child: _timeField(
                  label: "Start Time",
                  value: _formatTime(startTime),
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- END TIME ----------------
              GestureDetector(
                onTap: () => _openWheelPicker(isStart: false),
                child: _timeField(
                  label: "End Time",
                  value: _formatTime(endTime),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Available Rides",
                style: TextStyle(
                  color: kUniRideTeal2,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 14),

              // ------- RIDE CARDS WITH FIXED NAVIGATION --------
              _rideCard(
                name: "Talal AlHamer",
                rating: "4.8",
                pickup: "AUBH Campus",
                destination: "City Center",
                time: "2:00 PM",
                seats: "2 seats",
                price: "BD 2.0",
              ),

              const SizedBox(height: 12),

              _rideCard(
                name: "Renad Ibrahim",
                rating: "4.9",
                pickup: "Manama",
                destination: "Riffa",
                time: "4:00 PM",
                seats: "3 seats",
                price: "BD 3.0",
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- INPUT FIELD ----------------
  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kUniRideTeal2.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: kUniRideTeal2),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ---------------- TIME FIELD ----------------
  Widget _timeField({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kUniRideTeal2.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- RIDE CARD ----------------
  Widget _rideCard({
    required String name,
    required String rating,
    required String pickup,
    required String destination,
    required String time,
    required String seats,
    required String price,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideDetailsScreen()),
        );
      },
      child: Container(
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: kUniRideTeal2,
              child: Text(
                name[0],
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.white,
                            ),
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

                  const SizedBox(height: 6),
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
                          Text(time, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      Text(
                        seats,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kUniRideTeal2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
