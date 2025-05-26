import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';

class OnboardingPageThree extends StatefulWidget {
  const OnboardingPageThree({super.key});

  @override
  State<OnboardingPageThree> createState() => _OnboardingPageThreeState();
}

class _OnboardingPageThreeState extends State<OnboardingPageThree> {
  bool _isLoading = false;
  Position? _userPosition; // Store user location

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoading = true;
    });

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
      });

      // Show AlertDialog prompting the user to enable location
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Required'),
          content: const Text('Please turn on your location services to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openLocationSettings();
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      return;
    }

    // Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to continue.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is permanently denied. Please enable it in settings.')),
      );
      return;
    }

    // Fetch the user's location
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _isLoading = false;
        _userPosition = position; // Store position
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get location. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBGColor,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Address.png',
                  height: 153.h,
                  width: 194.w,
                ),
                const SizedBox(height: 20),
                Text(
                  LocaleData.yourAddress.getString(context),
                  style: bigTextStyle(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _getUserLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.whiteColor,
                          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 0),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: AppColors.mainBlackTextColor),
                            borderRadius: BorderRadius.circular(50.dg),
                          ),
                        ),
                        child: Text(
                          'Use Location',
                          style: appTextStyle14(AppColors.mainBlackTextColor),
                        ),
                      ),
                const SizedBox(height: 20),
                // if (_userPosition != null) // Show only if location is available
                // Column(
                //   children: [
                //     Text(
                //       'Your Location:',
                //       style: bigTextStyle(),
                //     ),
                //     const SizedBox(height: 5),
                //     Text(
                //       'Latitude: ${_userPosition!.latitude}\nLongitude: ${_userPosition!.longitude}',
                //       textAlign: TextAlign.center,
                //       style: appTextStyle14(AppColors.whiteColor),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
