import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF550000),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Account'),
            subtitle: Text('Manage your account settings'),
            leading: Icon(Icons.person_outline),
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: false,
            onChanged: (_) {},
          ),
          const ListTile(
            title: Text('Notifications'),
            subtitle: Text('Configure app notifications'),
            leading: Icon(Icons.notifications_outlined),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'App version 1.0.0',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}



