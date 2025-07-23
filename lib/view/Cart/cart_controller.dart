import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String name;
  final String imageUrl;
  final int price;
  int quantity;
  final String ean;
  final String? type; // Optional category for trial dish check
  final int soh; // Stock on Hand

  CartItem(
      {required this.name,
      required this.price,
      this.quantity = 1,
      required this.ean,
      required this.imageUrl,
      this.type,
      required this.soh});

  int get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
        'Name': name,
        'Price': price,
        'Quantity': quantity,
        'EAN': ean,
        'ImageUrl': imageUrl,
        'type': type,
        'SOH': soh, // Include stock on hand in JSON
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      name: json['Name'],
      price: json['Price'],
      quantity: json['Quantity'],
      ean: json['EAN'],
      imageUrl: json['ImageUrl'] ?? '',
      type: json['type'], // lowercase to match saved key
      soh: json['SOH'] ?? 0, // Handle optional stock on hand
    );
  }

  CartItem copyWith({int? quantity}) => CartItem(
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      ean: ean,
      imageUrl: imageUrl,
      type: type,
      soh: soh // Ensure stock on hand is copied
      );
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref ref;
  CartNotifier(this.ref) : super([]) {
    _initCart();
  }

  Timer? _cartTimer;
  static const _cartTimeout = Duration(minutes: 30);

  final Map<String, bool> _loadingMap = {};
  final Map<String, bool> _removeLoadingMap = {};

  bool isLoading(String itemName) => _loadingMap[itemName] ?? false;
  void setLoading(String itemName, bool loading) {
    _loadingMap[itemName] = loading;
    state = [...state];
  }

  bool isRemoving(String itemName) => _removeLoadingMap[itemName] ?? false;
  void setRemoveLoading(String itemName, bool isLoading) {
    _removeLoadingMap[itemName] = isLoading;
    state = [...state];
  }

  Future<void> _initCart() async {
    await loadCartItems();
    await _checkCartExpiry(); // Add await here
  }

  Future<void> loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString('cartItems');
    if (cartData != null) {
      final List<dynamic> jsonList = jsonDecode(cartData);
      final items = jsonList.map((item) => CartItem.fromJson(item)).toList();
      state = items;
    }
  }

  Future<void> saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String cartData =
        jsonEncode(state.map((item) => item.toJson()).toList());
    await prefs.setString('cartItems', cartData);
  }

  Future<void> _saveCartStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cartStartTime', DateTime.now().toIso8601String());
  }

  Future<void> _clearCartStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cartStartTime');
  }

  Future<void> _checkCartExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final String? startTimeStr = prefs.getString('cartStartTime');

    if (startTimeStr != null) {
      final startTime = DateTime.tryParse(startTimeStr);
      if (startTime != null) {
        final now = DateTime.now();
        final elapsed = now.difference(startTime);

        if (elapsed >= _cartTimeout) {
          await clearCart();
        } else {
          // Start timer for remaining time
          final remaining = _cartTimeout - elapsed;
          _startCartTimer(remaining);
        }
      }
    }
  }

  void _startCartTimer(Duration duration) {
    _cartTimer?.cancel();
    final endTime = DateTime.now().add(duration);

    _cartTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = endTime.difference(DateTime.now());

      if (remaining <= Duration.zero) {
        timer.cancel();
        clearCart();
        ref.read(remainingTimeProvider.notifier).state = null;
      } else {
        ref.read(remainingTimeProvider.notifier).state = remaining;
      }
    });
  }

  void _cancelCartTimer() {
    _cartTimer?.cancel();
  }

  Future<void> addItem(CartItem newItem) async {
    setLoading(newItem.name, true);
    final existingIndex = state.indexWhere((item) => item.name == newItem.name);

    if (existingIndex >= 0) {
      await incrementItem(newItem.name);
    } else {
      state = [...state, newItem];
      await saveCartItems();

      if (state.length == 1) {
        await _saveCartStartTime(); // First item
        _startCartTimer(_cartTimeout);
      }
    }

    setLoading(newItem.name, false);
  }

  Future<void> incrementItem(String name) async {
    setLoading(name, true);
    try {
      final index = state.indexWhere((item) => item.name == name);
      if (index >= 0) {
        state[index].quantity++;
        state = [...state];
        await saveCartItems();
      }
    } finally {
      setLoading(name, false);
    }
  }

  Future<void> decrementItem(String name) async {
    setLoading(name, true);
    try {
      final index = state.indexWhere((item) => item.name == name);
      if (index >= 0) {
        if (state[index].quantity > 1) {
          state[index].quantity--;
          state = [...state];
          await saveCartItems();
        } else {
          await removeItem(name);
        }
      }
    } finally {
      setLoading(name, false);
    }
  }

  Future<void> removeItem(String name) async {
    setRemoveLoading(name, true);
    state = state.where((item) => item.name != name).toList();
    await saveCartItems();
    setRemoveLoading(name, false);

    if (state.isEmpty) {
      _cancelCartTimer();
      await _clearCartStartTime();
    }
  }

  Future<void> clearCart() async {
    state = [];
    await saveCartItems();
    _cancelCartTimer();
    await _clearCartStartTime();
    print("🛒 Cart auto-cleared after timeout.");
  }

  double get totalPrice => state.fold(0, (sum, item) => sum + item.totalPrice);

  @override
  void dispose() {
    _cancelCartTimer();
    super.dispose();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(ref),
);
final remainingTimeProvider = StateProvider<Duration?>((ref) => null);
