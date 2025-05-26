import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:stylehub/constants/Helpers/app_helpers.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/onboarding_page/onboarding_screen.dart';
import 'package:stylehub/screens/specialist_pages/make_appointment_screen.dart';
import 'package:stylehub/storage/likes_method.dart';
import 'package:url_launcher/url_launcher.dart';

class SpecialistDetailScreen extends StatefulWidget {
  final String userId;
  final String name;
  final double rating;
  final double distance;
  const SpecialistDetailScreen({super.key, required this.userId, required this.name, required this.rating, required this.distance});

  @override
  State<SpecialistDetailScreen> createState() => _SpecialistDetailScreenState();
}

class _SpecialistDetailScreenState extends State<SpecialistDetailScreen> {
  // bool toggleReviewField = false;
  bool toggleLikeIcon = false;
  String? selectedImage;
  // final ReviewService _reviewService = ReviewService();
  final LikeService _likeService = LikeService();

  @override

  /// Initializes the state of the widget.
  ///
  /// Calls the superclass's `initState` method, and then fetches the services
  /// provided by the given specialist.
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

// In your SpecialistDetailScreen, update the like-related methods:

  Future<void> _checkIfFavorite() async {
    bool isFav = await _likeService.isFavorite(widget.userId);
    setState(() {
      toggleLikeIcon = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    String result = await _likeService.toggleFavorite(widget.userId);
    if (result == 'liked' || result == 'unliked') {
      setState(() {
        toggleLikeIcon = result == 'liked';
      });
    } else {
      print(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

// // Update the like icon in your app bar:
// Icon(
//   toggleLikeIcon ? Icons.favorite : Icons.favorite_border,
//   color: toggleLikeIcon ? Colors.red : AppColors.newThirdGrayColor,
// ),

  /// Submits a review for a specialist.
  ///
  /// Submits a review with the given `rating` and `comment` for the specialist
  /// with the provided `userId`. Shows a success message if the submission is
  /// successful, and shows an error message if the submission fails.
  ///
  /// Parameters:
  /// - `context`: The BuildContext to use for showing a SnackBar.
  /// - `rating`: An integer representing the user's rating for the specialist.
  /// - `comment`: A string containing the user's comments or feedback.
  // void _submitReview(context, int rating, String comment) async {
  //   String result = await _reviewService.submitReview(
  //     userId: widget.userId,
  //     rating: rating,
  //     comment: comment,
  //   );

  //   if (result == 'success') {
  //     setState(() => toggleReviewField = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Review submitted successfully!')),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(result)),
  //     );
  //   }
  // }

  void _showZoomableImage(BuildContext context, String image, {bool isBase64 = false}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.dg)),
        child: Container(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Spacer(),
              CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )),
              SizedBox(
                height: 30.h,
              ),
              SizedBox(
                width: double.infinity,
                height: 400.h,
                child: PhotoView(
                  imageProvider: isBase64 ? MemoryImage(base64Decode(image)) : NetworkImage(image) as ImageProvider,
                  minScale: PhotoViewComputedScale.covered,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: InkWell(
                radius: 10.dg,
                splashColor: AppColors.whiteColor,
                highlightColor: AppColors.grayColor,
                onTap: _toggleFavorite,
                child: Icon(
                  toggleLikeIcon ? Icons.favorite : Icons.favorite_border,
                  color: toggleLikeIcon ? Colors.red : AppColors.newThirdGrayColor,
                ),
              ),
            ),
          ],
        ),
        body: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('Specialist not found'));
              }

              // final userData = snapshot.data!.data() as Map<String, dynamic>;
              // final profileImage = userData['profileImage'];
              // final bio = userData['bio'] ?? 'No bio available';
              // final categories = List<String>.from(userData['categories'] ?? []);
              // final images = List<String>.from(userData['images'] ?? []);
              // final services = List<Map<String, dynamic>>.from(userData['services'] ?? []);
              // final phone = userData['phone'];

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final profileImage = userData['profileImage'];
              final bio = userData['bio'] ?? 'No bio available';
              final categories = List<String>.from(userData['categories'] ?? []);

              // Modified code: Get approved previous work
              final previousWorkStatus = userData['previousWorkStatus'] ?? 'draft';
              final previousWork = previousWorkStatus == 'approved' ? List<String>.from(userData['previousWork'] ?? []) : [];

              final services = List<Map<String, dynamic>>.from(userData['services'] ?? []);
              final phone = userData['phone'];
              final address = userData['address'];
              final available = userData['isAvailable'];

              // Set default top image if it's not set
              // if (selectedImage == null && images.isNotEmpty) {
              //   selectedImage = images[0];
              // }

              // stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
              // builder: (context, snapshot) {
              //   if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              //   if (!snapshot.data!.exists) return Center(child: Text('Specialist not found'));

              //   final userData = snapshot.data!.data() as Map<String, dynamic>;

              //   // Approval status checks
              //   final isProfileApproved = userData['profileImageStatus'] == 'approved';
              //   final isBioApproved = userData['bioStatus'] == 'approved';
              //   final isCategoriesApproved = userData['categoriesStatus'] == 'approved';
              //   final isPreviousWorkApproved = userData['previousWorkStatus'] == 'approved';
              //   final isServicesApproved = userData['servicesStatus'] == 'approved';
              //   final isPhoneApproved = userData['phoneStatus'] == 'approved';

              //   // Approved data
              //   final profileImage = isProfileApproved ? userData['profileImage'] : null;
              //   final bio = isBioApproved ? userData['bio'] : null;
              //   final categories = isCategoriesApproved ? List<String>.from(userData['categories'] ?? []) : [];
              //   final images = isPreviousWorkApproved ? List<String>.from(userData['images'] ?? []) : [];
              //   final services = isServicesApproved ? List<Map<String, dynamic>>.from(userData['services'] ?? []) : [];
              //   final phone = isPhoneApproved ? userData['phone'] : null;

              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // **Big Image at the Top**
                            SizedBox(
                              width: double.maxFinite,
                              height: 304.h,
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(15.dg),
                                  bottomRight: Radius.circular(15.dg),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    if (profileImage != null) {
                                      _showZoomableImage(context, profileImage, isBase64: true);
                                    }
                                  },
                                  child: profileImage != null
                                      ? Image.memory(
                                          base64Decode(profileImage),
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(Icons.person, size: 200.dg),
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_pin, color: AppColors.newThirdGrayColor),
                                      Text(
                                        formatDistance(widget.distance),
                                        style: appTextStyle15(AppColors.newThirdGrayColor),
                                      ),
                                    ],
                                  ),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('likes').snapshots(),
                                    builder: (context, snapshot) {
                                      return Row(
                                        children: [
                                          Text(widget.rating.toStringAsFixed(1), style: appTextStyle15(AppColors.newThirdGrayColor)),
                                          Icon(Icons.star, color: AppColors.mainBlackTextColor, size: 15.dg),
                                          SizedBox(width: 10.w),
                                        ],
                                      );
                                    },
                                  )
                                ],
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Text(LocaleData.serviceProvide.getString(context), style: appTextStyle15600(AppColors.newThirdGrayColor)),
                            ),
                            SizedBox(height: 20.h),
                            // Widget to display list of selected Categories
                            // Display categories
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: Wrap(
                                  spacing: 12.0,
                                  children: categories.map((category) {
                                    late ImageProvider image;

                                    // Set image based on category name
                                    if (category == 'Shave') {
                                      image = NetworkImage(
                                          'https://firebasestorage.googleapis.com/v0/b/stylehub-1cfee.firebasestorage.app/o/category_images%2Fshave.png?alt=media&token=0ed65c60-972d-4b60-b672-d1760c428f96');
                                    } else if (category == 'Haircut') {
                                      image = NetworkImage(
                                          'https://firebasestorage.googleapis.com/v0/b/stylehub-1cfee.firebasestorage.app/o/category_images%2Fhaircut.png?alt=media&token=3dbdcaba-6ca7-4e9c-a529-2ba661904a7d');
                                    } else if (category == 'Facials') {
                                      image = NetworkImage(
                                          'https://firebasestorage.googleapis.com/v0/b/stylehub-1cfee.firebasestorage.app/o/category_images%2Ffacials.png?alt=media&token=e83ecc0f-226f-486c-8b47-d26228787970'); //
                                    } else if (category == 'Manicure') {
                                      image = NetworkImage(
                                          'https://firebasestorage.googleapis.com/v0/b/stylehub-1cfee.firebasestorage.app/o/category_images%2Fmanicure.png?alt=media&token=a175f502-9439-47e3-b059-f96d8d5b1fc8');
                                    } else if (category == 'Massage') {
                                      image = NetworkImage(
                                          'https://firebasestorage.googleapis.com/v0/b/stylehub-1cfee.firebasestorage.app/o/category_images%2FGroup%2017.png?alt=media&token=46a73c77-20ac-40a1-a82c-7f02c8de351b');
                                    } else {
                                      image = AssetImage('assets/master1.png');
                                    }

                                    return Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 33.dg,
                                          backgroundColor: const Color.fromARGB(255, 129, 128, 127),
                                          child: CircleAvatar(radius: 30.dg, backgroundImage: image, backgroundColor: Colors.white),
                                        ),
                                        SizedBox(height: 6.h),
                                        Text(category, style: appTextStyle15(AppColors.newThirdGrayColor)),
                                      ],
                                    );
                                  }).toList(),
                                )),
                            // Widget to display services
                            SizedBox(height: 36.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Text(LocaleData.previousWork.getString(context), style: appTextStyle15600(AppColors.newThirdGrayColor)),
                            ),
                            SizedBox(height: 20.h),
                            // Display uploaded images
                            // **Display Uploaded Images (Previous Work)**
                            // images.isNotEmpty
                            //     ? SizedBox(
                            //         height: 140,
                            //         child: ListView.builder(
                            //           scrollDirection: Axis.horizontal,
                            //           itemCount: images.length,
                            //           itemBuilder: (context, index) {
                            //             return GestureDetector(
                            //               onTap: () {
                            //                 // Show zoomable image
                            //                 _showZoomableImage(context, images[index]);
                            //               },
                            //               child: Padding(
                            //                 padding: const EdgeInsets.all(5.0),
                            //                 child: Container(
                            //                   decoration: BoxDecoration(
                            //                     borderRadius: BorderRadius.circular(110.dg),
                            //                     color: AppColors.appBGColor,
                            //                   ),
                            //                   padding: EdgeInsets.all(3.w),
                            //                   child: ClipRRect(
                            //                     borderRadius: BorderRadius.circular(100.dg),
                            //                     child: Image.network(
                            //                       images[index],
                            //                       width: 120.w,
                            //                       height: 140.h,
                            //                       fit: BoxFit.cover,
                            //                       errorBuilder: (context, error, stackTrace) => Image.asset(
                            //                         'assets/default_work.png', // Add a default work image to your assets
                            //                         width: 120.w,
                            //                         height: 140.h,
                            //                         fit: BoxFit.cover,
                            //                       ),
                            //                     ),
                            //                   ),
                            //                 ),
                            //               ),
                            //             );
                            //           },
                            //         ),
                            //       )
                            //     : Padding(
                            //         padding: const EdgeInsets.only(left: 20.0),
                            //         child: Text('No images uploaded'),
                            //       ),

                            // Display approved previous work
                            previousWork.isNotEmpty
                                ? SizedBox(
                                    height: 140,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: previousWork.length,
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            _showZoomableImage(context, previousWork[index]);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(110.dg),
                                                color: AppColors.appBGColor,
                                              ),
                                              padding: EdgeInsets.all(3.w),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(100.dg),
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
                                        );
                                      },
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(left: 20.0),
                                    child: Text(
                                      previousWorkStatus == 'pending' ? 'Previous work pending approval' : 'No previous work available',
                                    ),
                                  ),

                            SizedBox(height: 36.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Text(LocaleData.services.getString(context), style: appTextStyle15600(AppColors.newThirdGrayColor)),
                            ),

                            SizedBox(height: 10.h),
                            // Display services
                            Column(
                              children: services.map((service) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                                  child: Row(
                                    children: [
                                      Text(service['service'] ?? 'Service', style: appTextStyle15(AppColors.newThirdGrayColor).copyWith(fontWeight: FontWeight.w700)),
                                      Spacer(),
                                      Text('-'),
                                      Spacer(),
                                      Text(
                                          formatPrice(
                                            service['price'],
                                          ),
                                          style: appTextStyle15(AppColors.newThirdGrayColor).copyWith(fontWeight: FontWeight.w700)),
                                    ],
                                    // title: Text(service['service'] ?? 'Service'),
                                    // subtitle: Text('Price: ${service['price']}'),
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 20.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Text(LocaleData.bio.getString(context), style: appTextStyle15600(AppColors.newThirdGrayColor)),
                            ),
                            SizedBox(height: 10.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Text(bio.toString(), style: appTextStyle15(AppColors.newThirdGrayColor)),
                            ),
                            SizedBox(height: 20.h),
                            if (phone != null && phone.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15.w),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 0.w),
                                      height: 32.h,
                                      child: ReusableButton(
                                        bgColor: AppColors.grayColor,
                                        color: AppColors.appBGColor,
                                        text: Text(LocaleData.callMe.getString(context), style: appTextStyle15600(AppColors.newThirdGrayColor)),
                                        onPressed: () async {
                                          final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                                          try {
                                            if (await canLaunchUrl(phoneUri)) {
                                              await launchUrl(phoneUri);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Could not launch phone app')),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error initiating call: $e')),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 36.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Text(LocaleData.reviews.getString(context), style: appTextStyle15600(AppColors.newThirdGrayColor)),
                            ),
                            SizedBox(height: 20.h),
                            // InkWell(
                            //   radius: 20.dg,
                            //   onTap: () => setState(() {
                            //     toggleReviewField = !toggleReviewField;
                            //   }),
                            //   child: Padding(
                            //     padding: EdgeInsets.symmetric(horizontal: 15.w),
                            //     child: Row(
                            //       children: [
                            //         Text(LocaleData.leaveA.getString(context), style: appTextStyle15(AppColors.newThirdGrayColor)),
                            //         SizedBox(width: 10.w),
                            //         Text(LocaleData.review.getString(context), style: appTextStyle15(AppColors.mainBlackTextColor)),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            // if (toggleReviewField)
                            // WriteReviewWidget(
                            //     toggleReviewField: toggleReviewField,
                            //     onSubmit: (int rating, String review) {
                            //       _submitReview(context, rating, review);
                            //     }),
                            SizedBox(
                              height: 18.h,
                            ),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('reviews').orderBy('timestamp', descending: true).snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Center(child: const CircularProgressIndicator());
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                                    child: Text(
                                      'No reviews yet',
                                      style: appTextStyle15(AppColors.newThirdGrayColor),
                                    ),
                                  );
                                }

                                final reviews = snapshot.data!.docs;

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                                  itemCount: reviews.length,
                                  separatorBuilder: (context, index) => SizedBox(height: 16.h),
                                  itemBuilder: (context, index) {
                                    final review = reviews[index].data() as Map<String, dynamic>;
                                    return buildProfessionalCard(review);
                                    // ReviewCard(review: review);
                                  },
                                );
                              },
                            ),

                            SizedBox(
                              height: 110.h,
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 100.h,
                      width: double.infinity,
                      color: Colors.grey.withValues(alpha: 0.5),
                      child: Center(
                        child: SizedBox(
                          height: 44.3.h,
                          width: 202.w,
                          child: ReusableButton(
                            bgColor: AppColors.whiteColor,
                            color: AppColors.appBGColor,
                            text: Text(LocaleData.makeAppointment.getString(context), style: appTextStyle15(AppColors.newThirdGrayColor)),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MakeAppointmentScreen(
                                            specialistId: widget.userId,
                                            specialistName: widget.name,
                                            address: address,
                                            isAvailable: available,

                                          )));
                            },
                            // onPressed: () => Navigator.pushNamed(context, '/make_appointment_screen'),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              );
            }));
  }

  Widget buildProfessionalCard(final Map<String, dynamic> review) {
    return GestureDetector(
      onTap: () {},
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16.w),
        color: Color(0xFFD7D1BE),
        child: Padding(
          padding: EdgeInsets.only(left: 17.w, right: 17.h, top: 29.h, bottom: 12.h),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(2.dg),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(100.dg),
                    ),
                    child: CircleAvatar(
                      radius: 30.dg,
                      backgroundImage: AssetImage('assets/master1.png'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 5.h),
                        Row(
                          children: [
                            Text(review['reviewerName'] ?? 'Anonymous', style: appTextStyle15(AppColors.newThirdGrayColor)),
                            SizedBox(width: 5.w),
                            Text(review['reviewerLastName'] ?? 'Anonymous', style: appTextStyle15(AppColors.newThirdGrayColor)),
                          ],
                        ),
                        Row(
                          children: List.generate(
                              5,
                              (index) => Icon(
                                    index < (review['rating'] as int) ? Icons.star : Icons.star_border,
                                    color: Colors.black,
                                    size: 20.dg,
                                  )),
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
                      SizedBox(width: 250.w, child: Text(review['comment'] ?? '', style: appTextStyle15(AppColors.newThirdGrayColor))),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formatDate(review['timestamp']?.toDate()),
                    style: appTextStyle12(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.dg),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              review['reviewerName'] ?? 'Anonymous',
              style: appTextStyle15600(AppColors.mainBlackTextColor),
            ),
            // Rating Stars
            Row(
              children: List.generate(
                  5,
                  (index) => Icon(
                        index < (review['rating'] as int) ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20.dg,
                      )),
            ),
            SizedBox(height: 8.h),

            // Comment
            Text(
              review['comment'] ?? '',
              style: appTextStyle15(AppColors.newThirdGrayColor),
            ),
            SizedBox(height: 8.h),

            // Reviewer Info and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review['reviewerEmail'] ?? 'Anonymous',
                  style: appTextStyle12(),
                ),
                Text(
                  formatDate(review['timestamp']?.toDate()),
                  style: appTextStyle12(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String formatDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('MMM dd, yyyy').format(date);
}
