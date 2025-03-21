import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kealthy_food/view/Cart/slot_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntp/ntp.dart';

final selectedSlotProvider =
    StateProvider<Map<String, DateTime>?>((ref) => null);
final isExpandedProvider = StateProvider<bool>((ref) => false);
final distanceProvider = FutureProvider<double>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('selectedDistance') ?? 3.0;
});

final selectedETAProvider = StateProvider<DateTime?>((ref) => null);

final etaTimeProvider = FutureProvider<DateTime>((ref) async {
  final distance = await ref.read(distanceProvider.future);
  const double averageSpeedKmH = 30.0;
  const int cookingTimeMinutes = 15;
  final etaMinutes = (distance / averageSpeedKmH) * 100 + cookingTimeMinutes;
  final currentTime = await NTP.now();
  return currentTime.add(Duration(minutes: etaMinutes.toInt()));
});

class SlotSelectionContainer extends ConsumerWidget {
  const SlotSelectionContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSlot = ref.watch(selectedSlotProvider);
    final isExpanded = ref.watch(isExpandedProvider);

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(isExpandedProvider.notifier).state = !isExpanded,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      selectedSlot != null
                          ? '${DateFormat('h:mm a').format(selectedSlot["start"]!)} - ${DateFormat('h:mm a').format(selectedSlot["end"]!)}'
                          : 'Preferred Delivery Time',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 5), // Spacing between text and icon
                    Icon(isExpanded
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down),
                  ],
                ),
                Text(
                  'Save ₹50 🎉',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded)
            FutureBuilder<Map<String, dynamic>>(
              future: () async {
                final generator =
                    AvailableSlotsGenerator(slotDurationMinutes: 180);
                return await generator.getSlots(0);
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:  CupertinoActivityIndicator(
                                  color:Colors.black,));
                }
                if (snapshot.hasError) {}

                final availableSlots =
                    (snapshot.data?["slots"] as List<dynamic>?)
                            ?.map((slot) => slot as Map<String, DateTime>)
                            .toList() ??
                        [];

                final message = snapshot.data?["message"] as String?;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    if (message != null)
                      Text(
                        message,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 10,
                        children: availableSlots.map((slot) {
                          final formattedStartTime =
                              DateFormat('h:mm a').format(slot["start"]!);
                          final formattedEndTime =
                              DateFormat('h:mm a').format(slot["end"]!);

                          return GestureDetector(
                            onTap: () async {
                              ref.read(selectedSlotProvider.notifier).state =
                                  slot;
                              ref.read(isExpandedProvider.notifier).state =
                                  false;
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                'selectedSlot',
                                "Slot Delivery 📦 $formattedStartTime - $formattedEndTime",
                              );
                            },
                            child: IntrinsicWidth(
                              stepWidth: 10,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.37,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 10),
                                decoration: BoxDecoration(
                                  color: (selectedSlot != null &&
                                          selectedSlot["start"] ==
                                              slot["start"] &&
                                          selectedSlot["end"] == slot["end"])
                                      ? const Color.fromARGB(255, 223, 240,
                                          224) // ✅ Change color if selected
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Center(
                                  child: Text(
                                    '$formattedStartTime - $formattedEndTime',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            )
        ],
      ),
    );
  }
}
