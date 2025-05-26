import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// This function checks if the user is logged in and submits a review with the
  /// provided rating and comment for the specified specialist. It adds the review
  /// to the Firestore database under the specialist's user ID. If successful, it
  /// hides the review field and displays a success message. If there's an error
  /// or the user is not logged in, it shows an error message.
  ///
  /// Parameters:
  /// - `rating`: An integer representing the user's rating for the specialist.
  /// - `comment`: A string containing the user's comments or feedback.
  ///
  /// Throws an error message if the user is not logged in or if the review
  /// submission fails.
  ///
  Future<String> submitReview({
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'Authentication required';
    }

    try {
      // Get reviewer details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final reviewerName = userDoc.exists ? (userDoc.data()?['firstName'] ?? 'Anonymous') : 'Anonymous';
      final reviewerLastName = userDoc.exists ? (userDoc.data()?['lastName'] ?? 'Anonymous') : 'Anonymous';

      // Add new review
      await _firestore.collection('users').doc(userId).collection('reviews').add({
        'rating': rating,
        'comment': comment,
        'reviewerId': user.uid,
        'reviewerName': reviewerName,
        'reviewerLastName': reviewerLastName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Calculate new average rating
      final reviewsSnapshot = await _firestore.collection('users').doc(userId).collection('reviews').get();

      int totalRating = 0;
      int reviewCount = reviewsSnapshot.docs.length;

      for (var doc in reviewsSnapshot.docs) {
        totalRating += doc['rating'] as int;
      }

      double averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;

      // Update specialist's average rating
      await _firestore.collection('users').doc(userId).update({
        'averageRating': averageRating,
      });

      return 'success';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
  // Future<String> submitReview({
  //   required String userId,
  //   required int rating,
  //   required String comment,
  // }) async {
  //   final user = _auth.currentUser;
  //   if (user == null) {
  //     return 'Authentication required';
  //   }

  //   try {
  //     // Get reviewer's name from Firestore
  //     final userDoc = await _firestore.collection('users').doc(user.uid).get();
  //     String reviewerName = userDoc.exists ? (userDoc.data()?['firstName'] ?? 'Anonymous') : 'Anonymous';
  //     String reviewerLastName = userDoc.exists ? (userDoc.data()?['lastName'] ?? 'Anonymous') : 'Anonymous';

  //     await _firestore.collection('users').doc(userId).collection('reviews').add({
  //       'rating': rating,
  //       'comment': comment,
  //       'reviewerId': user.uid,
  //       'reviewerName': reviewerName,
  //       'reviewerLastName': reviewerLastName,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     });

  //     return 'success';
  //   } catch (e) {
  //     return 'Error: ${e.toString()}';
  //   }
  // }
}
