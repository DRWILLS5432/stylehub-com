import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class PushNotificationService {
  static Future<String> getAccessToken() async {
    final serviceAccessJson =
        // ADD THE SERVICE ACCOUNT JSON


    // Properly formatted scopes with commas
    List<String> scopes = ['https://www.googleapis.com/auth/firebase.messaging', 'https://www.googleapis.com/auth/userinfo.email', 'https://www.googleapis.com/auth/userinfo.profile'];

    try {
      final client = await auth.clientViaServiceAccount(auth.ServiceAccountCredentials.fromJson(serviceAccessJson), scopes);

      final credentials = await auth.obtainAccessCredentialsViaServiceAccount(auth.ServiceAccountCredentials.fromJson(serviceAccessJson), scopes, client);

      client.close();
      return credentials.accessToken.data;
    } catch (e) {
      // print('Error getting access token: $e');
      rethrow;
    }
  }

  // static Future<void> sendPushNotificationToClient(

  static Future<void> sendPushNotification(String fcmToken, String title, String body) async {
    final accessToken = await PushNotificationService.getAccessToken();

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/stylehub-1cfee/messages:send'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "message": {
          "token": fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          "data": {
            "title": title,
            "body": body,
            // "screen": "broadcast",
            // "broadcastId": "123",
          },
          "android": {
            "priority": "high",
          },
          "apns": {
            "headers": {
              "apns-priority": "10",
            }
          }
        }
      }),
    );

    // print('Response status:}');
    // print('Response body: ');
  }
}

// Url to allow /expose secret key
// https://github.com/DRWILLS5432/stylehub/security/secret-scanning/unblock-secret/2votLMVyNHSIv9w2YQrrjfL8qlb
