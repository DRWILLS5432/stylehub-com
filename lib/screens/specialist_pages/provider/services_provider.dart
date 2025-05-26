import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:stylehub/screens/specialist_pages/model/post_details_model.dart';

class ServicesProvider extends ChangeNotifier {
  PostServicesModel? _specialistModel;

  PostServicesModel? get specialistModel => _specialistModel;

  // Fetch user data method
  Future<void> fetchSpecialistData(String userId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('services').doc(userId).get();

        if (userDoc.exists) {
          // Convert the document data to a PostServicesModel object using fromFirestore
          _specialistModel = PostServicesModel.fromFirestore(userDoc);
          // print(_specialistModel!.profileImage.toString());
        } else {
          // Handle the case where the user document doesn't exist
          _specialistModel = null;
        }
      } catch (error) {
        // Handle any errors that occur during data fetching
        print("Error fetching specialist data: $error");
        _specialistModel = null;
      }
      notifyListeners(); // Notify listeners after fetching data
    } else {
      // Handle the case where the user is not authenticated
      _specialistModel = null;
      notifyListeners();
    }
  }
}
