import 'package:flutter/material.dart';
import 'Category.dart';

class CategoryTabPage extends StatefulWidget {
  const CategoryTabPage({super.key});

  @override
  State<CategoryTabPage> createState() => _CategoryTabPageState();
}

class _CategoryTabPageState extends State<CategoryTabPage>
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            dividerColor: Colors.transparent,
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Theme.of(context).primaryColor,
            tabs:  [
              Tab(icon: Image.asset('lib/assets/images/vegetable.png',width: 30,), text: 'Groceries'),
              Tab(icon: Image.asset('lib/assets/images/dinner.png',width: 30,), text: 'Food'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 400, // Adjust as needed for category content height
          child: TabBarView(
            controller: _tabController,
            children: const [
              // HomeCategory manages its own scroll/layout
              HomeCategory(),
              Center(
                  child: Text('Coming Soon',
                      style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ],
    );
  }
}
