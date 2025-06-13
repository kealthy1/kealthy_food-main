import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/firebase_options.dart';
import 'package:kealthy_food/view/notifications/fcm.dart';
import 'package:kealthy_food/view/notifications/offers.dart';
import 'package:kealthy_food/view/splash_screen/network.dart';
import 'package:kealthy_food/view/splash_screen/splash_screen.dart';
import 'package:kealthy_food/view/subscription/subscription_details.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

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

final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

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
    final navigatorKey = ref.watch(navigatorKeyProvider);
    return MaterialApp(
      routes: {
        // your home or starting page
        '/offers': (context) => const OffersNotificationPage(),
        '/subscription': (context) => const SubscriptionDetailsPage(),
      },
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          surfaceTintColor: Colors.white,
        ),
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          background: Colors.white,
          onBackground: Colors.black,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      builder: (context, child) {
        return InternetAwareWidget(child: child ?? const SizedBox());
      },
      home: const SplashScreen(),
    );
  }
}
