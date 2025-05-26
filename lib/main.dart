import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/app_providers.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/routes/app_routes.dart';
import 'package:stylehub/services/auth_state_check.dart';
import 'package:stylehub/services/fcm_services/firebase_msg.dart';
import 'package:stylehub/services/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterLocalization.instance.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));
  // Initialize FCM and get token
  final firebaseService = FirebaseService();
  // Initialize FCM
  // await FirebaseNotificationService.initialize();
  // Initialize notifications
  await FirebaseNotificationService.initialize();

  // Set up token refresh listener
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    if (FirebaseAuth.instance.currentUser != null) {
      firebaseService.saveFcmToken(FirebaseAuth.instance.currentUser!.uid, newToken);
    }
  });

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalization localization = FlutterLocalization.instance;

  @override
  void initState() {
    super.initState();
    configureLocalization();
    // _setupNotificationClickHandler();
  }

  void configureLocalization() {
    localization.init(mapLocales: LOCALES, initLanguageCode: 'en');
    localization.onTranslatedLanguage = onTranslatedLanguage;
  }

  void onTranslatedLanguage(Locale? locale) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: changeNotifierProvider,
      child: ScreenUtilInit(
          designSize: Size(375, 812),
          builder: (context, child) => MaterialApp(
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                title: 'My App',
                theme: ThemeData(
                  primarySwatch: Colors.deepPurple,
                  appBarTheme: AppBarTheme(color: AppColors.whiteColor, surfaceTintColor: AppColors.whiteColor),
                  scaffoldBackgroundColor: AppColors.whiteColor,
                  dialogTheme: DialogTheme(
                    backgroundColor: AppColors.whiteColor,
                  ),
                ),
                supportedLocales: localization.supportedLocales,
                localizationsDelegates: localization.localizationsDelegates,
                home: AuthWrapper(),
                onGenerateRoute: onGenerateRoute,
              )),
    );
  }
}

// // Обертка для SplashScreen с переходом на LoginPage
// class SplashScreenWrapper extends StatefulWidget {
//   @override
//   _SplashScreenWrapperState createState() => _SplashScreenWrapperState();
// }

// class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
//   @override
//   void initState() {
//     super.initState();
//     // Переход на экран LoginPage через 3 секунды
//     Future.delayed(const Duration(seconds: 3), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => SplashScreen()),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SplashScreen(); // Отображаем сам SplashScreen
//   }
// }
