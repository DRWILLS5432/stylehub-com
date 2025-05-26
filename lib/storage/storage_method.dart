import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class StorageMethod {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads the given file to Firebase Storage, at the location specified by [childName].
  ///
  /// If [isPost] is true, the file is uploaded to a unique id under the user.
  /// If [isPost] is false, the file overwrites the existing file at the given location.
  ///
  /// Returns the download URL of the uploaded file.
  
  
}
