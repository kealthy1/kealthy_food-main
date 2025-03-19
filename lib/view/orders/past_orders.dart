import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/orders/provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';



class OrderCard extends ConsumerWidget {
  const OrderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(orderDataProvider.notifier).fetchOrderData();

    final orderDataAsync = ref.watch(orderDataProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: orderDataAsync.when(
        data: (orders) {
          if (orders == null || orders.isEmpty) {
            return Center(
              child: Text(
                "No order found.",
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                      fontSize: 14,),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: orders.map((orderData) {
                  final screenSize = MediaQuery.of(context).size;
                  final padding = screenSize.width * 0.03;

                  return Padding(
                    padding: EdgeInsets.all(padding),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Order ${orderData.orderId.length > 10 ? orderData.orderId.substring(orderData.orderId.length - 10) : orderData.orderId}",
                                    style: GoogleFonts.poppins(
                                      textStyle: const TextStyle(
                                        fontSize: 20,
                                        overflow: TextOverflow.ellipsis,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    CupertinoIcons.doc,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              Text(
                                orderData.date,
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Total Amount  ₹${orderData.totalAmountToPay.toStringAsFixed(0)}/-",
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                overflow: TextOverflow.ellipsis,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const Divider(
                            thickness: 1.5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Items:",
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Text(
                                "Delivered",
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: orderData.orderItems.map((item) {
                              return ListTile(
                                title: Text(
                                  item.itemName,
                                  style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                subtitle: Text(
                                  "Quantity: ${item.itemQuantity} | Price: ₹${item.itemPrice.toStringAsFixed(0)}/-",
                                  style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
        loading: () => Center(
          // Added 'const' for better performance
          child: LoadingAnimationWidget.inkDrop(
            size: 50,
            color: const Color.fromARGB(255, 65, 88, 108),
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            "Error: $err",
            style: GoogleFonts.poppins(
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
