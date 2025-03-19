import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/BottomNavBar/bottom_nav_bar_proivder.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/Login/login_page.dart';
import 'package:kealthy_food/view/Toast/toast_helper.dart';
import 'package:kealthy_food/view/address/provider.dart';
import 'package:kealthy_food/view/map/provider.dart';
import 'package:kealthy_food/view/profile%20page/getuserdetails.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Define a Profile Model
class ProfileModel {
  final String name;
  final String email;

  ProfileModel({required this.name, required this.email});

  ProfileModel copyWith({String? name, String? email}) {
    return ProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}

// Profile Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileModel>(
  (ref) => ProfileNotifier(),
);

class ProfileNotifier extends StateNotifier<ProfileModel> {
  ProfileNotifier() : super(ProfileModel(name: '', email: '')) {
    loadProfileData();
  }

  // ✅ 1️⃣ Load Profile from SharedPreferences (Fast Fetch)
  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString('user_name') ?? '';
    final storedEmail = prefs.getString('user_email') ?? '';

    // Update state with SharedPreferences data
    state = ProfileModel(name: storedName, email: storedEmail);

    // Fetch updated data from API in the background
    fetchProfileData();
  }

  // ✅ 2️⃣ Fetch Profile from API (Background Fetch)
  Future<void> fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');

    if (phoneNumber != null) {
      final userDetails = await UserService.getUserDetails(phoneNumber);

      // Update UI state
      state = ProfileModel(
        name: userDetails['name']!,
        email: userDetails['email']!,
      );
    }
  }

  // ✅ 3️⃣ Update User Profile
  Future<void> updateUserData(String name, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');

      if (phoneNumber == null) {
        print("❌ Phone number not found in SharedPreferences.");
        return;
      }

      await UserService.updateUserDetails(phoneNumber, name, email);

      // ✅ Update UI state after successful update
      state = state.copyWith(name: name, email: email);
      print("✅ UI updated with new profile details.");
    } catch (e) {
      print("❌ Error updating user profile: $e");
    }
  }
}

Future<void> deleteAccount(WidgetRef ref, BuildContext context) async {
  bool confirmed = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Delete Account",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to delete your account? This action cannot be undone.",
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel",
                    style: GoogleFonts.poppins(color: Colors.black)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete",
                    style: GoogleFonts.poppins(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ) ??
      false;

  if (!confirmed) return;

  try {
    ref.read(isLoadingProvider.notifier).state = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.black),
              const SizedBox(height: 15),
              Text(
                "Deleting Account...",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );

    // Remove any artificial delay here if you want it faster
    // await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');

    if (phoneNumber == null) {
      Navigator.pop(context); // close the "Deleting..." dialog
      return;
    }

    const deleteUrl = "https://api-jfnhkjk4nq-uc.a.run.app/delete";
    final response = await http.delete(
      Uri.parse(deleteUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );

    Navigator.pop(context); // close the "Deleting..." dialog

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == false) {
        ToastHelper.showErrorToast(
            'Failed to delete account: ${data['message']}');
        return;
      }

      // Clear all saved data from SharedPreferences
      await prefs.clear();
      ref.invalidate(selectedLocationProvider);
      ref.invalidate(phoneNumberProvider);
      ref.invalidate(customerNameProvider);
      ref.invalidate(cartProvider);
      ref.invalidate(addressProvider);
      ref.invalidate(bottomNavProvider);

      ToastHelper.showSuccessToast('Account deleted successfully.');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginFields()),
        (route) => false,
      );
    } else {
      ToastHelper.showErrorToast('Failed to delete account. Try again later.');
    }
  } catch (e) {
    ToastHelper.showErrorToast('Error occurred while deleting account.');
    Navigator.pop(context); // close the "Deleting..." dialog on error
  } finally {
    ref.read(isLoadingProvider.notifier).state = false;
  }
}

// Example: logout logic
Future<void> logoutUser(BuildContext context, WidgetRef ref) async {
  // Show a quick "Logging out" dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.black),
            SizedBox(height: 15),
            Text(
              "Logging out...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    },
  );

  // Remove or reduce this delay if you want it instant
  // await Future.delayed(const Duration(seconds: 2));

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  // Invalidate providers
  ref.invalidate(selectedLocationProvider);
  ref.invalidate(phoneNumberProvider);
  ref.invalidate(customerNameProvider);
  ref.invalidate(cartProvider);
  ref.invalidate(addressProvider);
  ref.invalidate(bottomNavProvider);

  Navigator.pop(context); // close the "Logging out" dialog

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const LoginFields(),
    ),
  );
}
