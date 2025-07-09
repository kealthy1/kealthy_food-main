import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryTabHeader extends ConsumerWidget {
  final TabController tabController;
  const CategoryTabHeader({super.key,required this.tabController});
  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: tabController,
            tabs: [
              Tab(
                icon: Image.asset('lib/assets/images/bag.png',
                    width: 30, color: Colors.black),
                text: 'Kealthy Store',
              ),
              Tab(
                icon: Image.asset('lib/assets/images/restaurant.png',
                    width: 30, color: Colors.black),
                text: 'Kealthy Kitchen',
              ),
            ],
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.black54,
            dividerColor: Colors.transparent, // Removes bottom divider
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
