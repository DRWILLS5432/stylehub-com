import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch(context);
  }

  Future<void> _checkFirstLaunch(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    // Delay for 3 seconds to simulate a splash screen
    // Future.delayed(const Duration(seconds: 0), () {
    //   Navigator.pushNamed(context, '/onboarding_screen');

    if (isFirstLaunch) {
      // If it's the first launch, navigate to the OnboardingScreen
      Navigator.pushNamed(context, '/onboarding_screen');

      // Set isFirstLaunch to false for future launches
      prefs.setBool('isFirstLaunch', true);
    } else {
      // If it's not the first launch, navigate to the LoginPage
      Navigator.pushNamed(context, '/login_screen');
    }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7D1BE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 300,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
