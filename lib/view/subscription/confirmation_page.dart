import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kealthy_food/view/Cart/checkout_provider.dart';
import 'package:kealthy_food/view/Cart/slot_generator.dart';
import 'package:kealthy_food/view/Toast/toast_helper.dart';
import 'package:kealthy_food/view/address/adress.dart';
import 'package:kealthy_food/view/subscription/sub_payment.dart';
import 'package:kealthy_food/view/subscription/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmationPage extends ConsumerWidget {
  final String title;
  final String description;
  final double baseRate;
  final int durationDays;
  final int selectedQty;
  final String productName;

  const ConfirmationPage({
    super.key,
    required this.title,
    required this.description,
    required this.baseRate,
    required this.durationDays,
    required this.selectedQty,
    required this.productName,
  });


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
        endDate != null ? DateFormat('d MMMM y').format(endDate) : '';
    print('📆 Start Date: ${fromDate != null ? DateFormat('d MMMM y').format(fromDate) : 'Not selected'}');
    print('📆 End Date: $endDateText');
   final total = (baseRate * selectedQty * durationDays).toStringAsFixed(0); 
   

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Confirm Subscription"),
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IntrinsicHeight(
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if (description.contains('Plus'))
                                  Row(
                                    children: [
                                      const Icon(CupertinoIcons.gift,
                                          size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        description.split('\n').firstWhere(
                                            (line) => line.contains('Plus')),
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
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.green),
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
                        onTap: () => pickDate(context, ref, isFrom: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                fromDate != null
                                    ? DateFormat('d MMMM y').format(fromDate)
                                    : 'Select Date',
                                style: TextStyle(
                                  color: fromDate != null
                                      ? Colors.black
                                      : Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(CupertinoIcons.calendar,
                                  color: Colors.black),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
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
                          final isSlotExpanded =
                              ref.watch(isSlotExpandedProvider);
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
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(isSlotExpandedProvider.notifier)
                                        .state = !isSlotExpanded;
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 14),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectedSlot != null
                                              ? 'Selected Slot : ${DateFormat('h:mm a').format(selectedSlot["start"]!)} - ${DateFormat('h:mm a').format(selectedSlot["end"]!)}'
                                              : 'Preferred Delivery Slot',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
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
                                        final generator =
                                            AvailableSlotsGenerator(
                                                slotDurationMinutes: 180);
                                        final todaySlots =
                                            await generator.getSlots(0);
                                        return todaySlots;
                                      }(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child: CupertinoActivityIndicator(
                                                  color: Colors.black));
                                        }
                                        final availableSlots = (snapshot
                                                        .data?["slots"]
                                                    as List<dynamic>?)
                                                ?.map((slot) => slot
                                                    as Map<String, DateTime>)
                                                .toList() ??
                                            [];
                                        // Deduplicate available slots
                                        final uniqueSlots = {
                                          for (var slot in availableSlots)
                                            '${slot["start"]}-${slot["end"]}':
                                                slot
                                        }.values.toList();
                                        // Filter and order slots: 9AM–12PM, 12PM–3PM, 3PM–6PM
                                        final slots9to12 =
                                            uniqueSlots.where((slot) {
                                          final hour = slot["start"]!.hour;
                                          return hour >= 9 && hour < 12;
                                        }).toList();

                                        final slots12to3 =
                                            uniqueSlots.where((slot) {
                                          final hour = slot["start"]!.hour;
                                          return hour >= 12 && hour < 15;
                                        }).toList();

                                        final slots3to6 =
                                            uniqueSlots.where((slot) {
                                          final hour = slot["start"]!.hour;
                                          return hour >= 15 && hour < 18;
                                        }).toList();

                                        final slotsToShow = [
                                          ...slots9to12,
                                          ...slots12to3,
                                          ...slots3to6
                                        ].take(3).toList();
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 10,
                                              runSpacing: 10,
                                              children: slotsToShow.map((slot) {
                                                final formattedStart =
                                                    DateFormat('h:mm a')
                                                        .format(slot["start"]!);
                                                final formattedEnd =
                                                    DateFormat('h:mm a')
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
                                                            .format(
                                                                slot["start"]!);
                                                    final formattedEndTime =
                                                        DateFormat('hh:mm a')
                                                            .format(
                                                                slot["end"]!);
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
                                                            selectedSlotProvider
                                                                .notifier)
                                                        .state = slot;
                                                    ref
                                                        .read(
                                                            isSlotExpandedProvider
                                                                .notifier)
                                                        .state = false;
                                                    final prefs =
                                                        await SharedPreferences
                                                            .getInstance();
                                                    await prefs.setString(
                                                        'selectedSlot',
                                                        selectedSlotLabel);
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? const Color
                                                              .fromARGB(255,
                                                              223, 240, 224)
                                                          : Colors.white,
                                                      border: Border.all(
                                                          color:
                                                              Colors.black12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                      "$formattedStart - $formattedEnd",
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500),
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

                        // Delivery Address Section
                        const SizedBox(height: 20),
                        Consumer(
                          builder: (context, ref, _) {
                            final addressAsyncValue =
                                ref.watch(addressProvider);

                            return addressAsyncValue.when(
                              loading: () => const Center(
                                child: CupertinoActivityIndicator(
                                    color: Colors.black),
                              ),
                              error: (error, stackTrace) => const Center(
                                child: Text(
                                  "Failed to load address.",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16),
                                ),
                              ),
                              data: (selectedAddress) {
                                if (selectedAddress == null ||
                                    selectedAddress.name.isEmpty == true ||
                                    selectedAddress.selectedRoad.isEmpty ==
                                        true) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.15),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AddressPage(),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.add,
                                              color: Color.fromARGB(
                                                  255, 65, 88, 108)),
                                          const SizedBox(width: 12.0),
                                          Text('Select address',
                                              style: GoogleFonts.poppins(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        const Text(
                                          'Delivery',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () async {
                                            final result =
                                                await Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const AddressPage(),
                                              ),
                                            );
                                            if (result == true) {
                                              ref.invalidate(addressProvider);
                                            }
                                          },
                                          child: const Text(
                                            'Change',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ]),
                                      Text(
                                        selectedAddress.type,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "${selectedAddress.name}, ${selectedAddress.selectedRoad}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text("Total Amount :",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("₹$total",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 65, 88, 108),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (fromDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select the start date.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final selectedSlot = ref.read(selectedSlotProvider);
                  if (selectedSlot == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a delivery slot.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final address = ref.read(addressProvider).asData?.value;
                  if (address == null ||
                      address.name.isEmpty ||
                      address.selectedRoad.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please select or add a delivery address.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionPaymentPage(
                        title: title,
                        startDate: fromDate,
                        endDate: endDateText,
                        quantity: selectedQty,
                        slot: selectedSlot,
                        address: address,
                        totalAmount: double.parse(total),
                        productName: productName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Confirm Subscription"),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
