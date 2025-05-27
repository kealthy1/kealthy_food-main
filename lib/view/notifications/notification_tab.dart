import 'package:flutter/material.dart';
import 'package:kealthy_food/view/notifications/offers.dart';
import 'notification_page.dart'; 

class NotificationTabPage extends StatelessWidget {
  const NotificationTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text('Notifications'),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Rating'),
              Tab(text: 'Offers & Deals'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NotificationsScreen(),
            OffersNotificationPage(),
          ],
        ),
      ),
    );
  }
}