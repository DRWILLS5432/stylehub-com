import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/screens/specialist_pages/model/specialist_model.dart';
import 'package:stylehub/screens/specialist_pages/provider/app_notification_provider.dart';
import 'package:stylehub/screens/specialist_pages/provider/edit_category_provider.dart';
import 'package:stylehub/screens/specialist_pages/provider/filter_provider.dart';
import 'package:stylehub/screens/specialist_pages/provider/language_provider.dart';
import 'package:stylehub/screens/specialist_pages/screens/notification_detail.dart';
import 'package:stylehub/screens/specialist_pages/specialist_detail_screen.dart';

class SpecialistDashboard extends StatefulWidget {
  const SpecialistDashboard({super.key});

  @override
  State<SpecialistDashboard> createState() => _SpecialistDashboardState();
}

class _SpecialistDashboardState extends State<SpecialistDashboard> with RouteAware {
  String? userName;
  Uint8List? _imageBytes;
  String? currentUserId;
  Position? _currentPosition;
  double? _userLat;
  double? _userLng;
  // Address? _selectedAddress;
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  @override
  void initState() {
    super.initState();

    fetchCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUserData();
    final ModalRoute<dynamic>? modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

// 2. Modify _fetchUserData to get stored coordinates

  void fetchCategories() {
    final provider = Provider.of<EditCategoryProvider>(context, listen: false);
    provider.loadCategories();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('No user is currently signed in')),
        // );
        return;
      }

