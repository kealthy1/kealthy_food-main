// order_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kealthy_food/view/Toast/toast_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OrderService {
  /// Decrements the SOH (Stock On Hand) for each item in the order.
  static Future<void> decrementSOHForItems(dynamic address) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final WriteBatch batch = firestore.batch();

      for (final item in address.cartItems) {
        final productName = item.name;
        final quantityPurchased = item.quantity ?? 1;

        final querySnapshot = await firestore
            .collection('Products')
            .where('Name', isEqualTo: productName)
            .get();

        for (final doc in querySnapshot.docs) {
          final docRef = doc.reference;
          final docData = doc.data();
          final currentSOH = docData['SOH'] ?? 0;

          final updatedSOH = (currentSOH - quantityPurchased) < 0
              ? 0
              : (currentSOH - quantityPurchased);

          // Check if offer is active (deal_of_the_day or deal_of_the_week)
          final isOfferActive = docData['deal_of_the_day'] == true || docData['deal_of_the_week'] == true;
          final currentOfferSOH = docData['offer_soh'] ?? 0;
          final updatedOfferSOH = (currentOfferSOH - quantityPurchased) < 0
              ? 0
              : (currentOfferSOH - quantityPurchased);

          // Always update SOH
          batch.update(docRef, {'SOH': updatedSOH});
          // If offer is active, also update offer_soh
          if (isOfferActive) {
            batch.update(docRef, {'offer_soh': updatedOfferSOH});
          }
        }
      }

      await batch.commit();
      print('SOH decremented successfully.');
    } catch (e) {
      print('Error decrementing SOH: $e');
      rethrow;
    }
  }

  /// Creates a Razorpay order via your backend’s `/create-order` route.
  static Future<String> createRazorpayOrder(double totalAmount) async {
    try {
      const String backendUrl = 'https://api-jfnhkjk4nq-uc.a.run.app';
      final response = await http.post(
        Uri.parse('$backendUrl/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': totalAmount
              .round(), // in rupees if your backend does the *100 conversion
          'currency': 'INR',
          'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final razorpayOrderId = data['orderId'];
        print("✅ Razorpay Order ID generated: $razorpayOrderId");

        // Save Razorpay Order ID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('RazorpayorderId', razorpayOrderId);

        print(
            "🔒 Saved Razorpay Order ID to SharedPreferences: $razorpayOrderId");
        return razorpayOrderId;
      } else {
        ToastHelper.showErrorToast('Failed to create Razorpay order. Please try again.');
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      print("❌ Error creating Razorpay order: $e");
      ToastHelper.showErrorToast('Something went wrong !');
      rethrow;
    }
  }

  /// Removes the Razorpay order ID from SharedPreferences
  static Future<void> removeRazorpayOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('RazorpayorderId');
    print("✅ Razorpay Order ID removed from SharedPreferences");
  }

  /// Saves a new order in Firebase (Realtime Database in this example).
  static Future<void> saveOrderToFirebase({
    // required double offerDiscount,
    required dynamic address,
    required double totalAmount,
    required double deliveryFee,
    required String packingInstructions,
    required String deliveryInstructions,
    required String deliveryTime,
    required String paymentMethod,
    // required double instantDeliveryFee,
  }) async {
    try {
      final database = FirebaseDatabase.instanceFor(
        databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
        app: Firebase.app(),
      );
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';

      // Generate Unique Order ID
      final orderId = _generateOrderId();
      await prefs.setString('order_id', orderId);
      await prefs.setString('latest_order_id', orderId);

      final orderTime = DateTime.now().toIso8601String();
      await prefs.setString('order_completed_time', orderTime);

      final orderData = {
        "Name": address.name ?? 'Unknown Name',
        "type": "Normal",
        "assignedto": "NotAssigned",
        "DA": "Waiting",
        "DAMOBILE": "Waiting",
        "cookinginstrcutions": packingInstructions,
        "createdAt": orderTime,
        "deliveryInstructions": deliveryInstructions,
        "distance": address.distance ?? 0.0,
        "landmark": address.landmark ?? '',
        "orderId": orderId,
        "orderItems": address.cartItems.map((item) {
          return {
            "item_name": item.name ?? '',
            "item_price": item.price ?? 0.0,
            "item_quantity": item.quantity ?? 1,
            "item_ean": item.ean ?? ''
          };
        }).toList(),
        "paymentmethod": paymentMethod,
        "fcm_token": prefs.getString("fcm_token") ?? '',
        "phoneNumber": phoneNumber,
        "selectedDirections": address.selectedInstruction ?? 0.0,
        "selectedLatitude": address.selectedLatitude ?? 0.0,
        "selectedLongitude": address.selectedLongitude ?? 0.0,
        "selectedRoad": address.selectedRoad ?? '',
        "selectedSlot": deliveryTime,
        "selectedType": address.type ?? '',
        "status": "Order Placed",
        "totalAmountToPay": totalAmount,
        "deliveryFee": deliveryFee,
        // "offerDiscount": offerDiscount,
        // "instantDeliveryfee": instantDeliveryFee,
      };

      // Save to Realtime Database
      await database.ref().child('orders').child(orderId).set(orderData);
      print('Order saved successfully with orderId = $orderId');
      

      // Decrement stock
      // await decrementSOHForItems(address);

      // Optionally save a notification doc to Firestore
      await saveNotificationToFirestore(orderId, address.cartItems);
    } catch (error, stackTrace) {
      print('Error saving order: $error');
      print('StackTrace: $stackTrace');
      rethrow; // or handle the error with a custom logic
    }
  }

  /// Saves a subscription order in Firebase Realtime Database.
  static Future<void> saveSubscriptionOrderToFirebase({
    required dynamic address,
    required double totalAmount,
    required double deliveryFee,
    required String packingInstructions,
    required String deliveryInstructions,
    required String deliveryTime,
    required String paymentMethod,
    // required double instantDeliveryFee,
  }) async {
    try {
      final database = FirebaseDatabase.instanceFor(
        databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
        app: Firebase.app(),
      );
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';

      // Generate Unique Subscription Order ID
      final orderId = _generateOrderId();
      await prefs.setString('subscription_order_id', orderId);
      await prefs.setString('latest_order_id', orderId);

      final orderTime = DateTime.now().toIso8601String();
      await prefs.setString('order_completed_time', orderTime);

      final String planTitle = prefs.getString('subscription_plan_title') ?? '';
      final String productName = prefs.getString('subscription_product_name') ?? '';
      final String startDate = prefs.getString('subscription_start_date') ?? '';
      final String endDate = prefs.getString('subscription_end_date') ?? '';
      final String subscriptionQty = prefs.getString('subscription_qty') ?? '';

      final orderData = {
        "Name": address.name ?? 'Unknown Name',
        "type": "subscription",
        "assignedto": "NotAssigned",
        "DA": "Waiting",
        "DAMOBILE": "Waiting",
        "createdAt": orderTime,
        "distance": address.distance ?? 0.0,
        "landmark": address.landmark ?? '',
        "orderId": orderId,
        "paymentmethod": 'Prepaid',
        "fcm_token": prefs.getString("fcm_token") ?? '',
        "phoneNumber": phoneNumber,
        "selectedDirections": address.selectedInstruction ?? 0.0,
        "selectedLatitude": address.selectedLatitude ?? 0.0,
        "selectedLongitude": address.selectedLongitude ?? 0.0,
        "selectedRoad": address.selectedRoad ?? '',
        "selectedSlot": deliveryTime,
        "selectedType": address.type ?? '',
        "status": "Order Placed",
        "totalAmountToPay": totalAmount,
        "deliveryFee": deliveryFee,
        // "instantDeliveryfee": instantDeliveryFee,
        "planTitle": planTitle,
        "productName": productName,
        "startDate": startDate,
        "endDate": endDate,
        "subscriptionQty": "$subscriptionQty L",
      };

      await database.ref().child('subscriptions').child(orderId).set(orderData);
      print('Subscription order saved successfully with orderId = $orderId');

    } catch (error, stackTrace) {
      print('Error saving subscription order: $error');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Saves a "review request" notification in Firestore
  static Future<void> saveNotificationToFirestore(
      String orderId, List cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';
      final productNames = cartItems.map((item) => item.name).toList();

      final notificationData = {
        'body': "How was your experience? Give us a quick star rating!",
        'imageUrl':
            "https://firebasestorage.googleapis.com/v0/b/kealthy-90c55.appspot.com/o/feedback%2Fa-minimalistic-design-for-a-healthy-food_38vJ50AsTdOxv4Z5Wt32LA_8cxtpxqbSYaVP_s8Ygh7bQ.jpeg?alt=media&token=03691f32-6713-44cb-8cb4-edf94ebf645a",
        'order_id': orderId,
        'payload': "review_screen",
        'phoneNumber': phoneNumber,
        'product_names': productNames,
        'timestamp': DateTime.now().toUtc(),
        'title': "Share Your Thoughts!",
      };

      await FirebaseFirestore.instance
          .collection('Notifications')
          .add(notificationData);
      print("✅ Notification data saved successfully!");
    } catch (e) {
      print("❌ Error saving notification data: $e");
    }
  }

  /// Helper: Generate a unique-ish Order ID
  static String _generateOrderId() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    int randomNum = Random().nextInt(900000) + 100000;
    return '$randomNum$timestamp';
  }
}
