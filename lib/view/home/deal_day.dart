import 'package:flutter/material.dart';

class DealOfTheDayPage extends StatelessWidget {
  const DealOfTheDayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deal of the Day')),
      body: const Center(child: Text('Deal of the Day Page')),
    );
  }
}