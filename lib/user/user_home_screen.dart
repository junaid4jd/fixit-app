import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../role_selection_screen.dart';
import 'bookings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chats_page.dart';
import 'notifications_screen.dart';
import 'available_services_screen.dart';
import 'booking_details_screen.dart' as booking_details;
import 'settings/notification_settings_screen.dart';
import 'settings/privacy_security_screen.dart';
import 'settings/help_support_screen.dart';
import 'settings/about_screen.dart';


class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const BookingsPage(),
    const ChatsPage(),
    ProfilePage(),
  ];

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show confirmation dialog
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Do you want to exit the app?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
        ) ?? false;

        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  String _selectedCity = 'Muscat';

  Widget _buildSlide({
    required String title,
    required String subtitle,
    required String buttonText,
    required List<Color> colors,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: colors[0],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use post frame callback to prevent issues during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Load cities and categories from Firebase
      final cities = await _authService.getCities();
      final categories = await _authService.getCategories();

      if (mounted) {
        setState(() {
          _cities = cities;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error loading data: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4169E1),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Fixit branding
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Text(
                      'Fixit',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4169E1),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        // Navigate to profile tab
                        if (context.findAncestorWidgetOfExactType<
                            UserHomeScreen>() != null) {
                          final userHomeState = context.findAncestorStateOfType<
                              _UserHomeScreenState>();
                          userHomeState?.changeTab(3);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        // Navigate to notifications
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // City Selection
              if (_cities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _showCitySelection,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF4169E1).withValues(
                                alpha: 0.2)),
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
                              color: const Color(0xFF4169E1).withValues(
                                  alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF4169E1),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Service Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedCity,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF4169E1),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
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
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for services in $_selectedCity...',
                      hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFBDC3C7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Promotional Slider
              SizedBox(
                height: 160,
                child: PageView(
                  children: [
                    _buildSlide(
                      title: "Expert Handyman Services",
                      subtitle: "Professional services across Oman",
                      buttonText: "Find Services",
                      colors: [
                        const Color(0xFF4169E1),
                        const Color(0xFF3A5FCD),
                      ],
                      icon: Icons.handyman,
                    ),
                    _buildSlide(
                      title: "24/7 Emergency Repairs",
                      subtitle: "Quick response in Muscat & beyond",
                      buttonText: "Call Now",
                      colors: [
                        const Color(0xFFE67E22),
                        const Color(0xFFD35400),
                      ],
                      icon: Icons.emergency,
                    ),
                    _buildSlide(
                      title: "Verified Professionals",
                      subtitle: "Trusted experts in your area",
                      buttonText: "Browse All",
                      colors: [
                        const Color(0xFF2ECC71),
                        const Color(0xFF27AE60),
                      ],
                      icon: Icons.verified_user,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text(
                  'Popular Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Dynamic Categories Grid
              if (_categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _categories.length > 8 ? 8 : _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return GestureDetector(
                        onTap: () =>
                            _navigateToHandymanFinder(category['name']),
                        child: _buildServiceCard(
                          icon: _getIconFromString(category['icon']),
                          title: category['name'],
                          color: _getCategoryColor(index),
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
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
                    child: const Center(
                      child: Text(
                        'No categories available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // Trusted Handymen Section
              _buildTrustedHandymenSection(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
      case 'electrical_services':
        return Icons.electrical_services;
      case 'painting':
      case 'format_paint':
        return Icons.format_paint;
      case 'cleaning':
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'carpentry':
      case 'handyman':
        return Icons.handyman;
      case 'hvac':
      case 'ac_unit':
        return Icons.ac_unit;
      default:
        return Icons.build;
    }
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFF4169E1), // Blue
      const Color(0xFF2ECC71), // Green
      const Color(0xFFE67E22), // Orange
      const Color(0xFF9B59B6), // Purple
      const Color(0xFFE74C3C), // Red
      const Color(0xFF1ABC9C), // Teal
      const Color(0xFFF39C12), // Yellow
      const Color(0xFF34495E), // Dark Blue
    ];
    return colors[index % colors.length];
  }

  Widget _buildTrustedHandymenSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trusted Handymen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .limit(20) // Get more documents to debug
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                print('Error loading handymen: ${snapshot.error}');
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
                  child: Center(
                    child: Text(
                      'Error loading handymen: ${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              // Debug: Print all handymen data
              if (snapshot.hasData) {
                print('==== HANDYMEN DEBUG INFO ====');
                print('Total documents found: ${snapshot.data!.docs.length}');

                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  print('--- Document ID: ${doc.id} ---');
                  print('Full data: $data');
                  print(
                      'Role: ${data['role']}'); // Changed from 'userType' to 'role'
                  print('FullName: ${data['fullName']}');
                  print(
                      'IsVerified: ${data['isVerified']}'); // Changed from 'isApproved' to 'isVerified'
                  print('IsAvailable: ${data['isAvailable']}');
                  print('Email: ${data['email']}');
                  print('--- End Document ---');
                }
                print('==== END DEBUG INFO ====');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                  child: const Center(
                    child: Text(
                      'No handymen found in the database',
                      style: TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              // Filter handymen from all users - only show verified service providers
              final handymenDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final userRole = data['role'];
                final isVerified = data['isVerified'] == true;
                print(
                    'Checking user: ${data['email']}, role: $userRole, verified: $isVerified');
                return userRole == 'service_provider' && isVerified;
              }).toList();

              print('Filtered handymen count: ${handymenDocs.length}');

              if (handymenDocs.isEmpty) {
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
                  child: const Center(
                    child: Text(
                      'No handymen found (check console for debug info)',
                      style: TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 175, // Slightly reduced to prevent the 7px overflow
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: handymenDocs.length,
                  itemBuilder: (context, index) {
                    final doc = handymenDocs[index];
                    final handymanData = doc.data() as Map<String, dynamic>;

                    return Container(
                      width: 150, // Reduced width for better fit
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 8,
                        right: index == handymenDocs.length - 1 ? 0 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Compact header section
                          Container(
                            padding: const EdgeInsets.all(8),
                            // Reduced from 10 to 8
                            decoration: BoxDecoration(
                              color: const Color(0xFF4169E1).withValues(
                                  alpha: 0.05),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Profile picture with availability
                                Stack(
                                  children: [
                                    Container(
                                      width: 42, // Reduced from 45 to 42
                                      height: 42, // Reduced from 45 to 42
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: ClipOval(
                                        child: handymanData['profileImageUrl'] !=
                                            null
                                            ? Image.network(
                                          handymanData['profileImageUrl'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error,
                                              stackTrace) {
                                            return Container(
                                              color: const Color(0xFF4169E1)
                                                  .withValues(alpha: 0.1),
                                              child: Center(
                                                child: Text(
                                                  (handymanData['fullName'] ??
                                                      'H')[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    // Reduced from 18 to 16
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4169E1),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                            : Container(
                                          color: const Color(0xFF4169E1)
                                              .withValues(alpha: 0.1),
                                          child: Center(
                                            child: Text(
                                              (handymanData['fullName'] ??
                                                  'H')[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                // Reduced from 18 to 16
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF4169E1),
                                              ),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    // Availability indicator
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: handymanData['isAvailable'] ==
                                              true
                                              ? const Color(0xFF2ECC71)
                                              : Colors.orange,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                // Reduced from 6 to 5
                                // Name
                                Text(
                                  handymanData['fullName'] ?? 'Handyman',
                                  style: const TextStyle(
                                    fontSize: 11, // Reduced from 12 to 11
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Content section
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              // Reduced from 8 to 6
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Rating and experience
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        children: [
                                          const Icon(
                                              Icons.star, color: Colors.amber,
                                              size: 11),
                                          // Reduced from 12 to 11
                                          const SizedBox(width: 2),
                                          Text(
                                            '${(handymanData['averageRating'] ??
                                                handymanData['rating'] ?? 0.0)
                                                .toStringAsFixed(1)}',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              // Reduced from 10 to 9
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          // Reduced from 4 to 3
                                          const Text('•', style: TextStyle(
                                              color: Colors.grey, fontSize: 7)),
                                          // Reduced from 8 to 7
                                          const SizedBox(width: 3),
                                          // Reduced from 4 to 3
                                          Text(
                                            '${handymanData['totalReviews'] ??
                                                handymanData['reviewCount'] ??
                                                0} reviews',
                                            style: TextStyle(
                                              fontSize: 9,
                                              // Reduced from 10 to 9
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Reduced from 6 to 4
                                      // Price
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        // Reduced padding
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4169E1)
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                              8), // Reduced from 10 to 8
                                        ),
                                        child: Text(
                                          'OMR ${(handymanData['hourlyRate'] ??
                                              0).toStringAsFixed(0)}/hr',
                                          style: const TextStyle(
                                            fontSize: 9, // Reduced from 10 to 9
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4169E1),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      // Reduced from 4 to 3
                                      // Location
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.location_on, size: 9,
                                              // Reduced from 10 to 9
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 2),
                                          Flexible(
                                            child: Text(
                                              handymanData['city'] ?? 'Muscat',
                                              style: TextStyle(
                                                fontSize: 8,
                                                // Reduced from 9 to 8
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Book Now button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 24, // Reduced from 26 to 24
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _viewHandymanServices(
                                              handymanData, doc.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: handymanData['isVerified'] !=
                                            true
                                            ? Colors.grey[400]
                                            : const Color(0xFF4169E1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              5), // Reduced from 6 to 5
                                        ),
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        handymanData['isVerified'] != true
                                            ? 'Pending'
                                            : 'Book Now',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9, // Reduced from 10 to 9
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToHandymanFinder(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AvailableServicesScreen(initialCategory: category),
      ),
    );
  }

  void _viewHandymanServices(Map<String, dynamic> handymanData,
      String handymanId) {
    // Navigate to handyman services screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _buildHandymanServicesBottomSheet(handymanData, handymanId),
    );
  }

  Widget _buildHandymanServicesBottomSheet(Map<String, dynamic> handymanData,
      String handymanId) {
    return Container(
      height: MediaQuery
          .of(context)
          .size
          .height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF4169E1).withValues(
                      alpha: 0.1),
                  child: handymanData['profileImageUrl'] != null
                      ? ClipOval(
                    child: Image.network(
                      handymanData['profileImageUrl'],
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          (handymanData['fullName'] ?? 'H')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4169E1),
                          ),
                        );
                      },
                    ),
                  )
                      : Text(
                    (handymanData['fullName'] ?? 'H')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4169E1),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        handymanData['fullName'] ?? 'Handyman',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        '${handymanData['experienceYears'] ??
                            0} years experience',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${(handymanData['averageRating'] ??
                                handymanData['rating'] ?? 0.0).toStringAsFixed(
                                1)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${handymanData['totalReviews'] ??
                                handymanData['reviewCount'] ?? 0} reviews)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('handyman_services')
                  .where('handymanId', isEqualTo: handymanId)
                  .where('approvalStatus', isEqualTo: 'approved')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_circle_outlined, size: 64,
                            color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No services available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Services Section
                      const Text(
                        'Available Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Services List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final serviceData = doc.data() as Map<String,
                              dynamic>;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
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
                                        serviceData['title'] ?? 'Service',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4169E1)
                                            .withValues(
                                            alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        serviceData['category'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF4169E1),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  serviceData['description'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text(
                                      'OMR ${(serviceData['price'] ?? 0)
                                          .toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4169E1),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _bookService(
                                              serviceData, doc.id, handymanData,
                                              handymanId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                            0xFF4169E1),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                      child: const Text(
                                        'Book Now',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Reviews Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Customer Reviews',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4169E1).withValues(
                                  alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                    Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${(handymanData['averageRating'] ??
                                      handymanData['rating'] ?? 0.0)
                                      .toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${handymanData['totalReviews'] ??
                                      handymanData['reviewCount'] ?? 0})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Reviews StreamBuilder
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('handyman_id', isEqualTo: handymanId)
                            .where('status', isEqualTo: 'approved')
                            .orderBy('created_at', descending: true)
                            .limit(5)
                            .snapshots(),
                        builder: (context, reviewSnapshot) {
                          if (reviewSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (!reviewSnapshot.hasData ||
                              reviewSnapshot.data!.docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.rate_review_outlined,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No reviews yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Be the first to leave a review!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: reviewSnapshot.data!.docs.map((
                                reviewDoc) {
                              final reviewData = reviewDoc.data() as Map<
                                  String,
                                  dynamic>;
                              final rating = reviewData['rating'] ?? 0;
                              final comment = reviewData['comment'] ?? '';
                              final userName = reviewData['user_name'] ??
                                  'Anonymous';
                              final createdAt = reviewData['created_at'] as Timestamp?;
                              final category = reviewData['category'] ??
                                  'General';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color(
                                              0xFF4169E1).withValues(
                                              alpha: 0.1),
                                          child: Text(
                                            userName.isNotEmpty ? userName[0]
                                                .toUpperCase() : 'U',
                                            style: const TextStyle(
                                              color: Color(0xFF4169E1),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment
                                                .start,
                                            children: [
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2C3E50),
                                                ),
                                              ),
                                              Text(
                                                category,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: List.generate(
                                                  5, (index) {
                                                return Icon(
                                                  index < rating
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 16,
                                                );
                                              }),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatReviewDate(createdAt),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (comment.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(
                                              8),
                                          border: Border.all(
                                              color: Colors.grey[200]!),
                                        ),
                                        child: Text(
                                          comment,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF2C3E50),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatReviewDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _bookService(Map<String, dynamic> serviceData, String serviceId,
      Map<String, dynamic> handymanData, String handymanId) {
    Navigator.pop(context); // Close services modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            booking_details.BookingDetailsScreen(
              serviceData: serviceData,
              serviceId: serviceId,
              handymanData: handymanData,
              handymanId: handymanId,
            ),
      ),
    );
  }



  void _showCitySelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Select Your City',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    final cityName = city['name'];
                    final isSelected = cityName == _selectedCity;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4169E1).withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_city,
                          color: isSelected
                              ? const Color(0xFF4169E1)
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        cityName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight
                              .normal,
                          color: isSelected
                              ? const Color(0xFF4169E1)
                              : const Color(0xFF2C3E50),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4169E1),
                        size: 20,
                      )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCity = cityName;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Circular icon container
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        // Category title
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}



// Comprehensive user profile screen
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedCity = '';
  List<String> _cities = [];
  List<String> _favoriteCategories = [];
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCities();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      if (_authService.currentUserId != null) {
        final userData = await _authService.getUserData(
            _authService.currentUserId!);
        if (mounted && userData != null) {
          setState(() {
            _userData = userData;
            _nameController.text = userData['fullName'] ?? '';
            _phoneController.text = userData['phoneNumber'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _selectedCity = userData['city'] ?? '';
            _favoriteCategories =
            List<String>.from(userData['favoriteCategories'] ?? []);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error loading profile: $e');
      }
    }
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _authService.getCities();
      if (mounted) {
        setState(() {
          _cities = cities.map((city) => city['name'] as String).toList();
        });
      }
    } catch (e) {
      print('Error loading cities: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _authService.getCategories();
      if (mounted) {
        setState(() {
          _availableCategories =
              categories.map((cat) => cat['name'] as String).toList();
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_authService.currentUserId == null) return;

    try {
      final updatedData = {
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _selectedCity,
        'favoriteCategories': _favoriteCategories,
        'updatedAt': Timestamp.now(),
      };

      await _authService.updateUserData(
          _authService.currentUserId!, updatedData);

      if (mounted) {
        setState(() {
          _userData = {..._userData!, ...updatedData};
          _isEditing = false;
        });
        _showSuccessSnackBar('Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating profile: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
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
              'Sign Out',
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
              'Are you sure you want to sign out?',
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF7F8C8D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _performSignOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performSignOut() async {
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
            content: Text('Successfully signed out'),
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
            content: Text('Failed to sign out: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4169E1)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4169E1), Color(0xFF3A5FCD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = !_isEditing;
                            });
                          },
                          icon: Icon(
                            _isEditing ? Icons.close : Icons.edit,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Profile Picture
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF4169E1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userData?['fullName'] ?? 'User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _userData?['email'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profile Information
              if (_isEditing) _buildEditingSection() else
                _buildViewingSection(),

              const SizedBox(height: 20),

              // Statistics Section
              _buildStatisticsSection(),

              const SizedBox(height: 20),

              // Settings Section  
              _buildSettingsSection(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInfoCard(
            'Personal Information',
            [
              _buildInfoRow('Full Name', _userData?['fullName'] ?? 'Not set'),
              _buildInfoRow(
                  'Phone Number', _userData?['phoneNumber'] ?? 'Not set'),
              _buildInfoRow('City', _userData?['city'] ?? 'Not set'),
              _buildInfoRow('Address', _userData?['address'] ?? 'Not set'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Favorite Categories',
            _favoriteCategories.isEmpty
                ? [const Text('No favorite categories selected')]
                : _favoriteCategories.map((category) =>
                Chip(
                  label: Text(category),
                  backgroundColor: const Color(0xFF4169E1).withValues(
                      alpha: 0.1),
                  labelStyle: const TextStyle(color: Color(0xFF4169E1)),
                )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildEditCard(
            'Edit Personal Information',
            [
              _buildTextField('Full Name', _nameController),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', _phoneController,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildCityDropdown(),
              const SizedBox(height: 16),
              _buildTextField('Address', _addressController, maxLines: 3),
            ],
          ),
          const SizedBox(height: 16),
          _buildEditCard(
            'Favorite Categories',
            [
              Wrap(
                spacing: 8,
                children: _availableCategories.map((category) {
                  final isSelected = _favoriteCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _favoriteCategories.add(category);
                        } else {
                          _favoriteCategories.remove(category);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF4169E1).withValues(
                        alpha: 0.2),
                    checkmarkColor: const Color(0xFF4169E1),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      // Reset controllers
                      _nameController.text = _userData?['fullName'] ?? '';
                      _phoneController.text = _userData?['phoneNumber'] ?? '';
                      _addressController.text = _userData?['address'] ?? '';
                      _selectedCity = _userData?['city'] ?? '';
                      _favoriteCategories =
                      List<String>.from(_userData?['favoriteCategories'] ?? []);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                      'Cancel', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                      'Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
              'Your Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Bookings',
                    '${_userData?['totalBookings'] ?? 0}',
                    Icons.calendar_today,
                    const Color(0xFF4169E1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Spent',
                    'OMR ${(_userData?['totalSpent'] ?? 0.0).toStringAsFixed(
                        2)}',
                    Icons.attach_money,
                    const Color(0xFF2ECC71),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
            _buildSettingsItem(
              'Notifications',
              Icons.notifications_outlined,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              'Privacy & Security',
              Icons.security,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySecurityScreen(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              'Help & Support',
              Icons.help_outline,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              'About',
              Icons.info_outline,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              'Sign Out',
              Icons.logout,
              _showSignOutDialog,
              textColor: Colors.red,
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF7F8C8D))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4169E1)),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCity.isEmpty ? null : _selectedCity,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4169E1)),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _cities.map((city) =>
              DropdownMenuItem(
                value: city,
                child: Text(city),
              )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCity = value ?? '';
            });
          },
          hint: const Text('Select a city'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap, {
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF7F8C8D)),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? const Color(0xFF2C3E50),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
          Icons.arrow_forward_ios, size: 16, color: Color(0xFF7F8C8D)),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFE0E0E0));
  }
}
