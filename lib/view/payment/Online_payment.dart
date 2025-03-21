import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_food/view/payment/dialogue_helper.dart';
import 'package:kealthy_food/view/payment/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';

class OnlinePaymentProcessing extends ConsumerStatefulWidget {
  final double totalAmount;
  final String packingInstructions;
  final String deliveryInstructions;
  final dynamic address;
  final String deliverytime;
  final double deliveryFee;
  final double instantDeliveryFee;
  final String razorpayOrderId;

  const OnlinePaymentProcessing({
    super.key,
    required this.totalAmount,
    required this.packingInstructions,
    required this.deliveryInstructions,
    required this.address,
    required this.deliverytime,
    required this.deliveryFee,
    required this.instantDeliveryFee,
    required this.razorpayOrderId,
  });

  @override
  _OnlinePaymentProcessingState createState() =>
      _OnlinePaymentProcessingState();
}

class _OnlinePaymentProcessingState
    extends ConsumerState<OnlinePaymentProcessing> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    openCheckout(); // Start payment as soon as the widget loads
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await OrderService.removeRazorpayOrderId();

    // Payment succeeded, so let's save the order
    await OrderService.saveOrderToFirebase(
      address: widget.address,
      totalAmount: widget.totalAmount,
      deliveryFee: widget.deliveryFee,
      packingInstructions: widget.packingInstructions,
      deliveryInstructions: widget.deliveryInstructions,
      deliveryTime: widget.deliverytime,
      instantDeliveryFee: widget.instantDeliveryFee,
      paymentMethod: "Online Payment",
    );

    // Clear the cart
    ref.read(cartProvider.notifier).clearCart();

    // Show success dialog from the new helper
    PaymentDialogHelper.showPaymentSuccessDialog(context, ref);
  }

  void _handlePaymentFailure(PaymentFailureResponse response) async {
    print("Payment Failed: ${response.code} | ${response.message}");

    await OrderService.removeRazorpayOrderId();

    // Show failure dialog from the new helper
    PaymentDialogHelper.showPaymentFailureDialog(context);
  }

  Future<void> _handleExternalWallet(ExternalWalletResponse response) async {
    await OrderService.removeRazorpayOrderId();
    Navigator.pop(context);
  }

  void openCheckout() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';
    final userName = prefs.getString('Name') ?? 'Test User';

    final storedOrderId = prefs.getString('RazorpayorderId') ?? '';
    if (storedOrderId.isEmpty) {
      print("❌ No stored Razorpay Order ID found");
      return;
    }

    try {
      final options = {
        'key': 'rzp_live_jA2MRdwkkUcT9v',
        'amount': widget.totalAmount
            .toStringAsFixed(0), // <-- If your server does the paise conversion
        'currency': 'INR',
        'name': 'Kealthy',
        'description': 'Kealthy',
        'image':
            'https://firebasestorage.googleapis.com/v0/b/kealthy-90c55.appspot.com/o/final-image-removebg-preview.png?alt=media&token=3184c1f9-2162-45e2-9bea-95519ef1519b',
        'order_id': storedOrderId,
        'prefill': {
          'contact': phoneNumber,
          'name': userName,
        },
        'method': {
          'upi': true,
          'card': true,
          'netbanking': true,
        },
        'upi': {'flow': 'intent'},
        if (!Platform.isIOS)
          'external': {
            'wallets': ['paytm', 'phonepe', 'gpay'],
          }
        else
          'external': {
            'wallets': ['paytm', 'phonepe'],
          },
      };

      _razorpay.open(options);
    } catch (e) {
      print('❌ Error opening Razorpay checkout: $e');
    }
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clear all listeners
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: Text(
          "Processing Payment",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
          child: CupertinoActivityIndicator(
        color: Color.fromARGB(255, 65, 88, 108),
      )),
    );
  }
}
