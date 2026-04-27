import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  /// Initialize notifications
  static Future<void> initializeNotifications() async {
    try {
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('✅ Notification permission: ${settings.authorizationStatus}');

      // Get device token
      String? token = await _firebaseMessaging.getToken();
      print('🔔 FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📨 Foreground Message: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('✅ App opened from notification');
        _handleNotificationTap(message);
      });

      print('🚀 Notifications initialized');
    } catch (e) {
      print('❌ Notification error: $e');
    }
  }

  static void _showForegroundNotification(RemoteMessage message) {
    if (message.notification != null) {
      print('🔔 Title: ${message.notification?.title}');
      print('💬 Body: ${message.notification?.body}');
      print('📦 Data: ${message.data}');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Handle when user taps notification
    if (message.data.isNotEmpty) {
      print('Quote: ${message.data['quote']}');
      print('Author: ${message.data['author']}');
    }
  }
}
