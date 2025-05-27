import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

final offersNotificationProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final prefs = await SharedPreferences.getInstance();
  final phone = prefs.getString('phoneNumber');

  if (phone == null || phone.isEmpty) {
    yield [];
    return;
  }

  final database = FirebaseFirestore.instance;
  yield* database
      .collection('Notifications')
      .where('phoneNumber', isEqualTo: phone)
      .where('type', isEqualTo: 'offer')
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
          return const Center(child: Text("No Offers Available"));
        }

        return ListView.builder(
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return ListTile(
              leading: const Icon(Icons.local_offer, color: Colors.green),
              title: Text(
                offer['title'] ?? 'Offer',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                offer['body'] ?? '',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('Notifications')
                      .doc(offer['id'])
                      .delete();
                  ref.invalidate(offersNotificationProvider);
                },
              ),
            );
          },
        );
      },
    );
  }
}