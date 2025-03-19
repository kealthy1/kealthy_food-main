import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kealthy_food/view/BottomNavBar/bottom_nav_bar.dart';
import 'package:kealthy_food/view/Login/login_page.dart';
import 'package:kealthy_food/view/splash_screen/network.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {

    // Delay navigation by 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // Check if the user has a saved phone number
    final hasPhoneNumber = await _checkPhoneNumber();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        CupertinoModalPopupRoute(
          builder: (context) => hasPhoneNumber
              ? const InternetAwareWidget(child: BottomNavBar())
              : const LoginFields(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/images/splash.gif'),
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _checkPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('phoneNumber');
  }
}