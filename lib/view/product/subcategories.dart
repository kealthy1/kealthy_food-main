import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kealthy_food/view/product/all_products.dart';
import 'package:kealthy_food/view/Cart/cart_container.dart';

class SubCategoryPage extends StatefulWidget {
  final String categoryName; // e.g., "Personal Care"

  const SubCategoryPage({required this.categoryName, super.key});

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  @override
  Widget build(BuildContext context) {
    // ignore: sized_box_for_whitespace
    return Stack(
      children: [
        Scaffold(
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
              stream: FirebaseFirestore.instance
                  .collection('SubCategory')
                  .where('Category', isEqualTo: widget.categoryName)
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CupertinoActivityIndicator(
                          color: Color.fromARGB(255, 65, 88, 108)));
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

                // Preload images
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  for (var doc in subcategories) {
                    final url = doc['ImageUrl'] ?? '';
                    if (url.isNotEmpty) {
                      precacheImage(CachedNetworkImageProvider(url), context);
                    }
                  }
                });

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
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
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.white,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subcategoryName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        color: Colors.black45,
                                        fontSize: 13  ,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
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
          
          bottomSheet: const CartContainer(),
        ),
        // ignore: prefer_const_constructors
       
      ],
    );
  }
}
