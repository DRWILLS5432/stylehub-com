import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:stylehub/constants/Helpers/app_helpers.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/screens/specialist_pages/provider/edit_category_provider.dart';
import 'package:stylehub/screens/specialist_pages/provider/location_provider.dart';
import 'package:stylehub/screens/specialist_pages/provider/specialist_provider.dart';
import 'package:stylehub/screens/specialist_pages/widgets/edit_category_screen.dart';
import 'package:stylehub/screens/specialist_pages/widgets/personal_detail_screen.dart';
import 'package:stylehub/screens/specialist_pages/widgets/select_address_widget.dart';

class UpdateServiceWidget extends StatefulWidget {
  const UpdateServiceWidget({super.key});

  @override
  State<UpdateServiceWidget> createState() => _UpdateServiceWidgetState();
}

class _UpdateServiceWidgetState extends State<UpdateServiceWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  bool isLoading = false;
  bool _isAvailable = false;
  bool _isLoading = false;
  List<File> _imageFiles = [];
  bool _isEditingProfession = false;
  bool _isEditingExperience = false;
  bool _isEditingCity = false;
  bool _isEditingBio = false;
  bool _isEditingPhone = false;
  bool _isEditingAddress = false;
  Map<String, dynamic>? _initialData;

  String _approvalStatus = 'draft';
  List<String> _previousWorkUrls = [];
  Map<String, dynamic> _statusFields = {
    'professionStatus': 'draft',
    'experienceStatus': 'draft',
    'cityStatus': 'draft',
    'addressStatus': 'draft',
    'bioStatus': 'draft',
    'phoneStatus': 'draft',
    'previousWorkStatus': 'draft',
    'categoriesStatus': 'draft',
  };

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    fetchAddress();
  }

  void fetchAddress() async {
    await Provider.of<AddressProvider>(context, listen: false).fetchAddresses();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        _initialData = doc.data();
        _statusFields = {
          'professionStatus': _initialData?['professionStatus'] ?? 'draft',
          'experienceStatus': _initialData?['experienceStatus'] ?? 'draft',
          'cityStatus': _initialData?['cityStatus'] ?? 'draft',
          'addressStatus': _initialData?['addressStatus'] ?? 'draft',
          'bioStatus': _initialData?['bioStatus'] ?? 'draft',
          'phoneStatus': _initialData?['phoneStatus'] ?? 'draft',
          'previousWorkStatus': _initialData?['previousWorkStatus'] ?? 'draft',
          'categoriesStatus': _initialData?['categoriesStatus'] ?? 'draft',
        };
        _previousWorkUrls = List<String>.from(_initialData?['previousWork'] ?? []);
        _approvalStatus = _initialData?['status'] ?? 'draft';
        _professionController.text = _initialData?['profession'] ?? '';
        _experienceController.text = _initialData?['experience'] ?? '';
        _cityController.text = _initialData?['city'] ?? '';
        _bioController.text = _initialData?['bio'] ?? '';
        _phoneController.text = _initialData?['phone'] ?? '';
        _isAvailable = _initialData?['isAvailable'] ?? false;
      });
    }
  }

  // Add status indicator widget
  Widget _buildFieldStatusIndicator(String fieldKey) {
    final status = _statusFields[fieldKey];
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending Approval';
        break;
      case 'approved':
        color = Colors.green;
        text = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected - Please update';
        break;
      default:
        color = Colors.grey;
        text = 'Draft - Not submitted';
    }

    return Padding(
      padding: EdgeInsets.only(top: 0),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 12),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  // Add delete function
  Future<void> _deleteImage(String imageUrl) async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Remove from Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'previousWork': FieldValue.arrayRemove([imageUrl])
      });

      // Delete from Storage
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      // Update local state
      setState(() => _previousWorkUrls.remove(imageUrl));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting image: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    setState(() {
      _imageFiles = pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
    });
  }

  Future<List<String>> _uploadImages(String userId) async {
    List<String> imageUrls = [];

    for (var imageFile in _imageFiles) {
      final String imageId = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = _storage.ref().child('user-images/$userId/$imageId');
      await storageRef.putFile(imageFile);
      final String imageUrl = await storageRef.getDownloadURL();
      imageUrls.add(imageUrl);
    }

    return imageUrls;
  }

  Future<void> uploadPreviousWork(context) async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      List<String> imageUrls = [];
      if (_imageFiles.isNotEmpty) {
        imageUrls = await _uploadImages(user.uid);
      }

      // Save to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'previousWork': FieldValue.arrayUnion(imageUrls),
        'previousWorkStatus': 'pending',
        'status': 'partial-pending', // Optional: same global flag as profession
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Previous work submitted for approval!')),
      );

      setState(() {
        _statusFields['previousWorkStatus'] = 'pending';
        _imageFiles.clear(); // Clear selected files after upload
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating previous work: Try again later')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfession(context) async {
    if (_professionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profession cannot be empty')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'profession': _professionController.text,
        'professionStatus': 'pending',
        'status': 'partial-pending', // Global status if needed
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profession updated and submitted for approval!')),
      );

      setState(() {
        _statusFields['professionStatus'] = 'pending';
        _isEditingProfession = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profession: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateExperience(context) async {
    if (_experienceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Experience field cannot be empty')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'experience': _experienceController.text,
        'experienceStatus': 'pending',
        'status': 'partial-pending',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Experience updated and submitted for approval!')),
      );

      setState(() {
        _statusFields['experienceStatus'] = 'pending';
        _isEditingExperience = false;
      });

      // final res = await FireStoreMethod().updateExperience(
      //   userId: user.uid,
      //   newExperience: _experienceController.text,
      // );

      // if (res == 'success') {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Experience updated successfully!')),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error: $res')),
      //   );
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating experience: Try again later')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateCity(context) async {
    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City field cannot be empty')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'city': _cityController.text,
        'cityStatus': 'pending',
        'status': 'partial-pending',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City updated and submitted for approval!')),
      );

      setState(() {
        _statusFields['cityStatus'] = 'pending';
        _isEditingCity = false;
      });

      // final res = await FireStoreMethod().updateCity(
      //   userId: user.uid,
      //   newCity: _cityController.text,
      // );

      // if (res == 'success') {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('City updated successfully!')),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error: $res')),
      //   );
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating City: try again later')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateAddress(context) async {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final selectedAddress = addressProvider.selectedAddress;

    if (_addressController.text.isEmpty || selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid address with location data')),
      );
      return;
    }
    if (selectedAddress.lat == null || selectedAddress.lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid address with location data')),
      );
      return;
    }

    print('.................${selectedAddress.lat}');
    print('.................${selectedAddress.lat}');

    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'address': _addressController.text,
        'lat': selectedAddress.lat, // Add latitude
        'lng': selectedAddress.lng, // Add longitude
        'addressStatus': 'pending',
        'status': 'partial-pending',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address updated and submitted for approval!')),
      );

      setState(() {
        _statusFields['addressStatus'] = 'pending';
        _isEditingAddress = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating address: try again later')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateBio(context) async {
    if (_bioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio field cannot be empty')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'bio': _bioController.text,
        'bioStatus': 'pending',
        'status': 'partial-pending',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio updated and submitted for approval!')),
      );

      setState(() {
        _statusFields['bioStatus'] = 'pending';
        _isEditingBio = false;
      });
      // final res = await FireStoreMethod().updateBio(
      //   userId: user.uid,
      //   newBio: _bioController.text,
      // );

      // if (res == 'success') {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Bio updated successfully!')),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error: $res')),
      //   );
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating Bio: Try again later')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updatePhone(context) async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number field cannot be empty')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'phone': _phoneController.text,
        'phoneStatus': 'pending',
        'status': 'partial-pending',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone updated and submitted for approval!')),
      );

      setState(() {
        _statusFields['phoneStatus'] = 'pending';
        _isEditingPhone = false;
      });

      // final res = await FireStoreMethod().updatePhone(
      //   userId: user.uid,
      //   newPhone: _phoneController.text,
      // );

      // if (res == 'success') {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Phone number updated successfully!')),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error: $res')),
      //   );
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating Phone number: Try again later')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateAvailability(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'isAvailable': value,
        'availabilityUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _isAvailable = value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating availability')),
      );
    }
    setState(() => _isLoading = false);
  }

  /// Submits the specialist's profile information for approval.
  ///
  /// This function first checks if all required fields have been filled in. If
  /// they have, it updates the Firestore document for the current user with
  /// the status 'pending' and the current timestamp. It also sets the local
  /// `_approvalStatus` variable to 'pending'.
