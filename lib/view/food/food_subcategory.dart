import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/product/add_to_cart.dart';

/// Provider that fetches product stock from Firestore.
/// The Firestore collection "productSOH" should have documents with product names as IDs
/// and each document should have a "stock" field.
final firestoreStockProvider = StreamProvider<Map<String, int>>((ref) {
  final stockCollection = FirebaseFirestore.instance.collection('productSOH');

  return stockCollection.snapshots().map((snapshot) {
    final Map<String, int> stockMap = {};
    for (var doc in snapshot.docs) {
      final name = doc.id;
      final soh = doc.data()['stock'] ?? 0;
      stockMap[name] = soh is int ? soh : int.tryParse(soh.toString()) ?? 0;
    }
    return stockMap;
  });
});

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
  const FoodSubCategoryPage({super.key});

  @override
  ConsumerState<FoodSubCategoryPage> createState() =>
      _FoodSubCategoryPageState();
}

class _FoodSubCategoryPageState extends ConsumerState<FoodSubCategoryPage> {
  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(firestoreStockProvider);

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
                          constraints:
                              const BoxConstraints(minWidth: 18, minHeight: 18),
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
      body: stockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text("Error loading stock")),
        data: (stockMap) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Container(
                  height: 50,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                _buildFoodItem(
                  "Buttercraft Chicken Bowl",
                  "200g",
                  [
                    "Marinated Chicken",
                    "Capsicum (Green/Yellow/Red)",
                    "Onion",
                    "Paneer(Grated)",
                    "Butter",
                    "Onion & Garlic & Celery",
                  ],
                  100,
                  stockMap['Buttercraft Chicken Bowl']!,
                ),
                _buildFoodItem(
                  "Quinoa & Tuna Fusion Bowl",
                  "200g",
                  [
                    "Quinoa",
                    "Tuna in Olive oil",
                    "Green & Black Olives",
                    "Capsicum (Green/Yellow/Red)",
                    "Onion & Garlic & Celery",
                    "Paneer(Grated)",
                  ],
                  100,
                  stockMap['Quinoa & Tuna Fusion Bowl']!,
                ),
                _buildFoodItem(
                  "Soya Paneer Bowl",
                  "200g",
                  [
                    "Soya",
                    "Paneer(Cubes & Grated)",
                    "Onion",
                    "Parsley",
                    "Mushroom",
                    "Capsicum (Green/Yellow/Red)",
                    "Onion & Garlic & Celery",
                    "Butter"
                  ],
                  100,
                  stockMap['Soya Paneer Bowl']!,
                ),
                _buildFoodItem(
                  "Herbrost Beef Bowl",
                  "200g",
                  [
                    "Marinated Beef Tenderloin",
                    "Potato",
                    "Mushroom",
                    "Capsicum (Green/Yellow/Red)",
                    "Onion & Garlic & Celery",
                    "Butter",
                    "Parsley",
                    "French Beans",
                    "Broccoli",
                    "Carrot",
                  ],
                  100,
                  stockMap['Herbrost Beef Bowl']!,
                ),
                Text('*Introductory price',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodItem(String name, String quantity, List<String> ingredients,
      int price, int soh) {
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
                name,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 5),
              Text(
                "($quantity)",
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
            ingredients.join(', '),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "*\u20B9$price/-",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: soh > 0 ? Colors.black87 : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (soh > 0)
                AddToCartSection(
                  productName: name,
                  productPrice: price,
                  productEAN: '',
                  soh: soh,
                  imageurl: '',
                  maxQuantity: _isTrialDish(name) ? 2 : null,
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
