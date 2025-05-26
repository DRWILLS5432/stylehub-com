import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String appointmentId;
  final String clientFirstName;
  final String clientLastName;
  final String specialistId;
  final String clientId;
  final String address;
  final DateTime date;
  final String status;
  String? specialistName;
  final int totalDuration;
  final DateTime createdAt;

  AppointmentModel({
    required this.appointmentId,
    required this.clientFirstName,
    required this.clientLastName,
    required this.specialistId,
    required this.clientId,
    required this.address,
    required this.date,
    required this.status,
    this.specialistName,
    required this.totalDuration,
    required this.createdAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> data) {
    return AppointmentModel(
      appointmentId: data['appointmentId'] ?? '',
      clientFirstName: data['clientFirstName'] ?? '',
      clientLastName: data['clientLastName'] ?? '',
      specialistId: data['specialistId'] ?? '',
      clientId: data['clientId'] ?? '',
      address: data['address'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'booked',
      specialistName: data['specialistName'] ?? '',
      totalDuration: data['totalDuration'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  AppointmentModel copyWith({
    String? appointmentId,
    String? clientFirstName,
    String? clientLastName,
    String? specialistId,
    String? clientId,
    String? address,
    DateTime? date,
    String? status,
    String? specialistName,
    int? totalDuration,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId ?? this.appointmentId,
      clientFirstName: clientFirstName ?? this.clientFirstName,
      clientLastName: clientLastName ?? this.clientLastName,
      specialistId: specialistId ?? this.specialistId,
      clientId: clientId ?? this.clientId,
      address: address ?? this.address,
      date: date ?? this.date,
      status: status ?? this.status,
      specialistName: specialistName ?? this.specialistName,
      totalDuration: this.totalDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
