import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../role_selection_screen.dart';
import 'service_requests_page.dart';
import 'service_provider_schedule_page.dart';
import 'service_provider_profile_page.dart';
import 'service_provider_reviews_screen.dart';
import 'debug_reviews_screen.dart';
import 'my_services_screen.dart';

class ServiceProviderHomeScreen extends StatefulWidget {
  const ServiceProviderHomeScreen({super.key});

  @override
  State<ServiceProviderHomeScreen> createState() =>
      _ServiceProviderHomeScreenState();
}

class _ServiceProviderHomeScreenState extends State<ServiceProviderHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ServiceProviderDashboard(),
    const ServiceRequestsPage(),
    const MyServicesScreen(),
    const ServiceProviderSchedulePage(),
    const ServiceProviderProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle),
            label: 'My Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}

class ServiceProviderDashboard extends StatefulWidget {
  const ServiceProviderDashboard({super.key});

  @override
  State<ServiceProviderDashboard> createState() =>
      _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends State<ServiceProviderDashboard> {
  final AuthService _authService = AuthService();

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentBookings = [];
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (_authService.currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user data
      final userData = await _authService.getUserData(
          _authService.currentUserId!);

      // Get handyman stats
      final stats = await _authService.getHandymanStats(
          _authService.currentUserId!);

      // Get recent bookings
      final recentBookings = await _authService.getRecentHandymanBookings(
          _authService.currentUserId!);

      if (mounted) {
        setState(() {
          _userData = userData;
          _stats = stats;
          _recentBookings = recentBookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getVerificationStatus() {
    if (_userData == null) return 'Pending';

    final isVerified = _userData!['isVerified'] ?? false;
    final verificationStatus = _userData!['verification_status'] ?? 'pending';

    if (isVerified) {
      return 'Verified';
    } else if (verificationStatus == 'rejected') {
      return 'Rejected';
    } else if (verificationStatus == 'pending') {
      return 'Pending';
    } else {
      return 'Under Review';
    }
  }

  Color _getVerificationColor() {
    final status = _getVerificationStatus();
    switch (status) {
      case 'Verified':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
      case 'Under Review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatScheduledTime(Map<String, dynamic> booking) {
    try {
      if (booking['scheduled_date'] != null &&
          booking['scheduled_time'] != null) {
        final scheduledDate = (booking['scheduled_date'] as Timestamp).toDate();
        final scheduledTime = booking['scheduled_time'] as String;

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final bookingDay = DateTime(
            scheduledDate.year, scheduledDate.month, scheduledDate.day);

        if (bookingDay == today) {
          return '$scheduledTime Today';
        } else if (bookingDay == tomorrow) {
          return '$scheduledTime Tomorrow';
        } else {
          return '$scheduledTime ${scheduledDate.day}/${scheduledDate.month}';
        }
      }
      return 'Time not set';
    } catch (e) {
      return 'Time not set';
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'New';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile and notifications
              Row(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Color(0xFF4169E1),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      if (_userData?['isVerified'] == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Good Morning!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _userData?['fullName'] ?? 'Loading...',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getVerificationStatus() == 'Verified'
                          ? Colors.green.withAlpha(30)
                          : _getVerificationStatus() == 'Rejected'
                          ? Colors.red.withAlpha(30)
                          : Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getVerificationStatus(),
                      style: TextStyle(
                        color: _getVerificationColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF7F8C8D),
                      size: 28,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        _showLogoutDialog();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                    [
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Logout', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF7F8C8D),
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Today\'s Jobs',
                      value: _stats['todayJobs']?.toString() ?? '0',
                      icon: Icons.today,
                      color: const Color(0xFF3498DB),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      title: 'This Month',
                      value: _stats['monthJobs']?.toString() ?? '0',
                      icon: Icons.calendar_month,
                      color: const Color(0xFF2ECC71),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Earnings',
                      value: '\$${_stats['totalEarnings']?.toStringAsFixed(2) ??
                          '0.00'}',
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFFE67E22),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Rating',
                      value: '${_stats['averageRating']?.toStringAsFixed(1) ??
                          '0.0'}',
                      icon: Icons.star,
                      color: const Color(0xFFF39C12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Recent Service Requests
              const Text(
                'Recent Service Requests',
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
                if (_recentBookings.isEmpty)
                  const Center(child: Text('No recent service requests'))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentBookings.length,
                    itemBuilder: (context, index) {
                      final booking = _recentBookings[index];
                      final status = booking['status'] ?? 'New';
                      final statusColor = status == 'Accepted'
                          ? Colors.green
                          : status == 'Pending'
                          ? Colors.orange
                          : status == 'Rejected'
                          ? Colors.red
                          : const Color(0xFF4169E1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildServiceRequest(
                          title: booking['description'] ?? 'Service Request',
                          client: booking['user_name'] ?? 'Unknown Client',
                          location: booking['address'] ?? 'Unknown Location',
                          time: _formatScheduledTime(booking),
                          status: _formatStatus(booking['status'] ?? 'pending'),
                          statusColor: statusColor,
                          price: '${booking['estimated_cost']?.toStringAsFixed(
                              2) ?? '0.00'} OMR',
                        ),
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
                      icon: Icons.schedule,
                      title: 'Set Availability',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.rate_review,
                      title: 'View Reviews',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const ServiceProviderReviewsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.payment,
                      title: 'Payment History',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.support_agent,
                      title: 'Support',
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Temporary debug button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DebugReviewsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Debug Reviews'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
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

  Widget _buildServiceRequest({
    required String title,
    required String client,
    required String location,
    required String time,
    required String status,
    required Color statusColor,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
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
                  title,
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
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
                client,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF7F8C8D)),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF7F8C8D)),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                ),
              ),
              const Spacer(),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4169E1),
                ),
              ),
            ],
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
              color: Colors.black.withAlpha(15),
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
                color: const Color(0xFF4169E1).withAlpha(30),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You will need to sign in again to access your account.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF7F8C8D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _performLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      // Close the dialog first
      Navigator.of(context).pop();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4169E1)),
                  SizedBox(width: 16),
                  Text('Signing out...'),
                ],
              ),
            ),
          );
        },
      );

      // Sign out using AuthService
      await _authService.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to role selection screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(),
          ),
              (route) => false,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
