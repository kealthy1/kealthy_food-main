import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/notifications/notification_page.dart';
import 'package:shimmer/shimmer.dart';

final offersNotificationProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final database = FirebaseFirestore.instance;

  yield* database
      .collection('offers')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

class OffersNotificationPage extends ConsumerWidget {
  const OffersNotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersNotificationProvider);

    return offersAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => const Center(child: Text("Error loading offers")),
      data: (offers) {
        if (offers.isEmpty) {
          return buildNoNotifications();
        }

        return ListView.builder(
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            final imageUrl = offer['ImageUrl'] as String?;

            return GestureDetector(
              onTap: () {
                final route = offer['route'] as String?;
                if (route != null && route.isNotEmpty) {
                  if (route == "pop") {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamed(context, route);
                  }
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer['title'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              offer['body'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12.8,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            // const SizedBox(height: 8),
                            // ElevatedButton.icon(
                            //   onPressed: () {
                            //     // handle navigation or offer click
                            //   },
                            //   icon: const Icon(CupertinoIcons.bag,color: Colors.black,
                            //       size: 16),
                            //   style: ElevatedButton.styleFrom(
                            //     elevation: 1,
                            //     foregroundColor: Colors.white,
                            //     shape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(10),
                            //     ),
                            //     padding: const EdgeInsets.symmetric(
                            //       vertical: 10,
                            //       horizontal: 20,
                            //     ),
                            //   ),
                            //   label: const Text(
                            //     'Shop Now',
                            //     style: TextStyle(fontSize: 13,color: Colors.black),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
