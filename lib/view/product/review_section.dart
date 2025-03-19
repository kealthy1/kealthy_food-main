import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/product/review_model.dart';
import 'package:http/http.dart' as http;

final reviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, productName) async {
  final url = 'https://api-jfnhkjk4nq-uc.a.run.app/rate/$productName';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    // 1) Parse as a map, not a list
    final data = json.decode(response.body) as Map<String, dynamic>;

    // 2) Extract the "ratings" field, which should be a list/array
    final List<dynamic> ratingList = data['ratings'] ?? [];

    // 3) Convert each item in "ratings" to a ReviewModel
    return ratingList.map((jsonItem) {
      return ReviewModel.fromJson(jsonItem as Map<String, dynamic>);
    }).toList();
  } else {
    throw Exception('Failed to fetch reviews for $productName');
  }
});
// ignore: unused_element
class ReviewsSection extends ConsumerWidget {
  final String productName;
  const ReviewsSection({super.key, required this.productName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider(productName));

    return reviewsAsync.when(
  // Instead of a spinner, you can return SizedBox.shrink() if you want no UI during loading
  loading: () => const SizedBox.shrink(),

  // If there's an error from the API, just return an empty widget (no text shown)
  error: (err, stack) {
    debugPrint("Error loading reviews: $err"); // Or remove if you don’t want to log
    return const SizedBox.shrink();
  },

  // If data is successfully fetched:
  data: (reviews) {
    // If there are no reviews, show nothing
    if (reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    // Otherwise, show the “Ratings & Reviews” header and the list of reviews
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ratings & Reviews",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
            // Render each review
            ...reviews.map((review) => _ReviewTile(review: review)),
          ],
        );
      },
    );
  }
}


class _ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    // For star icons
    Widget buildStars(int starCount) {
      return Row(
        children: List.generate(5, (index) {
          return Icon(
            index < starCount ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 16,
          );
        }),
      );
    }

    return Column(
      children: [
        const Divider(), // a horizontal line above each review
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle avatar with the first letter of the customer's name
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                review.customerName.isNotEmpty
                    ? review.customerName[0].toUpperCase()
                    : "U",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            // Name and stars side by side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Name
                  Text(
                    review.customerName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Star row
                  buildStars(review.starCount),
                  const SizedBox(height: 6),
                  // Feedback
                  Text(
                    review.feedback,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}