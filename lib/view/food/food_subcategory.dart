import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/product/add_to_cart.dart';

class FoodSubCategoryPage extends StatefulWidget {
  const FoodSubCategoryPage({super.key});

  @override
  State<FoodSubCategoryPage> createState() => _FoodSubCategoryPageState();
}

class _FoodSubCategoryPageState extends State<FoodSubCategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 0,
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  final cartItems = ref.watch(cartProvider);
                  final itemCount = cartItems.fold<int>(
                      0, (total, item) => total + item.quantity);

                  return Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Stack(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                                scale: animation, child: child);
                          },
                          child: IconButton(
                            key: ValueKey<int>(itemCount),
                            icon: const Icon(CupertinoIcons.cart, size: 30),
                            onPressed: () {
                              Navigator.pushNamed(context, '/cart');
                            },
                          ),
                        ),
                        if (itemCount > 0)
                          Positioned(
                            right: 3,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 18, minHeight: 18),
                              child: Text(
                                '$itemCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildFoodItem(
                    "Buttercraft Chicken Bowl",
                    "150g",
                    [
                      "Marinated Chicken",
                      "Capsicum (Green/Yellow/Red)",
                      "Onion",
                      "Paneer(Grated)",
                      "Butter",
                      "Onion & Garlic & Celery",
                    ],
                    100),
                _buildFoodItem(
                    "Quinoa & Tuna Fusion Bowl",
                    "150g",
                    [
                      "Quinoa",
                      "Tuna in Olive oil",
                      "Green & Black Olives",
                      "Capsicum (Green/Yellow/Red)",
                      "Onion & Garlic & Celery",
                      "Paneer(Grated)"
                    ],
                    100),
                _buildFoodItem(
                    "Soya Paneer Bowl",
                    "150g",
                    [
                      "Soya",
                      "Paneer(Cubes & Grated)",
                      "Onion",
                      "parsley",
                      "Mushroom",
                      "Capsicum (Green/Yellow/Red)",
                      "Onion & Garlic & Celery",
                      "Butter"
                    ],
                    100),
                _buildFoodItem(
                    "Herbrost Beef Bowl",
                    "150g",
                    [
                      "Marinated Beef Tenderloin",
                      "Potato",
                      "Mushroom",
                      "Capsicum (Green/Yellow/Red)",
                      "Onion & Garlic & Celery",
                      "Butter",
                      "Parsley",
                      "French Beans",
                      "Brocolli",
                      "Carrot"
                    ],
                    100),
              ],
            ),
          ),
          // floatingActionButton removed
        ),
        // ignore: prefer_const_constructors
      ],
    );
  }

  Widget _buildFoodItem(
      String name, String quantity, List<String> ingredients, int price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                "($quantity)",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ingredients:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ingredients.join(', '),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "\u20B9 $price/-",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              AddToCartSection(
                  productName: name,
                  productPrice: price,
                  productEAN: '',
                  soh: 1,
                  imageurl: '')
            ],
          ),
        ],
      ),
    );
  }
}
