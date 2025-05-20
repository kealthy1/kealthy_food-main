import 'package:flutter/material.dart';

class DealOfTheWeekPage extends StatelessWidget {
  const DealOfTheWeekPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deal of the Week')),
      body: const Center(child: Text('Deal of the Week Page')),
    );
  }
}