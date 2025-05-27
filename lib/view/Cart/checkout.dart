import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- NEW
import 'package:kealthy_food/view/Cart/bill.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/Cart/checkout_provider.dart';
import 'package:kealthy_food/view/Cart/instruction_container.dart';
import 'package:kealthy_food/view/payment/payment.dart';

// Asynchronous Provider for Address

// Checkout Page
class CheckoutPage extends ConsumerWidget {
  final double itemTotal;
  final List<CartItem> cartItems;
  final String deliveryTime;
  final double instantDeliveryfee;

  const CheckoutPage({
    super.key,
    required this.itemTotal,
    required this.cartItems,
    required this.deliveryTime,
    required this.instantDeliveryfee,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstOrderAsync = ref.watch(firstOrderProvider);

// ignore: dead_code
    // Watch the addressProvider
    final addressAsyncValue = ref.watch(addressProvider);

    final TextEditingController packingInstructionsController =
        TextEditingController(
      text: "Don't send cutleries, tissues, straws, etc.",
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        title: Text(
          "Checkout",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: firstOrderAsync.when(
          loading: () => const Center(
            child: CupertinoActivityIndicator(color: Color(0xFF273847)),
          ),
          error: (e, _) => Center(
            child: Text(
              "Error loading offer status: $e",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
            ),
          ),
          data: (isFirstOrder) {
            final TextEditingController packingInstructionsController =
                TextEditingController(
              text: "Don't send cutleries, tissues, straws, etc.",
            );

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Address',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ref.watch(addressProvider).when(
                        loading: () => const Center(
                          child: CupertinoActivityIndicator(
                            color: Color(0xFF273847),
                          ),
                        ),
                        error: (e, _) => Text(
                          "Error loading address: $e",
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.red),
                        ),
                        data: (selectedAddress) {
                          if (selectedAddress == null) {
                            return Text(
                              "No address selected",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            );
                          }

                          final double distanceInKm =
                              double.tryParse(selectedAddress.distance) ?? 0.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Address Card
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedAddress.type,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "${selectedAddress.name} , ${selectedAddress.selectedRoad}",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${selectedAddress.distance} km',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Delivery Time: $deliveryTime',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Packing Instructions
                              Text(
                                'Packing Instructions',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: TextField(
                                    controller: packingInstructionsController,
                                    maxLines: 3,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                    cursorColor: Colors.black,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Delivery Instructions
                              Text(
                                'Delivery Instructions',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 3,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      InstructionContainer(
                                        icon: Icons.notifications_off_outlined,
                                        label: "Avoid Ringing Bell",
                                        id: 1,
                                      ),
                                      SizedBox(width: 10),
                                      InstructionContainer(
                                        icon: Icons.door_front_door_outlined,
                                        label: "Leave at Door",
                                        id: 2,
                                      ),
                                      SizedBox(width: 10),
                                      InstructionContainer(
                                        icon: Icons.person_outlined,
                                        label: "Leave with Guard",
                                        id: 3,
                                      ),
                                      SizedBox(width: 10),
                                      InstructionContainer(
                                        icon: Icons.phone_disabled_outlined,
                                        label: "Avoid Calling",
                                        id: 4,
                                      ),
                                      SizedBox(width: 10),
                                      InstructionContainer(
                                        icon: Icons.pets_outlined,
                                        label: "Pet at home",
                                        id: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Offer section
                              if (isFirstOrder)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.green.shade400),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        '🎉',
                                        style: TextStyle(fontSize: 25),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Congratulations! You get ₹100 off on your first order.",
                                          style: GoogleFonts.poppins(
                                            color: Colors.green.shade800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 15),

                              // Final bill
                              BillDetailsWidget(
                                itemTotal: itemTotal,
                                distanceInKm: distanceInKm,
                                instantDeliveryFee: instantDeliveryfee,
                                offerDiscount: isFirstOrder ? 100.0 : 0.0,
                              ),

                              const SizedBox(height: 150),
                            ],
                          );
                        },
                      ),
                ],
              ),
            );
          },
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        height: 90,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 65, 88, 108),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            // Access selected instructions and packing instructions
            final instructions = getSelectedInstructions(ref);
            final packingInstructions = packingInstructionsController.text;

            // Navigate to the payment page with required arguments
            addressAsyncValue.whenData((selectedAddress) {
              if (selectedAddress != null) {
                final double distanceInKm =
                    double.tryParse(selectedAddress.distance) ?? 0.0;

                // Use helper methods:
                final double normalDeliveryFee =
                    calculateDeliveryFee(itemTotal, distanceInKm);

                // 2) Combine Normal + Instant
                final isFirstOrder =
                    ref.read(firstOrderProvider).value ?? false;
                final double offerDiscount = isFirstOrder ? 100.0 : 0.0;

                final double finalTotalToPay = calculateFinalTotal(
                  itemTotal - offerDiscount,
                  distanceInKm,
                  instantDeliveryfee,
                );

                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => PaymentPage(
                      totalAmount: finalTotalToPay,
                      instructions: instructions,
                      address: selectedAddress,
                      deliverytime: deliveryTime,
                      packingInstructions: packingInstructions,
                      deliveryfee: normalDeliveryFee,
                      instantDeliveryFee: instantDeliveryfee,
                    ),
                  ),
                );
              }
            });
          },
          child: Text(
            'Proceed to Payment',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
