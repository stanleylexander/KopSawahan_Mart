import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import 'user_service.dart';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'koperasi_notifications',
    'Koperasi Notifications',
    description: 'Notifikasi order dan pesanan koperasi',
    importance: Importance.high,
  );

  static bool _isInitialized = false;
  static bool _isFirebaseReady = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;

    if (kIsWeb) {
      return;
    }

    await _initializeLocalNotifications();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseReady = true;
    } catch (error) {
      debugPrint('Firebase belum siap: $error');
      return;
    }

    await _requestPermission();
    await _createNotificationChannel();
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await syncDeviceTokenWithServer(token: token);
    });
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(initializationSettings);
  }

  static Future<void> _requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _createNotificationChannel() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);
  }

  static Future<String?> getCurrentToken() async {
    final isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!_isFirebaseReady || kIsWeb || !isMobilePlatform) {
      return null;
    }

    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('Gagal mengambil FCM token: $error');
      return null;
    }
  }

  static Future<void> syncDeviceTokenWithServer({
    String? apiToken,
    String? token,
  }) async {
    final currentToken = token ?? await getCurrentToken();

    if (currentToken == null || currentToken.isEmpty) {
      return;
    }

    final authToken = apiToken ?? await _getApiTokenFromStorage();

    if (authToken == null || authToken.isEmpty) {
      return;
    }

    await UserService.saveDeviceToken(authToken, currentToken);
  }

  static Future<void> clearDeviceTokenFromServer({String? apiToken}) async {
    final authToken = apiToken ?? await _getApiTokenFromStorage();

    if (authToken == null || authToken.isEmpty) {
      return;
    }

    await UserService.saveDeviceToken(authToken, null);
  }

  static Future<String?> _getApiTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title']?.toString() ?? '';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty) {
      return;
    }

    await _localNotifications.show(
      title.hashCode ^ body.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'koperasi_notifications',
          'Koperasi Notifications',
          channelDescription: 'Notifikasi order dan pesanan koperasi',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
