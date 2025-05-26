import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stylehub/screens/specialist_pages/model/categories_model.dart';
import 'package:stylehub/storage/category_service.dart';

class EditCategoryProvider extends ChangeNotifier {
  List<Service> _services = [Service()];
  List<Service> _submittedServices = [];
  List<String> _submittedCategories = [];
  List<Category> _availableCategories = [];
  final List<String> _selectedCategories = [];
  final FirebaseServices _firebaseService = FirebaseServices();

  // Getters
  List<Service> get services => _services;
  List<Service> get submittedServices => _submittedServices;
  List<String> get submittedCategories => _submittedCategories;
  List<Category> get availableCategories => _availableCategories;
  List<String> get selectedCategories => _selectedCategories;

  void addService() {
    _services.add(Service());
    notifyListeners();
  }

  void updateService(int index, String name, String price, String duration) {
    _services[index] = Service(name: name, price: price, duration: duration);
    notifyListeners();
  }

  // void submitForm() {
  //   _submittedServices = List.from(_services.where((s) => s.name.isNotEmpty && s.price.isNotEmpty));
  //   _submittedCategories = List.from(_selectedCategories);
  //   _services = [Service()];
  //   notifyListeners();
  // }

  void submitForm() {
    _submittedServices = List.from(_services.where((s) => s.name.isNotEmpty && s.price.isNotEmpty && s.duration.isNotEmpty));
    _submittedCategories = List.from(_selectedCategories);
    _services = [Service()];
    notifyListeners();
  }

  void clearSelections() {
    _submittedServices.clear();
    _submittedCategories.clear();
    notifyListeners();
  }

  void clearAll() {
    _submittedServices.clear();
    _submittedCategories.clear();
    _services = [Service()];
    _selectedCategories.clear();
    notifyListeners();
  }

  void loadCategories() {
    _firebaseService.getCategories().listen((categories) {
      _availableCategories = categories;
      notifyListeners();
    });
  }

  void updateSubmittedCategories(List<String> categoryNames) {
    _submittedCategories = categoryNames;
    notifyListeners();
  }

  Future<void> loadExistingServices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null && doc['services'] != null) {
        final List<dynamic> rawServices = doc['services'];
        _services = rawServices.map((item) {
          return Service(
            name: item['service'] ?? '',
            price: item['price']?.toString() ?? '',
            duration: item['duration']?.toString() ?? '',
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading existing services: $e');
    }
  }

  Future<void> loadExistingCategories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null && doc['categories'] != null) {
        final List<dynamic> rawCategories = doc['categories'];
        _selectedCategories.clear();
        // Map category names to their IDs
        _selectedCategories.addAll(
          rawCategories.map((categoryName) {
            final category = _availableCategories.firstWhere(
              (cat) => cat.name == categoryName || cat.ruName == categoryName,
              orElse: () => Category(id: '', name: categoryName, ruName: categoryName),
            );
            return category.id;
          }).where((id) => id.isNotEmpty),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading existing categories: $e');
    }
  }

  void toggleCategory(String categoryId) {
    if (_selectedCategories.contains(categoryId)) {
      _selectedCategories.remove(categoryId);
    } else {
      _selectedCategories.add(categoryId);
    }
    notifyListeners();
  }

  String getCategoryName(String categoryId, String languageCode) {
    try {
      final category = _availableCategories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => Category(id: '', name: 'Unknown', ruName: 'Unknown'),
      );
      return languageCode == 'ru' ? (category.ruName) : category.name;
    } catch (e) {
      debugPrint('Error getting category name: $e');
      return 'Unknown';
    }
  }

  // New method to get category names for current language
  List<String> getSelectedCategoryNames(String languageCode) {
    return _selectedCategories.map((id) => getCategoryName(id, languageCode)).toList();
  }
}

class Service {
  // This is a field, not a getter
  String name;
  String price;
  String duration;
  String imageUrl;
  bool selected;

  Service({this.name = '', this.price = '60', this.duration = '', this.selected = false, this.imageUrl = ''});
}
