import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kealthy_food/view/product/all_products.dart';

class SubCategoryPage extends StatefulWidget {
  final String categoryName; // e.g., "Personal Care"

  const SubCategoryPage({required this.categoryName, super.key});

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: Text(
          widget.categoryName, // Displays "Personal Care" (the parent category)

          style: GoogleFonts.poppins(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // Instead of filtering by 'Subcategory', we filter by 'Category'
          // to get all documents whose 'Category' field = widget.categoryName
          stream: FirebaseFirestore.instance
              .collection('SubCategory')
              .where('Category', isEqualTo: widget.categoryName)
              .snapshots(),
          builder: (context, snapshot) {
            // 1. Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CupertinoActivityIndicator(
                                  color:Color.fromARGB(255, 65, 88, 108)));
            }
            // 2. Handle empty data
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text(
                "No subcategories available",
                style: GoogleFonts.poppins(),
              ));
            }

            // 3. We have data
            final subcategories = snapshot.data!.docs;

            return ListView.builder(
              itemCount: subcategories.length,
              itemBuilder: (context, index) {
                final subcategoryDoc = subcategories[index];
                final subcategoryName =
                    subcategoryDoc['Subcategory'] ?? 'No Subcategory Name';
                final imageUrl = subcategoryDoc['ImageUrl'] ?? '';
                final title = subcategoryDoc['Title'] ?? 'No Title';

                return GestureDetector(
                  onTap: () {
                    // On tap, navigate to the products list
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => AllProductsPage(
                          subcategoryName: subcategoryName,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3,vertical: 5),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error,
                                          color: Colors.red),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Subcategory details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // The Subcategory name
                                Text(
                                  subcategoryName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                                // Optional subtitle or description
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black45,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.black,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
