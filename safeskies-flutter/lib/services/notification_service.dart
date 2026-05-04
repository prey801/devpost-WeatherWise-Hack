import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:safeskies/services/api_service.dart';
import 'package:safeskies/services/location_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  late String? _fcmToken;
  Function(Map<String, dynamic>)? _onNotificationTapped;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init({
    Function(Map<String, dynamic>)? onNotificationTapped,
  }) async {
    _onNotificationTapped = onNotificationTapped;

    // Request permission for iOS/Web
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carryForward: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('app_icon');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (_onNotificationTapped != null && response.payload != null) {
          try {
            final data = {'tap': response.payload};
            _onNotificationTapped!(data);
          } catch (e) {
            // Handle error
          }
        }
      },
    );

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundTap);
  }

  String? get fcmToken => _fcmToken;

  Future<void> subscribeToAlerts(String phone) async {
    try {
      if (_fcmToken == null) {
        _fcmToken = await _firebaseMessaging.getToken();
      }

      final locationService = LocationService();
      final location = await locationService.getCurrentLocation();

      if (location != null && _fcmToken != null) {
        final apiService = ApiService();
        await apiService.subscribe(
          phone,
          location.latitude,
          location.longitude,
          _fcmToken!,
        );
      }
    } catch (e) {
      // Handle subscription error
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'safeskies_alerts',
        'SafeSkies Alerts',
        channelDescription: 'Real-time weather and hazard alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: message.data['alert_id'] ?? 'default',
      );
    }
  }

  void _handleBackgroundTap(RemoteMessage message) {
    if (_onNotificationTapped != null) {
      _onNotificationTapped!(message.data);
    }
  }

  Future<void> enableNotifications() async {
    // Re-request permissions (already done in init, but can be explicit)
    await _firebaseMessaging.requestPermission();
  }

  Future<void> disableNotifications() async {
    // Unsubscribe from all FCM topics
    await _firebaseMessaging.unsubscribeFromTopic('alerts');
  }
}

// Background message handler - must be a top-level function
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here if needed
}
