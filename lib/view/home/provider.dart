import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kealthy_food/view/address/provider.dart';
import 'package:kealthy_food/view/map/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';

/// 🔹 **State Providers**
final hasShownReviewAlertProvider = StateProvider<bool>((ref) => false);
final selectedItemProvider = StateProvider<CartItem?>((ref) => null);
final tapPositionProvider = StateProvider<Offset?>((ref) => null);
final overlayEntryProvider = StateProvider<OverlayEntry?>((ref) => null);
final cartVisibilityProvider = StateProvider<bool>((ref) => true);
final locationPermissionProvider =
    StateProvider<LocationPermission>((ref) => LocationPermission.denied);
final locationPermissionGrantedProvider = StateProvider<bool>((ref) => false);
final hasLocationPermissionProvider = StateProvider<bool>((ref) => false);

/// 🔹 **Cart Provider (Shared across all pages)**
// final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
//   return CartNotifier();
// });

/// 🔹 **Location Providers**
final locationProvider = StateProvider<String?>((ref) => null);
final locationTypeProvider = StateProvider<String?>((ref) => "Select address");
final totalItemsProvider = StateProvider<int>((ref) => 0);

/// 🔹 **Fetch Phone Number from Shared Preferences**
Future<String?> getStoredPhoneNumber() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('phoneNumber');
}

/// 🔹 **Live Orders Provider**
final liveOrdersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phoneNumber');

  if (phoneNumber == null || phoneNumber.isEmpty) {
    yield [];
    return;
  }

  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
  ).ref('orders');

  yield* database.onValue.map((event) {
    final data = event.snapshot.value as Map?;
    if (data == null) return [];

    return data.entries
        .where((entry) =>
            entry.value['phoneNumber'] == phoneNumber &&
            (entry.value['status'] == 'Order Placed' ||
             entry.value['status'] == 'Order Picked' ||
             entry.value['status'] == 'Order Reached'))
        .map<Map<String, dynamic>>((entry) =>
            Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>))
        .toList();
  });
});

 Future<Map<String, String>> getSelectedAddressOrCurrentLocation(
      WidgetRef ref) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 🔹 Get the location permission status
    final selectedAddress = ref.read(selectedLocationProvider);
    if (selectedAddress != null && selectedAddress.isNotEmpty) {
      return {
        "addressType": prefs.getString('selectedType') ?? "Selected Address",
        "address": selectedAddress,
      };
    }

    // 🔹 Get the location permission status
    final locationPermission = ref.read(locationPermissionProvider);

    // 1️⃣ If location is denied AND no selected address, return "Location Disabled"
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever) {
      return {
        "addressType": "Location Disabled",
        "address": "Enable location for better experience",
      };
    }

    final location = ref.read(locationProvider);
    if (location != null && location.isNotEmpty) {
      return {
        "address": location,
      };
    }

    // 4️⃣ Try fetching real-time location if no saved address exists
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Select the most relevant location field
        String userLocation = place.street?.isNotEmpty == true
            ? place.street!
            : place.subLocality?.isNotEmpty == true
                ? place.subLocality!
                : place.locality?.isNotEmpty == true
                    ? place.locality!
                    : "Locating...";

        // ✅ Save location for future reference
        await prefs.setString('user_location', userLocation);

        // ✅ Update provider for UI updates
        ref.read(locationProvider.notifier).state = userLocation;

        return {
          "address": userLocation,
        };
      }
    } catch (e) {
      print("Error fetching location: $e");
    }

    // 5️⃣ Default fallback if everything fails
    return {
      "address": "Locating...",
    };
  }
Future<void> checkLocationPermission(WidgetRef ref) async {
    LocationPermission permission = await Geolocator.checkPermission();
    ref.read(locationPermissionProvider.notifier).state = permission;

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      ref.read(hasLocationPermissionProvider.notifier).state = true;

      // Fetch the latest location
      await LocationHelper.getCurrentLocation();
    } else if (permission == LocationPermission.denied) {
      // 🔥 Request location permission (ONLY ask, don't show the bottom sheet)
      await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      // ❌ Do nothing if denied forever (no bottom sheet)
      print(
          "⚠️ Location permission permanently denied, user must enable manually.");
    } else if (permission == LocationPermission.unableToDetermine) {
      // ❌ Do nothing if unable to determine
      print("⚠️ Unable to determine location permission.");
    }
  }