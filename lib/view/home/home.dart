import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/Cart/cart_controller.dart';
import 'package:kealthy_food/view/address/adress.dart';
import 'package:kealthy_food/view/address/provider.dart';
import 'package:kealthy_food/view/Cart/cart_container.dart';
import 'package:kealthy_food/view/home/changing_image.dart';
import 'package:kealthy_food/view/home/Category.dart';
import 'package:kealthy_food/view/home/deal_day.dart';
import 'package:kealthy_food/view/home/deal_week.dart';
import 'package:kealthy_food/view/notifications/feedback_alert.dart';
import 'package:kealthy_food/view/notifications/rating_alert.dart';
import 'package:kealthy_food/view/home/kealthy_page.dart';
import 'package:kealthy_food/view/home/provider.dart';
import 'package:kealthy_food/view/home/title.dart';
import 'package:kealthy_food/view/notifications/notification_page.dart';
import 'package:kealthy_food/view/orders/myorders.dart';
import 'package:kealthy_food/view/search/searchbar.dart';
import 'package:kealthy_food/view/splash_screen/version_check.dart';
import 'package:kealthy_food/view/subscription/subscription_details.dart';
import 'package:lottie/lottie.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool hasShownDialog = false;
  final bool _hasLocationPermission = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionCheckService.checkForUpdate(context);
      ref.read(cartProvider.notifier).loadCartItems();
      checkLocationPermission(ref);
      getSelectedAddressOrCurrentLocation(ref);
    });
    WidgetsBinding.instance.addObserver(this);

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkLocationPermission(
          ref); // ✅ Check permission & show bottom sheet if needed
    }
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      ref.read(cartVisibilityProvider.notifier).state = false;
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      ref.read(cartVisibilityProvider.notifier).state = true;
    } else {
      ref.read(cartVisibilityProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cartItems = ref.read(cartProvider);
    final selectedAddress = ref.watch(selectedLocationProvider);
    final totalItems =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    final hasCartItems = totalItems > 0;

    print('Cart items: $cartItems');
    print('Total items: $totalItems');
    print('Has cart items: $hasCartItems');
    print('Location: $selectedAddress');

    // Use the stateful _scrollController and showCartContainer for scroll behavior
    ScrollController scrollController = _scrollController;
    ValueNotifier<bool> showCartContainer = ValueNotifier(true);
    // Listen to scroll events and update showCartContainer accordingly
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        showCartContainer.value = true;
      } else if (scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        showCartContainer.value = false;
      }
    });

    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          title: Column(
            children: [_buildHeader(context, ref)],
          )),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Wrap the CustomScrollView with RefreshIndicator
            CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const SearchBarWidget(),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: ChangingImageWidget(),
                      ),
                      const SizedBox(height: 20),
                      const CenteredTitleWidget(title: "Categories"),
                      const SizedBox(height: 10),
                      const HomeCategory(),
                      const SizedBox(height: 10),
                      const CenteredTitleWidget(title: "Subscribe & Save"),
                      // Subscription box padding inserted here
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SubscriptionDetailsPage(),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              color: const Color(0xFFF4F4F5),
                              child: Image.asset(
                                'lib/assets/images/Never Run Out of Milk Again-5.png',
                                height: 80,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const CenteredTitleWidget(title: "Hot Deals & Exclusive Offers"),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DealOfTheDayPage()),
                                );
                              },
                              child: SizedBox(
                                width: (MediaQuery.of(context).size.width - 48) / 2,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Container(
                                        color: const Color(0xFFF4F4F5),
                                        child: Image.asset(
                                          'lib/assets/images/deal day.png',
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DealOfTheWeekPage()),
                                );
                              },
                              child: SizedBox(
                                width: (MediaQuery.of(context).size.width - 48) / 2,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Container(
                                        color: const Color(0xFFF4F4F5),
                                        child: Image.asset(
                                          'lib/assets/images/deal week.png',
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const KealthyPage(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
            const ReviewAlert(),
            Consumer(
              builder: (context, ref, child) {
                return const OrderFeedbackAlert();
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: showCartContainer,
              builder: (context, showCart, child) {
                return IgnorePointer(
                  ignoring: !showCart,
                  child: AnimatedOpacity(
                    opacity: showCart ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Align(
                      alignment: Alignment.bottomCenter,
                      child: CartContainer(),
                    ),
                  ),
                );
              },
            ),
            if (!_hasLocationPermission) Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final liveOrdersAsync = ref.watch(liveOrdersProvider);
    final locationPermission = ref.watch(locationPermissionProvider);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddressPage()),
        );
      },
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.location_solid,
            color: Colors.red,
            size: 35,
          ),
          Expanded(
            child: FutureBuilder<Map<String, String>>(
              future: getSelectedAddressOrCurrentLocation(ref),
              builder: (context, snapshot) {
                String displayText;
                bool showSubText = false;
                String subText = "";

                if (locationPermission == LocationPermission.denied) {
                  displayText = "Location Disabled";
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  displayText = "Locating...";
                } else if (snapshot.hasData) {
                  final data = snapshot.data!;

                  if (data.containsKey('addressType')) {
                    // ✅ Selected Address: Show both fields
                    displayText = data['addressType']!;
                    subText = data['address']!;
                    showSubText = true;
                  } else {
                    // ✅ Current Location: Show only one field
                    displayText = data['address']!;
                  }
                } else {
                  displayText = "Locating...";
                }

                return Consumer(
                  builder: (context, ref, child) {
                    final liveOrders =
                        ref.watch(liveOrdersProvider).asData?.value ?? [];
                    final hasLiveOrders = liveOrders.isNotEmpty;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overflow: TextOverflow.ellipsis,
                          displayText,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (showSubText)
                          SizedBox(
                            width: hasLiveOrders
                                ? MediaQuery.of(context).size.width * 0.45
                                : double
                                    .infinity, // No width limit when no live order
                            child: Text(
                              subText,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          liveOrdersAsync.when(
            data: (liveOrders) {
              final hasLiveOrders = liveOrders.isNotEmpty;

              if (hasLiveOrders) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const MyOrdersPage(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipOval(
                          child: Container(
                            color: Colors.white,
                            width: 50,
                            height: 50,
                            child: Lottie.asset(
                              'lib/assets/animations/Delivery Boy.json',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Live',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
            loading: () => const CupertinoActivityIndicator(
              color: Colors.white,
            ),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          IconButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
            ),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoModalPopupRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications,
                  size: 25,
                  color: Color(0xFF273847),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final notificationsAsync = ref.watch(notificationProvider);

                    return notificationsAsync.when(
                      data: (notifications) {
                        final filteredNotifications =
                            notifications.where((notification) {
                          final orderId = notification['order_id'] ?? '';

                          final orderExistsAsync =
                              ref.watch(orderExistsProvider(orderId));

                          return orderExistsAsync.when(
                            data: (exists) => !exists,
                            loading: () => false,
                            error: (_, __) => false,
                          );
                        }).toList();

                        final notificationCount = filteredNotifications.length;

                        if (notificationCount > 0) {
                          return Positioned(
                            right: -13,
                            top: -20,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                notificationCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

