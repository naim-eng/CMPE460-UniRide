// lib/services/ride_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride.dart';

class RideService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---- EXISTING LOGIC (unchanged) ----
  Future<void> publishRide(Ride ride) async {
    await _db.collection("rides").doc(ride.rideId).set(ride.toMap());
  }

  // ---- NEW: Decrease seats when booking a request ----
  Future<void> bookSeat(String rideId, String passengerId) async {
    final rideRef = _db.collection("rides").doc(rideId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(rideRef);

      if (!snap.exists) return;

      final data = snap.data()!;
      int available = data["seatsAvailable"] ?? 0;

      if (available <= 0) {
        throw Exception("No seats available");
      }

      transaction.update(rideRef, {"seatsAvailable": available - 1});
    });
  }

  // ---- NEW: Increase seats when request is declined ----
  Future<void> cancelSeat(String rideId) async {
    final rideRef = _db.collection("rides").doc(rideId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(rideRef);

      if (!snap.exists) return;

      final data = snap.data()!;
      int totalSeats = data["seats"] ?? 0;
      int available = data["seatsAvailable"] ?? 0;

      // Don’t exceed total seats
      if (available < totalSeats) {
        transaction.update(rideRef, {"seatsAvailable": available + 1});
      }
    });
  }
}
