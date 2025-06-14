import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import '../services/admin_stats_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _recentBookings = [];
  List<Map<String, dynamic>> _topHandymen = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      // Load booking statistics
      Map<String, dynamic> stats = await BookingService.getBookingStatistics();

      // Load user statistics
      Map<String, dynamic> userStats = await _getUserStats();

      // Load recent bookings
      List<Map<String, dynamic>> recentBookings = await _getRecentBookings();

      // Load top handymen
      List<Map<String, dynamic>> topHandymen = await _getTopHandymen();

      setState(() {
        _analytics = {...stats, ...userStats};
        _recentBookings = recentBookings;
        _topHandymen = topHandymen;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getUserStats() async {
    QuerySnapshot allUsers = await FirebaseFirestore.instance
        .collection('users')
        .get();

    QuerySnapshot customers = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();

    QuerySnapshot handymen = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .get();

    QuerySnapshot verifiedHandymen = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .where('isVerified', isEqualTo: true)
        .get();

    QuerySnapshot pendingVerifications = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .where('verification_status', isEqualTo: 'pending')
        .get();

    return {
      'totalUsers': allUsers.docs.length,
      'totalCustomers': customers.docs.length,
      'totalHandymen': handymen.docs.length,
      'verifiedHandymen': verifiedHandymen.docs.length,
      'pendingVerifications': pendingVerifications.docs.length,
      'verificationRate': handymen.docs.isEmpty ? 0.0 :
      (verifiedHandymen.docs.length / handymen.docs.length) * 100,
    };
  }

  Future<List<Map<String, dynamic>>> _getRecentBookings() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    List<Map<String, dynamic>> bookings = [];
    for (var doc in snapshot.docs) {
      Map<String, dynamic> booking = doc.data() as Map<String, dynamic>;

      // Get user and handyman details
      if (booking['userId'] != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(booking['userId'])
            .get();
        if (userDoc.exists) {
          booking['customerName'] =
          (userDoc.data() as Map<String, dynamic>)['fullName'];
        }
      }

      if (booking['handymanId'] != null) {
        DocumentSnapshot handymanDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(booking['handymanId'])
            .get();
        if (handymanDoc.exists) {
          booking['handymanName'] =
          (handymanDoc.data() as Map<String, dynamic>)['fullName'];
        }
      }

      booking['id'] = doc.id;
      bookings.add(booking);
    }

    return bookings;
  }

  Future<List<Map<String, dynamic>>> _getTopHandymen() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'service_provider')
        .where('isVerified', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(5)
        .get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Analytics & Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildRecentBookings(),
            const SizedBox(height: 24),
            _buildTopHandymen(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),

        // First row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Bookings',
                value: '${_analytics['totalBookings'] ?? 0}',
                icon: Icons.book_online,
                color: const Color(0xFF3498DB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Revenue',
                value: AdminStatsService.formatCurrency(
                    _analytics['totalRevenue']?.toDouble() ?? 0.0),
                icon: Icons.monetization_on,
                color: const Color(0xFF2ECC71),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Second row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Users',
                value: '${_analytics['totalUsers'] ?? 0}',
                icon: Icons.people,
                color: const Color(0xFF9B59B6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Handymen',
                value: '${_analytics['totalHandymen'] ?? 0}',
                icon: Icons.build,
                color: const Color(0xFFE67E22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Third row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Pending',
                value: '${_analytics['pendingBookings'] ?? 0}',
                icon: Icons.pending,
                color: const Color(0xFFF39C12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Completed',
                value: '${_analytics['completedBookings'] ?? 0}',
                icon: Icons.done_all,
                color: const Color(0xFF27AE60),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to all bookings
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_recentBookings.isEmpty)
          const Center(
            child: Text(
              'No recent bookings',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._recentBookings.take(5).map((booking) =>
              _buildBookingCard(booking)).toList(),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    Color statusColor = _getStatusColor(booking['status'] ?? 'unknown');

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking['category'] ?? 'Service',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking['status'] ?? 'unknown',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Color(0xFF7F8C8D)),
              const SizedBox(width: 4),
              Text(
                booking['customerName'] ?? 'Unknown Customer',
                style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.build, size: 16, color: Color(0xFF7F8C8D)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  booking['handymanName'] ?? 'No handyman assigned',
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF7F8C8D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                  Icons.calendar_today, size: 16, color: Color(0xFF7F8C8D)),
              const SizedBox(width: 4),
              Text(
                _formatDate(booking['scheduledDate']),
                style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
              ),
              const Spacer(),
              Text(
                AdminStatsService.formatCurrency(
                    booking['estimatedCost']?.toDouble() ?? 0.0),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopHandymen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Handymen',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),

        if (_topHandymen.isEmpty)
          const Center(
            child: Text(
              'No handymen data available',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._topHandymen
              .map((handyman) => _buildHandymanCard(handyman))
              .toList(),
      ],
    );
  }

  Widget _buildHandymanCard(Map<String, dynamic> handyman) {
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
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF4169E1),
            backgroundImage: handyman['profileImage'] != null
                ? NetworkImage(handyman['profileImage'])
                : null,
            child: handyman['profileImage'] == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  handyman['fullName'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  handyman['primaryCategory'] ?? 'General',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${handyman['rating'] ??
                          0.0} (${handyman['reviewCount'] ?? 0} reviews)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Verified',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'No date';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Invalid date';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
