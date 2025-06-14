import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> _statsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      // Load various analytics data
      final results = await Future.wait([
        _getOverviewStats(),
        _getBookingStats(),
        _getRevenueStats(),
        _getUserGrowthStats(),
      ]);

      setState(() {
        _statsData = {
          'overview': results[0],
          'bookings': results[1],
          'revenue': results[2],
          'userGrowth': results[3],
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getOverviewStats() async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);

    // Get user counts
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();
    final handymenSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'handyman')
        .get();
    final customersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();

    // Get booking counts
    final totalBookingsSnapshot = await FirebaseFirestore.instance.collection(
        'bookings').get();
    final completedBookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: 'completed')
        .get();

    // Get this month's bookings
    final thisMonthBookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where(
        'created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonth))
        .get();

    return {
      'totalUsers': usersSnapshot.docs.length,
      'totalHandymen': handymenSnapshot.docs.length,
      'totalCustomers': customersSnapshot.docs.length,
      'totalBookings': totalBookingsSnapshot.docs.length,
      'completedBookings': completedBookingsSnapshot.docs.length,
      'thisMonthBookings': thisMonthBookingsSnapshot.docs.length,
      'successRate': totalBookingsSnapshot.docs.isEmpty
          ? 0.0
          : (completedBookingsSnapshot.docs.length /
          totalBookingsSnapshot.docs.length * 100),
    };
  }

  Future<Map<String, dynamic>> _getBookingStats() async {
    final bookingsSnapshot = await FirebaseFirestore.instance.collection(
        'bookings').get();

    Map<String, int> statusCounts = {};
    Map<String, int> categoryCounts = {};

    for (var doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'unknown';
      final category = data['category'] as String? ?? 'other';

      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    return {
      'statusCounts': statusCounts,
      'categoryCounts': categoryCounts,
    };
  }

  Future<Map<String, dynamic>> _getRevenueStats() async {
    final completedBookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: 'completed')
        .get();

    double totalRevenue = 0;
    Map<String, double> monthlyRevenue = {};

    for (var doc in completedBookingsSnapshot.docs) {
      final data = doc.data();
      final amount = (data['total_amount'] as num?)?.toDouble() ?? 0;
      final createdAt = data['created_at'] as Timestamp?;

      totalRevenue += amount;

      if (createdAt != null) {
        final date = createdAt.toDate();
        final monthKey = '${date.year}-${date.month.toString().padLeft(
            2, '0')}';
        monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + amount;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'monthlyRevenue': monthlyRevenue,
    };
  }

  Future<Map<String, dynamic>> _getUserGrowthStats() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('created_at')
        .get();

    Map<String, int> monthlySignups = {};

    for (var doc in usersSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = data['created_at'] as Timestamp?;

      if (createdAt != null) {
        final date = createdAt.toDate();
        final monthKey = '${date.year}-${date.month.toString().padLeft(
            2, '0')}';
        monthlySignups[monthKey] = (monthlySignups[monthKey] ?? 0) + 1;
      }
    }

    return {
      'monthlySignups': monthlySignups,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4169E1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4169E1),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Bookings'),
            Tab(text: 'Revenue'),
            Tab(text: 'Users'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadAnalyticsData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildBookingsTab(),
          _buildRevenueTab(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final overview = _statsData['overview'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildStatCard(
                  'Total Users', '${overview['totalUsers'] ?? 0}', Icons.people,
                  Colors.blue),
              _buildStatCard(
                  'Handymen', '${overview['totalHandymen'] ?? 0}', Icons.build,
                  Colors.orange),
              _buildStatCard('Customers', '${overview['totalCustomers'] ?? 0}',
                  Icons.person, Colors.green),
              _buildStatCard(
                  'Total Bookings', '${overview['totalBookings'] ?? 0}',
                  Icons.calendar_today, Colors.purple),
              _buildStatCard(
                  'Completed', '${overview['completedBookings'] ?? 0}',
                  Icons.check_circle, Colors.teal),
              _buildStatCard('Success Rate',
                  '${(overview['successRate'] ?? 0).toStringAsFixed(1)}%',
                  Icons.trending_up, Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    final bookings = _statsData['bookings'] as Map<String, dynamic>? ?? {};
    final statusCounts = bookings['statusCounts'] as Map<String, int>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Booking Status Chart
          if (statusCounts.isNotEmpty) ...[
            const Text('Booking Status Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: statusCounts.entries.map((entry) {
                    final colors = [
                      Colors.blue,
                      Colors.orange,
                      Colors.green,
                      Colors.red,
                      Colors.purple
                    ];
                    final index = statusCounts.keys.toList().indexOf(entry.key);
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n${entry.value}',
                      color: colors[index % colors.length],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    final revenue = _statsData['revenue'] as Map<String, dynamic>? ?? {};
    final totalRevenue = revenue['totalRevenue'] as double? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Total Revenue Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                      Icons.attach_money, size: 48, color: Color(0xFF4169E1)),
                  const SizedBox(height: 8),
                  const Text('Total Revenue', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'OMR ${totalRevenue.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4169E1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final userGrowth = _statsData['userGrowth'] as Map<String, dynamic>? ?? {};
    final monthlySignups = userGrowth['monthlySignups'] as Map<String, int>? ??
        {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Growth Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Monthly Signups List
          if (monthlySignups.isNotEmpty) ...[
            const Text('Monthly Signups',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...monthlySignups.entries.map((entry) =>
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text(entry.key),
                    trailing: Text('${entry.value} users',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
