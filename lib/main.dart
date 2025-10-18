import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/admin_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Initialize Supabase connection
  await Supabase.initialize(
    url: 'https://vwnkhectasrhquwsuruh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3bmtoZWN0YXNyaHF1d3N1cnVoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwODc1NjgsImV4cCI6MjA3NTY2MzU2OH0.gpM3gyLPy-xKiW6B1xbKsdGNe97jDRgA76KoqvPvf8Y',
  );

  runApp(const HautrackApp());
}

class HautrackApp extends StatelessWidget {
  const HautrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAUTRACK: Lost and Found',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF550000),
          foregroundColor: Colors.white,
        ),
      ),
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}