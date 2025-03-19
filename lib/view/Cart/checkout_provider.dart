import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_food/view/Cart/address_model.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/Cart/instruction_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        deliveryFee = 50; // flat charge up to 7 km
      } else {
        // 50 + ((distanceInKm - 7) * 10)
        deliveryFee = 50 + 10 * (distanceInKm - 7);
      }
    }

    // If you want just a raw double (e.g., 36.32), return as-is:
    return deliveryFee.roundToDouble();
  }

  /// Calculates the final total with delivery fee, handling fee, and instant delivery.
  double calculateFinalTotal(
      double itemTotal, double distanceInKm, double instantDeliveryFee) {
    double handlingFee = 5;
    double deliveryFee = calculateDeliveryFee(itemTotal, distanceInKm);

    // ✅ Ensure both delivery fees are added together
    double totalDeliveryFee = deliveryFee + instantDeliveryFee;

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