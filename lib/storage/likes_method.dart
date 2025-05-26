import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Toggles a specialist as favorite for the current user
  /// Returns:
  /// - 'liked' if the specialist was added to favorites
  /// - 'unliked' if the specialist was removed from favorites
  /// - Error message if something went wrong
  Future<String> toggleFavorite(String specialistId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'Authentication required';
    }

    // Prevent users from favoriting themselves
    if (specialistId == user.uid) {
      return 'Error: You cannot favorite yourself';
    }

    try {
      final favoriteRef = _firestore.collection('users').doc(user.uid).collection('favorites').doc(specialistId);

      final favoriteDoc = await favoriteRef.get();

      if (favoriteDoc.exists) {
        // Remove from favorites if already exists
        await favoriteRef.delete();
        return 'unliked';
      } else {
        // Add to favorites if not already exists
        // First get specialist data to store in favorites
        final specialistDoc = await _firestore.collection('users').doc(specialistId).get();

        if (!specialistDoc.exists) {
          return 'Error: Specialist not found';
        }

        final specialistData = specialistDoc.data()!;

        await favoriteRef.set({
          'specialistId': specialistId,
          'specialistName': specialistData['firstName'] ?? 'Unknown',
          'specialistLastName': specialistData['lastName'] ?? 'Unknown',
          'profileImage': specialistData['profileImage'] ?? '',
          'role': specialistData['role'] ?? 'Specialist',
          'timestamp': FieldValue.serverTimestamp(),
        });
        return 'liked';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Checks if the current user has favorited the specialist
  Future<bool> isFavorite(String specialistId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final favoriteDoc = await _firestore.collection('users').doc(user.uid).collection('favorites').doc(specialistId).get();

    return favoriteDoc.exists;
  }

  /// Gets all specialists favorited by the current user
  Stream<QuerySnapshot> getFavorites() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore.collection('users').doc(user.uid).collection('favorites').orderBy('timestamp', descending: true).snapshots();
  }
}
