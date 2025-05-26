
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/screens/specialist_pages/model/specialist_model.dart';
import 'package:stylehub/screens/specialist_pages/specialist_detail_screen.dart';
import 'package:stylehub/storage/likes_method.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user is currently signed in')),
        );
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found')),
        );
        return;
      }

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data is empty')),
        );
        return;
      }

      setState(() {
        // Safely parse coordinates
        _userLat = _parseCoordinate(userData['lat']);
        _userLng = _parseCoordinate(userData['lng']);
      });

      if (_userLat == null || _userLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load location data')),
        );
      }
    } catch (e) {
      // debugPrint('Error fetching user location: an ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading location data')),
      );
    }
  }

  /// Helper function to safely parse coordinates to double
  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double _calculateDistance(SpecialistModel specialist) {
    // Early return if any coordinate is missing
    if (_userLat == null || _userLng == null || specialist.lat == null || specialist.lng == null) {
      return 0; // Consistent with SpecialistDashboard
    }

    return Geolocator.distanceBetween(
          _userLat!,
          _userLng!,
          specialist.lat!,
          specialist.lng!,
        ) /
        1000; // Convert meters to kilometers
  }

  String _formatDistance(double km) {
    if (km <= 0) return 'N/A';
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          LocaleData.likes.getString(context),
          style: appTextStyle24(AppColors.newThirdGrayColor),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.w),
            child: Icon(Icons.favorite, color: AppColors.primaryRedColor),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: LikeService().getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No favorites found',
                style: appTextStyle16(AppColors.newThirdGrayColor),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(doc['specialistId']).get(),
                builder: (context, specialistSnapshot) {
                  if (!specialistSnapshot.hasData) {
                    return SizedBox.shrink();
                  }

                  final specialist = SpecialistModel.fromFirestore(specialistSnapshot.data!);
                  final distance = _calculateDistance(specialist);

                  return buildProfessionalCard(
                    context,
                    specialist,
                    distance,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget buildProfessionalCard(
    BuildContext context,
    SpecialistModel user,
    double distance,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Color(0xFFD7D1BE),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.dg),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(100.dg),
                  ),
                  child: CircleAvatar(
                    radius: 60.dg,
                    backgroundImage: user.profileImage != null ? MemoryImage(base64Decode(user.profileImage!)) : AssetImage('assets/master1.png') as ImageProvider,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user.fullName, style: appTextStyle20(AppColors.newThirdGrayColor)),
                      Text(
                        user.role,
                        style: appTextStyle15(AppColors.newThirdGrayColor),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < user.averageRating.floor() ? Icons.star : Icons.star_border,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_pin, color: AppColors.newThirdGrayColor),
                    Text(
                      _formatDistance(distance),
                      style: appTextStyle15(AppColors.newThirdGrayColor),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpecialistDetailScreen(
                          userId: user.userId,
                          name: user.fullName,
                          rating: user.averageRating,
                          distance: distance,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    LocaleData.view.getString(context),
                    style: appTextStyle14(AppColors.newThirdGrayColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
