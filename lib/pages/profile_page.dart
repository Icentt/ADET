import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'home_page.dart';
import 'report_lost_page.dart';
import 'report_found_page.dart';
import 'lost_page.dart';
import 'found_page.dart';
import 'login_page.dart';
import 'settings_page.dart';
import 'help_page.dart';
import 'about_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  
  // Sample user data - replace with actual user data from authentication
  final String userName = "Icent";
  final String userType = "SOC Student";
  final String email = "immui@student.hau.edu.ph";
  final String phone = "09968686921";
  final String birthDate = "June 26, 1980";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    
    if (isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Sidebar Menu
          _buildDesktopSidebar(),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header
                _buildDesktopHeader(),
                
                // Profile Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Cover Photo & Profile Picture
                        _buildProfileHeader(),
                        
                        // Profile Info and Tabs
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Side - About Section
                              Expanded(
                                flex: 1,
                                child: _buildAboutSection(),
                              ),
                              
                              const SizedBox(width: 30),
                              
                              // Right Side - Posts Section
                              Expanded(
                                flex: 2,
                                child: _buildPostsSection(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildMenu(context),
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF550000),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/icons/hau_logo.png',
                  height: 45,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.school, color: Colors.white, size: 40),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white, size: 26),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                      onPressed: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Profile Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildAboutSection(),
                        const SizedBox(height: 20),
                        _buildPostsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          _buildBottomNavigation(context),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 280,
      color: const Color(0xFF550000),
      child: Column(
        children: [
          // HAU Logo at top
          Padding(
            padding: const EdgeInsets.all(24),
            child: Image.asset(
              'assets/icons/hau_logo.png',
              height: 80,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school, color: Colors.white, size: 80),
            ),
          ),
          
          const Divider(color: Colors.white24, thickness: 1),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildSidebarItem(Icons.home, "Home", onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                }),
                _buildSidebarItem(Icons.search, "Lost", onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LostPage()),
                  );
                }),
                _buildSidebarItem(Icons.report, "Report Lost", onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportLostPage()),
                  );
                }),
                _buildSidebarItem(Icons.check_circle, "Found", onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => FoundPage()),
                  );
                }),
                _buildSidebarItem(Icons.inventory, "Report Found", onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportFoundPage()),
                  );
                }),
                _buildSidebarItem(Icons.forum, "Forum", onTap: () {}),
                
                const SizedBox(height: 20),
                const Divider(color: Colors.white24, thickness: 1),
                const SizedBox(height: 20),
                
                _buildSidebarItem(Icons.person, "Profile", isActive: true),
                _buildSidebarItem(Icons.help_outline, "Help", onTap: () {}),
                _buildSidebarItem(Icons.settings, "Settings", onTap: () {}),
                _buildSidebarItem(Icons.info_outline, "About", onTap: () {}),
              ],
            ),
          ),
          
          // Logout at bottom
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSidebarItem(Icons.logout, "Logout", onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFFFFD200) : Colors.white,
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFFFFD200) : Colors.white,
          fontSize: 16,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "My Profile",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF550000),
            ),
          ),
          Row(
            children: [
              // Search Bar
              Container(
                width: 250,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Photo
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/hau_building.jpg'),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {},
            ),
            color: Colors.grey.shade300,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        
        // Profile Picture and Name
        Positioned(
          bottom: -60,
          left: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Profile Picture
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: const Color(0xFFFFD200),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF550000),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Name and User Type
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      userType,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Follow Button (top right)
        Positioned(
          top: 200,
          right: 40,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add, size: 20),
            label: const Text("Follow"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF550000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildAboutItem(Icons.male, "Male"),
          _buildAboutItem(Icons.cake, "Born $birthDate"),
          _buildAboutItem(Icons.email, email),
          _buildAboutItem(Icons.phone, phone),
        ],
      ),
    );
  }

  Widget _buildAboutItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF550000),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF550000),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Lost"),
              Tab(text: "Found"),
              Tab(text: "Post"),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Tab Content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent("Lost Items"),
                _buildTabContent("Found Items"),
                _buildPostTabContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No $title yet",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your reported items will appear here",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTabContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "Forum Coming Soon",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Post feature will be available soon",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
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
                  backgroundColor: const Color(0xFFFFD200),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF550000),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _menuItem(Icons.person, "Profile", isActive: true),
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

  Widget _menuItem(IconData icon, String title, {bool isActive = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFFFFD200) : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? const Color(0xFFFFD200) : Colors.white,
          fontSize: 16,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      color: const Color(0xFF550000),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, "Home", onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }),
          _buildNavItem(Icons.search, "Lost", onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LostPage()),
            );
          }),
          _buildNavItem(Icons.check_circle, "Found", onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FoundPage()),
            );
          }),
          _buildNavItem(Icons.forum, "Forum", onTap: () {}),
          _buildNavItem(Icons.person, "Profile", isActive: true),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFFFD200) : Colors.white,
            size: 24,
          ),
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
}