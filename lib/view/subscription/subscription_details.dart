import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'confirmation_page.dart';

final quantityProvider = StateProvider.family<int, String>((ref, title) => 1);

class SubscriptionDetailsPage extends StatelessWidget {
  const SubscriptionDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white,
       surfaceTintColor: Colors.white,


        title: const Text('Subscription Plans'),
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
              title: '7-Day Plan',
              description: 'Plus 1 day Free\nFree Delivery',
              baseRate: 120,
              durationDays: 7,
            ),
            const SizedBox(height: 12),
            const PlanCard(
              title: '15-Day Plan',
              description: 'Plus 2 day Free\nFree Delivery',
              baseRate: 120,
              durationDays: 15,
            ),
            const SizedBox(height: 12),
            const PlanCard(
              title: '30-Day Plan',
              description: 'Plus 4 day Free\nFree Delivery',
              baseRate: 120,
              durationDays: 30,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class PlanCard extends ConsumerWidget {
  final String title;
  final String description;
  final double baseRate;
  final int durationDays;

  const PlanCard({
    super.key,
    required this.title,
    required this.description,
    required this.baseRate,
    required this.durationDays,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedQty = ref.watch(quantityProvider(title));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              title: title,
              description: description,
              baseRate: baseRate,
              durationDays: durationDays,
              selectedQty: selectedQty,
            ),
          ),
        );
      },
      child: Container(
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
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.17,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Text(
                        '₹${(baseRate * selectedQty * durationDays).toStringAsFixed(0)} ',
                        key: ValueKey('${baseRate * selectedQty * durationDays}'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (description.contains('Plus')) Row(
                          children: [
                            const Icon(CupertinoIcons.gift, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                description.split('\n').firstWhere((line) => line.contains('Plus')),
                                style: const TextStyle(fontSize: 13, color: Colors.green),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                        if (description.contains('Free Delivery')) const Row(
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Free Delivery',
                                style: TextStyle(fontSize: 13, color: Colors.green),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'Select Quantity:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<int>(
                          value: selectedQty,
                          dropdownColor: Colors.white,
                          items: List.generate(5, (index) {
                            final value = index + 1;
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value L'),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(quantityProvider(title).notifier).state = value;
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 40  ,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 65, 88, 108),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}