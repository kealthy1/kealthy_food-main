import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'Category.dart';

final tabIndexProvider = StateProvider<int>((ref) => 0);

class CategoryTabPage extends ConsumerStatefulWidget {
  const CategoryTabPage({super.key});

  @override
  ConsumerState<CategoryTabPage> createState() => _CategoryTabPageState();
}

class _CategoryTabPageState extends ConsumerState<CategoryTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tabIndexProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            onTap: (index) {
              ref.read(tabIndexProvider.notifier).state = index;
            },
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Groceries'),
              Tab(text: 'Food'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: MediaQuery.of(context).size.height*0.44,
          child: TabBarView(
            controller: _tabController,
            children: const [
              HomeCategory(),
              Center(child: Text('Coming Soon', style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ],
    );
  }
}