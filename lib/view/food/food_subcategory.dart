// Provider to manage expanded state for each ingredient block by dish name

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/product/add_to_cart.dart';
import 'package:kealthy_food/view/product/product_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

/// Model that maps your Firestore document
class TrialDish {
  final String id;
  final String name;
  final int stock;
  final int price;
  final String quantity;
  final String ingredients; // single string
  final String imageurl; // added
  final String what; // added
  final String nutrients; // added
  final String fiber; // added
  final String energy; // added
  final String protein; // added
  final String saturatedFat; // added
  final String totalFat; // added
  final String transFat; // added
  final String unsaturatedFat; // added
  final String whatisitusedfor; // added
  final String sugar; // added
  final String carbs; // added

  TrialDish({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.quantity,
    required this.ingredients,
    required this.imageurl,
    required this.what,
    required this.nutrients,
    required this.fiber,
    required this.energy,
    required this.protein,
    required this.saturatedFat,
    required this.totalFat,
    required this.transFat,
    required this.unsaturatedFat,
    required this.whatisitusedfor,
    required this.sugar,
    required this.carbs,
  });

  factory TrialDish.fromFirestore(String id, Map<String, dynamic> data) {
    return TrialDish(
      id: id,
      name: data['Name'] ?? '',
      carbs: data['Total Carbohydrates (g)'] ?? '',
      sugar: data['Sugars (g)'] ?? '',
      unsaturatedFat: data['Unsaturated Fat (g)'] ?? '',
      transFat: data['Trans Fat (g)'] ?? '',
      totalFat: data['Total Fat (g)'] ?? '',
      saturatedFat: data['Saturated Fat (g)'] ?? '',
      protein: data['Protein (g)'] ?? '',
      what: data['What is it?'] ?? '',
      whatisitusedfor: data['What is it used for?'] ?? '',
      energy: data['Energy (kcal)'] ?? '',
      fiber: data['Dietary Fiber (g)'] ?? '',
      nutrients: data['Vendor Name'] ?? '',
      stock: data['SOH'] ?? 0,
      price: data['Price'] ?? 0,
      quantity: data['Qty'] ?? '',
      ingredients: (data['Ingredients'] as List?)?.join(', ') ?? '',
      imageurl: (data['ImageUrl'] is List && data['ImageUrl'].isNotEmpty)
          ? data['ImageUrl'][0]
          : '',
    );
  }
}

/// Riverpod StreamProvider to fetch data from Firestore
final dishesProvider =
    StreamProvider.family<List<TrialDish>, String?>((ref, categoryName) async* {
  yield* FirebaseFirestore.instance
      .collection('Products')
      .where('Type', isEqualTo: categoryName)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return TrialDish.fromFirestore(doc.id, doc.data());
    }).toList();
  });
});

class FoodSubCategoryPage extends ConsumerStatefulWidget {
  final String categoryName;
  const FoodSubCategoryPage({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<FoodSubCategoryPage> createState() =>
      _FoodSubCategoryPageState();
}

class _FoodSubCategoryPageState extends ConsumerState<FoodSubCategoryPage> {
  final TextEditingController _suggestionController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final dishesAsync = ref.watch(dishesProvider(widget.categoryName));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
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
      body: dishesAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => const Center(child: Text("Error loading dishes")),
        data: (dishes) {
          print("Fetched dishes: ${dishes.length}");
          if (dishes.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('lib/assets/images/restaurant.png',
                        width: 60, color: Colors.black),
                    const SizedBox(height: 16),
                    Text(
                      'New dishes coming soon!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What would you like to add to this menu?',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              TextField(
                                controller: _suggestionController,
                                decoration: const InputDecoration(
                                  hintText: 'Suggest a dish...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5))),
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final phoneNumber =
                                      prefs.getString('phoneNumber') ??
                                          'Unknown';
                                  final suggestion =
                                      _suggestionController.text.trim();

                                  if (suggestion.isNotEmpty) {
                                    await FirebaseFirestore.instance
                                        .collection('MenuSuggestions')
                                        .add({
                                      'suggestion': suggestion,
                                      'phoneNumber': phoneNumber,
                                      'timestamp': DateTime.now(),
                                    });
                                    _suggestionController.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Thank you for your suggestion!')),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Submit',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: dishes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) {
                return _buildFoodItem(dishes[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodItem(TrialDish dish) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => ProductPage(productId: dish.id),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dish.imageurl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: dish.imageurl,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width * 0.32,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                            child: Icon(Icons.image_not_supported)),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    dish.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "\u20B9${dish.price}",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: dish.stock > 0 ? Colors.black87 : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dish.quantity,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (dish.stock == 0)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Out of Stock',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// class IngredientText extends StatelessWidget {
//   final TrialDish dish;

//   const IngredientText({
//     super.key,
//     required this.dish,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final exceedsLimit = dish.ingredients.length > 100;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           dish.ingredients,
//           maxLines: 3,
//           overflow: TextOverflow.ellipsis,
//           style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
//         ),
//         if (exceedsLimit)
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               TextButton(
//                 onPressed: () {
//                   showDialog(
//                     context: context,
//                     builder: (context) {
//                       return AlertDialog(
//                         title: Text(
//                           'Additional Information',
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                           ),
//                         ),
//                         content: SingleChildScrollView(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               RichText(
//                                 text: TextSpan(
//                                   style: GoogleFonts.poppins(
//                                       fontSize: 14, color: Colors.black87),
//                                   children: [
//                                     const TextSpan(
//                                       text: 'Ingredients: ',
//                                       style: TextStyle(
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                     TextSpan(text: dish.ingredients),
//                                     const TextSpan(text: '\n\n'),
//                                     TextSpan(text: dish.what),
//                                     const TextSpan(
//                                         text: '\n\nUsed for: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                     TextSpan(text: dish.whatisitusedfor),
//                                     const TextSpan(
//                                         text: '\n\nEnergy: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                     TextSpan(text: dish.energy),
//                                     const TextSpan(
//                                         text: '\nProtein: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                     TextSpan(text: dish.protein),
//                                     const TextSpan(
//                                         text: '\nFiber: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                     TextSpan(text: dish.fiber),
//                                     const TextSpan(
//                                         text: '\nTotal Fat: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                     TextSpan(text: dish.totalFat),
//                                     const TextSpan(
//                                         text: '\nSaturated Fat: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                     TextSpan(text: dish.saturatedFat),
//                                     const TextSpan(
//                                         text: '\nUnsaturated Fat: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                     TextSpan(text: dish.unsaturatedFat),
//                                     const TextSpan(
//                                         text: '\nTrans Fat: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                     TextSpan(text: dish.transFat),
//                                     const TextSpan(
//                                         text: '\nSugar: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                     TextSpan(text: dish.sugar),
//                                     const TextSpan(
//                                         text: '\nCarbs: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                     TextSpan(text: dish.carbs),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         actions: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: Text(
//                               'Close',
//                               style: GoogleFonts.poppins(),
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   );
//                 },
//                 child: Text(
//                   'More',
//                   style: GoogleFonts.poppins(fontSize: 14, color: Colors.green),
//                 ),
//               ),
//             ],
//           ),
//       ],
//     );
//   }
// }
