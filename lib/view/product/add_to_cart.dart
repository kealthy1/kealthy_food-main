import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';


class AddToCartSection extends ConsumerWidget {
  final String productName;
  final int productPrice;
  final String productEAN;
  final int soh;
  final String imageurl;// Add Stock on Hand parameter

  const AddToCartSection({super.key, 
    required this.productName,
    required this.productPrice,
    required this.productEAN,
    required this.soh,
    required this.imageurl // Include in constructor
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.watch(cartProvider.notifier);
    final cartItem = ref
        .watch(cartProvider)
        .firstWhereOrNull((item) => item.name == productName);

    if (soh == 0) {
      return Column(
        children: [
          Container(
            height: 40,
            width: MediaQuery.of(context).size.width * 0.30,
            decoration: BoxDecoration(
              color: Colors.grey.shade400, // Grey out the button
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'OUT OF STOCK',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (cartItem == null) {
      final loading = cartNotifier.isLoading(productName);
      return GestureDetector(
        onTap: loading
            ? null
            : () async {
                await cartNotifier.addItem(
                  CartItem(
                    name: productName,
                    price: productPrice,
                    ean: productEAN,
                    imageUrl: imageurl
                  ),
                );
              },
        child: Stack(
          children: [
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width * 0.30,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 65, 88, 108),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'ADD',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            if (loading)
              const Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: Colors.black,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      final loading = cartNotifier.isLoading(productName);
      return Stack(
        children: [
          Container(
            height: 40,
            width: MediaQuery.of(context).size.width * 0.30,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 65, 88, 108),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color.fromARGB(255, 65, 88, 108),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white),
                  onPressed: loading
                      ? null
                      : () => cartNotifier.decrementItem(productName),
                ),
                Text(
                  '${cartItem.quantity}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: loading
                      ? null
                      : () => cartNotifier.incrementItem(productName),
                ),
              ],
            ),
          ),
          if (loading)
            const Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: Colors.black,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }
}