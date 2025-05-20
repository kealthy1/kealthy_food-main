import 'package:flutter/material.dart';

class SubscriptionDetailsPage extends StatelessWidget {
  const SubscriptionDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white,
       surfaceTintColor: Colors.white,


        title: const Text('Subscription Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'lib/assets/images/promo_1736765179.jpg',
                  height: 140,
                  width: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'A2 Mate Milk 1L',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pure Goodness in Every Drop — Experience the Natural Taste of A2 Mate Milk, Delivered Fresh to Your Doorstep Daily.',
              style: TextStyle(fontSize: 14, color: Colors.black),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),
            const PlanCard(
              title: '7-Day Plan  ₹840/- ',
              price: '1 Packet free',
              description: 'Daily 500ml Milk',
            ),
            const SizedBox(height: 12),
            const PlanCard(
              title: '15-Day Plan',
              price: '₹499/month',
              description: 'Daily 1L Milk',
            ),
            const SizedBox(height: 12),
            const PlanCard(
              title: '30-Day Plan',
              price: '₹799/month',
              description: 'Daily 2L Milk',
            ),
          ],
        ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;

  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}