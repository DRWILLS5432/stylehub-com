import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylehub/main.dart';
import 'package:stylehub/screens/specialist_pages/model/app_notification_model.dart';
import 'package:stylehub/screens/specialist_pages/provider/app_notification_provider.dart';
import 'package:stylehub/screens/specialist_pages/screens/notification_detail.dart';
import 'package:stylehub/services/fcm_services/push_notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _setupFcmHandlers();
    await _requestPermissions();
    await _configureFcmSettings();
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationClick(details.payload);
      },
    );
  }

  static Future<void> _setupFcmHandlers() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotification(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotification);
  }

  static Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
  }

  static Future<void> _configureFcmSettings() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    await _processAndSaveNotification(message);
    await _showNotification(message);
  }

  static Future<void> _processAndSaveNotification(RemoteMessage message) async {
    try {
      final notification = AppNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        payload: message.data,
      );

      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList(NotificationProvider.storageKey) ?? [];
      notifications.add(json.encode(notification.toJson()));
      await prefs.setStringList(NotificationProvider.storageKey, notifications);
    } catch (e) {
      debugPrint('Error saving background notification: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    // Check if the user has notifications enabled
    bool isNotificationEnabled = userDoc.get('isNotificationsEnabled') ?? false;
    if (isNotificationEnabled == false) {
      return;
    }

    await _showNotification(message);
    _saveNotification(message);
  }

  static Future<void> _saveNotification(RemoteMessage message) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('No context available for saving notification');
        return;
      }

      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.addNotification(
        AppNotification(
          title: message.notification?.title ?? 'New Notification',
          body: message.notification?.body ?? '',
          payload: message.data,
        ),
      );
    } catch (e) {
      debugPrint('Error saving foreground notification: $e');
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final androidDetails = const AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      notification?.title,
      notification?.body,
      platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  static void _handleNotification(RemoteMessage message) {
    _saveNotification(message);
    _navigateToNotificationScreen(payload: jsonEncode(message.data));
  }

  static void _handleNotificationClick(String? payload) {
    try {
      if (payload != null) {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final context = navigatorKey.currentContext;

        if (context != null) {
          Provider.of<NotificationProvider>(context, listen: false).addNotification(
            AppNotification(
              title: data['title']?.toString() ?? 'Notification',
              body: data['body']?.toString() ?? '',
              payload: data,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling notification click: $e');
    }
    _navigateToNotificationScreen(payload: payload);
  }

  static void _navigateToNotificationScreen({String? payload}) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const NotificationScreen(),
      ),
    );
  }

  static Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  sendPushNotification(String title, String body, User user) async {
    // String? fcmToken = await _firebaseService.getFcmToken(user.uid);
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    // print('Current Token: $fcmToken');

    if (fcmToken != null) {
      // Save to your database
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': fcmToken});
      // Send welcome notification
      try {
        // print('Notification sending');
        await PushNotificationService.sendPushNotification(
          // fcmToken,
          // await PushNotificationService.getAccessToken(),
          fcmToken,

          title,
          body,
        );
      } catch (e) {
        // print('Error sending welcome notification: $e');
        // You can choose to handle this error or ignore it
      }
    }
  }

  Future<void> cancelPushNotification(String title, String body, String specialistToken) async {
    try {
      await PushNotificationService.sendPushNotification(
        specialistToken,
        title,
        body,
      );
    } catch (e) {
      print('Error sending notification: $e');
      // Add error handling as needed
    }
  }

// / Add this method at the bottom of the class, before the closing curly brace
  Future<void> schedulePushNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    tz.initializeTimeZones(); // Ensure this is called once in your app

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'appointment_reminders',
      'Appointment Reminders',
      channelDescription: 'Notifications for appointment reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      scheduledTime.millisecondsSinceEpoch ~/ 1000, // unique ID
      title,
      body,
      scheduledDate,
      platformChannelSpecifics,
      payload: payload,

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // <-- required!
    );
  }
}
