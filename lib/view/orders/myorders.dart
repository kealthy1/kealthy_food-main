import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/orders/live_orders.dart';
import 'package:kealthy_food/view/orders/past_orders.dart';

class MyOrdersPage extends StatelessWidget {
  final bool navigateToHome; // Indicates if navigation back should go to HomePage

  const MyOrdersPage({super.key, this.navigateToHome = false});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: const Color(0xFF273847),
          toolbarHeight: 30,
          backgroundColor: Colors.white,
          
          bottom:  TabBar(
            indicatorColor: const Color(0xFF273847),
            labelColor: const Color(0xFF273847),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                icon: const Icon(Icons.delivery_dining_outlined),
                child: Text(
                  'Live Orders',
                  
                  style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            Tab(
                icon: const Icon(Icons.check_circle_sharp),
                child: Text(
                  'Past Orders',
                 style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tab for "Live Orders"
            LiveOrdersTab(),
            // Tab for "Past Orders"
            OrderCard(),
          ],
        ),
      ),
    );
  }
}