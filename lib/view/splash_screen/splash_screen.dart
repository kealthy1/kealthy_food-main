import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_food/view/BottomNavBar/bottom_nav_bar.dart';
import 'package:kealthy_food/view/Login/login_page.dart';
import 'package:kealthy_food/view/maintanence/maintanence.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));

    final isUnderMaintenance = await _checkMaintenanceStatus();
    if (!mounted) return;

    if (isUnderMaintenance) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const MaintenanceScreen()),
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      final storedPhone = prefs.getString('phoneNumber') ?? '';

      // ✅ Set phone number into provider
      ref.read(phoneNumberProvider.notifier).state = storedPhone;

      Navigator.pushReplacement(
        context,
        CupertinoModalPopupRoute(
          builder: (_) => storedPhone.isNotEmpty
              ? const BottomNavBar()
              : const LoginFields(),
        ),
      );
    }
  }

  Future<bool> _checkMaintenanceStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('maintenance')
          .doc('status')
          .get();
      return doc.data()?['maintenance'] == true;
    } catch (e) {
      print("⚠️ Maintenance check failed: $e");
      return false;
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
}