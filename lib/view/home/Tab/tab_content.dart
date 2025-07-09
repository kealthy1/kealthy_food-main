import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_food/view/food/food_category.dart';
import 'package:kealthy_food/view/home/Category.dart';

class CategoryTabContent extends ConsumerWidget {
  final TabController tabController;
  const CategoryTabContent({super.key, required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBarView(
      controller: tabController,
      physics: const BouncingScrollPhysics(),
      children: const [
        HomeCategory(),
        FoodCategory(),
      ],
    );
  }
}