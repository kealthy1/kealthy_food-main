import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kealthy_food/custom_alert_dialogue.dart';
import 'package:kealthy_food/view/Login/login_page.dart';
import 'package:kealthy_food/view/blog/blog1.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define the LikesState with likesCount and isLiked
class LikesState {
  final int likesCount;
  final bool isLiked;

  LikesState({required this.likesCount, required this.isLiked});
}

// Define the StateNotifierProvider.family for each blog's likes
final blogLikesProvider =
    StateNotifierProvider.family<BlogLikesNotifier, LikesState, String>(
        (ref, blogId) {
  return BlogLikesNotifier(blogId);
});

// BlogLikesNotifier manages the like state for a specific blog
class BlogLikesNotifier extends StateNotifier<LikesState> {
  final String blogId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BlogLikesNotifier(this.blogId)
      : super(LikesState(likesCount: 0, isLiked: false)) {
    _init();
  }

  // Initialize by fetching the phone number and likes data
  Future<void> _init() async {
    await _fetchLikesFromFirestore();
  }

  // Initialize by fetching the phone number and likes data
  // Fetch likes and likedBy from Firestore

  // Retrieve the user's phone number from SharedPreferences
  Future<String?> _getPhoneNumberFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phoneNumber');
  }

  // Fetch likes and likedBy from Firestore
  Future<void> _fetchLikesFromFirestore() async {
    try {
      final doc = await _firestore.collection('blogs').doc(blogId).get();
      if (!doc.exists) {
        state = LikesState(likesCount: 0, isLiked: false);
        return;
      }

      final data = doc.data()!;
      final likes = data['likes'] ?? 0;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final userPhoneNumber = await _getPhoneNumberFromSharedPrefs();
      final isLiked =
          userPhoneNumber != null && likedBy.contains(userPhoneNumber);

      state = LikesState(likesCount: likes, isLiked: isLiked);
    } catch (e) {
      print("Error fetching likes: $e");
      state = LikesState(likesCount: 0, isLiked: false);
    }
  }

  // Toggle like status using Firestore transactions
  // Toggle like status using Firestore transactions
// Toggle like status using Firestore transactions
  Future<void> toggleLikeAsync() async {
    final userPhoneNumber = await _getPhoneNumberFromSharedPrefs();

    if (userPhoneNumber == null || userPhoneNumber.isEmpty) {
      throw Exception("User phone number not found");
    }

    final blogRef = _firestore.collection('blogs').doc(blogId);

    try {
      // Get the current state
      final bool previousLikedState = state.isLiked;
      final int previousLikesCount = state.likesCount;

      // Determine new state values
      final bool newLikedState = !previousLikedState;
      final int newLikesCount =
          newLikedState ? previousLikesCount + 1 : previousLikesCount - 1;

      // ✅ Optimistically update UI before Firestore update
      state = LikesState(likesCount: newLikesCount, isLiked: newLikedState);

      // Perform Firestore update in the background
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(blogRef);

        if (!docSnapshot.exists) {
          // If the blog doesn't exist, initialize it with 1 like
          transaction.set(blogRef, {
            'likes': 1,
            'likedBy': [userPhoneNumber],
            'title': '',
            'imageUrls': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
          return;
        }

        final data = docSnapshot.data()!;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final bool isCurrentlyLiked = likedBy.contains(userPhoneNumber);

        if (isCurrentlyLiked) {
          // Unlike the blog
          likedBy.remove(userPhoneNumber);
          transaction.update(blogRef, {
            'likedBy': likedBy,
            'likes': FieldValue.increment(-1), // Decrease count by 1
          });
        } else {
          // Like the blog
          likedBy.add(userPhoneNumber);
          transaction.update(blogRef, {
            'likedBy': likedBy,
            'likes': FieldValue.increment(1), // Increase count by 1
          });
        }
      });
    } catch (e) {
      print("Error toggling like: $e");

      // ✅ If Firestore update fails, rollback UI change
      state = LikesState(
        likesCount: state.likesCount, // Revert to previous count
        isLiked: state.isLiked, // Revert to previous liked state
      );
    }
  }

  // Format likes count for display (e.g., 1k, 1M)
  String formatLikesCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return '$count';
    }
  }
}

class BlogListTile extends ConsumerWidget {
  final Blog blog;
  final VoidCallback onTap;

  const BlogListTile({super.key, required this.blog, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesState = ref.watch(blogLikesProvider(blog.id));
    final blogNotifier = ref.read(blogLikesProvider(blog.id).notifier);

    // Assuming 'createdAt' is a Timestamp, convert to DateTime
    // ignore: unnecessary_null_comparison
    final dateFormatted = blog.createdAt != null
        ? DateFormat('d MMM').format(blog.createdAt)
        : 'Unknown date';
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: blog.imageUrls.isNotEmpty
                        ? blog.imageUrls[0]
                        : 'https://via.placeholder.com/150',
                    width: screenWidth * 0.35,
                    height: screenWidth * 0.25,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      dateFormatted,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.hand_thumbsup_fill,
                          color: likesState.isLiked
                              ? const Color(0xFF273847) // Liked color
                              : Colors.grey, // Default color
                        ),
                        onPressed: () async {
                          try {
                            await blogNotifier.toggleLikeAsync();
                          } catch (e) {
                            if (e
                                .toString()
                                .contains("User phone number not found")) {
                              CustomAlertDialog.show(
                                context: context,
                                title: "Login Required",
                                message:
                                    "You need to log in to like this blog and save your preferences.",
                                confirmText: "Login",
                                onConfirm: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginFields()),
                                    (route) =>
                                        false, // Remove all previous routes
                                  );
                                },
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('An error occurred: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      if (likesState.likesCount > 0)
                        Text(
                          '${blogNotifier.formatLikesCount(likesState.likesCount)} Likes',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
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

}