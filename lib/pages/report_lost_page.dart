import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'home_page.dart';
import 'report_found_page.dart';
import 'lost_page.dart';
import 'found_page.dart';
import 'login_page.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert';
import 'profile_page.dart';
import 'dart:typed_data'; // ✅ Added for Uint8List

class ReportLostPage extends StatefulWidget {
  const ReportLostPage({super.key});

  @override
  State<ReportLostPage> createState() => _ReportLostPageState();
}

class _ReportLostPageState extends State<ReportLostPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  
  File? _selectedImage;
  XFile? _selectedXFile; // ✅ Added to store XFile for web compatibility
  bool _isSubmitting = false;

  // ✅ Updated _pickImage to store XFile
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedXFile = pickedFile; // Store XFile
        _selectedImage = File(pickedFile.path); // Keep for display
      });
    }
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

      // ✅ FIXED: Upload image if selected using XFile for web compatibility
      if (_selectedImage != null && _selectedXFile != null) {
        try {
          print('🔹 Uploading image...');
          final fileName = 'lost_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          // ✅ Read bytes from XFile (works for both web and mobile)
          final Uint8List bytes = await _selectedXFile!.readAsBytes();
          print('🔹 File size: ${bytes.length} bytes');

          // ✅ Upload to Supabase Storage with proper contentType
          await supabase.storage.from('lost_images').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'image/jpeg', // ✅ Added contentType
            ),
          );

          // Get public URL
          imageUrl = supabase.storage.from('lost_images').getPublicUrl(fileName);
          print('🔹 Image uploaded: $imageUrl');
        } catch (uploadError) {
          print('🔹 Upload failed: $uploadError');
          imageUrl = null;
        }
      }

      // Prepare data for insertion
      final reportData = {
        'name': _nameController.text.trim(),
        'item': _itemController.text.trim(),
        'location': _locationController.text.trim(),
        'date': _dateController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      print('🔹 Submitting data: $reportData');

      // Insert into 'reports_lost' table
      final response = await supabase
          .from('reports_lost')
          .insert(reportData)
          .select();

      print('🔹 Database response: $response');

      // Show success message
      if (mounted) {
        final successMessage = imageUrl != null
            ? 'Lost item report submitted with image! Waiting for admin approval.'
            : 'Lost item report submitted! Waiting for admin approval.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Reset form
      _resetForm();

      // Navigate back to home page
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
      String errorMessage = 'Error submitting report: ${e.toString()}';

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

  // ✅ Updated _resetForm to clear XFile
  void _resetForm() {
    _nameController.clear();
    _itemController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _dateController.clear();
    setState(() {
      _selectedImage = null;
      _selectedXFile = null; // ✅ Clear XFile too
    });
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
      endDrawer: _buildMenu(context),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF550000),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    _buildDesktopNavItem("Report Lost", isActive: true),
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
                Row(
                  children: [
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.person, color: Colors.white, size: 28),
                      onPressed: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                    ),
                    const SizedBox(width: 8),
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
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF550000), Color(0xFFFFD200)],
                        ).createShader(bounds),
                        child: const Text(
                          "Report Lost Item",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildDesktopField("Name", _nameController),
                      _buildDesktopField("Item", _itemController),
                      _buildDesktopField("Location", _locationController),
                      _buildDesktopDateField(),
                      _buildDesktopField("Item Description", _descriptionController,
                          maxLines: 3),
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
                                : const Text("Submit",
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600)),
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
                            child: const Text("Reset",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
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
                      icon: const Icon(Icons.notifications,
                          color: Colors.white, size: 26),
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
          const SizedBox(height: 30),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF550000), Color(0xFFFFD200)],
            ).createShader(bounds),
            child: const Text(
              "Report Lost Item",
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
                    _buildField("Location", _locationController),
                    _buildDateField(),
                    _buildField("Item Description", _descriptionController,
                        maxLines: 3),
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
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            height: 150,
                                            width: double.infinity,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.image,
                                                size: 50, color: Colors.grey),
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
                                      fontSize: 10, fontStyle: FontStyle.italic)),
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
          _buildNavItem(Icons.report, "Report Lost", isActive: true),
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

  Widget _buildDesktopNavItem(String label,
      {bool isActive = false, VoidCallback? onTap}) {
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

  Widget _buildDesktopField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text("$label :",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Text("Date :",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image,
                                  size: 50, color: Colors.grey),
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
              child: Text("Date :",
                  style: TextStyle(fontWeight: FontWeight.bold))),
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