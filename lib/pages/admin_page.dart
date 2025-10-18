import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _pendingLostItems = [];
  List<Map<String, dynamic>> _pendingFoundItems = [];
  List<Map<String, dynamic>> _approvedLostItems = [];
  List<Map<String, dynamic>> _approvedFoundItems = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllItems() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final supabase = Supabase.instance.client;

      print('🔹 Loading all items from database...');

      // Load pending lost items
      final pendingLostResponse = await supabase
          .from('reports_lost')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      // Load pending found items
      final pendingFoundResponse = await supabase
          .from('reports_found')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      // Load approved lost items
      final approvedLostResponse = await supabase
          .from('reports_lost')
          .select('*')
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      // Load approved found items
      final approvedFoundResponse = await supabase
          .from('reports_found')
          .select('*')
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      print('🔹 Pending lost: ${pendingLostResponse.length}, Pending found: ${pendingFoundResponse.length}');
      print('🔹 Approved lost: ${approvedLostResponse.length}, Approved found: ${approvedFoundResponse.length}');

      setState(() {
        _pendingLostItems = List<Map<String, dynamic>>.from(pendingLostResponse);
        _pendingFoundItems = List<Map<String, dynamic>>.from(pendingFoundResponse);
        _approvedLostItems = List<Map<String, dynamic>>.from(approvedLostResponse);
        _approvedFoundItems = List<Map<String, dynamic>>.from(approvedFoundResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load items: ${e.toString()}';
        _isLoading = false;
      });
      print('❌ Error loading items: $e');
    }
  }

  Future<void> _approveItem(Map<String, dynamic> item, String table) async {
    try {
      print('🔹 Starting approval process...');
      
      final supabase = Supabase.instance.client;
      final adminEmail = 'admin@hau.edu.ph';

      final updateData = {
        'status': 'approved',
        'reviewed_by': adminEmail,
        'reviewed_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from(table)
          .update(updateData)
          .eq('id', item['id']);

      print('✅ Update completed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Item approved! Now visible in ${table == 'reports_lost' ? 'Lost' : 'Found'} Items.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await _loadAllItems();
    } catch (e) {
      print('❌ Error approving item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectItem(Map<String, dynamic> item, String table) async {
    try {
      final supabase = Supabase.instance.client;
      final adminEmail = 'admin@hau.edu.ph';

      await supabase.from(table).update({
        'status': 'rejected',
        'reviewed_by': adminEmail,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', item['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      await _loadAllItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsClaimed(Map<String, dynamic> item, String table) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark as Claimed/Retrieved?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item: ${item['item'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Reporter: ${item['name'] ?? 'Unknown'}'),
              const SizedBox(height: 16),
              const Text(
                'This will remove the item from public view. The item has been claimed or retrieved by its owner.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF550000),
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Claimed'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      print('🔹 Marking item as claimed...');
      
      final supabase = Supabase.instance.client;
      final adminEmail = 'admin@hau.edu.ph';

      await supabase.from(table).update({
        'status': 'claimed',
        'reviewed_by': adminEmail,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', item['id']);

      print('✅ Item marked as claimed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Item marked as claimed and removed from public view'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      await _loadAllItems();
    } catch (e) {
      print('❌ Error marking as claimed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildMenu(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF550000),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icons/hau_logo.png',
            height: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.school, color: Colors.white, size: 40),
          ),
        ),
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllItems,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD200),
          labelColor: const Color(0xFFFFD200),
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(text: 'Pending Lost (${_pendingLostItems.length})'),
            Tab(text: 'Pending Found (${_pendingFoundItems.length})'),
            Tab(text: 'Approved Lost (${_approvedLostItems.length})'),
            Tab(text: 'Approved Found (${_approvedFoundItems.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllItems,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF550000),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildItemsList(_pendingLostItems, 'reports_lost', isPending: true),
                    _buildItemsList(_pendingFoundItems, 'reports_found', isPending: true),
                    _buildItemsList(_approvedLostItems, 'reports_lost', isPending: false),
                    _buildItemsList(_approvedFoundItems, 'reports_found', isPending: false),
                  ],
                ),
    );
  }

  Widget _buildItemsList(List<Map<String, dynamic>> items, String table, {required bool isPending}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending items to review' : 'No approved items yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              isPending ? 'All caught up! 🎉' : 'Approved items will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildItemCard(items[index], table, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, String table, {required bool isPending}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF550000),
                  child: Text(
                    (item['name'] ?? 'A').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Submitted: ${item['created_at'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.orange.shade100 : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Status: ${item['status'] ?? 'unknown'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isPending ? Colors.orange.shade900 : Colors.green.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (item['image_url'] != null && item['image_url'].toString().isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ),

            _buildDetailRow('Item:', item['item'] ?? 'Unknown'),
            _buildDetailRow('Location:', item['location'] ?? 'Unknown'),
            _buildDetailRow('Date:', item['date'] ?? 'Unknown'),
            _buildDetailRow('Description:', item['description'] ?? 'No description'),

            const SizedBox(height: 16),

            // Different buttons based on status
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveItem(item, table),
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectItem(item, table),
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () => _markAsClaimed(item, table),
                icon: const Icon(Icons.done_all, size: 20),
                label: const Text('Mark as Claimed/Retrieved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF550000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
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
              const Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, size: 50, color: Color(0xFF550000)),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _menuItem(Icons.dashboard, "Dashboard"),
              _menuItem(Icons.pending_actions, "Pending Reviews", onTap: () {
                _tabController.animateTo(0);
                Navigator.pop(context);
              }),
              _menuItem(Icons.check_circle, "Approved Items", onTap: () {
                _tabController.animateTo(2);
                Navigator.pop(context);
              }),
              _menuItem(Icons.block, "Rejected Items"),
              _menuItem(Icons.people, "Users"),
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
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}