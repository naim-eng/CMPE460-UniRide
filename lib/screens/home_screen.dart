import 'package:flutter/material.dart';
import 'offer_ride_screen.dart';
import 'find_ride_screen.dart'; // <-- ADD THIS

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "UniRide",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              "Where do you want to go?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // Offer Ride Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OfferRideScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Offer a Ride",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Find Ride Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/find-ride');
                }, // <-- FIXED
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.teal),
                ),
                child: const Text(
                  "Find a Ride",
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
