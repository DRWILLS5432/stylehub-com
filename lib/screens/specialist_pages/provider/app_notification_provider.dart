import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylehub/screens/specialist_pages/model/app_notification_model.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  static const String storageKey = 'notifications';

  List<AppNotification> get notifications => _notifications;

  NotificationProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = prefs.getStringList(storageKey) ?? [];

    _notifications = jsonStrings.map((jsonString) => AppNotification.fromJson(json.decode(jsonString))).toList();
    notifyListeners();
  }

  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();

    await _saveNotifications();
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = _notifications.map((n) => json.encode(n.toJson())).toList();
    await prefs.setStringList(storageKey, jsonStrings);
  }

  void markNotificationAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      _saveNotifications();
    }
  }
}

// Add this extension to AppNotification class
extension AppNotificationExtension on AppNotification {
  AppNotification copyWith({
    String? title,
    String? body,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
