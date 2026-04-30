import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/foundation.dart';
import '../core/constants/service_account.dart';

/// Service for handling push notifications (FCM) and local notifications.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Scopes for FCM v1
  final List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging'
  ];

  /// Get OAuth2 access token using Service Account credentials.
  Future<String> _getAccessToken() async {
    try {
      final creds = ServiceAccount.credentials;
      if (creds['private_key'] == null || (creds['private_key'] as String).isEmpty) {
        debugPrint('Error: FCM Private Key is missing in .env');
      }
      
      final client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(creds),
        _scopes,
      );
      return client.credentials.accessToken.data;
    } catch (e) {
      debugPrint('Error getting FCM Access Token: $e');
      rethrow;
    }
  }

  /// Initialize notification channels and request permissions.
  Future<void> initialize() async {
    final notificationSettings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification Permission Status: ${notificationSettings.authorizationStatus}');

    // Initialize local notifications for foreground display
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'split_saathi_channel',
      'SplitSaathi Notifications',
      description: 'Notifications for expenses, settlements, and group activity',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Get the current FCM token for this device.
  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
    return token;
  }

  /// Listen to token refresh events.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Handle a foreground FCM message by showing a local notification.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'split_saathi_channel',
          'SplitSaathi Notifications',
          channelDescription:
              'Notifications for expenses, settlements, and group activity',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Send a push notification to specific device tokens.
  /// Uses the modern FCM HTTP v1 API with OAuth2.
  Future<void> sendNotification({
    required List<String> recipientTokens,
    required String title,
    required String body,
  }) async {
    if (recipientTokens.isEmpty) return;

    try {
      final accessToken = await _getAccessToken();
      final projectId = ServiceAccount.credentials['project_id'];
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      for (final token in recipientTokens) {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'message': {
              'token': token,
              'notification': {
                'title': title,
                'body': body,
              },
              'android': {
                'priority': 'HIGH',
                'notification': {
                  'channel_id': 'split_saathi_channel',
                  'sound': 'default',
                },
              },
              'apns': {
                'payload': {
                  'aps': {
                    'sound': 'default',
                    'badge': 1,
                    'content-available': 1,
                  },
                },
              },
              'data': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'status': 'done',
                'title': title,
                'body': body,
              },
            }
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('FCM v1 Notification sent successfully to $token');
        } else {
          debugPrint('FCM v1 Send Error ($token): ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
