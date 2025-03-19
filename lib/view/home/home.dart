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
import 'package:kealthy_food/view/home/header.dart';
import 'package:kealthy_food/view/notifications/feedback_alert.dart';
import 'package:kealthy_food/view/notifications/rating_alert.dart';
import 'package:kealthy_food/view/home/kealthy_page.dart';
import 'package:kealthy_food/view/home/provider.dart';
import 'package:kealthy_food/view/home/title.dart';
import 'package:kealthy_food/view/notifications/notification_page.dart';
import 'package:kealthy_food/view/orders/myorders.dart';
import 'package:kealthy_food/view/search/searchbar.dart';
import 'package:kealthy_food/view/splash_screen/version_check.dart';
import 'package:lottie/lottie.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
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
    final cartItems = ref.read(cartProvider);
    final selectedAddress = ref.watch(selectedLocationProvider);
    final totalItems =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    final hasCartItems = totalItems > 0;

    print('Cart items: $cartItems');
    print('Total items: $totalItems');
    print('Has cart items: $hasCartItems');
    print('Location: $selectedAddress');

    ScrollController scrollController = ScrollController();
    ValueNotifier<bool> showCartContainer = ValueNotifier(true);

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
              slivers: const [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      SearchBarWidget(),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: ChangingImageWidget(),
                      ),
                      SizedBox(height: 20),
                      CenteredTitleWidget(title: "Categories"),
                      SizedBox(height: 10),
                      HomeCategory(),
                      SizedBox(height: 50),
                      KealthyPage()
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
                return AnimatedOpacity(
                  opacity: showCart ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Align(
                    alignment: Alignment.bottomCenter,
                    child: CartContainer(),
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
                bool showSubText = false; // Flag to control subText display
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
            loading: () => const CircularProgressIndicator(color: Colors.white),
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
