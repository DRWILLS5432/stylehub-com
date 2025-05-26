import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/onboarding_page/onboarding_screen.dart';
import 'package:stylehub/screens/admin/admin_panel.dart';
import 'package:stylehub/screens/specialist_pages/provider/location_provider.dart';
import 'package:stylehub/screens/specialist_pages/provider/specialist_provider.dart';
import 'package:stylehub/screens/specialist_pages/widgets/help_screen.dart';
import 'package:stylehub/screens/specialist_pages/widgets/select_address_widget.dart';
import 'package:stylehub/screens/specialist_pages/widgets/settings_widget.dart';
import 'package:stylehub/screens/specialist_pages/widgets/update_service_widget.dart';
import 'package:stylehub/services/firebase_auth.dart';

class SpecialistProfileScreen extends StatefulWidget {
  const SpecialistProfileScreen({super.key});

  @override
  State<SpecialistProfileScreen> createState() => _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState extends State<SpecialistProfileScreen> {
  String? userName;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    // Clear addresses from the previous user and fetch for the current one.
    fetchAddresses();
  }

  void fetchAddresses() {
    Provider.of<SpecialistProvider>(context, listen: false).fetchSpecialistData();
    // Provider.of<AddressProvider>(context, listen: false).fetchAddresses();
  }

