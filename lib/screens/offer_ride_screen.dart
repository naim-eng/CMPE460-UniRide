import 'package:flutter/material.dart';

class OfferRideScreen extends StatefulWidget {
  const OfferRideScreen({super.key});

  @override
  State<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _seatsController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // -----------------------------------
  // UniRide Colors (same as FindRide + Home)
  // -----------------------------------
  static const Color kUniRideTeal1 = Color(0xFF00BCC9);
  static const Color kUniRideTeal2 = Color(0xFF009DAE);
  static const Color kUniRideYellow = Color(0xFFFFC727);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kUniRideTeal1, kUniRideTeal2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- TITLE ----------------
                const Text(
                  "Offer a Ride",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 26),

                // ---------------- FORM CARD ----------------
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildField(
                          controller: _fromController,
                          label: "From",
                          icon: Icons.location_on_outlined,
                        ),
                        _buildField(
                          controller: _toController,
                          label: "To",
                          icon: Icons.flag_outlined,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _dateController,
                                label: "Date",
                                icon: Icons.calendar_today,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                controller: _timeController,
                                label: "Time",
                                icon: Icons.access_time,
                              ),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _seatsController,
                                label: "Seats",
                                icon: Icons.event_seat,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                controller: _priceController,
                                label: "Price (BD)",
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ---------------- SUBMIT BUTTON ----------------
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Ride created (UI only)"),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kUniRideYellow,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              shadowColor: Colors.black26,
                            ),
                            child: const Text(
                              "Publish Ride",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- CUSTOM FIELD ----------------
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) {
            if (value == null || value.isEmpty) return "Required";
            return null;
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            prefixIcon: Icon(icon, color: kUniRideTeal2),
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black54, fontSize: 15),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