//  / Submission handler
  // Future<void> _submitForApproval() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;
  //   // Validate all required fields
  //   final isValid = _validateAllFields();

  //   if (isValid) {
  //     setState(() => isLoading = true);
  //     try {
  //       await _firestore.collection('users').doc(user.uid).update({
  //         'status': 'pending',
  //         'submissionDate': FieldValue.serverTimestamp(),
  //       });
  //       setState(() => _approvalStatus = 'pending');
  //     } finally {
  //       setState(() => isLoading = false);
  //     }
  //   }
  // }

  // bool _validateAllFields() {
  //   final requiredFields = [
  //     _professionController.text,
  //     _experienceController.text,
  //     _bioController.text,
  //     _cityController.text,
  //     _addressController.text,
  //     _phoneController.text,
  //     _previousWorkUrls.toString(),
  //   ];

  //   return requiredFields.every((field) => field.isNotEmpty) && _previousWorkUrls.isNotEmpty && Provider.of<EditCategoryProvider>(context, listen: false).submittedCategories.isNotEmpty;
  // }

  @override
  void dispose() {
    _bioController.dispose();
    _cityController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Widget _buildProfessionSection() {
    final hasProfession = _initialData?['profession'] != null && _initialData!['profession'].toString().isNotEmpty;
    final hasValue = _professionController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonalDetailText(text: LocaleData.profession.getString(context)),
        SizedBox(height: 15.h),
        TextFormField(
          controller: _professionController,
          decoration: InputDecoration(
            labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
            hintStyle: appTextStyle16400(AppColors.appGrayTextColor),
            hintText: '',
            fillColor: AppColors.grayColor,
            errorText: hasValue ? null : 'This field is required',
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.h), borderSide: BorderSide.none),
          ),
          enabled: _isEditingProfession || !hasProfession,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                if (_isEditingProfession || !hasProfession) {
                  _updateProfession(context);
                }
                setState(() {
                  _isEditingProfession = !_isEditingProfession;
                });
              },
              child: Row(
                children: [
                  _buildFieldStatusIndicator('professionStatus'),
                  SizedBox(width: 10.w),
                  Text(
                    _isEditingProfession
                        ? LocaleData.save.getString(context)
                        : hasProfession
                            ? LocaleData.edit.getString(context)
                            : LocaleData.create.getString(context),
                    style: appTextStyle14(AppColors.newThirdGrayColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    final hasExperience = _initialData?['experience'] != null && _initialData!['experience'].toString().isNotEmpty;
    final hasValue = _experienceController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonalDetailText(text: LocaleData.yearsOfExperience.getString(context)),
        SizedBox(height: 15.h),
        TextFormField(
          controller: _experienceController,
          decoration: InputDecoration(
            labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
            hintStyle: appTextStyle16400(AppColors.appGrayTextColor),
            hintText: '',
            errorText: hasValue ? null : 'This field is required',
            fillColor: AppColors.grayColor,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.h), borderSide: BorderSide.none),
          ),
          enabled: _isEditingExperience || !hasExperience,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                if (_isEditingExperience || !hasExperience) {
                  _updateExperience(context);
                }
                setState(() {
                  _isEditingExperience = !_isEditingExperience;
                });
              },
              child: Row(
                children: [
                  _buildFieldStatusIndicator('experienceStatus'),
                  SizedBox(width: 10.w),
                  Text(
                    _isEditingExperience
                        ? LocaleData.save.getString(context)
                        : hasExperience
                            ? LocaleData.edit.getString(context)
                            : LocaleData.create.getString(context),
                    style: appTextStyle14(AppColors.newThirdGrayColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCitySection() {
    final hasCity = _initialData?['city'] != null && _initialData!['city'].toString().isNotEmpty;
    final hasValue = _cityController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonalDetailText(text: LocaleData.city.getString(context)),
        SizedBox(height: 15.h),
        TextFormField(
          controller: _cityController,
          decoration: InputDecoration(
            labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
            hintStyle: appTextStyle16400(AppColors.appGrayTextColor),
            hintText: '',
            errorText: hasValue ? null : 'This field is required',
            fillColor: AppColors.grayColor,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.h), borderSide: BorderSide.none),
          ),
          enabled: _isEditingCity || !hasCity,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                if (_isEditingCity || !hasCity) {
                  _updateCity(context);
                }
                setState(() {
                  _isEditingCity = !_isEditingCity;
                });
              },
              child: Row(
                children: [
                  _buildFieldStatusIndicator('cityStatus'),
                  SizedBox(width: 10.w),
                  Text(
                    _isEditingCity
                        ? LocaleData.save.getString(context)
                        : hasCity
                            ? LocaleData.edit.getString(context)
                            : LocaleData.create.getString(context),
                    style: appTextStyle14(AppColors.newThirdGrayColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    final hasAddress = _initialData?['address'] != null && _initialData!['address'].toString().isNotEmpty;
    final selectedAddress = Provider.of<AddressProvider>(context).selectedAddress;
    // final hasValue = _addressController.text.isNotEmpty;

    // if (selectedAddress == null) {
    //   return Container();
    // }

    _addressController.text = selectedAddress?.address.toString() ?? '';

    return Consumer<SpecialistProvider>(builder: (context, provider, _) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonalDetailText(text: 'Address'),
          SizedBox(height: 15.h),
          InkWell(
            onTap: _showAddressBottomSheet,
            child: IgnorePointer(
              child: TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
                  hintStyle: appTextStyle16400(AppColors.appGrayTextColor),
                  hintText: provider.specialistModel!.address,
                  errorText: provider.specialistModel!.address.isNotEmpty ? null : 'This field is required',
                  fillColor: AppColors.grayColor,
                  suffixIcon: Icon(
                    Icons.arrow_drop_down,
                    size: 26.h,
                  ),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.h), borderSide: BorderSide.none),
                ),
                enabled: _isEditingAddress || !hasAddress,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  if (_isEditingAddress || !hasAddress) {
                    _updateAddress(context);
                  }
                  setState(() {
                    _isEditingAddress = !_isEditingAddress;
                  });
                },
                child: Row(
                  children: [
                    _buildFieldStatusIndicator('addressStatus'),
                    SizedBox(width: 10.w),
                    Text(
                      _isEditingAddress
                          ? LocaleData.save.getString(context)
                          : hasAddress
                              ? LocaleData.edit.getString(context)
                              : LocaleData.create.getString(context),
                      style: appTextStyle14(AppColors.newThirdGrayColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildBioSection() {
    final hasBio = _initialData?['bio'] != null && _initialData!['bio'].toString().isNotEmpty;
    final hasValue = _bioController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonalDetailText(text: LocaleData.bio.getString(context)),
        SizedBox(height: 15.h),
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
            hintStyle: appTextStyle16400(AppColors.appGrayTextColor),
            hintText: '',
            errorText: hasValue ? null : 'This field is required',
            fillColor: AppColors.grayColor,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.h), borderSide: BorderSide.none),
          ),
          maxLines: 4,
          enabled: _isEditingBio || !hasBio,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a bio';
            }
            return null;
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                if (_isEditingBio || !hasBio) {
                  _updateBio(context);
                }
                setState(() {
                  _isEditingBio = !_isEditingBio;
                });
              },
              child: Row(
                children: [
                  _buildFieldStatusIndicator('bioStatus'),
                  SizedBox(width: 10.w),
                  Text(
                    _isEditingBio
                        ? LocaleData.save.getString(context)
                        : hasBio
                            ? LocaleData.edit.getString(context)
                            : LocaleData.create.getString(context),
                    style: appTextStyle14(AppColors.newThirdGrayColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneSection() {
    final hasPhone = _initialData?['phone'] != null && _initialData!['phone'].toString().isNotEmpty;
    final hasValue = _phoneController.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonalDetailText(text: LocaleData.phoneNumber.getString(context)),
        SizedBox(height: 15.h),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelStyle: appTextStyle12K(AppColors.appGrayTextColor),
            hintStyle: appTextStyle16400(AppColors.appGrayTextColor),
            hintText: '',
            errorText: hasValue ? null : 'This field is required',
            fillColor: AppColors.grayColor,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.h), borderSide: BorderSide.none),
          ),
          enabled: _isEditingPhone || !hasPhone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                if (_isEditingPhone || !hasPhone) {
                  _updatePhone(context);
                }
                setState(() {
                  _isEditingPhone = !_isEditingPhone;
                });
              },
              child: Row(
                children: [
                  _buildFieldStatusIndicator('phoneStatus'),
                  SizedBox(width: 10.w),
                  Text(
                    _isEditingPhone
                        ? LocaleData.save.getString(context)
                        : hasPhone
                            ? LocaleData.edit.getString(context)
                            : LocaleData.create.getString(context),
                    style: appTextStyle14(AppColors.newThirdGrayColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EditCategoryProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(height: 50.h, width: 50.w, child: Image.asset('assets/images/Scissors.png')),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Text(
                        LocaleData.specialistDetails.getString(context),
                        style: appTextStyle205(AppColors.newThirdGrayColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        LocaleData.goToClient.getString(context),
                        style: appTextStyle205(AppColors.newThirdGrayColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                      value: _isAvailable,
                      onChanged: _isLoading ? null : _updateAvailability,
                      activeColor: AppColors.greenColor,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                _buildProfessionSection(),
                SizedBox(height: 24.h),
                _buildExperienceSection(),
                SizedBox(height: 24.h),
                _buildCitySection(),
                SizedBox(height: 24.h),
                _buildAddressSection(),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: PersonalDetailText(
                        text: LocaleData.serviceCategory.getString(context),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceSelectionScreen())),
                      child: Row(
                        children: [
                          // _buildFieldStatusIndicator('categoriesStatus'),
                          SizedBox(width: 10.w),
                          Text(
                            'Edit',
                            style: appTextStyle14(AppColors.newThirdGrayColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15.h),
                Wrap(
                  spacing: 8,
                  children: provider.submittedCategories.isNotEmpty
                      ? provider.submittedCategories.map((categoryId) {
                          final categoryName = provider.getCategoryName(categoryId, 'en');
                          return Chip(
                            backgroundColor: AppColors.grayColor,
                            label: Text(
                              categoryName,
                              style: appTextStyle12K(AppColors.mainBlackTextColor),
                            ),
                          );
                        }).toList()
                      : (_initialData?['categories'] as List?)?.map<Widget>((category) {
                            return Chip(
                              backgroundColor: AppColors.grayColor,
                              label: Text(
                                category.toString(),
                                style: appTextStyle12K(AppColors.mainBlackTextColor),
                              ),
                            );
                          }).toList() ??
                          [
                            Text(
                              'No categories selected',
                              style: appTextStyle12K(AppColors.mainBlackTextColor),
                            )
                          ],
                ),
                const SizedBox(height: 24),
                PersonalDetailText(
                  text: LocaleData.services.getString(context),
                ),
                ...(provider.submittedServices.isNotEmpty
                    ? provider.submittedServices.map((service) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  service.name,
                                  style: appTextStyle15(AppColors.mainBlackTextColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '-',
                                  style: appTextStyle15(AppColors.mainBlackTextColor),
                                ),
                                Text(
                                  formatPrice(service.price.toString()) ?? '',
                                  style: appTextStyle15(AppColors.mainBlackTextColor),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ],
                        );
                      }).toList()
                    : (_initialData?['services'] as List?)?.map((service) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    service['service'] ?? '',
                                    style: appTextStyle15(AppColors.mainBlackTextColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '-',
                                    style: appTextStyle15(AppColors.mainBlackTextColor),
                                  ),
                                  Text(
                                    formatPrice(service['price'].toString()) ?? '',
                                    style: appTextStyle15(AppColors.mainBlackTextColor),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ],
                              ),
                            ],
                          );
                        }).toList() ??
                        []),
                const SizedBox(height: 40),
                _buildBioSection(),
                SizedBox(height: 24.h),
                _buildPhoneSection(),
                SizedBox(height: 24.h),
                PersonalDetailText(
                  text: LocaleData.previousWork.getString(context),
                ),
                SizedBox(height: 20.h),
                _imageFiles.isNotEmpty
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _previousWorkUrls.length + _imageFiles.length,
                        itemBuilder: (context, index) {
                          if (index < _previousWorkUrls.length) {
                            return _buildUploadedImageItem(_previousWorkUrls[index]);
                          } else {
                            return _buildNewImageItem(_imageFiles[index - _previousWorkUrls.length]);
                          }
                        },
                      )
                    // GridView.builder(
                    //     shrinkWrap: true,
                    //     physics: const NeverScrollableScrollPhysics(),
                    //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    //       crossAxisCount: 2,
                    //       crossAxisSpacing: 4.0,
                    //       mainAxisSpacing: 4.0,
                    //       childAspectRatio: 0.7,
                    //     ),
                    //     itemCount: _imageFiles.length,
                    //     itemBuilder: (context, index) {
                    //       return _widgetBuildImageItems(context, index);
                    //     },
                    //   )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _pickImages,
                            child: CircleAvatar(
                              backgroundColor: AppColors.grayColor,
                              radius: 70.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 5.w),
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    color: AppColors.mainBlackTextColor,
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                              width: 180.w,
                              child: Text(
                                LocaleData.note.getString(context),
                                style: appTextStyle12K(AppColors.mainBlackTextColor),
                              ))
                        ],
                      ),
                _buildFieldStatusIndicator('previousWorkStatus'),
                SizedBox(width: 10.w),
                const SizedBox(height: 20),
                StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Center(child: Text('Specialist not found'));
                      }
                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                      final previousWorkStatus = userData['previousWorkStatus'] ?? 'draft';
                      final previousWork = previousWorkStatus == 'approved' ? List<String>.from(userData['previousWork'] ?? []) : [];

                      return Column(
                        children: [
                          previousWork.isNotEmpty
                              ? SizedBox(
                                  height: 80,
                                  child: GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1),
                                    itemCount: previousWork.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      return Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20.dg),
                                                color: AppColors.appBGColor,
                                              ),
                                              padding: EdgeInsets.all(3.w),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(20.dg),
                                                child: Image.network(
                                                  previousWork[index],
                                                  width: 120.w,
                                                  height: 140.h,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                                    'assets/default_work.png',
                                                    width: 130.w,
                                                    height: 140.h,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 0,
                                            child: IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteImage(previousWork[index]),
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                                )
                              : SizedBox.shrink(),
                        ],
                      );
                    }),

                // ElevatedButton(
                //   onPressed: _approvalStatus == 'draft' ? _submitForApproval : null,
                //   child: Text('Submit for Approval'),
                // ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedImageItem(String imageUrl) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20.h),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: 150,
            height: 150,
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteImage(imageUrl),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageItem(File imageFile) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20.h),
              child: Image.file(
                imageFile,
                fit: BoxFit.cover,
                width: 150,
                height: 150,
              ),
            ),
            // Spacer(),
            SizedBox(width: 20.w),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: CircleAvatar(radius: 16.dg, child: Icon(Icons.close, color: Colors.red)),
                  onPressed: () => setState(() => _imageFiles.remove(imageFile)),
                ),
              ],
            ),
            // Positioned(
            //   top: 5,
            //   right: 5,
            //   child: IconButton(
            //     icon: Icon(Icons.close, color: Colors.red),
            //     onPressed: () => setState(() => _imageFiles.remove(imageFile)),
            //   ),
            // ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () async {
                await uploadPreviousWork(context);
              },
              child: isLoading
                  ? const CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.appBGColor),
                    )
                  : Text(
                      LocaleData.save.getString(context),
                      style: appTextStyle14(AppColors.mainBlackTextColor),
                    ),
            ),
          ],
        ),
      ],
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
