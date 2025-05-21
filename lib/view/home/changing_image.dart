import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_food/view/home/Calorie.dart';
import 'package:kealthy_food/view/blog/blog.dart';
import 'package:kealthy_food/view/home/bmi_calculator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageData {
  final String imageUrl;
  final String title; // Add title to ImageData

  ImageData({required this.imageUrl, required this.title});
}

// Riverpod provider for list of image data
final imageDataProvider = StateNotifierProvider<ImageNotifier, List<ImageData>>(
  (ref) => ImageNotifier(ref: ref),
);

final carouselIndexProvider = StateProvider<int>((ref) => 0);

class ChangingImageWidget extends ConsumerStatefulWidget {
  const ChangingImageWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChangingImageWidgetState createState() => _ChangingImageWidgetState();
}

class _ChangingImageWidgetState extends ConsumerState<ChangingImageWidget> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final imageList = ref.read(imageDataProvider);
    for (final image in imageList) {
      precacheImage(CachedNetworkImageProvider(image.imageUrl), context);
    }
  }

  void _startAutoScroll() {
    _timer?.cancel(); // Ensure any existing timer is canceled
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final currentIndex = ref.read(carouselIndexProvider);
      final imageList = ref.read(imageDataProvider);
      if (imageList.isNotEmpty) {
        final nextIndex = (currentIndex + 1) % imageList.length;
        ref.read(carouselIndexProvider.notifier).state = nextIndex;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Stop scrolling when the user taps on an image
  void _stopAutoScroll() {
    _timer?.cancel(); // Stop the auto-scroll timer
  }

  /// Restart scrolling after a delay when the user stops interacting
  void _restartAutoScroll() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 20),
        () => _startAutoScroll()); // Restart after delay
  }

  /// Modify the onTap method to stop scrolling when tapped
  Future<void> _navigateBasedOnImageIndex(
      BuildContext context, int index) async {
    _stopAutoScroll(); // Stop auto-scrolling when user interacts

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BlogListPage()),
        );
        break;
      case 1:
        final instagramUrl = Uri.parse(
            'https://www.instagram.com/kealthy.life?igsh=MXVqa2hicG4ydzB5cQ==');
        if (await canLaunchUrl(instagramUrl)) {
          await launchUrl(instagramUrl);
        }
        break;
      case 2:
        final twitterUrl = Uri.parse('https://x.com/Kealthy_life/');
        if (await canLaunchUrl(twitterUrl)) {
          await launchUrl(twitterUrl);
        }
        break;
      case 3:
        final facebookUrl = Uri.parse(
            'https://www.facebook.com/profile.php?id=61571096468965&mibextid=ZbWKwL');
        if (await canLaunchUrl(facebookUrl)) {
          await launchUrl(facebookUrl);
        }
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BmiTrackerPage()),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalorieIntakePage()),
        );
        break;
      default:
        break;
    }

    _restartAutoScroll(); // Restart auto-scrolling after navigation
  }

  @override
  Widget build(BuildContext context) {
    final imageDataList = ref.watch(imageDataProvider);

    if (imageDataList.isEmpty) {
      // Show shimmer effect while loading images
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20)),
            width: MediaQuery.of(context).size.width,
            height: 180,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: GestureDetector(
            onPanDown: (_) =>
                _stopAutoScroll(), // Stop auto-scroll when user interacts
            onPanCancel: () =>
                _restartAutoScroll(), // Restart auto-scroll after interaction
            child: PageView.builder(
              controller: _pageController,
              itemCount: imageDataList.length,
              onPageChanged: (index) {
                ref.read(carouselIndexProvider.notifier).state = index;
              },
              itemBuilder: (context, index) {
                final imageData = imageDataList[index];

                return GestureDetector(
                  onTap: () {
                    _stopAutoScroll(); // Stop auto-scroll when user taps
                    _navigateBasedOnImageIndex(context, index);
                    _restartAutoScroll();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: imageData.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.grey[300]),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                          ),
                          if (imageData.title.trim().isNotEmpty)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ),
                          Positioned(
                            top: 10,
                            left: 10,
                            right: 10,
                            child: Text(
                              imageData.title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        SmoothPageIndicator(
          controller: _pageController,
          count: imageDataList.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 10,
            dotWidth: 10,
            activeDotColor: Color.fromARGB(255, 65, 88, 108),
            dotColor: Color.fromARGB(255, 120, 142, 162),
            spacing: 4.0,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}

class ImageNotifier extends StateNotifier<List<ImageData>> {
  ImageNotifier({required Ref ref}) : super([]) {
    _loadImagesAndTitlesFromFirestore();
  }

  Future<void> _loadImagesAndTitlesFromFirestore() async {
    try {
      // Fetching both image URLs and titles from Firestore collection 'Carousel'
      final snapshot =
          await FirebaseFirestore.instance.collection('Carousel').get();

      List<ImageData> loadedImages = [];

      // Loop through all documents in the collection and get image URLs and titles
      for (var doc in snapshot.docs) {
        // Fetch the image array and title array
        final imageUrls = List<String>.from(
            doc['Image']); // Assuming 'image' is an array of strings
        final titles = List<String>.from(
            doc['Title']); // Assuming 'title' is an array of strings

        // Ensure both arrays are of the same length
        if (imageUrls.length == titles.length) {
          for (int i = 0; i < imageUrls.length; i++) {
            // Create ImageData for each image and title pair
            loadedImages.add(ImageData(
              imageUrl: imageUrls[i],
              title: titles[i],
            ));
          }
        } else {
          print('Error: The number of images and titles do not match.');
        }
      }

      // Debugging: Print the number of images and titles loaded
      print('Total images loaded: ${loadedImages.length}');

      state = loadedImages; // Update the state with loaded images and titles
    } catch (e) {
      print("Error loading images and titles from Firestore: $e");
    }
  }
}
