import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/Toast/toast_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _isTrialDish(String name) {
  const trialDishes = [
    'Buttercraft Chicken Bowl',
    'Quinoa & Tuna Fusion Bowl',
    'Soya Paneer Bowl',
    'Herbrost Beef Bowl',
  ];
  return trialDishes.contains(name);
}

Future<int> getTodayOrderedQuantity({
  required String phoneNumber,
  required String productName,
}) async {
  int totalQty = 0;

  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);

  // 🔹 Step 1: Check Realtime Database orders
  try {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
    );

    final snapshot = await db
        .ref('orders')
        .orderByChild('phoneNumber')
        .equalTo(phoneNumber)
        .get();

    if (snapshot.exists) {
      print('🔍 Checking Realtime DB for $productName on $phoneNumber');

      for (final order in snapshot.children) {
        final data = Map<String, dynamic>.from(order.value as Map);
        final createdAt =
            DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime(2000);

        if (createdAt.isAfter(todayStart)) {
          final orderItems = List<Map>.from(data['orderItems'] ?? []);
          for (final item in orderItems) {
            if (item['item_name'] == productName) {
              totalQty += (item['item_quantity'] ?? 0) is int
                  ? (item['item_quantity'] ?? 0) as int
                  : ((item['item_quantity'] ?? 0) as num).toInt();
            }
          }
        }
      }
    }
  } catch (e) {
    print('⚠️ Error in Realtime DB check: $e');
  }

  // 🔹 Step 2: Check API-based orders (e.g., from past DB)
  try {
    final response = await http.get(
      Uri.parse('https://api-jfnhkjk4nq-uc.a.run.app/orders/$phoneNumber'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      for (final order in data) {
        final createdAt = DateTime.tryParse(order['createdAt'] ?? '');
        if (createdAt != null && createdAt.isAfter(todayStart)) {
          final orderItems =
              List<Map<String, dynamic>>.from(order['orderItems'] ?? []);
          for (final item in orderItems) {
            if (item['item_name'] == productName) {
              totalQty += (item['item_quantity'] ?? 0) is int
                  ? (item['item_quantity'] ?? 0) as int
                  : ((item['item_quantity'] ?? 0) as num).toInt();
            }
          }
        }
      }
    } else {
      print('⚠️ API failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('⚠️ Error fetching API orders: $e');
  }

  print('✅ Total ordered today for $productName: $totalQty');
  return totalQty;
}

class AddToCartSection extends ConsumerStatefulWidget {
  final String productName;
  final int productPrice;
  final String productEAN;
  final int soh;
  final String imageurl; // Add Stock on Hand parameter
  final int? maxQuantity;

  const AddToCartSection({
    super.key,
    required this.productName,
    required this.productPrice,
    required this.productEAN,
    required this.soh,
    required this.imageurl,
    this.maxQuantity,
    // Include in constructor
  });

  @override
  ConsumerState<AddToCartSection> createState() => _AddToCartSectionState();
}

class _AddToCartSectionState extends ConsumerState<AddToCartSection>
    with TickerProviderStateMixin {
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
                  final prefs = await SharedPreferences.getInstance();
                  final phoneNumber = prefs.getString('phoneNumber') ?? '';

                  // ✅ Trial dish logic
                  if (_isTrialDish(widget.productName)) {
                    final alreadyOrderedToday = await getTodayOrderedQuantity(
                      phoneNumber: phoneNumber,
                      productName: widget.productName,
                    );

                    if (alreadyOrderedToday >= 2) {
                      ToastHelper.showErrorToast(
                        'Daily limit reached: You can only order 2 of this item per day.',
                      );
                      return;
                    }
                  }

                  // ✅ Prevent double-add from BUY NOW
                  final itemInCart = ref
                      .read(cartProvider)
                      .any((item) => item.name == widget.productName);
                  if (itemInCart) return;

                  await cartNotifier.addItem(
                    CartItem(
                      name: widget.productName,
                      price: widget.productPrice,
                      ean: widget.productEAN,
                      imageUrl: widget.imageurl,
                      quantity: 1,
                    ),
                  );

                  ToastHelper.showSuccessToast('Item added to cart');
                },
          child: Stack(
            children: [
              Container(
                height: 40,
                width: MediaQuery.of(context).size.width * 0.30,
                decoration: BoxDecoration(
                  color: Colors.white,
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
                color: Colors.green,
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
                  icon: Icon(
                    Icons.add,
                    color: (widget.maxQuantity != null &&
                            cartItem.quantity >= widget.maxQuantity!)
                        ? Colors.grey
                        : Colors.green,
                  ),
                  onPressed: () async {
                    if (_isTrialDish(widget.productName)) {
                      if (widget.maxQuantity != null &&
                          cartItem.quantity >= widget.maxQuantity!) {
                        ToastHelper.showErrorToast(
                          'You can only select 2 quantities for trial dishes.',
                        );
                        return;
                      }

                      final prefs = await SharedPreferences.getInstance();
                      final phoneNumber = prefs.getString('phoneNumber') ?? '';

                      int alreadyOrderedToday = await getTodayOrderedQuantity(
                        phoneNumber: phoneNumber,
                        productName: widget.productName,
                      );

                      int totalIfAdded =
                          alreadyOrderedToday + cartItem.quantity + 1;

                      if (totalIfAdded > 2) {
                        ToastHelper.showErrorToast(
                          'Daily limit reached: You can only order 2 quantities of this item per day.',
                        );
                        return;
                      }
                    }

                    await cartNotifier.incrementItem(widget.productName);
                  },
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
