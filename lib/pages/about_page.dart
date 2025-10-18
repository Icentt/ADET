import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: const Color(0xFF550000),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('About Page Content'),
      ),
    );
  }
}
