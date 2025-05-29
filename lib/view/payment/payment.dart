import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/payment/dialogue_helper.dart';
import 'package:kealthy_food/view/payment/services.dart';
import 'Online_payment.dart';

final selectedPaymentProvider =
    StateProvider<String>((ref) => 'Cash on Delivery');

final isOrderSavingProvider = StateProvider<bool>((ref) => false);

class PaymentPage extends ConsumerStatefulWidget {
  final double totalAmount;
  final String instructions;
  final dynamic address;
  final String deliverytime;
  final String packingInstructions;
  final double deliveryfee;
  // final double instantDeliveryFee;

  const PaymentPage(
      {super.key,
      required this.totalAmount,
      required this.instructions,
      required this.address,
      required this.deliverytime,
      required this.packingInstructions,
      required this.deliveryfee,
      // required this.instantDeliveryFee
      });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    final selectedPaymentMethod = ref.watch(selectedPaymentProvider);
    final isOrderSaving = ref.watch(isOrderSavingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "Select Payment Method",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentOption(
              context,
              "Cash on Delivery",
              Icons.currency_rupee,
              selectedPaymentMethod == 'Cash on Delivery',
              () => ref.read(selectedPaymentProvider.notifier).state =
                  'Cash on Delivery',
            ),
            const SizedBox(height: 20),
            _buildPaymentOption(
              context,
              "Online Payment",
              Icons.credit_card,
              selectedPaymentMethod == 'Online Payment',
              () => ref.read(selectedPaymentProvider.notifier).state =
                  'Online Payment',
            ),
            const Spacer(),

            // Total Amount Display
            _buildTotalAmount(),

            const SizedBox(height: 10),


            _buildActionButton(selectedPaymentMethod, isOrderSaving, context),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Builds Payment Option Container
  Widget _buildPaymentOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.1,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F4F5) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 65, 88, 108)
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? const Color(0xFF41586C) : Colors.grey),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF41586C)),
          ],
        ),
      ),
    );
  }

  /// Builds the Total Amount Section
  Widget _buildTotalAmount() {
    return Row(
      children: [
        Text(
          "Total Amount",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        Text(
          "₹${widget.totalAmount.toStringAsFixed(2)}",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  /// Builds Place Order or Make Payment Button
  Widget _buildActionButton(
      String selectedPaymentMethod, bool isOrderSaving, BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF41586C),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isOrderSaving ? null : () async => _handlePayment(context),
        child: isOrderSaving
            ? const CupertinoActivityIndicator(
                color: Color(0xFF41586C),
              )
            : Text(
                selectedPaymentMethod == 'Cash on Delivery'
                    ? "Place Order"
                    : "Make Payment",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Handles Payment or Order Placement
  Future<void> _handlePayment(BuildContext context) async {
    ref.read(isOrderSavingProvider.notifier).state = true;

    try {
      final selectedPaymentMethod = ref.read(selectedPaymentProvider);

      if (selectedPaymentMethod == 'Cash on Delivery') {
        await OrderService.saveOrderToFirebase(
          address: widget.address,
          totalAmount: widget.totalAmount,
          deliveryFee: widget.deliveryfee,
          packingInstructions: widget.packingInstructions,
          deliveryInstructions: widget.instructions,
          deliveryTime: widget.deliverytime,
          // instantDeliveryFee: widget.instantDeliveryFee,
          paymentMethod: 'Cash on Delivery',
        );
        await ref.read(cartProvider.notifier).clearCart();

        PaymentDialogHelper.showPaymentSuccessDialog(context, ref);
      } else {
        final razorpayOrderId =
            await OrderService.createRazorpayOrder(widget.totalAmount);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnlinePaymentProcessing(
              totalAmount: widget.totalAmount,
              packingInstructions: widget.packingInstructions,
              deliveryInstructions: widget.instructions,
              address: widget.address,
              deliverytime: widget.deliverytime,
              deliveryFee: widget.deliveryfee,
              // instantDeliveryFee: widget.instantDeliveryFee,
              razorpayOrderId: razorpayOrderId, 
              orderType: 'Normal',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error placing order: $e');
      PaymentDialogHelper.showPaymentFailureDialog(context);
    } finally {
      ref.read(isOrderSavingProvider.notifier).state = false;
    }
  }
}
