import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stylehub/screens/specialist_pages/model/appointment_model.dart';
import 'package:stylehub/screens/specialist_pages/model/specialist_model.dart';

class AppointmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<AppointmentModel>> fetchAppointments({
    required String userId,
    required bool isSpecialist,
  }) async {
    try {
      final field = isSpecialist ? 'specialistId' : 'clientId';

      final query = _firestore.collection('appointments').where(field, isEqualTo: userId).orderBy('date', descending: false);

      final snapshot = await query.get();

      List<AppointmentModel> appointments = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final appointment = AppointmentModel.fromMap(data);

        // If the user is a client, fetch the specialist's name
        if (!isSpecialist) {
          final specialistId = data['specialistId'];
          final specialistDoc = await _firestore
              .collection('users') // or 'specialists', depending on your setup
              .doc(specialistId)
              .get();

          if (specialistDoc.exists) {
            final specialist = SpecialistModel.fromFirestore(specialistDoc);
            appointment.specialistName = specialist.fullName; // Add this to the model
          }
        }

        appointments.add(appointment);
      }

      return appointments.reversed.toList(); // Show latest first
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      return [];
    }
  }

  // // Fetch appointments by user role (client or specialist)
  // Future<List<AppointmentModel>> fetchAppointments({
  //   required String userId,
  //   required bool isSpecialist,
  // }) async {
  //   try {
  //     // Determine the field to query based on user type
  //     final field = isSpecialist ? 'specialistId' : 'clientId';

  //     final query = _firestore.collection('appointments').where(field, isEqualTo: userId).orderBy('date', descending: false); // Changed to ascending

  //     final snapshot = await query.get();

  //     // Convert to models and reverse to show newest first in UI
  //     final appointments = snapshot.docs.map((doc) => AppointmentModel.fromMap(doc.data())).toList();

  //     return appointments.reversed.toList(); // Reverse the list
  //   } catch (e) {
  //     debugPrint('Error fetching appointments: $e');
  //     if (e is FirebaseException && e.code == 'failed-precondition') {
  //       debugPrint('You need to create a Firestore index for this query');
  //     }
  //     return [];
  //   }
  // }
  // Future<List<AppointmentModel>> fetchAppointments({
  //   required String userId,
  //   required bool isSpecialist,
  // }) async {
  //   try {
  //     QuerySnapshot snapshot = await _firestore.collection('appointments').where(isSpecialist ? 'specialistId' : 'clientId', isEqualTo: userId).orderBy('date', descending: true).get();

  //     return snapshot.docs.map((doc) => AppointmentModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
  //   } catch (e) {
  //     // print('Error fetching appointments: $e');
  //     return [];
  //   }
  // }

  // Cancel an appointment using the AppointmentRepository class

  /// Cancel an appointment by its ID.
  ///
  /// Sets the status of the appointment to 'cancelled' and adds the current timestamp
  /// to the 'cancelledAt' field. If the operation fails, throws an [Exception] with the error message.
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  Future<void> deleteAppointment(context, String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
      Navigator.pop(context);
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }
}
