import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// CartItem model
class CartItem {
  final String name;
  final int price;
  int quantity;
  final String ean;

  CartItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.ean
  });

  /// Returns the total price (price * quantity) for this item
  int get totalPrice => price * quantity;

  /// Convert to JSON for saving in SharedPreferences
  Map<String, dynamic> toJson() => {
        'Name': name,
        'Price': price,
        'Quantity': quantity,
        'EAN' : ean
      };

  /// Create a CartItem from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      name: json['Name'],
      price: json['Price'],
      quantity: json['Quantity'],
      ean: json['EAN'],
    );
  }

  /// Helper if you want to create a copy with a new quantity
  CartItem copyWith({int? quantity}) => CartItem(
        name: name,
        price: price,
        quantity: quantity ?? this.quantity,
        ean: ean
      );
}

/// StateNotifier to manage the cart state purely in SharedPreferences
class CartNotifier extends StateNotifier<List<CartItem>> {
  /// Constructor loads saved cart items from SharedPreferences
  CartNotifier() : super([]) {
    loadCartItems();
  }

  // ---------------
  // Loading states
  // ---------------
  /// A map to track loading states for each item, keyed by item name
  final Map<String, bool> _loadingMap = {};

  bool isLoading(String itemName) {
    return _loadingMap[itemName] ?? false;
  }

  void setLoading(String itemName, bool loading) {
    _loadingMap[itemName] = loading;
    // We overwrite state with the same list to trigger a rebuild
    state = [...state];
  }

  /// A separate map to track "removing" states
  final Map<String, bool> _removeLoadingMap = {};

  bool isRemoving(String itemName) {
    return _removeLoadingMap[itemName] ?? false;
  }

  void setRemoveLoading(String itemName, bool isLoading) {
    _removeLoadingMap[itemName] = isLoading;
    state = [...state];
  }

  // ---------------
  // SharedPreferences methods
  // ---------------

  /// Load all cart items from SharedPreferences
  Future<void> loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString('cartItems');

    if (cartData != null) {
      final List<dynamic> jsonList = jsonDecode(cartData);
      final List<CartItem> items = jsonList
          .map((item) => CartItem.fromJson(item))
          .toList();
      state = items;
    }
  }

  /// Save the current cart items to SharedPreferences
  Future<void> saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String cartData = jsonEncode(state.map((item) => item.toJson()).toList());
    await prefs.setString('cartItems', cartData);
  }

  // ---------------
  // Cart operations
  // ---------------

  /// Add a new item or increment if it already exists (local only)
  Future<void> addItem(CartItem newItem) async {
    setLoading(newItem.name, true);

    final existingItemIndex =
        state.indexWhere((item) => item.name == newItem.name);

    if (existingItemIndex >= 0) {
      // If the item already exists, just increment its quantity
      await incrementItem(newItem.name);
    } else {
      // Add a new item locally
      state = [...state, newItem];
      await saveCartItems();
    }

    setLoading(newItem.name, false);
  }

  /// Remove an item entirely (local only)
  Future<void> removeItem(String name) async {
    setRemoveLoading(name, true);

    // Filter the item out from the state
    state = state.where((cartItem) => cartItem.name != name).toList();
    await saveCartItems();

    setRemoveLoading(name, false);
  }

  /// Increment item quantity by 1 (local only)
  Future<void> incrementItem(String name) async {
    setLoading(name, true);
    try {
      final index = state.indexWhere((cartItem) => cartItem.name == name);
      if (index >= 0) {
        state[index].quantity++;
        state = [...state]; // triggers UI update
        await saveCartItems();
      }
    } finally {
      setLoading(name, false);
    }
  }

  /// Decrement item quantity by 1 (local only). If it goes below 1, remove the item.
  Future<void> decrementItem(String name) async {
    setLoading(name, true);
    try {
      final index = state.indexWhere((cartItem) => cartItem.name == name);
      if (index >= 0) {
        if (state[index].quantity > 1) {
          state[index].quantity--;
          state = [...state]; 
          await saveCartItems();
        } else {
          // If the quantity is already 1, removing does the same thing
          await removeItem(name);
        }
      }
    } finally {
      setLoading(name, false);
    }
  }

  /// Clear the entire cart (local only)
  Future<void> clearCart() async {
    state = [];
    await saveCartItems();
    print('Cart cleared successfully (local).');
  }

  // ---------------
  // Utility getters
  // ---------------

  /// Compute the total price for all items in the cart
  double get totalPrice {
    double total = 0;
    for (final item in state) {
      total += item.totalPrice;
    }
    return total;
  }

  // ---------------
  // Example “updateCart” or “placeOrder”
  // ---------------
  /// In a real app, you might add your API call here
  /// once the user completes the order. Currently, it does nothing.
  Future<void> updateCart() async {
    // This method does nothing in the local-only version.
    // You could implement an API call here to sync with server if needed.
    print('updateCart() called — no server logic in local-only mode.');
  }
}

// Provider for using CartNotifier in your UI
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});