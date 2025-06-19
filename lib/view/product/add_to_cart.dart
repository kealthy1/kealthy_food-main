import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';


class AddToCartSection extends ConsumerStatefulWidget {
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
  ConsumerState<AddToCartSection> createState() => _AddToCartSectionState();
}

class _AddToCartSectionState extends ConsumerState<AddToCartSection> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.watch(cartProvider.notifier);
    final cartItem = ref
        .watch(cartProvider)
        .firstWhereOrNull((item) => item.name == widget.productName);

    if (widget.soh == 0) {
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
      final loading = cartNotifier.isLoading(widget.productName);
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: loading
              ? null
              : () async {
                  await cartNotifier.addItem(
                    CartItem(
                      name: widget.productName,
                      price: widget.productPrice,
                      ean: widget.productEAN,
                      imageUrl: widget.imageurl
                    ),
                  );
                },
          child: Stack(
            children: [
              Container(
                height: 40,
                width: MediaQuery.of(context).size.width * 0.30,
                decoration: BoxDecoration(
                  color:    Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green,
                  ),
                ),
                child: Center(
                  child: Text(
                    'BUY NOW',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.green,
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
        ),
      );
    } else {
      final loading = cartNotifier.isLoading(widget.productName);
      return Stack(
        children: [
          Container(
            height: 40,
            width: MediaQuery.of(context).size.width * 0.30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:  Colors.green,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.green),
                  onPressed: loading
                      ? null
                      : () => cartNotifier.decrementItem(widget.productName),
                ),
                Text(
                  '${cartItem.quantity}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: loading
                      ? null
                      : () => cartNotifier.incrementItem(widget.productName),
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