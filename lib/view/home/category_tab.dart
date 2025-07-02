import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/food/food_category.dart';
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
  late ProviderSubscription<int> _subscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Update provider when user swipes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      ref.read(tabIndexProvider.notifier).state = _tabController.index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Safe ref.listen setup
    _subscription = ref.listenManual<int>(tabIndexProvider, (previous, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });
  }

  @override
  void dispose() {
    _subscription.close();
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
            controller: _tabController,
            onTap: (index) {
              ref.read(tabIndexProvider.notifier).state = index;
            },
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.black54,
            labelStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            indicatorColor: Theme.of(context).primaryColor,
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
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: TabBarView(
            controller: _tabController,
            children: const [HomeCategory(), FoodCategory()],
          ),
        ),
      ],
    );
  }
}
