import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/product/subcategories.dart';
import 'package:shimmer/shimmer.dart';

class HomeCategory extends ConsumerWidget {
  const HomeCategory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
  future: firestore.collection('categories')
      .orderBy('Categories') // 👈 Sort alphabetically
      .get(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final categories = snapshot.data?.docs.map((doc) {
        return {
          'Categories': doc.data()['Categories'],
          'image': doc.data()['imageurl'],
        };
      }).toList();

          return Center(
            child: Column(
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: categories?.map((category) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => SubCategoryPage(
                                  categoryName: category['Categories'],
                                ),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: (MediaQuery.of(context).size.width - 48) / 3,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF4F4F5),
                                    ),
                                    // Set your desired background color here
                                    child: CachedNetworkImage(
                                      imageUrl: category['image'] as String,
                                      width: double.infinity,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(color: Colors.white),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category['Categories'] as String,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList() ??
                      [],
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
