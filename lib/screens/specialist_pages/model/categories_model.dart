import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String ruName;
  final String name;
  final String? imageUrl;

  Category({required this.id, required this.name, required this.ruName, this.imageUrl});

  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      ruName: data['ru-name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}
