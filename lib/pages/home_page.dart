import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'report_lost_page.dart';
import 'report_found_page.dart';
import 'lost_page.dart';
import 'found_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Detect if we're on web/desktop (use kIsWeb for web platform detection)
    // This will be true for web browsers, false for mobile apps (Android/iOS)
    if (kIsWeb) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black87,
      endDrawer: _buildMenu(context),
      body: Stack(
        children: [
          // Background image with overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/hau_bg.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.4),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Desktop Layout
          Column(
            children: [
              // Desktop Header with horizontal navigation
              Container(
                color: const Color(0xFF550000),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // HAU Logo and Title
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/hau_logo.png',
                          height: 50,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.school, color: Colors.white, size: 45),
                        ),
                      ],
                    ),
                    
                    // Desktop Navigation Menu
                    Row(
                      children: [
                        _buildDesktopNavItem("Home", isActive: true),
                        _buildDesktopNavItem("Lost", onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LostPage()),
                          );
                        }),
                        _buildDesktopNavItem("Report Lost", onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ReportLostPage()),
                          );
                        }),
                        _buildDesktopNavItem("Found", onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => FoundPage()),
                          );
                        }),
                        _buildDesktopNavItem("Report Found", onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ReportFoundPage()),
                          );
                        }),
                        _buildDesktopNavItem("Forum", onTap: () {}),
                      ],
                    ),
                    
                    // Search and User Profile
                    Row(
                      children: [
                        // Search Bar
                        Container(
                          width: 200,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Search",
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // User Profile Icon
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.white, size: 28),
                          onPressed: () {
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                        ),
                        const SizedBox(width: 8),
                        // Menu Icon
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                          onPressed: () {
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Hero Section
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Angelites Find & Recover With Ease",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Your one-stop hub for lost and found items at HAU",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Report buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ReportLostPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF550000),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Report Lost",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ReportFoundPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Report Found",
                              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Carousel indicators
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCarouselDot(true),
                    const SizedBox(width: 8),
                    _buildCarouselDot(false),
                    const SizedBox(width: 8),
                    _buildCarouselDot(false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black87,
      endDrawer: _buildMenu(context),
      body: Stack(
        children: [
          // Background image with overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/hau_bg.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.4),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Foreground content
          Column(
            children: [
              // Header (Deep Maroon)
              Container(
                color: const Color(0xFF550000),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // HAU Logo
                    Image.asset(
                      'assets/icons/hau_logo.png',
                      height: 45,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.school, color: Colors.white, size: 40),
                    ),
                    // Right side icons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications,
                              color: Colors.white, size: 26),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.menu,
                              color: Colors.white, size: 26),
                          onPressed: () {
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Center content
              Column(
                children: [
                  const Text(
                    "Angelites Find & Recover With Ease",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your one-stop hub for lost and found items at HAU.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Report buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReportLostPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF550000),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          "Report Lost",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReportFoundPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          "Report Found",
                          style: TextStyle(color: Colors.black, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Fixed Bottom Navigation Bar
              Container(
                color: const Color(0xFF550000),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, "Home", isActive: true),
                    _buildNavItem(Icons.report, "Report Lost", onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ReportLostPage()),
                      );
                    }),
                    _buildNavItem(Icons.search, "Lost", onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LostPage()),
                      );
                    }),
                    _buildNavItem(Icons.inventory, "Report Found", onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ReportFoundPage()),
                      );
                    }),
                    _buildNavItem(Icons.check_circle, "Found", onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => FoundPage()),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavItem(String label, {bool isActive = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFFFFD200) : Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label,
      {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isActive ? const Color(0xFFFFD200) : Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFFFD200) : Colors.white,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF550000),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  backgroundImage: const AssetImage('assets/icons/hau_logo.png'),
                ),
              ),
              const SizedBox(height: 30),
              _menuItem(Icons.person, "Profile"),
              _menuItem(Icons.help_outline, "Help"),
              _menuItem(Icons.settings, "Settings"),
              _menuItem(Icons.info_outline, "About"),
              const Spacer(),
              _menuItem(Icons.logout, "Logout", onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}