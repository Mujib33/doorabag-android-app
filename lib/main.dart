import 'package:doora_app/features/home/presentation/home_page.dart';
import 'package:flutter/material.dart';
import 'package:doora_app/theme/app_theme.dart';

// 👉 NEW: Splash import
import 'package:doora_app/brand_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🔔 Global notification plugin (foreground notifications ke liye)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔔 Local notifications init (Android)
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: androidInitializationSettings);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 🔐 Android 13+ notification permission
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    sound: true,
  );

  // 📩 Foreground message listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'doorabag_channel', // channel id
      'Doorabag Notifications', // channel name
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    flutterLocalNotificationsPlugin.show(
      notification.hashCode, // unique id
      notification.title,
      notification.body,
      details,
    );
  });

  // 🔥 FCM Token Generate & Print (debug ke liye)
  String? token = await FirebaseMessaging.instance.getToken();
  // ignore: avoid_print
  print("FCM TOKEN: $token");

  runApp(const DooraApp());
}

class DooraApp extends StatelessWidget {
  const DooraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DooraBag',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // ❗ App first shows the animated splash screen
      home: const BrandSplashScreen(),
      routes: {
        '/home': (_) => const HomePage(),
      },
    );
  }
}
