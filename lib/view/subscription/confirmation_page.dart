import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kealthy_food/view/Cart/slot_generator.dart';
import 'package:kealthy_food/view/Toast/toast_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

// Providers for the date selection
final fromDateProvider = StateProvider<DateTime?>((ref) => null);
final selectedSlotProvider =
    StateProvider<Map<String, DateTime>?>((ref) => null);
final isSlotExpandedProvider = StateProvider<bool>((ref) => false);

Future<bool> isSlotAvailable(String selectedSlotLabel) async {
  final databaseRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
  ).ref().child('orders');

  final snapshot = await databaseRef
      .orderByChild('selectedSlot')
      .equalTo(selectedSlotLabel)
      .get();

  final existingOrders = snapshot.children.length;
  return existingOrders < 10;
}

class ConfirmationPage extends ConsumerWidget {
  final String title;
  final String description;
  final double baseRate;
  final int durationDays;
  final int selectedQty;

  const ConfirmationPage({
    super.key,
    required this.title,
    required this.description,
    required this.baseRate,
    required this.durationDays,
    required this.selectedQty,
  });

  Future<void> _pickDate(BuildContext context, WidgetRef ref,
      {required bool isFrom}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      if (isFrom) {
        ref.read(fromDateProvider.notifier).state = picked;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromDate = ref.watch(fromDateProvider);
    final int additionalDays = description.contains("Plus")
        ? int.tryParse(
                RegExp(r'Plus\s+(\d+)').firstMatch(description)?.group(1) ??
                    '0') ??
            0
        : 0;
    final endDate =
        fromDate?.add(Duration(days: durationDays + additionalDays));
    final endDateText =
        endDate != null ? DateFormat('MMMM d, y').format(endDate) : '';
    final total = (baseRate * selectedQty * durationDays).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Confirm Subscription"),
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (description.contains('Plus'))
                        Row(
                          children: [
                            const Icon(CupertinoIcons.gift,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              description
                                  .split('\n')
                                  .firstWhere((line) => line.contains('Plus')),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.green),
                            ),
                          ],
                        ),
                      if (description.contains('Free Delivery'))
                        const Row(
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Free Delivery',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.green),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'lib/assets/images/promo_1736765179.jpg',
                      height: 64,
                      width: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Starts from',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _pickDate(context, ref, isFrom: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fromDate != null
                          ? DateFormat('MMMM d, y').format(fromDate)
                          : 'Select Date',
                      style: TextStyle(
                        color: fromDate != null
                            ? Colors.black
                            : Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(CupertinoIcons.calendar, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (fromDate != null) ...[
              const Text(
                'Ends on',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: Row(
                  children: [
                    Text(
                      endDateText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Delivery Slot Selection Section
              const SizedBox(height: 20),
              Builder(builder: (context) {
                final isSlotExpanded = ref.watch(isSlotExpandedProvider);
                final selectedSlot = ref.watch(selectedSlotProvider);
                return Container(
                  margin: const EdgeInsets.only(top: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref.read(isSlotExpandedProvider.notifier).state =
                              !isSlotExpanded;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedSlot != null
                                    ? 'Selected Slot : ${DateFormat('h:mm a').format(selectedSlot["start"]!)} - ${DateFormat('h:mm a').format(selectedSlot["end"]!)}'
                                    : 'Preferred Delivery Slot',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              Icon(
                                isSlotExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isSlotExpanded)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: () async {
                              final generator = AvailableSlotsGenerator(
                                  slotDurationMinutes: 180);
                              final todaySlots = await generator.getSlots(0);
                              return todaySlots;
                            }(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CupertinoActivityIndicator(
                                        color: Colors.black));
                              }
                              final availableSlots =
                                  (snapshot.data?["slots"] as List<dynamic>?)
                                          ?.map((slot) =>
                                              slot as Map<String, DateTime>)
                                          .toList() ??
                                      [];
                              final slotsToShow =
                                  availableSlots.take(3).toList();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: slotsToShow.map((slot) {
                                      final formattedStart =
                                          DateFormat('h:mm a')
                                              .format(slot["start"]!);
                                      final formattedEnd = DateFormat('h:mm a')
                                          .format(slot["end"]!);
                                      final isSelected =
                                          selectedSlot?["start"] ==
                                                  slot["start"] &&
                                              selectedSlot?["end"] ==
                                                  slot["end"];

                                      return GestureDetector(
                                        onTap: () async {
                                          final formattedStartTime =
                                              DateFormat('hh:mm a')
                                                  .format(slot["start"]!);
                                          final formattedEndTime =
                                              DateFormat('hh:mm a')
                                                  .format(slot["end"]!);
                                          final selectedSlotLabel =
                                              "$formattedStartTime - $formattedEndTime";

                                          final isAvailable =
                                              await isSlotAvailable(
                                                  selectedSlotLabel);
                                          if (!isAvailable) {
                                            ToastHelper.showErrorToast(
                                                'Slot not available. Please choose another slot');
                                            return;
                                          }

                                          ref
                                              .read(
                                                  selectedSlotProvider.notifier)
                                              .state = slot;
                                          ref
                                              .read(isSlotExpandedProvider
                                                  .notifier)
                                              .state = false;
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          await prefs.setString('selectedSlot',
                                              selectedSlotLabel);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color.fromARGB(
                                                    255, 223, 240, 224)
                                                : Colors.white,
                                            border: Border.all(
                                                color: Colors.black12),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "$formattedStart - $formattedEnd",
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            const Spacer(),
            Row(
              children: [
                const Text("Total Amount :",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("₹$total",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 65, 88, 108),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (fromDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select the From date.')),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Subscription Confirmed"),
                      content: Text(
                        "You've subscribed to $title starting from ${DateFormat('MMMM d, y').format(fromDate)}.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Confirm Subscription"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
