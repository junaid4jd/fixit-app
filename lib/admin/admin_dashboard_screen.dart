import 'package:flutter/material.dart';
import 'admin_analytics_screen.dart';
import 'customer_management_screen.dart';
import 'handyman_management_screen.dart';
import 'category_management_screen.dart';
import 'cities_management_screen.dart';
import 'payment_commission_screen.dart';
import 'reviews_moderation_screen.dart';
import 'reports_analytics_screen.dart';
import 'content_management_screen.dart';
import 'service_approval_screen.dart';
import '../services/admin_stats_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AdminOverview(onTabChange: _handleTabChange),
      const CustomerManagementScreen(),
      const HandymanManagementScreen(),
      const SystemSettings(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF4169E1),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.engineering),
            label: 'Providers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class AdminOverview extends StatefulWidget {
  final Function(int) onTabChange;

  const AdminOverview({super.key, required this.onTabChange});

  @override
  State<AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<AdminOverview> {
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;

  Future<void> _createTestServiceProviders() async {
    try {
      print('🔧 Creating test service providers...');

      // First, let's check what's currently in the database
      QuerySnapshot existingUsers = await firestore.FirebaseFirestore.instance
          .collection('users').get();
      print('📊 Current users in database: ${existingUsers.docs.length}');

      for (var doc in existingUsers.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print(
            '👤 Existing user: ${data['fullName']} - role: ${data['role']} - verified: ${data['isVerified']}');
      }

      // Create test service providers with different verification statuses
      final testProviders = [
        {
          'fullName': 'Ahmed Al-Rashid',
          'email': 'ahmed.plumber@example.com',
          'role': 'service_provider',
          'isVerified': true,
          'verification_status': 'approved',
          'createdAt': firestore.FieldValue.serverTimestamp(),
          'verifiedAt': firestore.FieldValue.serverTimestamp(),
          'primaryCategory': 'Plumbing',
          'services': ['Plumbing', 'Pipe Repair'],
          'phoneNumber': '+968 9876 5432',
          'city': 'Muscat',
          'averageRating': 4.5,
          'totalReviews': 12,
          'isActive': true,
        },
        {
          'fullName': 'Khalid Al-Mansouri',
          'email': 'khalid.electric@example.com',
          'role': 'service_provider',
          'isVerified': true,
          'verification_status': 'approved',
          'createdAt': firestore.FieldValue.serverTimestamp(),
          'verifiedAt': firestore.FieldValue.serverTimestamp(),
          'primaryCategory': 'Electrical',
          'services': ['Electrical', 'Wiring'],
          'phoneNumber': '+968 9876 5433',
          'city': 'Muscat',
          'averageRating': 4.8,
          'totalReviews': 20,
          'isActive': true,
        },
        {
          'fullName': 'Saeed Al-Balushi',
          'email': 'saeed.ac@example.com',
          'role': 'service_provider',
          'isVerified': false,
          'verification_status': 'pending',
          'createdAt': firestore.FieldValue.serverTimestamp(),
          'primaryCategory': 'AC Repair',
          'services': ['AC Repair', 'HVAC'],
          'phoneNumber': '+968 9876 5434',
          'city': 'Salalah',
          'averageRating': 0.0,
          'totalReviews': 0,
          'isActive': true,
        },
        {
          'fullName': 'Omar Al-Hinai',
          'email': 'omar.carpenter@example.com',
          'role': 'service_provider',
          'isVerified': false,
          'verification_status': 'pending',
          'createdAt': firestore.FieldValue.serverTimestamp(),
          'primaryCategory': 'Carpentry',
          'services': ['Carpentry', 'Furniture Repair'],
          'phoneNumber': '+968 9876 5435',
          'city': 'Nizwa',
          'averageRating': 0.0,
          'totalReviews': 0,
          'isActive': true,
        },
        {
          'fullName': 'Hassan Al-Kindi',
          'email': 'hassan.painter@example.com',
          'role': 'service_provider',
          'isVerified': true,
          'verification_status': 'approved',
          'createdAt': firestore.FieldValue.serverTimestamp(),
          'verifiedAt': firestore.FieldValue.serverTimestamp(),
          'primaryCategory': 'Painting',
          'services': ['Painting', 'Wall Decoration'],
          'phoneNumber': '+968 9876 5436',
          'city': 'Sohar',
          'averageRating': 4.2,
          'totalReviews': 8,
          'isActive': true,
        }
      ];

      for (int i = 0; i < testProviders.length; i++) {
        DocumentReference docRef = await firestore.FirebaseFirestore.instance
            .collection('users').add(testProviders[i]);
        print('✅ Created test provider ${i +
            1}: ${testProviders[i]['fullName']} with ID: ${docRef.id}');

        // Immediately verify it was created
        DocumentSnapshot verifyDoc = await docRef.get();
        if (verifyDoc.exists) {
          var verifyData = verifyDoc.data() as Map<String, dynamic>;
          print(
              '✅ Verified creation: ${verifyData['fullName']} - role: ${verifyData['role']} - verified: ${verifyData['isVerified']}');
        }
      }

      // Also create some test users (customers)
      final testUsers = [
        {
          'fullName': 'Fatima Al-Zahra',
          'email': 'fatima.customer@example.com',
          'role': 'user',
          'isVerified': true,
          'createdAt': firestore.FieldValue.serverTimestamp(),
          'phoneNumber': '+968 9111 1111',
          'city': 'Muscat',
          'totalBookings': 3,
        },
        {
          'fullName': 'Mohammed Al-Said',
          'email': 'mohammed.customer@example.com',
          'role': 'user',
          'isVerified': true,
          'createdAt': firestore.FieldValue.serverTimestamp(),
          'phoneNumber': '+968 9222 2222',
          'city': 'Muscat',
          'totalBookings': 1,
        }
      ];

      for (int i = 0; i < testUsers.length; i++) {
        DocumentReference docRef = await firestore.FirebaseFirestore.instance
            .collection('users').add(testUsers[i]);
        print('✅ Created test user ${i +
            1}: ${testUsers[i]['fullName']} with ID: ${docRef.id}');
      }

      print('🎉 All test data created successfully!');

      // Wait a moment for Firestore to sync
      await Future.delayed(Duration(seconds: 2));

      // Now check the database again
      QuerySnapshot afterUsers = await firestore.FirebaseFirestore.instance
          .collection('users').get();
      print('📊 Users after creation: ${afterUsers.docs.length}');

      for (var doc in afterUsers.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print(
            '👤 User after creation: ${data['fullName']} - role: ${data['role']} - verified: ${data['isVerified']}');
      }

      // Manually trigger stats refresh
      print('🔄 Refreshing dashboard stats...');
      await _loadDashboardData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Test service providers and users created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating test providers: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating test providers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testStatsDirectly() async {
    try {
      print('📊 Testing stats service directly...');
      Map<String, dynamic> stats = await AdminStatsService.getDashboardStats();
      print('📊 Raw stats from service: $stats');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Stats test completed. See console for details.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error testing stats service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error testing stats service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Load dashboard statistics
      Map<String, dynamic> stats = await AdminStatsService.getDashboardStats();

      // Load recent activities
      List<Map<String, dynamic>> activities = await _loadRecentActivities();

      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _recentActivities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentActivities() async {
    List<Map<String, dynamic>> activities = [];

    try {
      // Get recent user registrations
      QuerySnapshot recentUsers = await firestore.FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      for (var doc in recentUsers.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        activities.add({
          'icon': Icons.person_add,
          'title': 'New User Registration',
          'subtitle': '${userData['fullName'] ?? 'User'} joined the platform',
          'time': _getTimeAgo(userData['createdAt'] as firestore.Timestamp?),
          'color': Colors.green,
        });
      }

      // Get recent verifications
      QuerySnapshot recentVerifications = await firestore.FirebaseFirestore
          .instance
          .collection('users')
          .where('role', isEqualTo: 'service_provider')
          .where('isVerified', isEqualTo: true)
          .orderBy('verifiedAt', descending: true)
          .limit(2)
          .get();

      for (var doc in recentVerifications.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        activities.add({
          'icon': Icons.engineering,
          'title': 'Service Provider Verified',
          'subtitle': '${userData['fullName'] ??
              'Provider'} verified successfully',
          'time': _getTimeAgo(userData['verifiedAt'] as firestore.Timestamp?),
          'color': const Color(0xFF4169E1),
        });
      }

      // Get recent bookings
      QuerySnapshot recentBookings = await firestore.FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('created_at', descending: true)
          .limit(2)
          .get();

      for (var doc in recentBookings.docs) {
        Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;
        activities.add({
          'icon': Icons.work,
          'title': 'New Service Request',
          'subtitle': '${bookingData['category'] ?? 'Service'} booking created',
          'time': _getTimeAgo(
              bookingData['created_at'] as firestore.Timestamp?),
          'color': Colors.orange,
        });
      }

      // Get recent completed payments
      QuerySnapshot recentPayments = await firestore.FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .orderBy('completed_at', descending: true)
          .limit(2)
          .get();

      for (var doc in recentPayments.docs) {
        Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;
        double amount = bookingData['final_cost']?.toDouble() ??
            bookingData['estimated_cost']?.toDouble() ?? 0.0;
        activities.add({
          'icon': Icons.payment,
          'title': 'Payment Processed',
          'subtitle': 'Payment of ${amount.toStringAsFixed(3)} OMR completed',
          'time': _getTimeAgo(
              bookingData['completed_at'] as firestore.Timestamp?),
          'color': Colors.green,
        });
      }

      // Sort activities by time (most recent first)
      activities.sort((a, b) {
        // This is a simple sort - in a real app you'd sort by actual timestamp
        return 0;
      });

      return activities.take(5).toList();
    } catch (e) {
      debugPrint('Error loading recent activities: $e');
      return [];
    }
  }

  String _getTimeAgo(firestore.Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1
          ? 's'
          : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1
          ? 's'
          : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Show confirmation dialog
      bool? confirmLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          );
        },
      );

      if (confirmLogout == true) {
        final authService = AuthService();
        await authService.signOut();

        if (context.mounted) {
          // Navigate back to auth wrapper/role selection
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/auth',
                (route) => false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF7F8C8D),
            ),
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(
              Icons.logout,
              color: Color(0xFF7F8C8D),
            ),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4169E1),
                      Color(0xFF3A5FCD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, Admin!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage Fixit platform efficiently',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Platform Stats
              const Text(
                'Platform Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(height: 15),

              // Main Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
                // Increased from 1.2 to give more height
                children: [
                  _buildStatCard(
                    title: 'Total Users',
                    value: '${_dashboardStats['totalUsers'] ?? 0}',
                    icon: Icons.people,
                    color: const Color(0xFF3498DB),
                    // Blue
                    change: AdminStatsService.formatGrowth(
                        _dashboardStats['userGrowth'] ?? 0.0),
                  ),
                  _buildStatCard(
                    title: 'Verified Providers',
                    value: '${_dashboardStats['verifiedHandymen'] ?? 0}',
                    icon: Icons.verified,
                    color: const Color(0xFF2ECC71),
                    // Green
                    change: AdminStatsService.formatPercentage(
                        _dashboardStats['verificationRate'] ?? 0.0),
                  ),
                  _buildStatCard(
                    title: 'Active Bookings',
                    value: '${_dashboardStats['activeBookings'] ?? 0}',
                    icon: Icons.work,
                    color: const Color(0xFFE67E22),
                    // Orange
                    change: AdminStatsService.formatGrowth(
                        _dashboardStats['bookingGrowth'] ?? 0.0),
                  ),
                  _buildStatCard(
                    title: 'Total Revenue',
                    value: AdminStatsService.formatCurrency(
                        _dashboardStats['totalRevenue']?.toDouble() ?? 0.0),
                    icon: Icons.attach_money,
                    color: const Color(0xFF9B59B6),
                    // Purple
                    change: AdminStatsService.formatGrowth(
                        _dashboardStats['revenueGrowth'] ?? 0.0),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Additional Statistics Section
              const Text(
                'Detailed Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(height: 15),

              // Additional Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
                // Increased from 1.2 to give more height
                children: [
                  _buildStatCard(
                    title: 'Pending Approvals',
                    value: '${_dashboardStats['pendingVerifications'] ?? 0}',
                    icon: Icons.pending_actions,
                    color: const Color(0xFFF39C12),
                    change: '${_dashboardStats['pendingServices'] ??
                        0} services',
                  ),
                  _buildStatCard(
                    title: 'Completed Jobs',
                    value: '${_dashboardStats['completedBookings'] ?? 0}',
                    icon: Icons.check_circle,
                    color: const Color(0xFF27AE60),
                    // Emerald
                    change: AdminStatsService.formatPercentage(
                        _dashboardStats['completionRate'] ?? 0.0),
                  ),
                  _buildStatCard(
                    title: 'Service Reviews',
                    value: '${_dashboardStats['totalReviews'] ?? 0}',
                    icon: Icons.star,
                    color: const Color(0xFFE74C3C),
                    // Red
                    change: '${(_dashboardStats['averageRating'] ?? 0.0)
                        .toStringAsFixed(1)} avg',
                  ),
                  _buildStatCard(
                    title: 'Platform Commission',
                    value: AdminStatsService.formatCurrency(
                        _dashboardStats['totalCommission']?.toDouble() ?? 0.0),
                    icon: Icons.account_balance,
                    color: const Color(0xFF8E44AD),
                    // Deep Purple
                    change: AdminStatsService.formatCurrency(
                        _dashboardStats['averageOrderValue']?.toDouble() ??
                            0.0),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Service Provider Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Provider Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total Providers',
                          '${_dashboardStats['totalHandymen'] ?? 0}',
                          Colors.blue,
                        ),
                        _buildSummaryItem(
                          'Verified',
                          '${_dashboardStats['verifiedHandymen'] ?? 0}',
                          Colors.green,
                        ),
                        _buildSummaryItem(
                          'Unverified',
                          '${_dashboardStats['unverifiedHandymen'] ?? 0}',
                          Colors.orange,
                        ),
                        _buildSummaryItem(
                          'Pending',
                          '${_dashboardStats['pendingVerifications'] ?? 0}',
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Recent Activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(height: 15),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivities.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> activity = _recentActivities[index];
                    return _buildActivityItem(
                      icon: activity['icon'] as IconData,
                      title: activity['title'] as String,
                      subtitle: activity['subtitle'] as String,
                      time: activity['time'] as String,
                      color: activity['color'] as Color,
                    );
                  },
                ),

              const SizedBox(height: 30),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(height: 15),

              // Add debug button for test data
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                child: ElevatedButton.icon(
                  onPressed: _createTestServiceProviders,
                  icon: const Icon(Icons.add_business),
                  label: const Text('Create Test Service Providers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Add debug button to test stats directly
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                child: ElevatedButton.icon(
                  onPressed: _testStatsDirectly,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Test Stats Directly'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.people_alt,
                      title: 'Manage Users',
                      onTap: () => widget.onTabChange(1),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.verified_user,
                      title: 'Verify Providers',
                      onTap: () => widget.onTabChange(2),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.analytics,
                      title: 'View Reports',
                      onTap: () =>
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (
                                  context) => const AdminAnalyticsScreen(),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.support_agent,
                      title: 'Support Tickets',
                      onTap: () =>
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (
                                  context) => const ReviewsModerationScreen(),
                            ),
                          ),
                    ),
                  ),
                ],
              ),

              // Management Section
              const SizedBox(height: 30),
              const Text(
                'Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),

              _buildManagementCard(
                title: 'Service Approvals',
                subtitle: 'Review and approve handyman services',
                icon: Icons.approval,
                color: const Color(0xFF8E44AD),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ServiceApprovalScreen()),
                    ),
              ),
              const SizedBox(height: 12),

              _buildManagementCard(
                title: 'Customer Management',
                subtitle: 'View, edit, or delete customer accounts',
                icon: Icons.people,
                color: const Color(0xFF3498DB),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (
                          context) => const CustomerManagementScreen()),
                    ),
              ),
              const SizedBox(height: 12),

              _buildManagementCard(
                title: 'Handyman Management',
                subtitle: 'Approve, suspend, or delete handyman accounts',
                icon: Icons.build,
                color: const Color(0xFFE67E22),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (
                          context) => const HandymanManagementScreen()),
                    ),
              ),
              const SizedBox(height: 12),

              _buildManagementCard(
                title: 'Service Categories',
                subtitle: 'Add, edit, or remove service categories',
                icon: Icons.category,
                color: const Color(0xFF9B59B6),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (
                          context) => const CategoryManagementScreen()),
                    ),
              ),
              const SizedBox(height: 12),

              _buildManagementCard(
                title: 'Cities Management',
                subtitle: 'Add, edit, or remove cities',
                icon: Icons.location_city,
                color: const Color(0xFF4169E1),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CitiesManagementScreen()),
                    ),
              ),
              const SizedBox(height: 12),

              _buildManagementCard(
                title: 'Payment & Commission',
                subtitle: 'Monitor transactions and set commission rates',
                icon: Icons.payment,
                color: const Color(0xFF2ECC71),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (
                          context) => const PaymentCommissionScreen()),
                    ),
              ),
              const SizedBox(height: 12),

              _buildManagementCard(
                title: 'Reviews Moderation',
                subtitle: 'View and moderate customer reviews',
                icon: Icons.rate_review,
                color: const Color(0xFFF39C12),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (
                          context) => const ReviewsModerationScreen()),
                    ),
              ),
              const SizedBox(height: 12),

              _buildManagementCard(
                title: 'Content Management',
                subtitle: 'Edit FAQ, Terms, Privacy Policy',
                icon: Icons.content_paste,
                color: const Color(0xFF34495E),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (
                          context) => const ContentManagementScreen()),
                    ),
              ),

              // Reports & Analytics Section
              const SizedBox(height: 30),
              const Text(
                'Reports & Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),

              _buildDashboardCard(
                title: 'Analytics Dashboard',
                subtitle: 'Detailed analytics and business insights',
                icon: Icons.analytics,
                color: const Color(0xFF9B59B6),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminAnalyticsScreen()),
                    ),
              ),
              const SizedBox(height: 12),

              _buildDashboardCard(
                title: 'Reports & Export',
                subtitle: 'Generate and export detailed reports',
                icon: Icons.assessment,
                color: const Color(0xFF27AE60),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReportsAnalyticsScreen()),
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
  }) {
    // Determine growth color based on value
    Color growthColor;
    if (change.startsWith('+')) {
      growthColor = Colors.green;
    } else if (change.startsWith('-')) {
      growthColor = Colors.red;
    } else {
      growthColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF95A5A6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4169E1),
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7F8C8D),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF7F8C8D),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class SystemSettings extends StatefulWidget {
  const SystemSettings({super.key});

  @override
  State<SystemSettings> createState() => _SystemSettingsState();
}

