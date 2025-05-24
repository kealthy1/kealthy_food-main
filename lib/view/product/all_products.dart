import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_container.dart';
import 'package:kealthy_food/view/product/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kealthy_food/view/product/product_page.dart';

// Provider for toggling cart container visibility.
final cartVisibilityProvider = StateProvider<bool>((ref) => true);
// Provider for the selected type, scoped by subcategoryName.
final selectedTypeProvider =
    StateProvider.family<String?, String>((ref, subcategory) => null);

// Provider for the search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider to fetch distinct product types based on subcategory.
final productTypesProvider = FutureProvider.family<List<String>, String>(
  (ref, subcategory) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Products')
        .where('Subcategory', isEqualTo: subcategory)
        .get();

    final types = snapshot.docs
        .map((doc) => doc.data()['Type'] as String?)
        .where((type) => type != null)
        .cast<String>()
        .toSet()
        .toList();

    return types;
  },
);

final allProductsProvider = FutureProvider.family<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>(
  (ref, subcategory) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Products')
        .where('Subcategory', isEqualTo: subcategory)
        .get();
    return snapshot.docs;
  },
);

// Provider to manage loading state during search.
final isLoadingProvider = StateProvider<bool>((ref) => false);

class AllProductsPage extends ConsumerStatefulWidget {
  final String subcategoryName;

  const AllProductsPage({super.key, required this.subcategoryName});

  @override
  _AllProductsPageState createState() => _AllProductsPageState();
}

