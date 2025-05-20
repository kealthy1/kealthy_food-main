import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/Cart/cart.dart';

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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => const CartPage(),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.50,
        height: MediaQuery.of(context).size.height * 0.08,
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
              spreadRadius: 3,
            ),
          ],
          color: Color.fromARGB(255, 255, 255, 245), // This will be overridden by the gradient
          borderRadius: BorderRadius.all(Radius.circular(45)
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View Cart',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 65, 88, 108),
                  ),
                ),
                Text(
                  '$totalItems item(s)',
                  
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 65, 88, 108),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 65, 88, 108),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
            // const SizedBox(
            //   width: 5,
            // ),
            // GestureDetector(
            //   onTap: () {
            //     for (var item in cartItems) {
            //           ref.read(cartProvider.notifier).removeItem(item.name);
            //         }
            //   },
            //   child: const Icon(CupertinoIcons.delete,size: 15,
            //           color: Color.fromARGB(255, 65, 88, 108)),
            //    ),
          
          ],
        ),
      ),
    );
  }
}
