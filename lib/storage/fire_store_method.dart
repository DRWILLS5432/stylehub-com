import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stylehub/screens/specialist_pages/model/post_details_model.dart';

class FireStoreMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uploads service details to Firestore.
  ///
  /// This method takes in a user's details, services, categories, and images,
  /// and uploads them to Firestore under the 'services' collection. The document
  /// ID is the user's ID. The 'timestamp' field is set to the server timestamp.
  ///
  /// The method returns a string indicating the result of the operation. If
  /// successful, the string is 'success'. Otherwise, it is an error message.
  Future<String> uploadServiceDetails({
    required String userId,
    required String bio,
    required String phone,
    required String city,
    required String profession,
    required String experience,
    required List<Map<String, String>> services,
    required List<String> categories,
    required List<String> images,
  }) async {
    String res = "Some error occurred";
    try {
      // String postId = const Uuid().v1();

      PostServicesModel post = PostServicesModel(
        userId: userId,
        bio: bio,
        phone: phone,
        city: city,
        profession: profession,
        experience: experience,
        services: services,
        categories: categories,
        images: images,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('services').doc(userId).set({
        ...post.toJson(),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // New method to update profession specifically
  // Future<String> updateServiceProfession({
  //   required String userId,
  //   required String newProfession,
  // }) async {
  //   String res = "Some error occurred";
  //   try {
  //     await _firestore.collection('users').doc(userId).set({
  //       'profession': newProfession,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //     res = 'success';
  //   } catch (err) {
  //     res = err.toString();
  //   }
  //   return res;
  // }

  /// Updates the 'services' field in the user's document in the 'services' collection
  /// with the given list of services.
  ///
  /// The update operation targets the user's document in the 'services' collection,
  /// identified by the `userId` parameter. The 'services' field is updated with the
  /// new list of services, and the 'timestamp' field is updated with the current
  /// timestamp.
  ///
  /// Returns 'success' if the operation is successful, or a string describing the
  /// error if the operation fails.
  ///

  Future<String> updateServices({
    required String userId,
    required List<Map<String, String>> newServices,
  }) async {
    try {
      for (var service in newServices) {
        if (service['service'] == null || service['service']!.isEmpty || service['price'] == null || service['price']!.isEmpty || service['duration'] == null || service['duration']!.isEmpty) {
          return 'All service fields (name, price, duration) are required';
        }

        if (double.tryParse(service['price']!) == null) {
          return 'Price must be a valid number';
        }

        if (int.tryParse(service['duration']!) == null) {
          return 'Duration must be a valid number (minutes)';
        }
      }

      await _firestore.collection('users').doc(userId).set({
        'services': newServices,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return 'success';
    } catch (err) {
      if (err is FirebaseException) {
        return 'Firebase error: ${err.message}';
      }
      return 'Failed to update services: ${err.toString()}';
    }
  }

  Future<String> updateCategories({
    required String userId,
    required List<String> newCategories,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'categories': newCategories,
      });
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<String>> getExistingCategories(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null && doc['categories'] != null) {
        return List<String>.from(doc['categories']);
      }
      return [];
    } catch (e) {
      // debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  // Future<String> updateCategories({
  //   required String userId,
  //   required List<String> newCategories,
  // }) async {
  //   try {
  //     await _firestore.collection('users').doc(userId).set({
  //       'categories': newCategories,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));

  //     return 'success';
  //   } catch (err) {
  //     return 'Failed to update categories: ${err.toString()}';
  //   }
  // }
}

  // Future<String> updateServices({
  //   required String userId,
  //   required List<Map<String, String>> newServices,
  // }) async {
  //   try {
  //     // Validate input data first
  //     for (var service in newServices) {
  //       if (service['service'] == null || service['service']!.isEmpty || service['price'] == null || service['price']!.isEmpty || service['duration'] == null || service['duration']!.isEmpty) {
  //         return 'All service fields (name, price, duration) are required';
  //       }

  //       // Validate price and duration are numbers
  //       if (double.tryParse(service['price']!) == null) {
  //         return 'Price must be a valid number';
  //       }

  //       if (int.tryParse(service['duration']!) == null) {
  //         return 'Duration must be a valid number (minutes)';
  //       }
  //     }

  //     await _firestore.collection('users').doc(userId).set({
  //       'services': newServices,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));

  //     return 'success';
  //   } catch (err) {
  //     // More specific error handling
  //     if (err is FirebaseException) {
  //       return 'Firebase error: ${err.message}';
  //     }
  //     return 'Failed to update services: ${err.toString()}';
  //   }
  // }

//   Future<String> updateCategories({
//     required String userId,
//     required List<String> newCategories,
//   }) async {
//     String res = "Some error occurred";
//     try {
//       await _firestore.collection('users').doc(userId).set({
//         'categories': newCategories,
//         'timestamp': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//       res = 'success';
//     } catch (err) {
//       res = err.toString();
//     }
//     return res;
//   }
// }

  // Future<String> updateBio({
  //   required String userId,
  //   required String newBio,
  // }) async {
  //   String res = "Some error occurred";
  //   try {
  //     await _firestore.collection('users').doc(userId).set({
  //       'bio': newBio,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //     res = 'success';
  //   } catch (err) {
  //     res = err.toString();
  //   }
  //   return res;
  // }

  // Future<String> updatePhone({
  //   required String userId,
  //   required String newPhone,
  // }) async {
  //   String res = "Some error occurred";
  //   try {
  //     await _firestore.collection('users').doc(userId).set({
  //       'phone': newPhone,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //     res = 'success';
  //   } catch (err) {
  //     res = err.toString();
  //   }
  //   return res;
  // }

  // Future<String> updateCity({
  //   required String userId,
  //   required String newCity,
  // }) async {
  //   String res = "Some error occurred";
  //   try {
  //     await _firestore.collection('users').doc(userId).set({
  //       'city': newCity,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //     res = 'success';
  //   } catch (err) {
  //     res = err.toString();
  //   }
  //   return res;
  // }

  // Future<String> updateAddress({
  //   required String userId,
  //   required String newAddress,
  // }) async {
  //   String res = "Some error occurred";
  //   try {
  //     await _firestore.collection('users').doc(userId).set({
  //       'address': newAddress,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //     res = 'success';
  //   } catch (err) {
  //     res = err.toString();
  //   }
  //   return res;
  // }

  // Future<String> updateExperience({
  //   required String userId,
  //   required String newExperience,
  // }) async {
  //   String res = "Some error occurred";
  //   try {
  //     await _firestore.collection('users').doc(userId).set({
  //       'experience': newExperience,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //     res = 'success';
  //   } catch (err) {
  //     res = err.toString();
  //   }
  //   return res;
  // }

  // Future<String> addImages({
  //   required String userId,
  //   required List<String> newImages,
  // }) async {
  //   String res = "Some error occurred";
  //   try {
  //     await _firestore.collection('users').doc(userId).update({
  //       'images': FieldValue.arrayUnion(newImages),
  //       'timestamp': FieldValue.serverTimestamp(),
  //     });
  //     res = 'success';
  //   } catch (err) {
  //     res = err.toString();
  //   }
  //   return res;
  // }

  /// Retrieves the average rating for a user.
  ///
  /// This method fetches all review documents for a specified user from the 'reviews'
  /// subcollection in Firestore, calculates the average of the 'rating' fields, and
  /// returns it. If there are no reviews, it returns 0.0.
  ///
  /// Returns a [Future] that resolves to a [double] representing the average rating.
  ///
  /// - Parameter userId: The ID of the user whose average rating is to be calculated.

  // Future<double> getAverageRating(String userId) async {
  //   QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).collection('reviews').get();

  //   if (querySnapshot.docs.isEmpty) return 0.0;

  //   double totalRating = 0;
  //   for (var doc in querySnapshot.docs) {
  //     final data = doc.data() as Map<String, dynamic>;
  //     totalRating += (data['rating'] ?? 0).toDouble(); // Ensure rating is double
  //   }

  //   return totalRating / querySnapshot.docs.length;
  // }

  
// }