class _SystemSettingsState extends State<SystemSettings> {
  // Settings state variables
  bool _maintenanceMode = false;
  bool _newUserRegistration = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _autoApproveBookings = false;
  bool _requireIdVerification = true;
  bool _allowGuestBookings = false;

  double _platformCommissionRate = 5.0;
  double _cancellationFee = 2.5;
  int _bookingTimeoutMinutes = 30;
  int _maxBookingsPerDay = 10;

  String _defaultCurrency = 'OMR';
  String _defaultLanguage = 'English';
  String _supportEmail = 'support@fixitoman.com';
  String _supportPhone = '+968 2234 5678';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from Firestore
    try {
      DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_config')
          .get();

      if (settingsDoc.exists) {
        Map<String, dynamic> data = settingsDoc.data() as Map<String, dynamic>;
        setState(() {
          _maintenanceMode = data['maintenanceMode'] ?? false;
          _newUserRegistration = data['newUserRegistration'] ?? true;
          _emailNotifications = data['emailNotifications'] ?? true;
          _pushNotifications = data['pushNotifications'] ?? true;
          _smsNotifications = data['smsNotifications'] ?? false;
          _autoApproveBookings = data['autoApproveBookings'] ?? false;
          _requireIdVerification = data['requireIdVerification'] ?? true;
          _allowGuestBookings = data['allowGuestBookings'] ?? false;
          _platformCommissionRate =
              data['platformCommissionRate']?.toDouble() ?? 5.0;
          _cancellationFee = data['cancellationFee']?.toDouble() ?? 2.5;
          _bookingTimeoutMinutes = data['bookingTimeoutMinutes'] ?? 30;
          _maxBookingsPerDay = data['maxBookingsPerDay'] ?? 10;
          _defaultCurrency = data['defaultCurrency'] ?? 'OMR';
          _defaultLanguage = data['defaultLanguage'] ?? 'English';
          _supportEmail = data['supportEmail'] ?? 'support@fixitoman.com';
          _supportPhone = data['supportPhone'] ?? '+968 2234 5678';
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_config')
          .set({
        'maintenanceMode': _maintenanceMode,
        'newUserRegistration': _newUserRegistration,
        'emailNotifications': _emailNotifications,
        'pushNotifications': _pushNotifications,
        'smsNotifications': _smsNotifications,
        'autoApproveBookings': _autoApproveBookings,
        'requireIdVerification': _requireIdVerification,
        'allowGuestBookings': _allowGuestBookings,
        'platformCommissionRate': _platformCommissionRate,
        'cancellationFee': _cancellationFee,
        'bookingTimeoutMinutes': _bookingTimeoutMinutes,
        'maxBookingsPerDay': _maxBookingsPerDay,
        'defaultCurrency': _defaultCurrency,
        'defaultLanguage': _defaultLanguage,
        'supportEmail': _supportEmail,
        'supportPhone': _supportPhone,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'System Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4169E1),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Status Section
            _buildSectionCard(
              title: 'App Status',
              icon: Icons.power_settings_new,
              color: const Color(0xFFE74C3C),
              children: [
                _buildSwitchTile(
                  title: 'Maintenance Mode',
                  subtitle: 'Temporarily disable app for maintenance',
                  value: _maintenanceMode,
                  onChanged: (value) {
                    setState(() {
                      _maintenanceMode = value;
                    });
                  },
                  icon: Icons.build_circle,
                  color: Colors.orange,
                ),
                _buildSwitchTile(
                  title: 'New User Registration',
                  subtitle: 'Allow new users to create accounts',
                  value: _newUserRegistration,
                  onChanged: (value) {
                    setState(() {
                      _newUserRegistration = value;
                    });
                  },
                  icon: Icons.person_add,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Notifications Section
            _buildSectionCard(
              title: 'Notifications',
              icon: Icons.notifications,
              color: const Color(0xFF3498DB),
              children: [
                _buildSwitchTile(
                  title: 'Email Notifications',
                  subtitle: 'Send notifications via email',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                  icon: Icons.email,
                  color: Colors.blue,
                ),
                _buildSwitchTile(
                  title: 'Push Notifications',
                  subtitle: 'Send push notifications to mobile devices',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                  icon: Icons.phone_android,
                  color: Colors.green,
                ),
                _buildSwitchTile(
                  title: 'SMS Notifications',
                  subtitle: 'Send notifications via SMS',
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() {
                      _smsNotifications = value;
                    });
                  },
                  icon: Icons.sms,
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Booking Settings Section
            _buildSectionCard(
              title: 'Booking Settings',
              icon: Icons.book_online,
              color: const Color(0xFF9B59B6),
              children: [
                _buildSwitchTile(
                  title: 'Auto-approve Bookings',
                  subtitle: 'Automatically approve new booking requests',
                  value: _autoApproveBookings,
                  onChanged: (value) {
                    setState(() {
                      _autoApproveBookings = value;
                    });
                  },
                  icon: Icons.auto_mode,
                  color: Colors.purple,
                ),
                _buildSwitchTile(
                  title: 'Require ID Verification',
                  subtitle: 'Require service providers to verify their identity',
                  value: _requireIdVerification,
                  onChanged: (value) {
                    setState(() {
                      _requireIdVerification = value;
                    });
                  },
                  icon: Icons.verified_user,
                  color: Colors.green,
                ),
                _buildSwitchTile(
                  title: 'Allow Guest Bookings',
                  subtitle: 'Allow users to book services without registration',
                  value: _allowGuestBookings,
                  onChanged: (value) {
                    setState(() {
                      _allowGuestBookings = value;
                    });
                  },
                  icon: Icons.person_outline,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                _buildSliderTile(
                  title: 'Booking Timeout (Minutes)',
                  subtitle: 'Time before pending bookings expire',
                  value: _bookingTimeoutMinutes.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 21,
                  onChanged: (value) {
                    setState(() {
                      _bookingTimeoutMinutes = value.round();
                    });
                  },
                  icon: Icons.timer,
                  color: Colors.orange,
                ),
                _buildSliderTile(
                  title: 'Max Bookings Per Day',
                  subtitle: 'Maximum bookings per user per day',
                  value: _maxBookingsPerDay.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  onChanged: (value) {
                    setState(() {
                      _maxBookingsPerDay = value.round();
                    });
                  },
                  icon: Icons.today,
                  color: Colors.blue,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Financial Settings Section
            _buildSectionCard(
              title: 'Financial Settings',
              icon: Icons.attach_money,
              color: const Color(0xFF2ECC71),
              children: [
                _buildSliderTile(
                  title: 'Platform Commission Rate (%)',
                  subtitle: 'Commission rate charged on completed bookings',
                  value: _platformCommissionRate,
                  min: 0,
                  max: 20,
                  divisions: 40,
                  onChanged: (value) {
                    setState(() {
                      _platformCommissionRate = value;
                    });
                  },
                  icon: Icons.percent,
                  color: Colors.green,
                ),
                _buildSliderTile(
                  title: 'Cancellation Fee (OMR)',
                  subtitle: 'Fee charged for booking cancellations',
                  value: _cancellationFee,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _cancellationFee = value;
                    });
                  },
                  icon: Icons.money_off,
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // General Settings Section
            _buildSectionCard(
              title: 'General Settings',
              icon: Icons.settings,
              color: const Color(0xFF34495E),
              children: [
                _buildDropdownTile(
                  title: 'Default Currency',
                  subtitle: 'Primary currency for the platform',
                  value: _defaultCurrency,
                  items: ['OMR', 'USD', 'EUR', 'GBP', 'AED'],
                  onChanged: (value) {
                    setState(() {
                      _defaultCurrency = value!;
                    });
                  },
                  icon: Icons.currency_exchange,
                  color: Colors.green,
                ),
                _buildDropdownTile(
                  title: 'Default Language',
                  subtitle: 'Primary language for the platform',
                  value: _defaultLanguage,
                  items: ['English', 'Arabic', 'Hindi', 'Urdu'],
                  onChanged: (value) {
                    setState(() {
                      _defaultLanguage = value!;
                    });
                  },
                  icon: Icons.language,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildTextFieldTile(
                  title: 'Support Email',
                  subtitle: 'Customer support email address',
                  value: _supportEmail,
                  onChanged: (value) {
                    setState(() {
                      _supportEmail = value;
                    });
                  },
                  icon: Icons.support_agent,
                  color: Colors.purple,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextFieldTile(
                  title: 'Support Phone',
                  subtitle: 'Customer support phone number',
                  value: _supportPhone,
                  onChanged: (value) {
                    setState(() {
                      _supportPhone = value;
                    });
                  },
                  icon: Icons.phone,
                  color: Colors.orange,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Save All Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadSettings,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Changes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7F8C8D),
                      side: const BorderSide(color: Color(0xFF7F8C8D)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon,
        color: color,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF7F8C8D),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4169E1),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: const Color(0xFF4169E1),
          inactiveColor: Colors.grey[300],
          label: value.toStringAsFixed(1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Current value: ${value.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF7F8C8D),
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextFieldTile({
    required String title,
    required String subtitle,
    required String value,
    required ValueChanged<String> onChanged,
    required IconData icon,
    required Color color,
    required TextInputType keyboardType,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF7F8C8D),
        ),
      ),
      trailing: SizedBox(
        width: 150,
        child: TextField(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
    );
  }
}
