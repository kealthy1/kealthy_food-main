//

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/notifications/Rating.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to fetch notifications for the logged-in user
final notificationProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final prefs = await SharedPreferences.getInstance();
  final String? phoneNumber = prefs.getString('phoneNumber');

  if (phoneNumber == null || phoneNumber.isEmpty) {
    yield []; // Return empty list if phone number is not found
    return;
  }

  final database = FirebaseFirestore.instance;
  yield* database
      .collection('Notifications')
      .where('phoneNumber', isEqualTo: phoneNumber) // ✅ Filter by phone number
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});
// Provider to fetch product images for each product name
final productImageProvider = FutureProvider.family
    .autoDispose<String?, String>((ref, productName) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('Products')
      .where('Name', isEqualTo: productName)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    final productData = querySnapshot.docs.first.data();
    final imageUrls = productData['ImageUrl'] as List<dynamic>?;

    return imageUrls?.isNotEmpty == true ? imageUrls?.first : null;
  }
  return null;
});

// Provider to fetch live order status from Firebase Realtime Database
final orderExistsProvider = StreamProvider.family<bool, String>((ref, orderId) {
  const databaseURL = 'https://kealthy-90c55-dd236.firebaseio.com/';
  final orderRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseURL,
  ).ref('orders/$orderId');

  return orderRef.onValue.map((event) {
    return event.snapshot.exists; // ✅ Returns true if order exists, false otherwise
  });
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text("Notifications"),
      ),
      body: notificationsAsync.when(
        loading: () => Center(
          child: LoadingAnimationWidget.inkDrop(
            size: 50,
            color: const Color.fromARGB(255, 65, 88, 108),
          ),
        ), 
        error: (error, stackTrace) {
          print("Error fetching notifications: $error");
          return _buildNoNotifications();
        },
        data: (notifications) {
          if (notifications.isEmpty) return _buildNoNotifications();

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final orderId = notification['order_id'] ?? '';

              if (orderId.isEmpty) return Container();

              return Consumer(
                builder: (context, ref, child) {
                  final orderExistsAsync = ref.watch(orderExistsProvider(orderId));

                  return orderExistsAsync.when(
                    data: (exists) {
                      if (exists) return Container(); // Skip if order exists
                      return _buildNotificationTile(notification, context, ref);
                    },
                    loading: () => _buildLoadingNotificationTile(),
                    error: (_, __) => _buildLoadingNotificationTile(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

   Widget _buildLoadingNotificationTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Row(
        children: [
          _buildLoadingImage(),
          const SizedBox(width: 12),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 50,
                color: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

  /// **No Notifications UI**
  Widget _buildNoNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.bell_slash,
            size: 50,
            color: Color(0xFF273847),
          ),
          const SizedBox(height: 10),
          Text(
            'No Notifications',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF273847),
            ),
          ),
        ],
      ),
    );
  }

  /// **Notification Tile**
  Widget _buildNotificationTile(
      Map<String, dynamic> notification, BuildContext context, WidgetRef ref) {
    final List<dynamic> productNames = notification['product_names'] ?? [];
    final String orderId = notification['order_id'] ?? '';

    if (productNames.isEmpty || orderId.isEmpty) return Container();

    final orderExistsAsync = ref.watch(orderExistsProvider(orderId));

    return orderExistsAsync.when(
      data: (exists) {
        if (exists) return Container();

        return GestureDetector(
          onTap: () async {
            List<String?> productImages = await Future.wait(
              productNames.map((productName) => fetchProductImage(productName)),
            );

            List<String> validProductImages =
                productImages.map((e) => e ?? "").toList();

            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => RatingPage(
                  productNames: productNames.cast<String>(),
                  orderId: orderId,
                  productImages: validProductImages,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final productImageAsync =
                        ref.watch(productImageProvider(productNames.first));
                    return productImageAsync.when(
                      data: (imageUrl) => _buildImage(imageUrl),
                      loading: () => _buildLoadingImage(),
                      error: (_, __) =>
                          const Icon(Icons.image, size: 60, color: Colors.grey),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildNotificationDetails(notification),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.grey, size: 20),
                  onPressed: () =>
                      _confirmDelete(ref, context, notification['id']),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(),
      error: (_, __) => Container(),
    );
  }

  /// **Image Widget with Placeholder**
  Widget _buildImage(String? imageUrl) {
    return imageUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 80,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildLoadingImage(),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          )
        : const Icon(Icons.image, size: 60, color: Colors.grey);
  }

  /// **Shimmer Effect for Image Loading**
  Widget _buildLoadingImage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildNotificationDetails(Map<String, dynamic> notification) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['title'] ?? "No Title",
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              notification['body'] ?? "No Message",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) => const Icon(Icons.star_border,
                    color: Colors.amber, size: 20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Rate This Product Now",
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  /// **Confirm Delete Notification**
  void _confirmDelete(WidgetRef ref, BuildContext context, String id) async {
    bool confirmed = await _showConfirmationDialog(
      context,
      "Delete Notification",
      "Are you sure you want to delete this notification?",
    );

    if (confirmed) {
      await FirebaseFirestore.instance
          .collection('Notifications')
          .doc(id)
          .delete();
      ref.invalidate(notificationProvider);
    }
  }

  /// Show Confirmation Dialog
  Future<bool> _showConfirmationDialog(
      BuildContext context, String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Text(content, style: GoogleFonts.poppins(fontSize: 14)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel",
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.black))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("OK",
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.black))),
            ],
          ),
        ) ??
        false;
  }

  /// **Fetch Product Image**
  Future<String?> fetchProductImage(String productName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Products')
        .where('Name', isEqualTo: productName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final productData = querySnapshot.docs.first.data();
      final imageUrls = productData['ImageUrl'] as List<dynamic>?;
      return imageUrls?.isNotEmpty == true ? imageUrls!.first : null;
    }
    return null;
  }

