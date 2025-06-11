import 'package:cloud_firestore/cloud_firestore.dart';
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
final newsletterSubscribedProvider = StateProvider<bool>((ref) => false);
final hasShownReviewAlertProvider = StateProvider<bool>((ref) => false);
final selectedItemProvider = StateProvider<CartItem?>((ref) => null);
final tapPositionProvider = StateProvider<Offset?>((ref) => null);
final overlayEntryProvider = StateProvider<OverlayEntry?>((ref) => null);
final cartVisibilityProvider = StateProvider<bool>((ref) => true);
final locationPermissionProvider =
    StateProvider<LocationPermission>((ref) => LocationPermission.denied);
final locationPermissionGrantedProvider = StateProvider<bool>((ref) => false);
final hasLocationPermissionProvider = StateProvider<bool>((ref) => false);
final cachedLocationProvider = StateProvider<Map<String, String>?>((ref) => null);


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
            (entry.value['assignedTo'] != 'none' ))
        .map<Map<String, dynamic>>((entry) =>
            Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>))
        .toList();
  });
});

Future<Map<String, String>> getSelectedAddressOrCurrentLocation(
    FutureProviderRef<Map<String, String>> ref) async {
  print("Starting location fetch process");

  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Helper function to cache and return result
  void cacheAndReturn(Map<String, String> result) {
    ref.read(cachedLocationProvider.notifier).state = result;
    print("Caching and returning result: $result");
  }

  // Retry logic
  int retryCount = 0;
  const maxRetries = 3;
  const retryDuration = Duration(seconds: 3);

  Future<Map<String, String>> fetchLocation() async {
    // Check for selected address first
    final selectedAddress = ref.read(selectedLocationProvider);
    if (selectedAddress != null && selectedAddress.isNotEmpty) {
      return {
        "addressType": prefs.getString('selectedType') ?? "Selected Address",
        "address": selectedAddress,
      };
    }

    // Fetch real-time location
    try {
      print("Attempting to fetch current position");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("Position obtained: $position");

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      print("Placemarks obtained: $placemarks");

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String userLocation = place.street?.isNotEmpty == true
            ? place.street!
            : place.subLocality?.isNotEmpty == true
                ? place.subLocality!
                : place.locality?.isNotEmpty == true
                    ? place.locality!
                    : "Locating...";

        await prefs.setString('user_location', userLocation);
        ref.read(locationProvider.notifier).state = userLocation;

        return {"address": userLocation};
      }
    } catch (e) {
      print("Error fetching location: $e");
    }

    // If no selected address, check cached location
    final cachedLocation = ref.read(cachedLocationProvider);
    if (cachedLocation != null) {
      print("Returning cached location: $cachedLocation");
      return cachedLocation;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    print("Current location permission status: $permission");

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print("Requested permission, new status: $permission");
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return {
        "addressType": "Location Disabled",
        "address": "Enable location for better experience",
      };
    }

    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print("Location service enabled: $serviceEnabled");

    if (!serviceEnabled) {
      return {
        "addressType": "Location Service Disabled",
        "address": "Please enable location services",
      };
    }

    // Check for saved location
    final location = ref.read(locationProvider);
    if (location != null && location.isNotEmpty) {
      return {"address": location};
    }

    // Default fallback
    return {"address": "Locating..."};
  }

  // Retry loop
   while (retryCount < maxRetries) {
    try {
      final result = await fetchLocation();
      cacheAndReturn(result);
      return result;
    } catch (e) {
      print("Error fetching location: $e");
      retryCount++;
      if (retryCount < maxRetries) {
        print("Retrying location fetch...");
        print("${ maxRetries - retryCount } retries remaining");
        await Future.delayed(retryDuration);
      } else {
        print("Maximum retries reached. Returning default location.");
        return {"address": "Locating..."};
      }
    }
  }

  // If all retries fail, return a default location
  return {"address": "Locating..."};
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

 // FutureProvider to fetch image URLs
final homeImageUrlsProvider = FutureProvider<List<String>>((ref) async {
  final bannerDocs = await FirebaseFirestore.instance.collection('banners').get();
  final productDocs = await FirebaseFirestore.instance.collection('products').limit(10).get();

  final bannerUrls = bannerDocs.docs.map((doc) => doc['image'] as String);
  final productUrls = productDocs.docs.map((doc) => doc['image'] as String);

  return [...bannerUrls, ...productUrls];
});
final locationDataProvider = FutureProvider<Map<String, String>>((ref) async {
  // This will cause the provider to re-run when selectedLocationProvider changes
  ref.watch(selectedLocationProvider);
  return getSelectedAddressOrCurrentLocation(ref);
});

