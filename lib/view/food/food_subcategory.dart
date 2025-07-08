import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/product/add_to_cart.dart';

/// Model that maps your Firestore document
class TrialDish {
  final String name;
  final int stock;
  final int price;
  final String quantity;
  final String ingredients; // single string

  TrialDish({
    required this.name,
    required this.stock,
    required this.price,
    required this.quantity,
    required this.ingredients,
  });

  factory TrialDish.fromFirestore(Map<String, dynamic> data) {
    return TrialDish(
      name: data['Name'] ?? '',
      stock: data['stock'] ?? 0,
      price: data['price'] ?? 0,
      quantity: data['qty'] ?? '',
      ingredients: data['Ingredients'] ?? '',
    );
  }
}

/// Riverpod StreamProvider to fetch data from Firestore
final trialDishesProvider = StreamProvider<List<TrialDish>>((ref) {
  return FirebaseFirestore.instance.collection('productSOH').snapshots().map(
    (snapshot) {
      return snapshot.docs.map((doc) {
        return TrialDish.fromFirestore(doc.data());
      }).toList();
    },
  );
});

/// Utility to restrict max quantity for trial items
bool _isTrialDish(String name) {
  const trialDishes = [
    'Buttercraft Chicken Bowl',
    'Quinoa & Tuna Fusion Bowl',
    'Soya Paneer Bowl',
    'Herbrost Beef Bowl',
  ];
  return trialDishes.contains(name);
}

class FoodSubCategoryPage extends ConsumerStatefulWidget {
  const FoodSubCategoryPage({super.key, });
  

  @override
  ConsumerState<FoodSubCategoryPage> createState() => _FoodSubCategoryPageState();
}

class _FoodSubCategoryPageState extends ConsumerState<FoodSubCategoryPage> {
  @override
  Widget build(BuildContext context) {
    final trialDishesAsync = ref.watch(trialDishesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trial Dishes',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: IconButton(
                        key: ValueKey<int>(itemCount),
                        icon: const Icon(CupertinoIcons.cart, size: 30),
                        onPressed: () => Navigator.pushNamed(context, '/cart'),
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
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
      body: trialDishesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error loading dishes")),
        data: (dishes) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Lunch Only (12 PM - 3 PM)',
                      style: GoogleFonts.poppins(
                        color: Colors.orange.shade800,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...dishes.map(_buildFoodItem).toList(),
                const SizedBox(height: 12),
                Text(
                  '*Introductory price',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodItem(TrialDish dish) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                dish.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                "(${dish.quantity})",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ingredients:',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            dish.ingredients,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "*\u20B9${dish.price}/-",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: dish.stock > 0 ? Colors.black87 : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (dish.stock > 0)
                AddToCartSection(
                  productName: dish.name,
                  productPrice: dish.price,
                  productEAN: '',
                  soh: dish.stock,
                  imageurl: '',
                  maxQuantity: _isTrialDish(dish.name) ? 1 : null,
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Out of Stock',
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }
}