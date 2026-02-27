import 'package:flutter/material.dart';

class WarrantyPage extends StatelessWidget {
  const WarrantyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warranty')),
      body: const Center(
        child: Text('Your warranty details will appear here.'),
      ),
    );
  }
}
