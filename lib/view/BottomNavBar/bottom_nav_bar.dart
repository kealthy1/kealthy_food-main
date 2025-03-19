import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_food/view/BottomNavBar/bottom_nav_bar_proivder.dart';
import 'package:kealthy_food/view/home/home.dart';
import 'package:kealthy_food/view/profile%20page/profile.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// 🔥 **Using IndexedStack to prevent unnecessary widget rebuilding**
          IndexedStack(
            index: currentIndex, 
            children: const [
              HomePage(),   // 🚀 Kept alive, does not rebuild when switching tabs
              ProfilePage(),
            ],
          ),
          // DraggableFloatingActionButton(
          //   imageUrl: 'lib/assets/images/PHOTO-2025-02-25-15-14-38-removebg-preview.png',
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const ChatScreen()),
          //     );
          //   },
          //   label: 'Ask Nutri',
          // ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(bottomNavProvider.notifier).setIndex(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black54,
        unselectedItemColor: Colors.grey,
        elevation: 0.5,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.house_fill,
              color: Color.fromARGB(255, 65, 88, 108),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              CupertinoIcons.person_fill,
              color: Color.fromARGB(255, 65, 88, 108),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}