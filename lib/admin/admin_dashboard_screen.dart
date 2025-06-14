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
import 'package:cloud_firestore/cloud_firestore.dart';

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
      QuerySnapshot recentUsers = await FirebaseFirestore.instance
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
          'time': _getTimeAgo(userData['createdAt'] as Timestamp?),
          'color': Colors.green,
        });
      }

      // Get recent verifications
      QuerySnapshot recentVerifications = await FirebaseFirestore.instance
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
          'time': _getTimeAgo(userData['verifiedAt'] as Timestamp?),
          'color': const Color(0xFF4169E1),
        });
      }

      // Get recent bookings
      QuerySnapshot recentBookings = await FirebaseFirestore.instance
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
          'time': _getTimeAgo(bookingData['created_at'] as Timestamp?),
          'color': Colors.orange,
        });
      }

      // Get recent completed payments
      QuerySnapshot recentPayments = await FirebaseFirestore.instance
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
          'time': _getTimeAgo(bookingData['completed_at'] as Timestamp?),
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

  String _getTimeAgo(Timestamp? timestamp) {
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
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    title: 'Total Users',
                    value: '${_dashboardStats['totalUsers'] ?? 0}',
                    icon: Icons.people,
                    color: const Color(0xFF3498DB),
                    change: AdminStatsService.formatGrowth(
                        _dashboardStats['userGrowth'] ?? 0.0),
                  ),
                  _buildStatCard(
                    title: 'Verified Providers',
                    value: '${_dashboardStats['verifiedHandymen'] ?? 0}',
                    icon: Icons.verified,
                    color: const Color(0xFF2ECC71),
                    change: AdminStatsService.formatPercentage(
                        _dashboardStats['verificationRate'] ?? 0.0),
                  ),
                  _buildStatCard(
                    title: 'Active Bookings',
                    value: '${_dashboardStats['activeBookings'] ?? 0}',
                    icon: Icons.work,
                    color: const Color(0xFFE67E22),
                    change: AdminStatsService.formatGrowth(
                        _dashboardStats['bookingGrowth'] ?? 0.0),
                  ),
                  _buildStatCard(
                    title: 'Total Revenue',
                    value: AdminStatsService.formatCurrency(
                        _dashboardStats['totalRevenue']?.toDouble() ?? 0.0),
                    icon: Icons.attach_money,
                    color: const Color(0xFF9B59B6),
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
                childAspectRatio: 1.2,
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
                    change: AdminStatsService.formatPercentage(
                        _dashboardStats['completionRate'] ?? 0.0),
                  ),
                  _buildStatCard(
                    title: 'Service Reviews',
                    value: '${_dashboardStats['totalReviews'] ?? 0}',
                    icon: Icons.star,
                    color: const Color(0xFFE74C3C),
                    change: '${(_dashboardStats['averageRating'] ?? 0.0)
                        .toStringAsFixed(1)} avg',
                  ),
                  _buildStatCard(
                    title: 'Platform Commission',
                    value: AdminStatsService.formatCurrency(
                        _dashboardStats['totalCommission']?.toDouble() ?? 0.0),
                    icon: Icons.account_balance,
                    color: const Color(0xFF8E44AD),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: growthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: growthColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
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

class SystemSettings extends StatelessWidget {
  const SystemSettings({super.key});

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
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 64,
              color: Color(0xFF7F8C8D),
            ),
            SizedBox(height: 16),
            Text(
              'System Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Configure system-wide settings and preferences',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
