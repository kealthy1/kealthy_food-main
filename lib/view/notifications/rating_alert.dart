import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kealthy_food/view/notifications/notification_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ StateNotifierProvider to track whether alert has been shown
final hasShownReviewAlertProvider =
    StateNotifierProvider<HasShownReviewNotifier, bool>((ref) {
  return HasShownReviewNotifier();
});

class HasShownReviewNotifier extends StateNotifier<bool> {
  HasShownReviewNotifier() : super(false) {
    _loadHasShownStatus();
  }

  Future<void> _loadHasShownStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool storedValue = prefs.getBool('hasShownReviewAlert') ?? false;
    state = storedValue;
    print("📌 Has shown review alert: $state");
  }

  Future<void> setHasShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasShownReviewAlert', true);
    state = true;
  }

  // Optional: If you want to allow resetting this (for new orders),
  // add a method like:
  // Future<void> resetAlert() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('hasShownReviewAlert');
  //   state = false;
  // }
}

class ReviewAlert extends ConsumerWidget {
  const ReviewAlert({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Watch notifications
    final notificationsAsync = ref.watch(notificationProvider);

    // 2) Watch whether the alert has already been shown
    final hasShownAlert = ref.watch(hasShownReviewAlertProvider);

    // 🔒 If we've already shown the alert, do nothing.
    if (hasShownAlert) return const SizedBox.shrink();

    return notificationsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) {
        debugPrint("⚠️ Error fetching notifications: $err");
        return const SizedBox.shrink();
      },
      data: (notifications) {
        if (notifications.isEmpty) return const SizedBox.shrink();
        final delivered = notifications.where((notif) {
          final orderId = notif['order_id'] ?? '';
          final orderExistsAsync = ref.watch(orderExistsProvider(orderId));
          return orderExistsAsync.when(
            data: (exists) => !exists,
            loading: () => false,
            error: (_, __) => false,
          );
        }).toList();

        if (delivered.isEmpty) {
          return const SizedBox.shrink();
        }

        // 4) Sort by 'timestamp' descending so the newest notification is first
        //    Ensure your 'timestamp' is a valid DateTime or Timestamp field.
        delivered.sort((a, b) {
          final aTime = a['timestamp']?.toDate() ?? DateTime(1970);
          final bTime = b['timestamp']?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime); // Descending
        });

        // 5) Take the newest delivered notification
        final newestNotification = delivered.first;

        // 6) Show the review dialog AFTER build finishes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Double-check we haven't set hasShownAlert in the meantime
          if (!ref.read(hasShownReviewAlertProvider)) {
            _showReviewDialog(context, ref, newestNotification);
            ref.read(hasShownReviewAlertProvider.notifier).setHasShown();
          }
        });

        return const SizedBox.shrink();
      },
    );
  }

  static void _showReviewDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> notification,
  ) {
    final productNames = notification['product_names'] as List<dynamic>? ?? [];
    final orderId = notification['order_id'] ?? '';

    // Guard: If productNames or orderId are missing
    if (productNames.isEmpty || orderId.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            "Love It or Leave It?",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF273847),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final productImageAsync =
                      ref.watch(productImageProvider(productNames.first));
                  return productImageAsync.when(
                    data: (imageUrl) {
                      if (imageUrl == null || imageUrl.isEmpty) {
                        return const Icon(Icons.image, size: 80);
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image_not_supported, size: 80),
                        ),
                      );
                    },
                    loading: () => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                      ),
                    ),
                    error: (error, stack) => const Icon(Icons.error),
                  );
                },
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Tell us what you think about your recent purchase by leaving a star rating ⭐",
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close the dialog
              },
              child: Text(
                "Not Now",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: const Color(0xFF273847),
              ),
              onPressed: () {
                Navigator.pop(dialogContext); // Close the dialog first
                // Then open NotificationsScreen
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              child: Text(
                "Rate Now",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}