// lib/models/ride.dart

class Ride {
  final String rideId;
  final String driverId;
  final String from;
  final String to;
  final String date; // Stored as string for easy display
  final String time; // Stored as string for easy display
  final int seats;
  final double price;
  final DateTime createdAt;

  Ride({
    required this.rideId,
    required this.driverId,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.seats,
    required this.price,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'driverId': driverId,
      'from': from,
      'to': to,
      'date': date,
      'time': time,
      'seats': seats,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
