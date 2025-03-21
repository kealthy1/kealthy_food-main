import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _AllProductsPageState extends ConsumerState<AllProductsPage> {
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
    final ref = this.ref;
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
    final isLoading = ref.watch(isLoadingProvider);
    final allProducts = ref.watch(allProductsProvider(widget.subcategoryName));
    final productTypes =
        ref.watch(productTypesProvider(widget.subcategoryName));
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
                                  color:Color.fromARGB(255, 65, 88, 108))
                                ),
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
          // Product Types List
          productTypes.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => Center(
              child: Text(
                "Error: $error",
                style: GoogleFonts.poppins(),
              ),
            ),
            data: (types) {
              return SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: types.length,
                  itemBuilder: (context, index) {
                    final type = types[index];
                    final isSelected = (type == selectedType);

                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          // Deselect the type if it's already selected
                          ref
                              .read(selectedTypeProvider(widget.subcategoryName)
                                  .notifier)
                              .state = null;
                        } else {
                          // Select the new type
                          ref
                              .read(selectedTypeProvider(widget.subcategoryName)
                                  .notifier)
                              .state = type;
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color.fromARGB(255, 65, 88, 108)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(
                                    color:
                                        const Color.fromARGB(255, 65, 88, 108),
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              type,
                              style: GoogleFonts.poppins(
                                color:
                                    isSelected ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.bold
                                ,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Grid of Products
          Expanded(
            child: allProducts.when(
              loading: () => const Center(
                child: CupertinoActivityIndicator(
                                  color:Color.fromARGB(255, 65, 88, 108))
              ),
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
                    child: Text("No products available",
                        style: GoogleFonts.poppins()),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
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
                      final productName = data['Name'] ?? 'No Name';
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
                        child: Container(
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(productName,
                                        style: GoogleFonts.poppins(
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                                    const SizedBox(height: 4),
                                    Text('\u20B9 $price/-',
                                        style: GoogleFonts.poppins(
                                          textStyle: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
