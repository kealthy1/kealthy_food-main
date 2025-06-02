import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_food/view/Cart/address_model.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/Cart/instruction_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

double calculateDeliveryFee(double itemTotal, double distanceInKm) {
  // We'll keep everything as doubles—no rounding.
  double deliveryFee = 0;

  if (itemTotal >= 199) {
    // 0–7 km free if >= 199
    if (distanceInKm <= 7) {
      deliveryFee = 0;
    } else {
      // e.g. 11.54 - 7 = 4.54 * 8 = 36.32
      deliveryFee = 8 * (distanceInKm - 7);
    }
  } else {
    // If < 199
    if (distanceInKm <= 7) {
      deliveryFee = 50;
    } else {
      // 50 + ((distanceInKm - 7) * 10)
      deliveryFee = 50 + 10 * (distanceInKm - 7);
    }
  }

  return deliveryFee.roundToDouble();
}

final firstOrderProvider = AsyncNotifierProvider<FirstOrderNotifier, bool>(() {
  return FirstOrderNotifier();
});

class FirstOrderNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return false; // default
  }

  Future<void> checkFirstOrder(String phoneNumber) async {
    state = const AsyncLoading();
    final url =
        Uri.parse('https://api-jfnhkjk4nq-uc.a.run.app/orders/$phoneNumber');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        state = AsyncData(data.isEmpty); // true if no orders
      } else if (response.statusCode == 404) {
        state = const AsyncData(true); // First order
      } else {
        state = const AsyncData(false);
      }
    } catch (e) {
      state = const AsyncData(false);
    }
  }
}

/// Calculates the final total with delivery fee, handling fee, and instant delivery.
double calculateFinalTotal(
  double itemTotal,
  double distanceInKm,
  //  double instantDeliveryFee
) {
  double handlingFee = 5;
  double deliveryFee = calculateDeliveryFee(itemTotal, distanceInKm);

  double totalDeliveryFee = deliveryFee
      // + instantDeliveryFee
      ;

  double finalTotal = itemTotal + totalDeliveryFee + handlingFee;

  return finalTotal.roundToDouble();
}

final addressProvider = FutureProvider.autoDispose<Address?>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  // Fetch cart items
  final cartItems = ref.watch(cartProvider);

  // Retrieve and print all relevant values for debugging
  final fetchedSlot = prefs.getString('selected_slot') ?? '';
  final fetchedType = prefs.getString('selectedType') ?? '';
  final fetchedName = prefs.getString('selectedName') ?? '';
  final fetchedLandmark = prefs.getString('selectedLandmark') ?? '';
  final fetchedInstruction = prefs.getString('selectedInstruction') ?? '';
  final fetchedRoad = prefs.getString('selectedRoad') ?? '';

  // Numeric values
  final fetchedDistance = prefs.getDouble('selectedDistance') ?? 0.0;
  final fetchedSelectedDistance = prefs.getDouble('selectedDistance') ?? 0.0;
  final fetchedSelectedLatitude = prefs.getDouble('selectedLatitude') ?? 0.0;
  final fetchedSelectedLongitude = prefs.getDouble('selectedLongitude') ?? 0.0;

  // Debug
  print('--- Fetched Address Data ---');
  print('Slot: $fetchedSlot');
  print('Type: $fetchedType');
  print('Name: $fetchedName');
  print('Landmark: $fetchedLandmark');
  print('Instruction: $fetchedInstruction');
  print('Road: $fetchedRoad');
  print('Distance: $fetchedDistance km');
  print('Selected Distance: $fetchedSelectedDistance km');
  print('Selected Latitude: $fetchedSelectedLatitude');
  print('Selected Longitude: $fetchedSelectedLongitude');
  print('Selected Road: $fetchedRoad');
  print('Selected Instruction: $fetchedInstruction');
  print('-----------------------------');

  return Address(
    slot: fetchedSlot,
    type: fetchedType,
    name: fetchedName,
    landmark: fetchedLandmark,
    instruction: fetchedInstruction,
    distance: fetchedDistance.toString(),
    cartItems: cartItems,
    selectedDistance: fetchedSelectedDistance,
    selectedLatitude: fetchedSelectedLatitude,
    selectedLongitude: fetchedSelectedLongitude,
    selectedRoad: fetchedRoad,
    selectedInstruction: fetchedInstruction,
  );
});

String getSelectedInstructions(WidgetRef ref) {
  List<String> instructions = [];

  if (ref.watch(selectionProvider(1))) {
    instructions.add("Avoid Ringing Bell");
  }
  if (ref.watch(selectionProvider(2))) {
    instructions.add("Leave at Door");
  }
  if (ref.watch(selectionProvider(3))) {
    instructions.add("Leave with Guard");
  }
  if (ref.watch(selectionProvider(4))) {
    instructions.add("Avoid Calling");
  }
  if (ref.watch(selectionProvider(5))) {
    instructions.add("Pet at home");
  }

  print("Selected Instruction States:");
  print("Avoid Ringing Bell: ${ref.watch(selectionProvider(1))}");
  print("Leave at Door: ${ref.watch(selectionProvider(2))}");
  print("Leave with Guard: ${ref.watch(selectionProvider(3))}");
  print("Avoid Calling: ${ref.watch(selectionProvider(4))}");
  print("Final Selected Delivery Instructions: $instructions");

  return instructions.join(", ");
}
