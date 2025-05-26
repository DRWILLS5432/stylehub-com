import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stylehub/auth_screens/splash_screen.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/screens/customer_pages/customer_home_page.dart';
import 'package:stylehub/screens/specialist_pages/specialist_home_page.dart';
import 'package:stylehub/services/firebase_auth.dart';

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.active) {
//           User? user = snapshot.data;
//           if (user != null) {
//             // User is signed in, fetch their role and navigate accordingly
//             return FutureBuilder<String?>(
//               future: FirebaseService().getUserRole(user.uid),
//               builder: (context, roleSnapshot) {
//                 if (!roleSnapshot.hasData) {
//                   return Scaffold(
//                     backgroundColor: AppColors.appBGColor,
//                     body: Center(
//                         child: CircularProgressIndicator.adaptive(
//                       valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainBlackTextColor),
//                     )),
//                   );
//                 } else if (roleSnapshot.hasData) {
//                   String? role = roleSnapshot.data;
//                   if (role == 'Customer') {
//                     return CustomerPage();
//                   } else if (role == 'Stylist') {
//                     return SpecialistPage();
//                   } else {
//                     // Handle unknown roles or errors
//                     return Scaffold(
//                       body: Center(
//                         child: Text('Unknown role. Please contact support.'),
//                       ),
//                     );
//                   }
//                 } else {
//                   // Handle errors fetching the role
//                   return Scaffold(
//                     body: Center(
//                       child: Text('Failed to fetch user role. Please try again.'),
//                     ),
//                   );
//                 }
//               },
//             );
//           } else {
//             // User is not signed in, navigate to SplashScreen or LoginScreen
//             return SplashScreen();
//           }
//         }
//         // Show a loading indicator while checking auth state
//         return Scaffold(
//           body: Center(
//             child: CircularProgressIndicator.adaptive(
//               valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainBlackTextColor),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;

          if (user != null) {
            return FutureBuilder<String?>(
              future: FirebaseService().getUserRole(user.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }
                return _handleRoleResponse(roleSnapshot);
              },
            );
          }
          // Directly return login screen for non-authenticated users
          return SplashScreen();
        }
        return _buildLoadingScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainBlackTextColor),
        ),
      ),
    );
  }

  Widget _handleRoleResponse(AsyncSnapshot<String?> snapshot) {
    if (snapshot.hasError) {
      return Scaffold(
        body: Center(child: Text('Error: ${snapshot.error}')),
      );
    }

    final role = snapshot.data;
    switch (role) {
      case 'Customer':
        return CustomerPage();
      case 'Stylist':
        return SpecialistPage();
      default:
        return Scaffold(
          body: Center(child: Text('Unknown user role')),
        );
    }
  }
}