class _AllProductsPageState extends ConsumerState<AllProductsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Reset the search query only when the page first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ref = this.ref;
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
    final isLoading = ref.watch(isLoadingProvider);
    final allProducts = ref.watch(allProductsProvider(widget.subcategoryName));
    // final productTypes =
    //     ref.watch(productTypesProvider(widget.subcategoryName));
    final selectedType =
        ref.watch(selectedTypeProvider(widget.subcategoryName));

    // Reset the search query when the page is rebuilt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only reset if not triggered by a search
      if (searchQuery.isNotEmpty) return;
      ref.read(searchQueryProvider.notifier).state = ""; // Reset search query
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            iconSize: 30,
            onPressed: () {
              ref.read(searchQueryProvider.notifier).state = '';
              Navigator.pop(context);
            },
            icon: const Icon(CupertinoIcons.back)),
        surfaceTintColor: Colors.white,
        title: Text(
          widget.subcategoryName,
          style: GoogleFonts.poppins(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search Bar with Loading Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        ref.read(isLoadingProvider.notifier).state = true;
                        ref.read(searchQueryProvider.notifier).state = value;
                        Future.delayed(const Duration(milliseconds: 500), () {
                          ref.read(isLoadingProvider.notifier).state = false;
                        });
                      },
                      decoration: InputDecoration(
                        constraints: const BoxConstraints(maxHeight: 40.0),
                        hintText: 'Search for products',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: const Icon(CupertinoIcons.search,
                            color: Colors.green),
                        suffixIcon: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(
                                    10.0), // Adjust padding to position the spinner
                                child: SizedBox(
                                    width: 6,
                                    height: 6,
                                    child: CupertinoActivityIndicator(
                                        color:
                                            Color.fromARGB(255, 65, 88, 108))),
                              )
                            : null, // Show nothing if not searching
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: allProducts.when(
              loading: () => const Center(
                  child: CupertinoActivityIndicator(
                      color: Color.fromARGB(255, 65, 88, 108))),
              error: (error, stack) => Center(
                child: Text(
                  "Error: $error",
                  style: GoogleFonts.poppins(),
                ),
              ),
              data: (products) {
                // Filter products based on search query and selected type
                final filteredProducts = products.where((product) {
                  final data = product.data();
                  final productName =
                      data['Name']?.toString().toLowerCase() ?? '';

                  return (searchQuery.isEmpty ||
                          productName.contains(searchQuery)) &&
                      (selectedType == null || data['Type'] == selectedType);
                }).toList();
                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_circle,
                            size: 50, color: Colors.black),
                        const SizedBox(height: 10),
                        Text("No products available",
                            style: GoogleFonts.poppins()),
                      ],
                    ),
                  );
                }

                // Pre-cache first image of each product
                for (final product in filteredProducts) {
                  final data = product.data();
                  final imageUrls = data['ImageUrl'] ?? [];
                  if (imageUrls.isNotEmpty && imageUrls[0] is String) {
                    precacheImage(
                        CachedNetworkImageProvider(imageUrls[0]), context);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filteredProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 columns
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder: (context, index) {
                      final data = filteredProducts[index].data();
                      final productqty = data['Qty'] ?? '0';
                      final productNameRaw = data['Name'] ?? 'No Name';
                      final price = data['Price'] ?? '0';
                      final imageUrls = data['ImageUrl'] ?? [];
                      final firstImageUrl = imageUrls.isNotEmpty
                          ? imageUrls[0]
                          : 'https://via.placeholder.com/150';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductPage(
                                  productId: filteredProducts[index].id),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Product Image.
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: firstImageUrl,
                                        fit: BoxFit.cover,
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
                                  // Product Info.
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IntrinsicHeight(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height:
                                                50, // enough to fit two lines of text
                                            child: Text(
                                              productNameRaw,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                textStyle: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 18,
                                            child: Consumer(
                                              builder: (context, ref, child) {
                                                final averageStarsAsync = ref
                                                    .watch(averageStarsProvider(
                                                        productNameRaw));

                                                return averageStarsAsync.when(
                                                  data: (rating) {
                                                    if (rating == 0.0) {
                                                      return const SizedBox(); // Hide stars if rating is 0
                                                    }

                                                    int fullStars = rating
                                                        .floor(); // Get integer part (e.g., 3 from 3.8)
                                                    bool hasHalfStar = rating -
                                                            fullStars >=
                                                        0.5; // Check if it needs a half-star

                                                    return Row(
                                                      children: [
                                                        Text(
                                                          rating
                                                              .toStringAsFixed(
                                                                  1),
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ),

                                                        // Generate full stars
                                                        ...List.generate(
                                                          fullStars,
                                                          (index) => const Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.orange,
                                                              size: 16),
                                                        ),

                                                        // Show half-star if needed
                                                        if (hasHalfStar)
                                                          const Icon(
                                                              Icons.star_half,
                                                              color:
                                                                  Colors.orange,
                                                              size: 20),

                                                        // Show empty stars to keep alignment
                                                        ...List.generate(
                                                          5 -
                                                              fullStars -
                                                              (hasHalfStar
                                                                  ? 1
                                                                  : 0),
                                                          (index) => const Icon(
                                                              Icons.star_border,
                                                              color:
                                                                  Colors.orange,
                                                              size: 20),
                                                        ),

                                                        // Show the numeric rating next to stars
                                                      ],
                                                    );
                                                  },
                                                  loading: () => Container(),
                                                  error: (error, _) =>
                                                      const Text('N/A'),
                                                );
                                              },
                                            ),
                                          ),
                                          SizedBox(
                                            height: 8,
                                          ),  
                                          const Spacer(),
                                          Row(
                                            children: [
                                              Text(
                                                '\u20B9$price/-',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.green.shade800,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(productqty,
                                                  maxLines: 2,
                                                  style: GoogleFonts.poppins(
                                                    textStyle: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  )),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if ((data['SOH'] ?? 1) <= 4)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(10),
                                  ),
                                  child: Container(
                                    height: 46,
                                    width: 38,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 201, 82, 74),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: (data['SOH'] ?? 1) == 0
                                          ? [
                                              Text('OUT',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 6,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text('OF',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 7,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text('STOCK',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 6,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ]
                                          : [
                                              Text('ONLY',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 6,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text('${data['SOH']}',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 7,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text('LEFT',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 6,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
      bottomSheet: const CartContainer(),
    );
  }
}
