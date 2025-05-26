import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State <CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  String? userName;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Use the data() method to access the document's data as a Map
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          setState(() {
            // Safely access the 'firstName' field
            userName = userData['firstName'] as String?;

            // Safely access the 'profileImage' field
            String? base64Image = userData['profileImage'] as String?;
            if (base64Image != null) {
              try {
                _imageBytes = base64Decode(base64Image);
              } catch (e) {
                // print("Error decoding base64 image: $e");
              }
            }
          });
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List imageBytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      setState(() {
        _imageBytes = imageBytes;
      });
      await _saveImageToFirestore(base64Image);
    }
  }

  Future<void> _saveImageToFirestore(String base64Image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profileImage': base64Image,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12.0),
                      bottomRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                          child: _imageBytes == null ? Icon(Icons.add_a_photo, size: 60, color: Colors.grey[600]) : null,
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.03,
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Welcome Back ${userName ?? ''}',
                            style: TextStyle(fontSize: 18, fontFamily: "InstrumentSans"),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 150,
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFD7D1BE),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories',
                        style: TextStyle(fontSize: 18, fontFamily: 'InstrumentSans'),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: _buildCategoryIcon('Haircut', 'assets/haircut_icon.png')),
                          Expanded(child: _buildCategoryIcon('Shave', 'assets/shave_icon.png')),
                          Expanded(child: _buildCategoryIcon('Facials', 'assets/facials_icon.png')),
                          Expanded(child: _buildCategoryIcon('Manicure', 'assets/manicure_icon.png')),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Find beauty professionals near you',
                              style: TextStyle(fontSize: 16, fontFamily: 'InstrumentSans'),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Ваш код для настроек
                            },
                            child: Image.asset(
                              'assets/categ_settings.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      _buildProfessionalCard('John Doe', 'Barber', 4.5),
                      _buildProfessionalCard('Jane Smith', 'Hairstylist', 4.8),
                      SizedBox(height: 70),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.15,
                width: MediaQuery.of(context).size.width * 0.7,
                margin: EdgeInsets.all(16.0),
                padding: EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(220, 209, 190, 0.7),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: Colors.black, // Цвет выбранной иконки
                  unselectedItemColor: Colors.grey, // Цвет невыбранных иконок
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_today),
                      label: 'Appointments',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.favorite),
                      label: 'Likes',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildCategoryIcon(String label, String assetPath) {
  return GestureDetector(
    child: Column(
      children: [
        Image.asset(assetPath, width: 50, height: 50),
        SizedBox(height: 8),
        Text(label),
      ],
    ),
  );
}

Widget _buildProfessionalCard(String name, String profession, double rating) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 10),
    color: Color(0xFFD7D1BE),
    child: Padding(
      padding: const EdgeInsets.all(25.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/manicure_icon.png'), // Replace with actual image path
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 255, 255, 255))),
                Text(
                  profession,
                  style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 255, 255, 255)),
                ),
                SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: const Color.fromARGB(255, 2, 1, 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              "View",
              style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 255, 255, 255)),
            ),
          ),
        ],
      ),
    ),
  );
}
