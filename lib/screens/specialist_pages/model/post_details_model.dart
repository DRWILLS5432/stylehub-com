// Updated PostServicesModel
import 'package:cloud_firestore/cloud_firestore.dart';

class PostServicesModel {
  final String userId;
  final String bio;
  final String phone;
  final String city;
  final String profession;
  final String experience;
  final List<Map<String, String>> services;
  final List<String> categories;
  final List<String> images;
  final DateTime createdAt;

  PostServicesModel({
    required this.userId,
    required this.bio,
    required this.phone,
    required this.city,
    required this.profession,
    required this.experience,
    required this.services,
    required this.categories,
    required this.images,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'bio': bio,
      'phone': phone,
      'city': city,
      'profession': profession,
      'experience': experience,
      'services': services,
      'categories': categories,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PostServicesModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostServicesModel(
      userId: data['userId'],
      bio: data['bio'],
      phone: data['phone'],
      city: data['city'],
      profession: data['profession'],
      experience: data['experience'],
      services: List<Map<String, String>>.from(data['services']),
      categories: List<String>.from(data['categories']),
      images: List<String>.from(data['images']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  static PostServicesModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return PostServicesModel(
      userId: snapshot['userId'],
      bio: snapshot['bio'],
      phone: snapshot['phone'],
      city: snapshot['city'],
      profession: snapshot['profession'],
      experience: snapshot['experience'],
      services: List<Map<String, String>>.from(snapshot['services']),
      categories: List<String>.from(snapshot['categories']),
      images: List<String>.from(snapshot['images']),
      createdAt: (snapshot['createdAt'] as Timestamp).toDate(),
    );
  }
}
