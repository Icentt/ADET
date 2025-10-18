import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'home_page.dart';
import 'report_lost_page.dart';
import 'lost_page.dart';
import 'found_page.dart';
import 'login_page.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import 'dart:convert';

class ReportFoundPage extends StatefulWidget {
  const ReportFoundPage({super.key});

  @override
  State<ReportFoundPage> createState() => _ReportFoundPageState();
}

class _ReportFoundPageState extends State<ReportFoundPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  File? _selectedImage;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Test function to verify image upload
  Future<void> _testImageUpload() async {
    if (_selectedImage == null) {
      print('🔹 No image selected for test');
      return;
    }
    
    print('🔹 ===== IMAGE UPLOAD TEST =====');
    try {
      final bytes = await _selectedImage!.readAsBytes();
      print('🔹 Test: File size: ${bytes.length} bytes');
      
      // Test base64 encoding
      final base64String = base64Encode(bytes);
      print('🔹 Test: Base64 length: ${base64String.length}');
      print('🔹 Test: Base64 preview: ${base64String.substring(0, 50)}...');
      
      // Test if we can create a data URL
      final dataUrl = 'data:image/jpeg;base64,$base64String';
      print('🔹 Test: Data URL length: ${dataUrl.length}');
      print('🔹 Test: Data URL preview: ${dataUrl.substring(0, 100)}...');
      
    } catch (e) {
      print('🔹 Test failed: $e');
    }
    print('🔹 ===== IMAGE UPLOAD TEST END =====');
  }

  Future<void> _submitReport() async {
    // Validate all required fields
    if (_nameController.text.trim().isEmpty ||
        _itemController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      print('🔹 Starting submission to Supabase...');

      String? imageUrl;

      // 🔹 Upload image if selected
      if (_selectedImage != null) {
        print('🔹 ===== IMAGE UPLOAD DEBUG START =====');
        print('🔹 Selected image path: ${_selectedImage!.path}');
        print('🔹 Selected image exists: ${await _selectedImage!.exists()}');
        
        try {
          print('🔹 Uploading image...');
          final fileName =
              'found_${DateTime.now().millisecondsSinceEpoch}.jpg';
          print('🔹 Generated filename: $fileName');
          
          // Convert file to bytes for web compatibility
          final bytes = await _selectedImage!.readAsBytes();
          print('🔹 File size: ${bytes.length} bytes');
          print('🔹 First 10 bytes: ${bytes.take(10).toList()}');
          
          // Check if storage bucket exists
          try {
            final buckets = await supabase.storage.listBuckets();
            print('🔹 Available buckets: ${buckets.map((b) => b.name).toList()}');
          } catch (bucketError) {
            print('🔹 Error listing buckets: $bucketError');
          }
          
          // Try to upload to storage
          print('🔹 Attempting upload to found_images bucket...');
          final uploadResponse = await supabase.storage.from('found_images').uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );
          
          print('🔹 Upload response: $uploadResponse');
          print('🔹 Upload response type: ${uploadResponse.runtimeType}');
          
          final publicUrl =
              supabase.storage.from('found_images').getPublicUrl(fileName);
          imageUrl = publicUrl;
          print('🔹 Image uploaded successfully: $imageUrl');
          print('🔹 Full image URL: $imageUrl');
          
          // Test if the URL is accessible
          try {
            print('🔹 Testing image accessibility...');
            final response = await supabase.storage.from('found_images').download(fileName);
            print('🔹 Image download test successful, size: ${response.length} bytes');
          } catch (testError) {
            print('🔹 Image download test failed: $testError');
          }
        } catch (uploadError) {
          print('🔹 ===== UPLOAD ERROR =====');
          print('🔹 Image upload failed: $uploadError');
          print('🔹 Upload error details: ${uploadError.toString()}');
          print('🔹 Error type: ${uploadError.runtimeType}');
          
          // Fallback: Store image as base64 string
          try {
            print('🔹 ===== BASE64 FALLBACK =====');
            print('🔹 Attempting base64 fallback...');
            final bytes = await _selectedImage!.readAsBytes();
            final base64String = base64Encode(bytes);
            imageUrl = 'data:image/jpeg;base64,$base64String';
            print('🔹 Image stored as base64, length: ${base64String.length}');
            print('🔹 Base64 preview: ${base64String.substring(0, 50)}...');
          } catch (base64Error) {
            print('🔹 ===== BASE64 ERROR =====');
            print('🔹 Base64 fallback also failed: $base64Error');
            imageUrl = null;
          }
        }
        print('🔹 ===== IMAGE UPLOAD DEBUG END =====');
      } else {
        print('🔹 No image selected for upload');
      }

      // 🔹 Prepare data for insertion WITH PENDING STATUS
      final reportData = {
        'name': _nameController.text.trim(),
        'item': _itemController.text.trim(),
        'location': _locationController.text.trim(),
        'date': _dateController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending', // 🔹 SET STATUS AS PENDING FOR ADMIN REVIEW
      };

      print('🔹 ===== DATABASE INSERT DEBUG =====');
      print('🔹 Submitting data: $reportData');
      print('🔹 Image URL being stored: $imageUrl');

      // 🔹 Insert into 'reports_found' table
      final response = await supabase
          .from('reports_found')
          .insert(reportData)
          .select();
      
      print('🔹 Database response: $response');
      print('🔹 Database response type: ${response.runtimeType}');
      if (response.isNotEmpty) {
        print('🔹 Inserted record ID: ${response[0]['id']}');
        print('🔹 Inserted image_url: ${response[0]['image_url']}');
      }

      // Show success message
      if (mounted) {
        final successMessage = imageUrl != null 
            ? 'Found item report submitted with image! Waiting for admin approval.'
            : 'Found item report submitted! Waiting for admin approval.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Reset form after successful submission
      _resetForm();
      
      // Navigate back to home page after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      });

    } catch (e) {
      print('🔹 Error submitting report: $e');
      
      String errorMessage = 'Error submitting report';
      
      // Handle specific error types
      if (e.toString().contains('PGRST205') || e.toString().contains('table')) {
        errorMessage = 'Table not found. Please create "reports_found" table in Supabase.';
      } else if (e.toString().contains('storage') || e.toString().contains('_Namespace')) {
        errorMessage = 'Image upload failed. Report submitted without image.';
      } else if (e.toString().contains('database')) {
        errorMessage = 'Database error. Please check your connection.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('_Namespace')) {
        errorMessage = 'File upload error. Report submitted without image.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    _itemController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _dateController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detect if we're on desktop/web
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
      endDrawer: _buildMenu(context),
      body: Column(
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
                    _buildDesktopNavItem("Home", onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    }),
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
                    _buildDesktopNavItem("Report Found", isActive: true),
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

          // Desktop Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Container(
                  width: 800,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Desktop Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF550000), Color(0xFFFFD200)],
                        ).createShader(bounds),
                        child: const Text(
                          "Report Found Item",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Desktop Form
                      _buildDesktopField("Name", _nameController),
                      _buildDesktopField("Item", _itemController),
                      _buildDesktopField("Location Found", _locationController),
                      _buildDesktopDateField(),
                      _buildDesktopField("Item Description", _descriptionController, maxLines: 3),

                      const SizedBox(height: 20),
                      _buildDesktopImageUpload(),

                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Submit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: _resetForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Reset", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

          const SizedBox(height: 30),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF550000), Color(0xFFFFD200)],
            ).createShader(bounds),
            child: const Text(
              "Report Found Item",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField("Name", _nameController),
                    _buildField("Item", _itemController),
                    _buildField("Location Found", _locationController),
                    _buildDateField(),
                    _buildField("Item Description", _descriptionController, maxLines: 3),

                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 120,
                          child: Text("Upload Photo :",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.upload),
                                label: const Text("Choose Image"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF550000),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_selectedImage != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: kIsWeb 
                                      ? Image.network(
                                          _selectedImage!.path,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 150,
                                            width: double.infinity,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                          ),
                                        )
                                      : Image.file(
                                          _selectedImage!,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              const SizedBox(height: 6),
                              const Text("(Upload if available)",
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _testImageUpload,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Test Image Upload', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Submit"),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _resetForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                          ),
                          child: const Text("Reset"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          _buildBottomNavigation(context),
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
          _buildNavItem(Icons.inventory, "Report Found", isActive: true),
          _buildNavItem(Icons.check_circle, "Found", onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FoundPage()),
            );
          }),
        ],
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

  Widget _buildField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text("$label :",
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: const InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Color(0xFFE0E0E0),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
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

  Widget _buildDesktopField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text("$label :",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 150,
            child: Text("Date :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: TextField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                suffixIcon: Icon(Icons.calendar_today, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  _dateController.text = DateFormat('MM/dd/yyyy').format(pickedDate);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopImageUpload() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 150,
            child: Text("Upload Photo :",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload),
                  label: const Text("Choose Image"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF550000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb 
                        ? Image.network(
                            _selectedImage!.path,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                          )
                        : Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                const SizedBox(height: 8),
                const Text("(Upload if available)",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _testImageUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Image Upload'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(
              width: 120,
              child:
                  Text("Date :", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: TextField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Color(0xFFE0E0E0),
                suffixIcon: Icon(Icons.calendar_today, size: 18),
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  _dateController.text =
                      DateFormat('MM/dd/yyyy').format(pickedDate);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}