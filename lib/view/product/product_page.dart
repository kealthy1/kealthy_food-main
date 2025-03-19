import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/product/alert_dialogue.dart';
import 'package:kealthy_food/view/product/product_content.dart';
// import 'package:kealthy_food/view/product/kealthy_score.dart';
import 'package:kealthy_food/view/Cart/cart_container.dart';
// ----------------------------------------------------------------------

final currentPageProvider = StateProvider<int>((ref) => 0);

/// ProductPage - a single page that shows a product's details from Firestore.
/// We pass only the productId, then fetch product data from Firestore.
class ProductPage extends StatefulWidget {
  final String productId; // Firestore document ID

  const ProductPage({super.key, required this.productId});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> with WidgetsBindingObserver {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // <-- Use 'this', not 'widget'
    _pageController = PageController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this); // <-- Use 'this', not 'widget'
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Products')
                  .doc(widget.productId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.poppins(),
                  ));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                      child: Text(
                    'Product not found.',
                    style: GoogleFonts.poppins(),
                  ));
                }
                final docData = snapshot.data!.data()!;

                return ProductContent(
                  docData: docData,
                  pageController: _pageController,
                  productId: widget.productId,
                );
              },
            ),
          ),
          const CartContainer(),
        ],
      ),
    );
  }
}



void showDetailsDialog({
  required BuildContext context,
  required String label,
  required String details,
  required Color backgroundColor,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return DetailsDialog(
        label: label,
        details: details,
        backgroundColor: backgroundColor,
      );
    },
  );
}
