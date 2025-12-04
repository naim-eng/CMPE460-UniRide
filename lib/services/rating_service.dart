import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get average rating for a user
  static Future<double> getAverageRating(String userId) async {
    try {
      final query = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .get();

      if (query.docs.isEmpty) {
        return 0.0;
      }

      final total = query.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc['score'] as int? ?? 0),
      );

      return total / query.docs.length;
    } catch (e) {
      print('Error fetching average rating: $e');
      return 0.0;
    }
  }

  /// Get rating count for a user
  static Future<int> getRatingCount(String userId) async {
    try {
      final query = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .get();

      return query.docs.length;
    } catch (e) {
      print('Error fetching rating count: $e');
      return 0;
    }
  }

  /// Get rating as a stream for real-time updates
  static Stream<double> getRatingStream(String userId) {
    return _firestore
        .collection('ratings')
        .where('ratedUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      final total = snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc['score'] as int? ?? 0),
      );

      return total / snapshot.docs.length;
    });
  }

  /// Check if user has already rated another user for a specific ride
  static Future<bool> hasRated(
    String riderUserId,
    String ratedUserId,
    String rideId,
  ) async {
    try {
      final query = await _firestore
          .collection('ratings')
          .where('rideId', isEqualTo: rideId)
          .where('ratedBy', isEqualTo: riderUserId)
          .where('ratedUserId', isEqualTo: ratedUserId)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking rating status: $e');
      return false;
    }
  }
}