  /// Fetches user data from Firestore for the current authenticated user.
  ///
  /// Retrieves the document corresponding to the current user's UID from the
  /// 'users' collection in Firestore. If the document exists, it extracts the
  /// user's first name and profile image (encoded in base64). The first name
  /// is stored in the `userName` field, and the profile image is decoded to
  /// `Uint8List` and stored in `_imageBytes`. If the image decoding fails,
  /// an error is caught, and appropriate handling (such as setting a default
  /// image) should be implemented.

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      // print(userDoc.data());
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
                // Handle the error, e.g., set a default image
              }
            }
          });
        }
      }
    }
  }

  void _navigateToAdminPanel() async {
    // final user = FirebaseAuth.instance.currentUser;
    // if (user == null) return;

    // final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    // if (doc.data()?['role'] == LocaleData.stylist.getString(context)) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboard()));
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Admin access required')),
    //   );
    // }
  }

  /// Allows the user to pick an image from their device's gallery, and then
  ///
  /// 1. Converts the picked image to bytes.
  /// 2. Encodes the image bytes to a base64 string.
  /// 3. Updates the `_imageBytes` field with the encoded image bytes.
  /// 4. Calls the [_saveImageToFirestore] method to store the base64 image in Firestore.
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Read image bytes
        Uint8List imageBytes = await pickedFile.readAsBytes();

        // Check image size (e.g., limit to 5MB)
        const maxSizeInBytes = 2 * 1024 * 1024; // 2MB
        if (imageBytes.length > maxSizeInBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image size is too large. Please select an image smaller than 2MB.')),
          );
          return;
        }

        // Encode to base64
        String base64Image = base64Encode(imageBytes);

        // Update UI
        setState(() {
          _imageBytes = imageBytes;
          _isLoading = true;
        });

        // Save to Firestore
        await _saveImageToFirestore(base64Image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image. Please try another image.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Stores the given base64-encoded image in Firestore for the current authenticated user.
  ///
  /// Updates the 'profileImage' field of the user document in the 'users' collection
  /// with the given base64 image. If the document doesn't exist, this method will
  /// create it.
  Future<void> _saveImageToFirestore(String base64Image) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImage': base64Image,
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile image updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image to Firestore')),
      );
    }
  }

  // Future<void> _saveImageToFirestore(String base64Image) async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //       'profileImage': base64Image,
  //     }, SetOptions(merge: true));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
      ),
      body: SafeArea(
        child: Consumer2<SpecialistProvider, AddressProvider>(builder: (context, provider, addressProvider, _) {
          // final userData = provider.specialistModel;
          // final fullName = "${userData?.firstName} ${userData?.lastName.toString()}";

          if (provider.specialistModel == null) {
            return Center(child: CircularProgressIndicator());
          }
          // print(userData.role);
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Container(height: 20),
                  Stack(
                    children: [
                      Hero(
                        tag: '1',
                        child: Container(
                          padding: EdgeInsets.all(3.dg),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100.dg), color: AppColors.appBGColor),
                          child: CircleAvatar(
                            radius: 60.dg,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                            child: _imageBytes == null ? Icon(Icons.add_a_photo, size: 30, color: Colors.grey[600]) : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  TextButton(onPressed: _pickImage, child: Text(LocaleData.changeProfilePics.getString(context), style: appTextStyle14(AppColors.appGrayTextColor))),
                  SizedBox(width: 29.h),
                  GestureDetector(
                    onTap: _showAddressBottomSheet,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_pin, color: AppColors.newThirdGrayColor),
                        SizedBox(width: 2.w),

                        // entered or selected location address
                        // Text(userData.address, style: appTextStyle12K(AppColors.newThirdGrayColor)),
                        Text(
                          addressProvider.selectedAddress != null
                              ? provider.specialistModel!.address
                              : provider.specialistModel!.address.isNotEmpty
                                  ? provider.specialistModel!.address
                                  : 'Tap to select address',
                          style: appTextStyle12K(AppColors.newThirdGrayColor),
                        ),
                        SizedBox(width: 5.w),
                        Container(
                          // padding: EdgeInsets.all(5.dg),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50.dg), border: Border.all(color: AppColors.mainBlackTextColor)),
                          child: CircleAvatar(
                            backgroundColor: AppColors.mainBlackTextColor,
                            radius: 10.dg,
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.whiteColor,
                              size: 16.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 26),
                  Column(
                    children: [
                      ProfileTiles(
                          onTap: () => Navigator.pushNamed(context, '/personal_details'),
                          title: LocaleData.personalDetails.getString(context),
                          subtitle: LocaleData.editProfileDetail.getString(context),
                          icon: 'assets/images/User.png'),
                      if (provider.specialistModel!.role == 'Stylist')
                        ProfileTiles(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateServiceWidget())),
                            title: LocaleData.specialistDetails.getString(context),
                            subtitle: LocaleData.updateServiceDetail.getString(context),
                            icon: 'assets/images/Scissors.png'),
                      ProfileTiles(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsWidget())),
                          title: LocaleData.appSettings.getString(context),
                          subtitle: LocaleData.updateSettings.getString(context),
                          icon: 'assets/images/Settings.png'),
                      ProfileTiles(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HelpScreen())),
                          title: LocaleData.help.getString(context),
                          subtitle: LocaleData.updateSettings.getString(context),
                          icon: 'assets/images/help1.png')
                    ],
                  ),
                  SizedBox(height: 51.h),
                  // ProfileTiles(onTap: _navigateToAdminPanel, title: 'Admin Panel', subtitle: LocaleData.updateSettings.getString(context), icon: 'assets/images/Settings.png'),
                  SizedBox(
                    width: 212.w,
                    height: 45.h,
                    child: ReusableButton(
                        bgColor: AppColors.whiteColor,
                        width: 212.w,
                        height: 45.h,
                        text: _isLoading
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: CircularProgressIndicator.adaptive(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.whiteColor),
                                  strokeWidth: 3.dg,
                                ),
                              )
                            : Text(LocaleData.logout.getString(context), style: mediumTextStyle25(AppColors.mainBlackTextColor)),
                        onPressed: () {
                          setState(() => _isLoading = true);

                          _firebaseService.logout(context);
                          setState(() => _isLoading = false);
                        }),
                  ),
                  SizedBox(height: 20),

                  /// Here is the logout button
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(width: double.infinity, child: SelectAddressBottomSheet(addressController: _addressController)),
    );
  }
}

class ProfileTiles extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? icon;
  const ProfileTiles({super.key, required this.title, required this.subtitle, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h, left: 30.w, right: 30.w),
        padding: EdgeInsets.only(
          right: 10.w,
          left: 25.w,
          top: 12.h,
        ),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.dg), color: AppColors.appBGColor),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(height: 50.h, width: 50.w, child: Image.asset(icon.toString())),
                SizedBox(width: 5.w),
                SizedBox(
                  width: 180.w,
                  child: Text(
                    title,
                    style: appTextStyle205(AppColors.newThirdGrayColor),
                  ),
                ),
              ],
            ),

            // subtitle: Text(subtitle, style: appTextStyle10(AppColors.mainBlackTextColor)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  // padding: EdgeInsets.all(5.dg),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(50.dg), border: Border.all(color: AppColors.mainBlackTextColor)),
                  child: CircleAvatar(
                    backgroundColor: AppColors.appBGColor,
                    radius: 12.dg,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.mainBlackTextColor,
                      size: 16.h,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 12.h,
            )
          ],
        ),
      ),
    );
  }
}
