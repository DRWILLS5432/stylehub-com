import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Register a new user
  Future<User?> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user details to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
      });

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use by another account.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'Registration failed. Please try again.';
      }
      throw errorMessage;
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Login a user
  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }
      throw errorMessage;
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.get('role');
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch user role. Please try again.';
    }
  }

  // Send OTP (Password Reset Email)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        default:
          errorMessage = 'Failed to send password reset email. Please try again.';
      }
      throw errorMessage;
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Reset Password
  Future<void> resetPassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw 'No authenticated user found.';
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log in again to update your password.';
          break;
        default:
          errorMessage = 'Failed to reset password. Please try again.';
      }
      throw errorMessage;
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

// Add service data to Firestore
  Future<void> addServiceData({
    required String userId,
    required String services,
    required String bio,
    required String phone,
    required List<String> images,
  }) async {
    try {
      // Add data to Firestore
      await _firestore.collection('services').add({
        'userId': userId, // Associate data with the logged-in user
        'services': services,
        'bio': bio,
        'phone': phone,
        'images': images,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Return success message
      return;
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      String errorMessage;
      switch (e.code) {
        case 'permission-denied':
          errorMessage = 'You do not have permission to post service data.';
          break;
        case 'unavailable':
          errorMessage = 'Firestore is currently unavailable. Please try again later.';
          break;
        default:
          errorMessage = 'Failed to post service data: ${e.message}';
      }
      throw errorMessage;
    } on Exception catch (e) {
      // Handle generic exceptions
      throw 'An unexpected error occurred: $e';
    }
  }

  // Method to save FCM token to Firestore
  Future<void> saveFcmToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving FCM token: $e');
      rethrow;
    }
  }

  // Method to get FCM token from Firestore
  Future<String?> getFcmToken(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      return doc['fcmToken'] as String?;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Method to logout
  Future<void> logout(context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login_screen');
  }
}
