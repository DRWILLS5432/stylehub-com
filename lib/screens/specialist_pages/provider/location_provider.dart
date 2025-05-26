import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class Address {
  final String name;
  final String address;
  final double? lat;
  final double? lng;

  Address({
    required this.name,
    required this.address,
    this.lat,
    this.lng,
  });
}

class AddressProvider with ChangeNotifier {
  final List<Address> _addresses = [];
  Address? _selectedAddress;

  List<Address> get addresses => _addresses;
  Address? get selectedAddress => _selectedAddress;

  set selectedAddress(Address? address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Use this method to clear stored addresses (e.g. when a new user logs in).
  void clearAddresses() {
    _addresses.clear();
    _selectedAddress = null;
    notifyListeners();
  }

  Future<void> addAddress(Address newAddress) async {
    _addresses.add(newAddress);
    _selectedAddress = newAddress;
    notifyListeners();
    await _saveToFirestore(newAddress);
  }

  Future<void> fetchAddresses() async {
    // Clear current addresses.
    _addresses.clear();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('addresses').get();
      _addresses.addAll(querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Address(
          name: data['name'] ?? 'No Name',
          address: data['address'] ?? '',
          lat: data['lat'] is num ? (data['lat'] as num).toDouble() : null,
          lng: data['lng'] is num ? (data['lng'] as num).toDouble() : null,
        );
      }).toList());
      notifyListeners();
    }
  }

  Future<void> _saveToFirestore(Address address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': address.name,
        'address': address.address,
        'lat': address.lat,
        'lng': address.lng,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Retrieves the current location. If location services are off,
  /// this method attempts to open the device’s location settings.
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('Location service enabled: $serviceEnabled');

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    debugPrint('Position: ${position.latitude}, ${position.longitude}');
    return position;
  }

  Future<Address> getCurrentLocationAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('Location service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw Exception('Location services are disabled');
      }
      final position = await _getCurrentLocation();
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = places.first;
      return Address(
        name: 'Current Location',
        address: '${place.street}, ${place.locality}, ${place.country}',
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }
}