      setState(() => currentUserId = user.uid);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('User data not found')),
        // );
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
        // Safely access firstName
        userName = userData['firstName'] as String? ?? 'Unknown';

        // Safely handle profileImage
        String? base64Image = userData['profileImage'] as String?;
        if (base64Image != null && base64Image.isNotEmpty) {
          try {
            _imageBytes = base64Decode(base64Image);
          } catch (e) {
            debugPrint('Error decoding image: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load profile image')),
            );
          }
        }

        // Safely handle lat and lng
        try {
          _userLat = _parseCoordinate(userData['lat']);
          _userLng = _parseCoordinate(userData['lng']);
        } catch (e) {
          debugPrint('Error parsing coordinates: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load location data')),
          );
          _userLat = null;
          _userLng = null;
        }
      });
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data. Please try again.')),
      );
    }
  }

  /// Helper function to safely parse coordinates to double
  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
  // Future<void> _fetchUserData() async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     setState(() => currentUserId = user.uid);

  //     DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

  //     if (userDoc.exists) {
  //       Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

  //       if (userData != null) {
  //         setState(() {
  //           userName = userData['firstName'] as String?;
  //           String? base64Image = userData['profileImage'] as String?;
  //           if (base64Image != null) {
  //             try {
  //               _imageBytes = base64Decode(base64Image);
  //             } catch (e) {
  //               debugPrint('Error decoding image: $e');
  //             }
  //           }
  //         });

  //         _userLat = userData['lat']?.toDouble();
  //         _userLng = userData['lng']?.toDouble();
  //       }
  //     }
  //   }
  // }

  @override
  void dispose() {
    // Unsubscribe from RouteAware
    routeObserver.unsubscribe(this);

    super.dispose();
  }

  List<String> categoryImages = [
    'assets/images/four.png',
    'assets/images/three.png',
    'assets/images/two.png',
    'assets/images/one.png',
    'assets/images/four.png',
  ];
  Stream<QuerySnapshot> _getSpecialistsStream(FilterProvider filterProvider) {
    Query query = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Stylist');

    // Filter for all status fields being "approved"
    const statusFields = [
      'professionStatus',
      'experienceStatus',
      'cityStatus',
      'addressStatus',
      'bioStatus',
      'phoneStatus',
      'previousWorkStatus',
    ];
    for (final statusField in statusFields) {
      query = query.where(statusField, isEqualTo: 'approved');
    }

    // Existing filters
    if (filterProvider.selectedCity != null && filterProvider.selectedCity!.isNotEmpty) {
      query = query.where('city', isEqualTo: filterProvider.selectedCity);
    }

    if (filterProvider.selectedCategory != null && filterProvider.selectedCategory!.isNotEmpty) {
      query = query.where('categories', arrayContains: filterProvider.selectedCategory);
    }

    if (filterProvider.highestRating) {
      query = query.orderBy('averageRating', descending: true);
    } else if (filterProvider.mediumRating) {
      query = query.where('averageRating', isGreaterThanOrEqualTo: 2.5).where('averageRating', isLessThan: 4.0);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // final provider = Provider.of<NotificationProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: CustomScrollView(
        slivers: [
          // First SliverAppBar for the header section
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 170.h,
            toolbarHeight: 10.h,
            pinned: true,
            // backgroundColor: AppColors.appBGColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.0),
                    bottomRight: Radius.circular(12.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile avatar
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/specialist_profile'),
                      child: Hero(
                        tag: '1',
                        child: Container(
                          padding: EdgeInsets.all(4.dg),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100.dg),
                            color: AppColors.appBGColor,
                          ),
                          child: CircleAvatar(
                            radius: 50.dg,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                            child: _imageBytes == null ? Icon(Icons.add_a_photo, size: 30, color: Colors.grey[600]) : null,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    // Welcome text
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 0.h),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                LocaleData.welcomeBack.getString(context),
                                style: appTextStyle20(AppColors.newGrayColor),
                              ),
                              Text(
                                userName ?? '',
                                style: appTextStyle20(AppColors.newGrayColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Notification icon
                    InkWell(
                      radius: 20,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: Consumer<NotificationProvider>(builder: (context, provider, _) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 30.h),
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/Bell.png',
                                height: 26.h,
                                width: 27.w,
                              ),
                              provider.notifications.isEmpty
                                  ? const SizedBox()
                                  : const Positioned(
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 4,
                                        backgroundColor: Colors.red,
                                      ))
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Second SliverAppBar for the categories (pinned)
          SliverAppBar(
            floating: true,
            pinned: true,
            toolbarHeight: 140.h,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                height: 120.h,
                color: Color(0xFFD7D1BE),
                padding: EdgeInsets.only(left: 16.w, top: 15.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    Text(
                      LocaleData.category.getString(context),
                      style: appTextStyle18(AppColors.newThirdGrayColor),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 110.h,
                      child: Consumer<EditCategoryProvider>(
                        builder: (context, categoryProvider, _) {
                          if (categoryProvider.availableCategories.isEmpty) {
                            return Center(child: CircularProgressIndicator());
                          }
                          return Consumer<FilterProvider>(
                            builder: (context, filterProvider, _) {
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: categoryProvider.availableCategories.length,
                                itemBuilder: (context, index) {
                                  final category = categoryProvider.availableCategories[index];
                                  return GestureDetector(
                                    onTap: () {
                                      filterProvider.setSelectedCategory(filterProvider.selectedCategory == category.name ? null : category.name);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 10.w),
                                      child: Column(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color.fromARGB(255, 129, 128, 127),
                                                width: 3,
                                              ),
                                              boxShadow: filterProvider.selectedCategory == category.name
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.grey,
                                                        blurRadius: 6,
                                                        offset: Offset(0, 5),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: CircleAvatar(
                                              backgroundColor: AppColors.whiteColor,
                                              radius: 35,
                                              backgroundImage: category.imageUrl != null
                                                  ? NetworkImage(category.imageUrl!)
                                                  : AssetImage(
                                                      categoryImages[index % categoryImages.length],
                                                    ) as ImageProvider,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Consumer<LanguageProvider>(builder: (context, provider, child) {
                                            return Text(
                                              provider.currentLanguage == 'en' ? category.name : category.ruName,
                                              style: appTextStyle15(
                                                filterProvider.selectedCategory == category.name ? Colors.black : AppColors.newThirdGrayColor,
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Title and filter button
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h, top: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.dg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 205.w,
                    child: Text(
                      LocaleData.findProfessional.getString(context),
                      style: appTextStyle16400(AppColors.newThirdGrayColor),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/filter_screen'),
                    child: Image.asset(
                      'assets/categ_settings.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content with specialists
          Consumer<FilterProvider>(
            builder: (context, filterProvider, child) {
              return StreamBuilder<QuerySnapshot>(
                stream: _getSpecialistsStream(filterProvider),

// In the StreamBuilder's builder function:
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(child: Text('Error: ${snapshot.error}', style: appTextStyle16400(Colors.red))),
                    );
                  }

                  if (!snapshot.hasData) {
                    return SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          'No specialists found matching your filters',
                          style: appTextStyle16400(AppColors.newThirdGrayColor),
                        ),
                      ),
                    );
                  }

                  final specialists = docs.map((doc) => SpecialistModel.fromFirestore(doc)).toList();
                  final filteredSpecialists = _applyProximityFilters(
                    specialists: specialists,
                    filterProvider: filterProvider,
                  );

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final specialist = filteredSpecialists[index];
                        final distance = _calculateDistance(specialist);
                        return buildProfessionalCard(
                          context,
                          specialist,
                          specialist.averageRating,
                          distance.toString(),
                        );
                      },
                      childCount: filteredSpecialists.length,
                    ),
                  );
                },
              );
            },
          ),

          SliverAppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 40,
          )
        ],
      ),
    );
  }

  Widget buildProfessionalCard(
    BuildContext context,
    SpecialistModel user,
    double averageRating,
    String? distance,
  ) {
    double distance = _calculateDistance(user);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpecialistDetailScreen(userId: user.userId, name: user.fullName, rating: averageRating, distance: distance),
        ),
      ),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        color: Color(0xFFD7D1BE),
        child: Padding(
          padding: EdgeInsets.only(left: 17.w, right: 17.h, top: 29.h, bottom: 12.h),
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
                      backgroundImage: user.profileImage != null ? MemoryImage(base64Decode(user.profileImage!)) : AssetImage('assets/images/pro.png') as ImageProvider,
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
                              index < averageRating.floor() ? Icons.star : Icons.star_border,
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
                        formatDistance(distance),
                        style: appTextStyle15(AppColors.newThirdGrayColor),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpecialistDetailScreen(userId: user.userId, name: user.fullName, rating: averageRating, distance: distance),
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
      ),
    );
  }

  double _calculateDistance(SpecialistModel specialist) {
    // Early return if any coordinate is missing
    if (_userLat == null || _userLng == null || specialist.lat == null || specialist.lng == null) {
      // debugPrint('Missing coordinates:');
      // if (_userLat == null) debugPrint(' - User latitude is null');
      // if (_userLng == null) debugPrint(' - User longitude is null');
      // if (specialist.lat == null) debugPrint(' - Specialist latitude is null (ID: ${specialist.userId})');
      // if (specialist.lng == null) debugPrint(' - Specialist longitude is null (ID: ${specialist.userId})');
      // // Optional: Print available coordinates
      // if (_userLat != null || _userLng != null) {
      //   debugPrint('User coordinates: lat:$_userLat, lng:$_userLng');
      // }

      // if (specialist.lat != null || specialist.lng != null) {
      //   debugPrint('Specialist coordinates: lat:${specialist.lat}, lng:${specialist.lng}');
      // }
      return 0; // Or return null, or throw an error, depending on your needs
    }

    final distance = Geolocator.distanceBetween(
      _userLat!,
      _userLng!,
      specialist.lat!,
      specialist.lng!,
    );

    // debugPrint('Distance calculation successful:');
    // debugPrint(' - User location: ($_userLat, $_userLng)');
    // debugPrint(' - Specialist location: (${specialist.lat}, ${specialist.lng})');
    // debugPrint(' - Calculated distance: ${distance / 1000} km');

    return distance / 1000; // Convert meters to kilometers
  }

  List<SpecialistModel> _applyProximityFilters({
    required List<SpecialistModel> specialists,
    required FilterProvider filterProvider,
  }) {
    final hasValidUserCoords = _userLat != null && _userLng != null;

    var filtered = specialists.where((specialist) {
      // Skip specialists with missing coordinates if proximity is enabled
      if (filterProvider.maxDistance != null || filterProvider.sortByDistance) {
        if (specialist.lat == null || specialist.lng == null || !hasValidUserCoords) {
          return false; // Exclude from results
        }
      }

      // Proximity check
      if (filterProvider.maxDistance != null && hasValidUserCoords) {
        final distance = _calculateDistance(specialist);
        return distance <= filterProvider.maxDistance!;
      }

      return true;
    }).toList();

    // Sort only if user coordinates are valid
    if (filterProvider.sortByDistance && hasValidUserCoords) {
      filtered.sort((a, b) {
        final distA = _calculateDistance(a);
        final distB = _calculateDistance(b);
        return distA.compareTo(distB);
      });
    }

    return filtered;
  }

// 5. Update distance display formatting
  String formatDistance(double km) {
    if (km <= 0) return 'N/A';
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)}km';
  }
}
