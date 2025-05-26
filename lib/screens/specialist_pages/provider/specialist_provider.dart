// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:stylehub/screens/specialist_pages/model/specialist_model.dart';

// class SpecialistProvider extends ChangeNotifier {
//   SpecialistModel? _specialistModel;

//   SpecialistModel? get specialistModel => _specialistModel;

//   // final List<Map<String, dynamic>> _selectedServices = [];
//   // In your SpecialistProvider class
//   final List<Map<String, dynamic>> _selectedServices = [];

//   List<Map<String, dynamic>> get selectedServices => _selectedServices;

//   // Fetch user data method
//   Future<void> fetchSpecialistData() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       try {
//         DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

//         if (userDoc.exists) {
//           // Convert the document data to a SpecialistModel object using fromFirestore
//           _specialistModel = SpecialistModel.fromFirestore(userDoc);
//           // print(_specialistModel!.profileImage.toString());
//         } else {
//           // Handle the case where the user document doesn't exist
//           _specialistModel = null;
//         }
//       } catch (error) {
//         // Handle any errors that occur during data fetching
//         // print("Error fetching specialist data: $error");
//         _specialistModel = null;
//       }
//       notifyListeners(); // Notify listeners after fetching data
//     } else {
//       // Handle the case where the user is not authenticated
//       _specialistModel = null;
//       notifyListeners();
//     }
//   }

//   Future<void> updateProfileImage(String base64Image) async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
//           'profileImage': base64Image,
//         });

//         // Update the local SpecialistModel with the new image
//         _specialistModel = _specialistModel?.copyWith(profileImage: base64Image);
//         notifyListeners(); // Notify listeners after updating
//       } catch (e) {
//         // print("Error updating profile image: $e");
//       }
//     }
//   }

//   bool isServiceSelected(String serviceName) {
//     return _selectedServices.any((s) => s['service'] == serviceName);
//   }

//   void toggleServiceSelection(Map<String, dynamic> service, {bool hasSelectedTimeSlot = true}) {
//     if (_selectedServices.any((s) => s['service'] == service['service'])) {
//       _selectedServices.removeWhere((s) => s['service'] == service['service']);
//     } else {
//       _selectedServices.add(service);
//     }
//     notifyListeners();
//   }

//   int get totalDuration {
//     return _selectedServices.fold(0, (int sum, Map<String, dynamic> service) {
//       final durationStr = service['duration']?.toString();
//       if (durationStr == null) return sum;

//       final duration = int.tryParse(durationStr);
//       return sum + (duration ?? 0);
//     });
//   }

//   String? getProfileImage() {
//     return _specialistModel?.profileImage;
//   }

//   void clearSelections() {
//     _selectedServices.clear();
//     notifyListeners();
//   }
// }

// specialist_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stylehub/screens/specialist_pages/model/specialist_model.dart';

class SpecialistProvider extends ChangeNotifier {
  SpecialistModel? _specialistModel;
  SpecialistModel? get specialistModel => _specialistModel;

  final List<Map<String, dynamic>> _selectedServices = [];
  List<Map<String, dynamic>> get selectedServices => _selectedServices;

  Future<void> fetchSpecialistData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          _specialistModel = SpecialistModel.fromFirestore(userDoc);
        } else {
          _specialistModel = null;
        }
      } catch (error) {
        _specialistModel = null;
      }
      notifyListeners();
    } else {
      _specialistModel = null;
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String base64Image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profileImage': base64Image});
        _specialistModel = _specialistModel?.copyWith(profileImage: base64Image);
        notifyListeners();
      } catch (e) {}
    }
  }

  bool isServiceSelected(String serviceName) {
    return _selectedServices.any((s) => s['service'] == serviceName);
  }

  void toggleServiceSelection(Map<String, dynamic> service, {bool hasSelectedTimeSlot = true}) {
    if (_selectedServices.any((s) => s['service'] == service['service'])) {
      _selectedServices.removeWhere((s) => s['service'] == service['service']);
    } else {
      _selectedServices.add(service);
    }
    notifyListeners();
  }

  int get totalDuration {
    return _selectedServices.fold(0, (int sum, Map<String, dynamic> service) {
      final durationStr = service['duration']?.toString();
      if (durationStr == null) return sum;
      final duration = int.tryParse(durationStr);
      return sum + (duration ?? 0);
    });
  }

  String? getProfileImage() {
    return _specialistModel?.profileImage;
  }

  void clearSelections() {
    _selectedServices.clear();
    notifyListeners();
  }
}
