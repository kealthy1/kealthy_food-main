import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';

// Provider for total item count in cart
final cartItemCountProvider = StateProvider<int>((ref) => 0);

class CartContainer extends ConsumerWidget {
  const CartContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch totalItems count from the provider
    final cartItems = ref.watch(cartProvider);
    final totalItems =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    // If no items in the cart, return an empty widget
    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 255, 255), // Light blue
            Color.fromARGB(255, 244, 235, 235), // Lighter blue
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            spreadRadius: 5,
          ),
        ],
        color: Color.fromARGB(
            255, 243, 240, 240), // This will be overridden by the gradient
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cart',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 65, 88, 108),
                ),
              ),
              Text(
                '$totalItems item(s) selected',
                
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 65, 88, 108),
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const CartPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 65, 88, 108),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:  Text(
              'Go to Cart',
              

              style: GoogleFonts.poppins(
                color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            ),
          ),
          IconButton(
              icon: const Icon(CupertinoIcons.delete,
                  color: Color.fromARGB(255, 65, 88, 108)),
              onPressed: () {
                for (var item in cartItems) {
                  ref.read(cartProvider.notifier).removeItem(item.name);
                }
              }),
        ],
      ),
    );
  }
}