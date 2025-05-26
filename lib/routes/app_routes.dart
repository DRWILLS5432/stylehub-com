import 'package:flutter/material.dart';
import 'package:stylehub/auth_screens/login_page.dart';
import 'package:stylehub/auth_screens/send_otp_screen.dart';
import 'package:stylehub/auth_screens/splash_screen.dart';
import 'package:stylehub/onboarding_page/onboarding_screen.dart';
import 'package:stylehub/screens/admin/admin_login_screen.dart';
import 'package:stylehub/screens/customer_pages/customer_home_page.dart';
import 'package:stylehub/screens/specialist_pages/filter_screen.dart';
import 'package:stylehub/screens/specialist_pages/profile_screen.dart';
import 'package:stylehub/screens/specialist_pages/specialist_home_page.dart';
import 'package:stylehub/screens/specialist_pages/widgets/personal_detail_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  // To Extract the route name from settings
  final routeName = settings.name;

  // Define a map of routes and their corresponding widgets
  final routes = {
    '/': (context) => SplashScreen(),
    '/onboarding_screen': (context) => OnboardingScreen(),
    '/login_screen': (context) => LoginPage(),
    '/send_otp_screen': (context) => SendOtpScreen(),
    '/customer_page': (context) => CustomerPage(),
    '/specialist_page': (context) => SpecialistPage(),
    '/specialist_profile': (context) => SpecialistProfileScreen(),
    '/personal_details': (context) => PersonalDetailScreen(),
    '/filter_screen': (context) => FilterScreen(),
    '/admin_page': (context) => AdminLoginPage(),
    // '/notification_detail': (context) => NotificationScreen(),
    // '/specialist_detail_screen': (context) => SpecialistDetailScreen(),
    // '/make_appointment_screen': (context) => MakeAppointmentScreen(),
  };

  // Check if the requested route is in the routes map
  final builder = routes[routeName];

  // If the route is found, return the corresponding widget
  if (builder != null) {
    return MaterialPageRoute(
      builder: builder,
      settings: settings,
    );
  }
  // If the route is not found, you can handle it with a default page or error page
  return MaterialPageRoute(
    builder: (context) => const ErrorPage(), // Create a DefaultPage widget
    settings: settings,
  );
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Back",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              )),
          const SizedBox(width: 40),
          const Text("Error"),
        ],
      ),
    );
  }
}
