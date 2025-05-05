import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kealthy_food/firebase_options.dart';
import 'package:kealthy_food/view/notifications/fcm.dart';
import 'package:kealthy_food/view/splash_screen/splash_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try { 
    await NotificationService.instance.initialize();
    await NotificationService.instance.setupFlutterNotifications();
    print("[MAIN] Notification service initialized successfully.");
  } catch (e) {
    print("[MAIN] Error initializing notification service: $e");
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  runApp(
    ProviderScope(
      child: MyApp(navigatorKey: navigatorKey),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  MyApp({super.key, required this.navigatorKey}) {
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[Foreground Message] Received: ${message.notification?.title}');

      // Debug logging
      print("FCM Message Data: ${message.data}");
      print("FCM Notification: ${message.notification?.toMap()}");

      // Extract image URL
      final imageUrl = message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl ??
          message.data['image'] ??
          "";

      print("Extracted Image URL: $imageUrl");

      NotificationService.instance.showNotification(
        title: message.notification?.title ?? "No Title",
        body: message.notification?.body ?? "No Body",
        imageUrl: imageUrl,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
