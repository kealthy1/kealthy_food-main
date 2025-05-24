import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kealthy_food/view/product/add_to_cart.dart';
import 'package:kealthy_food/view/product/fullscreen.dart';
import 'package:kealthy_food/view/product/info_card.dart';
import 'package:kealthy_food/view/product/product_page.dart';
import 'package:kealthy_food/view/product/provider.dart';
import 'package:kealthy_food/view/product/review_section.dart';
import 'package:kealthy_food/view/product/text.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductContent extends ConsumerWidget {
  final PageController pageController;

  final Map<String, dynamic> docData;
  final String productId;

  const ProductContent({
    super.key,
    required this.docData,
    required this.pageController,
    required this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse Firestore fields.
    final productName = docData['Name'] ?? 'No Name';
    final productBrand = docData['Brand Name'] ?? 'No Name';
    final productQty = docData['Qty'] ?? '';
    final baseProductName = productName.replaceAll(productQty, '').trim();
    final productPrice = (docData['Price'] is int || docData['Price'] is double)
        ? docData['Price']
        : int.tryParse(docData['Price']?.toString() ?? '0') ?? 0;

    // final rawScore = docData['Kealthy Score'] ?? '100';
    // final kealthyScore = int.tryParse(rawScore) ?? 100;

    final productWhatIs = docData['What is it?'] ?? '';
    final productUseFor = docData['What is it used for?'] ?? '';
    final productEAN = docData['EAN'] ?? '';
    final productImageUrl =
        (docData['ImageUrl'] is List<dynamic> && (docData['ImageUrl'] as List).isNotEmpty)
            ? docData['ImageUrl'][0]
            : '';
    // final productSource = docData['Imported&Marketed By'] ?? '';
    final productOrigin = docData['Orgin'] ?? '';
    final productBestBefore = docData['Best Before'] ?? '';
    final productSoh = (docData['SOH'] is int)
        ? docData['SOH']
        : int.tryParse(docData['SOH'].toString().split('.')[0]) ?? 0;
    final bool needsFormatting = docData['needFormatting'] ?? false;

    String formattedDate = productBestBefore; // default: raw text

    if (needsFormatting && productBestBefore.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(productBestBefore);
        // e.g. "dd-MM-yyyy" or "dd MMM yyyy" or whichever you prefer
        formattedDate = DateFormat('dd-MM-yyyy').format(parsedDate);
      } catch (e) {
        // Fallback if parse fails or data is invalid
        formattedDate = productBestBefore; // or "Invalid Date"
      }
    }

    // Macro fields.
    final protein = docData['Protein (g)'] ?? 'Not Applicable';
    final totalFat = docData['Total Fat (g)'] ?? 'Not Applicable';
    final carbs = docData['Total Carbohydrates (g)'] ?? 'Not Applicable';
    final sugars = docData['Sugars (g)'] ?? 'Not Applicable';
    final cholesterol = docData['Cholesterol (mg)'] ?? 'Not Applicable';
    final addedSugars = docData['Added Sugars (g)'] ?? 'Not Applicable';
    final Map<String, String> macrosMap = {
      'Protein (g)': protein,
      'Total Fat (g)': totalFat,
      'Carbs (g)': carbs,
      'Sugars (g)': sugars,
      'Cholesterol (mg)': cholesterol,
      'Added Sugars (g)': addedSugars,
    };
    final sodium = docData['Sodium (mg)'] ?? 'Not Applicable';
    final iron = docData['Iron (mg)'] ?? 'Not Applicable';
    final calcium = docData['Calcium (mg)'] ?? 'Not Applicable';
    final copper = docData['Copper (mg)'] ?? 'Not Applicable';
    final magnesium = docData['Magnesium (mg)'] ?? 'Not Applicable';
    final phosphorus = docData['Phosphorus (mg)'] ?? 'Not Applicable';
    final pottassium = docData['Potassium (mg)'] ?? 'Not Applicable';
    final zinc = docData['Zinc (mg)'] ?? 'Not Applicable';
    final manganese = docData['Manganese (mg)'] ?? 'Not Applicable';
    final selenium = docData['Selenium (mcg)'] ?? 'Not Applicable';

    final Map<String, String> microsMap = {
      'Sodium (mg)': sodium,
      'Iron (mg)': iron,
      'Calcium (mg)': calcium,
      'Copper (mg)': copper,
      'Magnesium (mg)': magnesium,
      'Phosphorus (mg)': phosphorus,
      'Potassium (mg)': pottassium,
      'Zinc (mg)': zinc,
      'Manganese (mg)': manganese,
      'Selenium (mcg)': selenium,
    };
    final List<dynamic> productFSSAI = docData['FSSAI'] ?? [];
    final fssiList = productFSSAI.map((e) => e.toString()).toList();

    final List<dynamic> rawIngredients = docData['Ingredients'] ?? [];
    final ingredientsList = rawIngredients.map((e) => e.toString()).toList();

    // Image URLs.
    final List<dynamic> rawImageUrls = docData['ImageUrl'] ?? [];
    final imageUrls = rawImageUrls.map((e) => e.toString()).toList();

    final validIngredientsList =
        ingredientsList.where((e) => e != "Not Applicable").toList();
    final filteredMacrosMap = Map.fromEntries(
      macrosMap.entries.where((entry) => entry.value != "Not Applicable"),
    );
    final filteredMicrosMap = Map.fromEntries(
      microsMap.entries.where((entry) => entry.value != "Not Applicable"),
    );
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top images carousel.
          AspectRatio(
            aspectRatio: 10 / 10.5,
            child: Stack(
              alignment: Alignment
                  .bottomCenter, // Align all children to the bottom center
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageZoomPage(
                            imageUrls: imageUrls,
                            initialIndex: index,
                          ),
                        ),
                      ),
                      child: InteractiveViewer(
                        clipBehavior:
                            Clip.none, // Allows zooming without clipping
                        panEnabled: true, // Enables panning
                        minScale: 1.0, // Minimum zoom scale
                        maxScale: 4.0, // Maximum zoom scale
                        child: CachedNetworkImage(
                          imageUrl: imageUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.grey[300]),
                          ),
                          errorWidget: (_, __, ___) => const Icon(Icons.error),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 10.0), // Adjust as needed
                  child: SmoothPageIndicator(
                    controller: pageController,
                    count: imageUrls.length,
                    effect: const ExpandingDotsEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: Color.fromARGB(255, 65, 88, 108),
                      dotColor: Color.fromARGB(255, 120, 142, 162),
                      spacing: 4.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Overlapping details container.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name + Add-to-Cart section.
                Row(
                  children: [
                    /// Wrap the long text with `Expanded` or `Flexible`
                    Expanded(
                      child: Text(
                        productName.contains(productQty) ? productName : '$productName $productQty',
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    // KealthyScoreSection(productIdOrName: productId),
                  ],
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final averageStarsAsync =
                        ref.watch(averageStarsProvider(productName));

                    return averageStarsAsync.when(
                      data: (rating) {
                        if (rating == 0.0) {
                          return const SizedBox(); // Hide stars if rating is 0
                        }

                        int fullStars = rating
                            .floor(); // Get integer part (e.g., 3 from 3.8)
                        bool hasHalfStar = rating - fullStars >=
                            0.5; // Check if it needs a half-star

                        return Row(
                          children: [
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),

                            // Generate full stars
                            ...List.generate(
                              fullStars,
                              (index) => const Icon(Icons.star,
                                  color: Colors.orange, size: 16),
                            ),

                            // Show half-star if needed
                            if (hasHalfStar)
                              const Icon(Icons.star_half,
                                  color: Colors.orange, size: 20),

                            // Show empty stars to keep alignment
                            ...List.generate(
                              5 - fullStars - (hasHalfStar ? 1 : 0),
                              (index) => const Icon(Icons.star_border,
                                  color: Colors.orange, size: 20),
                            ),

                            // Show the numeric rating next to stars
                          ],
                        );
                      },
                      loading: () => Container(),
                      error: (error, _) => const Text('N/A'),
                    );
                  },
                ),

                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Aligns rupee symbol and price at the top
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Baseline(
                              baseline:
                                  17, // Adjust this value for proper alignment
                              baselineType: TextBaseline.alphabetic,
                              child: Text(
                                '\u20B9',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Text(
                              '$productPrice/-', // Product price

                              style: const TextStyle(
                                fontSize: 20, // Larger size for the price
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '(Inclusive of all taxes)', // Product price

                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ), // Add slight spacing between rupee and price

                    const Spacer(),
                    AddToCartSection(
                      productName: productName,
                      productPrice: productPrice,
                      productEAN: productEAN,
                      soh: productSoh,
                      imageurl: productImageUrl,
                      
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Macro / Ingredients / Micros row.

                Row(
                  children: [
                    if (filteredMacrosMap.isNotEmpty)
                      Expanded(
                        child: InfoCard(
                          icon: Icons.energy_savings_leaf,
                          label: 'Macros',
                          names: filteredMacrosMap.keys.toList(),
                          backgroundColor: Colors.blue.shade50,
                          onMorePressed: () {
                            final detailsString = filteredMacrosMap.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join('\n');
                            showDetailsDialog(
                              context: context,
                              label: 'Macros',
                              details: detailsString,
                              backgroundColor: Colors.blue.shade50,
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 5),
                    if (filteredMicrosMap.isNotEmpty)
                      Expanded(
                        child: InfoCard(
                          icon: Icons.grain,
                          label: 'Micros',
                          names: filteredMicrosMap.keys.toList(),
                          backgroundColor: Colors.green.shade50,
                          onMorePressed: () {
                            final detailsString = filteredMicrosMap.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join('\n');
                            showDetailsDialog(
                              context: context,
                              label: 'Micronutrients',
                              details: detailsString,
                              backgroundColor: Colors.green.shade50,
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 5),
                    if (validIngredientsList.isNotEmpty)
                      Expanded(
                        child: InfoCard(
                          icon: Icons.restaurant_menu,
                          label: 'Ingredients',
                          names: validIngredientsList,
                          backgroundColor: Colors.yellow.shade50,
                          onMorePressed: () {
                            final detailsString =
                                validIngredientsList.join('\n');
                            showDetailsDialog(
                              context: context,
                              label: 'Ingredients',
                              details: detailsString,
                              backgroundColor: Colors.yellow.shade50,
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 30),
                // Price + Kealthy Score section.
                const Divider(),
                Row(
                  children: [
                    const ReusableText(
                      text: 'Brand : ',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    ReusableText(text: '$productBrand', fontSize: 16),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('Products')
                          .where('Name', isGreaterThanOrEqualTo: baseProductName)
                          .where('Name', isLessThan: baseProductName + 'z')
                          .where('Qty', isNotEqualTo: productQty)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text(
                            'Error: ${snapshot.error}',
                            style: GoogleFonts.poppins(),
                          ));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox
                              .shrink(); // Return an invisible widget
                        }

                        final relatedProducts = snapshot.data!.docs;

                        return Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20)),
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedProducts.length,
                            itemBuilder: (context, index) {
                              final product = relatedProducts[index].data();
                              final qty = product['Qty'];

                              return GestureDetector(
                                onTap: () {
                                  if (relatedProducts[index].id != productId) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductPage(
                                            productId: relatedProducts[index].id),
                                      ),
                                    );
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (relatedProducts.isNotEmpty)
                                      Text(
                                        'Options :',
                                        style: GoogleFonts.poppins(
                                          textStyle: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 10),

                                    // Replace product image with styled quantity box
                                    Container(
                                      width: 60,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade400),
                                      ),
                                      child: Text(
                                        '$qty',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
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
                  ],
                ),

                // "What is it?" section.
                if (productWhatIs.isNotEmpty) ...[
                  Text(
                    'What is it?',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  ReusableText(text: productWhatIs, fontSize: 14),
                  const SizedBox(height: 20),
                ],
                if (productUseFor.isNotEmpty) ...[
                  Text(
                    'What is it used for?',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  ReusableText(text: productUseFor, fontSize: 14),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      shape: const RoundedRectangleBorder(
                        // No border when expanded
                        borderRadius: BorderRadius.zero,
                        side: BorderSide.none,
                      ),
                      collapsedShape: const RoundedRectangleBorder(
                        // No border when collapsed
                        borderRadius: BorderRadius.zero,
                        side: BorderSide.none,
                      ),
                      tilePadding: EdgeInsets
                          .zero, // Remove default padding// Adjust content padding
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Other Product Info",
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ReusableText(
                              text: 'EAN Code: $productEAN', fontSize: 14),
                          if (fssiList.isNotEmpty)
                            ReusableText(
                                text: 'FSSAI: ${fssiList.join('\n')}',
                                fontSize: 14)
                        ],
                      ),

                      children: [
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: ReusableText(
                            text: 'Sourced & Marketed by: Cotolore Enterprises LLP, 15/293 - C, Muriyankara-Pinarmunda Milma Road, Peringala (PO), Ernakulam, 683565, Kerala, India.',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ReusableText(
                            text: 'Country of Origin: $productOrigin',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ReusableText(
                            text:
                                'Best Within: $formattedDate from the date of packaging',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const ReusableText(
                          text:
                              'Disclaimer: The image(s) shown are representative of the actual product While every effort has been made to maintain accurate and up to date product related content, it is recommended to read product labels, batch and manufacturing/packing details along with warnings and directions before using or consuming a packed product.',
                          fontSize: 14,
                        ),
                        const SizedBox(height: 10),
                        const ReusableText(
                          text:
                              'Customer Service: For Queries/Feedback/Complaints, contact our customer care executive at 8848673425.',
                          fontSize: 14,
                        ),
                        const SizedBox(height: 10),
                        const ReusableText(
                          text:
                              'Address: Cotolore Enterprises LLP, 15/293 - C, Muriyankara-Pinarmunda Milma Road, Peringala (PO), Ernakulam, 683565, Kerala, India.',
                          fontSize: 14,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
                ReviewsSection(productName: productName),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
