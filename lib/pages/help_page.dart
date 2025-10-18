import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        backgroundColor: const Color(0xFF550000),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Help Page Content'),
      ),
    );
  }
}